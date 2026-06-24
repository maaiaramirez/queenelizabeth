/* ═══════════════════════════════════════════════════
   QUEEN ELIZABETH ACADEMY — backend.js
   Conexión real a Supabase: materiales, estadísticas y ventas.

   ⚠️ PASO OBLIGATORIO ANTES DE USAR:
   Reemplazá SUPABASE_URL más abajo por la URL de tu proyecto.
   La encontrás en: Supabase → Project Settings → API → "Project URL"
   (algo como https://abcdefghij.supabase.co)
═══════════════════════════════════════════════════ */

"use strict";

const SUPABASE_URL = "https://TU-PROYECTO.supabase.co"; // ← REEMPLAZAR
const SUPABASE_ANON_KEY = "sb_publishable_WjBgPoBpB1ONRrQh_JSucA_X_cCiDZY";

// Cliente global de Supabase (la librería se carga vía CDN en index.html)
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Bucket donde se guardan los archivos subidos
const MATERIALS_BUCKET = "materials";

// ── Identidad simple del alumno (sin login todavía) ──
// Se guarda en localStorage solo para no pedir el nombre/email cada vez
// en ESTE navegador. No es una sesión segura ni multi-dispositivo.
function getStudentIdentity() {
  let name = localStorage.getItem("qe_student_name");
  let email = localStorage.getItem("qe_student_email");
  return { name, email };
}

function setStudentIdentity(name, email) {
  localStorage.setItem("qe_student_name", name);
  localStorage.setItem("qe_student_email", email);
}

// ── CURSOS Y LECCIONES ────────────────────────────────
async function fetchCourses() {
  const { data, error } = await supabaseClient
    .from("courses")
    .select("id, title, level")
    .order("created_at", { ascending: true });
  if (error) { console.error("fetchCourses:", error); return []; }
  return data;
}

async function fetchLessons(courseId) {
  const { data, error } = await supabaseClient
    .from("lessons")
    .select("id, title, position")
    .eq("course_id", courseId)
    .order("position", { ascending: true });
  if (error) { console.error("fetchLessons:", error); return []; }
  return data;
}

// ── MATERIALES ─────────────────────────────────────────
async function fetchAllMaterials() {
  const { data, error } = await supabaseClient
    .from("materials")
    .select("id, title, type, file_path, external_url, description, created_at, lessons(title, course_id, courses(title))")
    .order("created_at", { ascending: false });
  if (error) { console.error("fetchAllMaterials:", error); return []; }
  return data;
}

function getMaterialPublicUrl(filePath) {
  if (!filePath) return null;
  const { data } = supabaseClient.storage.from(MATERIALS_BUCKET).getPublicUrl(filePath);
  return data?.publicUrl || null;
}

// Subir un archivo real (PDF, audio o video) y crear el registro del material
async function uploadMaterial({ file, lessonId, title, type, description, externalUrl }) {
  let filePath = null;

  if (file) {
    const safeName = file.name.replace(/[^a-zA-Z0-9.\-_]/g, "_");
    filePath = `${lessonId || "general"}/${Date.now()}_${safeName}`;
    const { error: uploadError } = await supabaseClient
      .storage
      .from(MATERIALS_BUCKET)
      .upload(filePath, file);
    if (uploadError) {
      console.error("uploadMaterial (storage):", uploadError);
      throw uploadError;
    }
  }

  const { data, error } = await supabaseClient
    .from("materials")
    .insert({
      lesson_id: lessonId || null,
      title,
      type,
      file_path: filePath,
      external_url: externalUrl || null,
      description: description || null,
    })
    .select()
    .single();

  if (error) { console.error("uploadMaterial (insert):", error); throw error; }
  return data;
}

async function deleteMaterial(materialId, filePath) {
  if (filePath) {
    await supabaseClient.storage.from(MATERIALS_BUCKET).remove([filePath]);
  }
  const { error } = await supabaseClient.from("materials").delete().eq("id", materialId);
  if (error) { console.error("deleteMaterial:", error); throw error; }
}

// Registrar que un alumno vio o descargó un material (esto da las stats reales)
async function logMaterialEvent(materialId, action) {
  const { name, email } = getStudentIdentity();
  const { error } = await supabaseClient.from("material_events").insert({
    material_id: materialId,
    student_name: name || "Anónimo",
    student_email: email || null,
    action, // 'view' | 'download'
  });
  if (error) console.error("logMaterialEvent:", error);
}

// ── PLANES Y VENTAS (módulo comercial) ────────────────
async function fetchPlans() {
  const { data, error } = await supabaseClient
    .from("plans")
    .select("id, name, price, period, description")
    .order("price", { ascending: true });
  if (error) { console.error("fetchPlans:", error); return []; }
  return data;
}

async function registerSale({ planId, planName, amount, studentName, studentEmail }) {
  const { data, error } = await supabaseClient
    .from("sales")
    .insert({
      plan_id: planId,
      plan_name: planName,
      amount,
      student_name: studentName,
      student_email: studentEmail,
      status: "pendiente",
    })
    .select()
    .single();
  if (error) { console.error("registerSale:", error); throw error; }
  return data;
}

// ── ESTADÍSTICAS REALES (sin simular nada) ────────────
async function fetchRealStats() {
  const [salesRes, eventsRes, materialsRes] = await Promise.all([
    supabaseClient.from("sales").select("amount, status, student_email, created_at"),
    supabaseClient.from("material_events").select("material_id, action, student_email, created_at"),
    supabaseClient.from("materials").select("id, title"),
  ]);

  const sales = salesRes.data || [];
  const events = eventsRes.data || [];
  const materials = materialsRes.data || [];

  const totalRevenue = sales
    .filter(s => s.status === "pagado")
    .reduce((sum, s) => sum + Number(s.amount), 0);

  const totalSalesCount = sales.length;

  const uniqueStudents = new Set(
    [...sales.map(s => s.student_email), ...events.map(e => e.student_email)].filter(Boolean)
  ).size;

  const viewsByMaterial = {};
  events.forEach(e => {
    viewsByMaterial[e.material_id] = (viewsByMaterial[e.material_id] || 0) + 1;
  });

  const topMaterials = Object.entries(viewsByMaterial)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([materialId, count]) => {
      const material = materials.find(m => m.id === materialId);
      return { title: material ? material.title : "Material eliminado", views: count };
    });

  return {
    totalRevenue,
    totalSalesCount,
    uniqueStudents,
    totalMaterialEvents: events.length,
    totalMaterials: materials.length,
    topMaterials,
  };
}

// ── ACCESO AL PANEL DOCENTE (gate simple, NO es seguridad real) ─
// Esto solo evita que cualquier visitante toque el botón por error.
// Para seguridad real hay que sumar Supabase Auth con roles.
const TEACHER_ACCESS_CODE = "queen2026";
function checkTeacherAccess(code) {
  return code === TEACHER_ACCESS_CODE;
}

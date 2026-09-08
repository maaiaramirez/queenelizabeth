#!/bin/bash
set -e
echo "Corré esto parado en la raíz del repo"
rm -f aplicar_suspendida.sh aplicar_estados.sh aplicar_fixdelete.sh aplicar_fixprofile.sh aplicar_dropzone.sh aplicar_cambios.sh aplicar_cambios2.sh
cat > server.js << 'SERVERJS_EOF'
// server.js - Frontend estático + API en un solo servicio (Render)
require('dotenv').config();

const path = require('path');
const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());

app.use(express.static(path.join(__dirname, 'client', 'dist')));

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

function getMailTransport() {
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) return null;
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}

function receiptHtml(sale) {
  const receiptNo = 'REC-' + String(sale.id).slice(0, 8).toUpperCase();
  return `
    <div style="font-family: Georgia, serif; max-width: 480px; margin: 0 auto; border: 1px solid #ddd; padding: 24px;">
      <h2 style="margin: 0 0 4px">Queen Elizabeth Academy</h2>
      <p style="color:#666; margin-top:0">Recibo de pago — ${receiptNo}</p>
      <hr />
      <p><strong>Alumno:</strong> ${sale.student_name || '—'}</p>
      <p><strong>Plan:</strong> ${sale.plan_name || '—'}</p>
      <p><strong>Fecha:</strong> ${new Date(sale.created_at).toLocaleDateString('es-AR')}</p>
      <p><strong>Estado:</strong> ${sale.status}</p>
      <p style="font-size: 1.2em"><strong>Monto:</strong> $${Number(sale.amount || 0).toLocaleString('es-AR')}</p>
      <p style="color:#999; font-size: 0.8em; margin-top: 24px">Comprobante generado digitalmente.</p>
    </div>`;
}

async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Falta token de autenticación' });

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }

  const { data: profile, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('role, payment_status')
    .eq('id', data.user.id)
    .single();
  if (profileError || !profile) {
    return res.status(401).json({ error: 'Perfil no encontrado' });
  }

  req.user = { id: data.user.id, role: profile.role, paymentStatus: profile.payment_status };
  next();
}

const authorize = (role) => (req, res, next) => {
  if (req.user.role !== role) return res.status(403).json({ error: 'Acceso denegado' });
  next();
};

async function requirePaidPlan(req, res, next) {
  if (req.user.paymentStatus === 'pagado') return next();

  const { data: sale, error } = await supabaseAdmin
    .from('sales')
    .select('id, status')
    .eq('student_user_id', req.user.id)
    .eq('status', 'pagado')
    .limit(1)
    .maybeSingle();
  if (error) return res.status(500).json({ error: error.message });
  if (!sale) {
    return res.status(403).json({
      error: 'Necesitás tener un plan pagado y confirmado para rendir el Test de Nivel.',
      code: 'PLAN_NOT_PAID',
    });
  }
  next();
}

app.get('/api/lessons/:id', requireAuth, async (req, res) => {
  const { user } = req;
  const hasCompleted = await hasCompletedPrevious(user.id, req.params.id);
  if (!hasCompleted) {
    return res.status(401).json({ error: 'Contenido bloqueado: completa el hito anterior.' });
  }
  res.json({ title: 'British Pronunciation', content: '...' });
});

async function hasCompletedPrevious(userId, lessonId) {
  return true;
}

app.get('/api/level-test/questions', requireAuth, requirePaidPlan, async (req, res) => {
  const { data, error } = await supabaseAdmin
    .from('level_test_questions')
    .select('id, level, skill, question, options, audio_url')
    .eq('is_active', true);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ questions: data });
});

const CEFR_ORDER = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

function assignLevel(levelScores) {
  let assigned = 'A1';
  for (const level of CEFR_ORDER) {
    const s = levelScores[level];
    if (!s || s.total === 0) continue;
    const ratio = s.correct / s.total;
    if (ratio >= 0.6) {
      assigned = level;
    } else {
      break;
    }
  }
  return assigned;
}

app.post('/api/level-test/submit', requireAuth, requirePaidPlan, async (req, res) => {
  const { answers, cheatEvents, startedAt } = req.body || {};
  if (!Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({ error: 'Faltan respuestas.' });
  }

  const { data: existing, error: existingError } = await supabaseAdmin
    .from('level_test_results')
    .select('id')
    .eq('student_id', req.user.id)
    .limit(1)
    .maybeSingle();
  if (existingError) return res.status(500).json({ error: existingError.message });
  if (existing) return res.status(409).json({ error: 'Ya rendiste el Test de Nivel. No se puede repetir.' });

  const questionIds = answers.map((a) => a.question_id).filter(Boolean);
  const { data: questions, error: qError } = await supabaseAdmin
    .from('level_test_questions')
    .select('id, level, correct_index')
    .in('id', questionIds);
  if (qError) return res.status(500).json({ error: qError.message });

  const qMap = Object.fromEntries(questions.map((q) => [q.id, q]));
  const levelScores = {};
  let score = 0;

  const gradedAnswers = answers.map((a) => {
    const q = qMap[a.question_id];
    if (!q) return { question_id: a.question_id, selected_index: a.selected_index, correct: false };
    const correct = q.correct_index === a.selected_index;
    levelScores[q.level] = levelScores[q.level] || { correct: 0, total: 0 };
    levelScores[q.level].total += 1;
    if (correct) {
      levelScores[q.level].correct += 1;
      score += 1;
    }
    return { question_id: a.question_id, selected_index: a.selected_index, correct };
  });

  const levelAssigned = assignLevel(levelScores);
  const flaggedCheat = Array.isArray(cheatEvents) && cheatEvents.length > 0;

  const { data: inserted, error: insertError } = await supabaseAdmin
    .from('level_test_results')
    .insert([
      {
        student_id: req.user.id,
        level_assigned: levelAssigned,
        score,
        total_questions: answers.length,
        answers: gradedAnswers,
        flagged_cheat: flaggedCheat,
        cheat_events: cheatEvents || [],
        started_at: startedAt || new Date().toISOString(),
        completed_at: new Date().toISOString(),
      },
    ])
    .select()
    .single();
  if (insertError) return res.status(500).json({ error: insertError.message });

  res.json({ result: inserted });
});

app.post('/api/receipts/send', requireAuth, async (req, res) => {
  if (!['admin', 'teacher'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  const { saleId } = req.body || {};
  if (!saleId) return res.status(400).json({ error: 'Falta saleId' });

  const { data: sale, error: saleError } = await supabaseAdmin
    .from('sales')
    .select('*')
    .eq('id', saleId)
    .single();
  if (saleError || !sale) return res.status(404).json({ error: 'Venta no encontrada' });
  if (!sale.student_email) return res.status(400).json({ error: 'Esta venta no tiene email de alumno cargado' });

  const transport = getMailTransport();
  if (!transport) {
    return res.status(503).json({
      error:
        'El envío de mail no está configurado todavía. Faltan las variables SMTP_HOST, SMTP_USER y SMTP_PASS en el servidor.',
    });
  }

  try {
    await transport.sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: sale.student_email,
      subject: `Tu recibo — Queen Elizabeth Academy (${sale.plan_name || 'Plan'})`,
      html: receiptHtml(sale),
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Error enviando recibo:', err.message);
    res.status(500).json({ error: 'No se pudo enviar el mail. Revisá las credenciales SMTP.' });
  }
});

async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Falta token de autenticación' });
  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) return res.status(401).json({ error: 'Token inválido o expirado' });
  req.authUser = data.user;
  next();
}

app.post('/api/auth/ensure-profile', verifyToken, async (req, res) => {
  const { displayName, role } = req.body || {};
  const user = req.authUser;

  const { data: existing } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('id', user.id)
    .maybeSingle();
  if (existing) return res.json({ ok: true, alreadyExisted: true });

  const { error } = await supabaseAdmin.from('profiles').insert([
    {
      id: user.id,
      email: user.email,
      display_name: displayName || user.email?.split('@')[0] || 'Usuario',
      role: ['student', 'teacher', 'admin'].includes(role) ? role : 'student',
      payment_status: 'pendiente',
    },
  ]);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true, alreadyExisted: false });
});

app.delete('/api/admin/users/:id', requireAuth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Acceso denegado' });
  const { id } = req.params;
  if (id === req.user.id) return res.status(400).json({ error: 'No podés borrar tu propia cuenta.' });

  const { error } = await supabaseAdmin.auth.admin.deleteUser(id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
});

app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'dist', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Academy corriendo en puerto ${PORT}`));
SERVERJS_EOF

cat > client/src/services/auth.js << 'AUTHJS_EOF'
import { supabase } from '../lib/supabase'

/**
 * Registra un nuevo usuario y crea su perfil con el rol indicado.
 * role: 'student' | 'teacher' | 'admin'
 */
export async function signUpUser(email, password, displayName, role = 'student') {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { display_name: displayName, role } },
  })
  if (error) throw error

  // El trigger on_auth_user_created de Supabase debería crear el perfil solo,
  // pero por las dudas lo garantizamos también acá (idempotente, no duplica).
  if (data.session?.access_token) {
    try {
      await fetch('/api/auth/ensure-profile', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${data.session.access_token}`,
        },
        body: JSON.stringify({ displayName, role }),
      })
    } catch (e) {
      console.error('No se pudo asegurar el perfil vía API:', e)
    }
  }

  return data
}

export async function signInUser(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

export async function signOutUser() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export async function getCurrentUser() {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  return user
}

export async function getCurrentProfile() {
  const user = await getCurrentUser()
  if (!user) return null
  let { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single()
  if (error) {
    // Perfil faltante (cuenta vieja/rota): lo creamos ahora mismo, server-side.
    const {
      data: { session },
    } = await supabase.auth.getSession()
    if (session?.access_token) {
      try {
        await fetch('/api/auth/ensure-profile', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${session.access_token}` },
          body: JSON.stringify({ displayName: user.user_metadata?.display_name, role: user.user_metadata?.role }),
        })
        ;({ data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single())
      } catch (e) {
        console.error('No se pudo autoreparar el perfil:', e)
      }
    }
  }
  if (error) return null
  return data
}

export function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange((event, session) => callback(event, session))
}

export async function checkTeacherAccess() {
  const profile = await getCurrentProfile()
  return !!profile && (profile.role === 'teacher' || profile.role === 'admin')
}

export function traducirError(msg) {
  if (!msg) return 'Ocurrió un error inesperado.'
  if (msg.includes('Invalid login credentials')) return 'Email o contraseña incorrectos.'
  if (msg.includes('Email not confirmed')) return 'Confirmá tu email antes de ingresar.'
  if (msg.includes('User already registered')) return 'Ese email ya tiene una cuenta registrada.'
  if (msg.includes('Password should be')) return 'La contraseña debe tener al menos 6 caracteres.'
  return msg
}

export function rolLabel(role) {
  return { admin: 'Admin', teacher: 'Docente', student: 'Alumno' }[role] || role
}
AUTHJS_EOF

cat > client/src/services/profiles.js << 'PROFILESJS_EOF'
import { supabase } from '../lib/supabase'

export async function fetchAllProfiles() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, email, display_name, role, payment_status, created_at')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function updateUserRole(userId, newRole) {
  const { error } = await supabase.from('profiles').update({ role: newRole }).eq('id', userId)
  if (error) throw error
}

export async function deleteUserProfile(userId) {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  const res = await fetch(`/api/admin/users/${userId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${session?.access_token || ''}` },
  })
  const body = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(body.error || 'No se pudo borrar la cuenta')
  return body
}

export async function fetchAllStudents() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, display_name, email')
    .eq('role', 'student')
    .order('display_name')
  if (error) throw error
  return data || []
}

export async function fetchProfileCountsByRole() {
  const { data, error } = await supabase.from('profiles').select('role')
  if (error) throw error
  const counts = { student: 0, teacher: 0, admin: 0 }
  ;(data || []).forEach((p) => {
    if (counts[p.role] !== undefined) counts[p.role]++
  })
  return counts
}

export async function fetchAllStudentsPayment() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, display_name, email, payment_status, created_at')
    .eq('role', 'student')
    .order('display_name')
  if (error) throw error
  return data || []
}

export async function updatePaymentStatus(userId, status) {
  const { error } = await supabase.from('profiles').update({ payment_status: status }).eq('id', userId)
  if (error) throw error
}
PROFILESJS_EOF

cat > client/src/views/AdminUsersView.vue << 'ADMINUSERS_VUE_EOF'
<script setup>
import { onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { fetchAllProfiles, updateUserRole, deleteUserProfile, updatePaymentStatus } from '../services/profiles'

const toast = useToastStore()

const profiles = ref([])
const loading = ref(false)
const ROLES = ['student', 'teacher', 'admin']
const ROLE_LABELS = { student: 'Alumno', teacher: 'Docente', admin: 'Admin' }

function isActive(profile) {
  return profile.payment_status !== 'cancelado'
}

async function loadProfiles() {
  loading.value = true
  try {
    profiles.value = await fetchAllProfiles()
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo cargar la lista de usuarios.')
  } finally {
    loading.value = false
  }
}

async function handleRoleChange(profile, event) {
  const newRole = event.target.value
  const previous = profile.role
  try {
    await updateUserRole(profile.id, newRole)
    profile.role = newRole
    toast.show(`✓ Rol actualizado: ${profile.display_name} ahora es ${ROLE_LABELS[newRole]}`)
  } catch (err) {
    console.error(err)
    event.target.value = previous
    toast.show('⚠ No se pudo actualizar el rol.')
  }
}

async function handleDelete(profile) {
  if (!confirm(`¿Borrar la cuenta de ${profile.display_name} (${profile.email})? Esta acción no se puede deshacer.`)) return
  try {
    await deleteUserProfile(profile.id)
    toast.show(`✓ Cuenta de ${profile.display_name} eliminada.`)
    await loadProfiles()
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo borrar la cuenta.')
  }
}

async function handleToggleActive(profile) {
  const goingActive = !isActive(profile)
  const newStatus = goingActive ? 'pendiente' : 'cancelado'
  if (!goingActive && !confirm(`¿Desactivar la cuenta de ${profile.display_name}? Va a quedar suspendida.`)) return
  try {
    await updatePaymentStatus(profile.id, newStatus)
    profile.payment_status = newStatus
    toast.show(goingActive ? `✓ ${profile.display_name} reactivado` : `✓ ${profile.display_name} desactivado`)
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo cambiar el estado.')
  }
}

onMounted(loadProfiles)
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Usuarios</h1>
      <p class="dash__subtitle">Gestión de roles y cuentas.</p>
    </div>

    <div class="dash__panel" style="margin-top: 1.5rem">
      <p v-if="loading" style="opacity: 0.6">Cargando…</p>
      <table v-else style="width: 100%; border-collapse: collapse">
        <thead>
          <tr style="text-align: left; border-bottom: 1px solid rgba(0,0,0,.08)">
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Usuario
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Cambiar rol
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Rol actual
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Estado
            </th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in profiles" :key="p.id" style="border-bottom: 1px solid rgba(0,0,0,.05)">
            <td style="padding: 0.75rem 0">
              <strong style="display: block; color: var(--navy)">{{ p.display_name }}</strong>
              <span style="font-size: 0.85rem; opacity: 0.6">{{ p.email }}</span>
            </td>
            <td>
              <select :value="p.role" @change="handleRoleChange(p, $event)">
                <option v-for="r in ROLES" :key="r" :value="r">{{ ROLE_LABELS[r] }}</option>
              </select>
            </td>
            <td>
              <span
                style="
                  font-size: 0.75rem;
                  font-weight: 700;
                  letter-spacing: 0.03em;
                  padding: 0.25rem 0.6rem;
                  border-radius: 999px;
                  background: var(--ivory-dark);
                  color: var(--navy);
                  text-transform: uppercase;
                "
              >
                {{ ROLE_LABELS[p.role] || p.role }}
              </span>
            </td>
            <td>
              <span
                :style="{
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  letterSpacing: '0.03em',
                  padding: '0.25rem 0.6rem',
                  borderRadius: '999px',
                  textTransform: 'uppercase',
                  background: isActive(p) ? '#e3f5ea' : '#fbe4e4',
                  color: isActive(p) ? '#1e7e42' : '#c0392b',
                }"
              >
                {{ isActive(p) ? 'Activo' : 'Desactivado' }}
              </span>
            </td>
            <td style="text-align: right">
              <button
                class="btn btn--sm"
                style="margin-right: 0.4rem"
                @click="handleToggleActive(p)"
              >
                {{ isActive(p) ? '🚫 Desactivar' : '✓ Reactivar' }}
              </button>
              <button class="btn btn--sm" style="border-color: #c0392b; color: #c0392b" @click="handleDelete(p)">
                🗑 Borrar
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </DashboardLayout>
</template>
ADMINUSERS_VUE_EOF

cat > fix_delete_usuarios.sql << 'FIXSQL_EOF'
-- Permite borrar un perfil aunque tenga datos relacionados.
-- Regla aplicada:
--   - Inscripciones y eventos de materiales del alumno: se borran en cascada (son del alumno).
--   - Ventas, materiales subidos, carpetas/items de biblioteca, cursos (como docente),
--     actividades extra y bajas registradas: se CONSERVAN como historial, solo se
--     desvincula la referencia al usuario (queda en null).

-- El borrado real ahora se hace sobre auth.users (vía backend con service role),
-- así que profiles tiene que caer en cascada cuando se borra el usuario de Auth.
alter table public.profiles drop constraint if exists profiles_id_fkey;
alter table public.profiles add constraint profiles_id_fkey
  foreign key (id) references auth.users(id) on delete cascade;

alter table public.enrollments drop constraint if exists enrollments_student_id_fkey;
alter table public.enrollments add constraint enrollments_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete cascade;

alter table public.material_events drop constraint if exists material_events_student_id_fkey;
alter table public.material_events add constraint material_events_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete cascade;

alter table public.courses drop constraint if exists courses_teacher_id_fkey;
alter table public.courses add constraint courses_teacher_id_fkey
  foreign key (teacher_id) references public.profiles(id) on delete set null;

alter table public.materials drop constraint if exists materials_uploaded_by_fkey;
alter table public.materials add constraint materials_uploaded_by_fkey
  foreign key (uploaded_by) references public.profiles(id) on delete set null;

alter table public.library_folders drop constraint if exists library_folders_created_by_fkey;
alter table public.library_folders add constraint library_folders_created_by_fkey
  foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.library_items drop constraint if exists library_items_uploaded_by_fkey;
alter table public.library_items add constraint library_items_uploaded_by_fkey
  foreign key (uploaded_by) references public.profiles(id) on delete set null;

alter table public.sales drop constraint if exists sales_student_id_fkey;
alter table public.sales add constraint sales_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete set null;

alter table public.cancellations drop constraint if exists cancellations_student_id_fkey;
alter table public.cancellations add constraint cancellations_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete set null;

alter table public.extra_activities add column if not exists created_by uuid;
alter table public.extra_activities drop constraint if exists extra_activities_created_by_fkey;
alter table public.extra_activities add constraint extra_activities_created_by_fkey
  foreign key (created_by) references public.profiles(id) on delete set null;
FIXSQL_EOF

rm -f "$0"
git add -A
git commit -m "fix: estados de usuario, borrado completo (auth+profile), y creacion garantizada de perfil"
git push origin main
echo ""
echo "==================================================="
echo "LISTO. Ahora te faltan 2 cosas MANUALES:"
echo "1) Correr fix_delete_usuarios.sql en el SQL Editor de Supabase"
echo "2) En Render: Manual Deploy -> Deploy latest commit"
echo "==================================================="

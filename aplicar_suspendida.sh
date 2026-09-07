#!/bin/bash
set -e
echo "Corré este script parado en la raíz del repo"
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

rm -f "$0"
git add -A
git commit -m "fix: borrar usuario ahora elimina tambien el auth.user (antes solo borraba profiles y quedaba huerfano)"
git push origin main
echo "Listo. Acordate: Manual Deploy -> Deploy latest commit en Render."
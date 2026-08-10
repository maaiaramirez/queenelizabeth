// server.js - Frontend estático + API en un solo servicio (Render)
require('dotenv').config();

const path = require('path');
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(express.json());

app.use(express.static(path.join(__dirname, 'client', 'dist')));

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Falta token de autenticación' });

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) return res.status(401).json({ error: 'Token inválido o expirado' });

  const { data: profile, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .single();
  if (profileError || !profile) return res.status(401).json({ error: 'Perfil no encontrado' });

  req.user = { id: data.user.id, role: profile.role };
  next();
}

const authorize = (role) => (req, res, next) => {
  if (req.user.role !== role) return res.status(403).json({ error: 'Acceso denegado' });
  next();
};

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

app.get('/api/level-test/questions', requireAuth, async (req, res) => {
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

app.post('/api/level-test/submit', requireAuth, async (req, res) => {
  const { answers, cheatEvents, startedAt } = req.body || {};
  if (!Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({ error: 'Faltan respuestas.' });
  }

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

app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'dist', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Academy corriendo en puerto ${PORT}`));

// server.js - Frontend estático + API en un solo servicio (Render)
require('dotenv').config();

const path = require('path');
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(express.json());

// ── Servir el frontend estático (build de Vue en client/dist) ───
app.use(express.static(path.join(__dirname, 'client', 'dist')));

// ── Cliente de Supabase del lado del servidor ───────────────────
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ── Middleware: verifica el JWT de Supabase y arma req.user ─────
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

// ── API ──────────────────────────────────────────────────────────
app.get('/api/lessons/:id', requireAuth, async (req, res) => {
  const { user } = req;
  const hasCompleted = await hasCompletedPrevious(user.id, req.params.id);
  if (!hasCompleted) {
    return res.status(401).json({ error: 'Contenido bloqueado: completa el hito anterior.' });
  }
  res.json({ title: 'British Pronunciation', content: '...' });
});

async function hasCompletedPrevious(userId, lessonId) {
  // TODO: consulta real contra tu tabla de progreso.
  return true;
}

// ── Fallback: cualquier ruta que no sea /api/* devuelve index.html ──
// (necesario para que funcione el router de Vue con rutas como /dashboard)
app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'dist', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Academy corriendo en puerto ${PORT}`));

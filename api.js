// services/api.js — capa única de acceso HTTP.
// Los stores nunca hacen fetch/axios directo: todo pasa por acá,
// así se puede mockear en tests y cambiar de backend sin tocar componentes.

const BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

async function request(path, options = {}) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error || `Error ${res.status} en ${path}`)
  }
  return res.json()
}

// ── Onboarding / test nivelador ──────────────────────────────
export function fetchLevelTestQuestions() {
  return request('/level-test/questions')
}

export function assignCourseAndTutor({ level }) {
  return request('/level-test/assign', {
    method: 'POST',
    body: JSON.stringify({ level }),
  })
}

// ── Docente ───────────────────────────────────────────────────
export function fetchAssignedStudents() {
  return request('/teacher/students')
}

export function fetchAttendanceStats() {
  return request('/teacher/attendance-stats')
}

// ── Admin ─────────────────────────────────────────────────────
export function createCourse(payload) {
  return request('/admin/courses', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

import { supabase } from '../lib/supabase'

async function authHeader() {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session) throw new Error('Necesitás estar logueado para rendir el test.')
  return { Authorization: `Bearer ${session.access_token}` }
}

export async function fetchLevelTestQuestions() {
  const headers = await authHeader()
  const res = await fetch('/api/level-test/questions', { headers })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error || 'No se pudieron cargar las preguntas del test.')
  }
  const { questions } = await res.json()
  return questions || []
}

export async function submitLevelTest({ answers, cheatEvents, startedAt }) {
  const headers = await authHeader()
  const res = await fetch('/api/level-test/submit', {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ answers, cheatEvents, startedAt }),
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error || 'No se pudo enviar el test.')
  }
  const { result } = await res.json()
  return result
}

export async function fetchMyLastLevelTestResult() {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return null
  const { data, error } = await supabase
    .from('level_test_results')
    .select('*')
    .eq('student_id', user.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (error) throw error
  return data
}

export async function fetchAllLevelTestResults() {
  const { data, error } = await supabase
    .from('level_test_results')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

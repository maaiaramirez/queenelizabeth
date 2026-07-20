import { supabase } from '../lib/supabase'

export async function fetchAllProfiles() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, email, display_name, role, created_at')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function updateUserRole(userId, newRole) {
  const { error } = await supabase.from('profiles').update({ role: newRole }).eq('id', userId)
  if (error) throw error
}

export async function deleteUserProfile(userId) {
  const { error } = await supabase.from('profiles').delete().eq('id', userId)
  if (error) throw error
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

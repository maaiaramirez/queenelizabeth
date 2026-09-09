import { supabase } from '../lib/supabase'

export async function fetchActiveActivities() {
  const { data, error } = await supabase
    .from('extra_activities')
    .select('id, title, description, level, questions, created_at')
    .eq('active', true)
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function fetchAllActivitiesAdmin() {
  const { data, error } = await supabase
    .from('extra_activities')
    .select('id, title, description, level, questions, active, created_at')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function createActivity({ title, description, level, questions }) {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  const { data, error } = await supabase
    .from('extra_activities')
    .insert([{ title, description, level, questions, active: true, created_by: user?.id || null }])
    .select()
  if (error) throw error
  return data
}

export async function updateActivity(id, changes) {
  const { data, error } = await supabase
    .from('extra_activities')
    .update(changes)
    .eq('id', id)
    .select()
  if (error) throw error
  return data
}

export async function toggleActivityActive(id, active) {
  return updateActivity(id, { active })
}

export async function deleteActivity(id) {
  const { error } = await supabase.from('extra_activities').delete().eq('id', id)
  if (error) throw error
}

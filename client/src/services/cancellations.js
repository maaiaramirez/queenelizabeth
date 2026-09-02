import { supabase } from '../lib/supabase'

export const CANCELLATION_REASONS = {
  precio: 'El precio',
  tiempo: 'Falta de tiempo',
  no_cumplio_expectativas: 'No cumplió mis expectativas',
  cambio_metodo: 'Prefiero otro método de estudio',
  otro: 'Otro motivo',
}

export async function submitCancellation({ reason, reasonDetail, satisfaction, comments }) {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) throw new Error('No hay sesión activa')

  const { data: profile } = await supabase
    .from('profiles')
    .select('display_name, email')
    .eq('id', user.id)
    .single()

  const { error: insertError } = await supabase.from('cancellations').insert([
    {
      student_id: user.id,
      student_name: profile?.display_name || '',
      student_email: profile?.email || user.email,
      reason,
      reason_detail: reasonDetail || null,
      satisfaction,
      comments: comments || null,
    },
  ])
  if (insertError) throw insertError

  const { error: statusError } = await supabase
    .from('profiles')
    .update({ payment_status: 'cancelado' })
    .eq('id', user.id)
  if (statusError) throw statusError
}

export async function fetchAllCancellations() {
  const { data, error } = await supabase
    .from('cancellations')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

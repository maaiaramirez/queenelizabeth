import { supabase } from '../lib/supabase'

export async function registerSale({ planId, planName, amount, studentName, studentEmail }) {
  const { data, error } = await supabase
    .from('sales')
    .insert([
      {
        plan_id: planId,
        plan_name: planName,
        amount,
        student_name: studentName,
        student_email: studentEmail,
        status: 'pagado',
      },
    ])
    .select()
  if (error) throw error
  return data
}

export async function fetchAllSales() {
  const { data, error } = await supabase.from('sales').select('*').order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function updateSaleStatus(saleId, status) {
  const { error } = await supabase.from('sales').update({ status }).eq('id', saleId)
  if (error) throw error
}

export function fmtMoney(n) {
  return '$' + Number(n || 0).toLocaleString('es-AR', { maximumFractionDigits: 0 })
}

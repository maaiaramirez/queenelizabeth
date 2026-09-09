import { supabase } from '../lib/supabase'

export async function startCheckout({ planSlug, saleId } = {}) {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  const res = await fetch('/api/payments/create-preference', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session?.access_token || ''}`,
    },
    body: JSON.stringify({ planSlug, saleId }),
  })
  const body = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(body.error || 'No se pudo iniciar el pago')
  return body.initPoint
}

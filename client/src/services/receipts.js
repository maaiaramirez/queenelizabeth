import jsPDF from 'jspdf'
import { supabase } from '../lib/supabase'

function receiptNumber(sale) {
  return 'REC-' + sale.id.slice(0, 8).toUpperCase()
}

export function buildReceiptDoc(sale) {
  const doc = new jsPDF({ unit: 'pt', format: 'a4' })
  const pageWidth = doc.internal.pageSize.getWidth()

  doc.setFont('times', 'bold')
  doc.setFontSize(20)
  doc.text('Queen Elizabeth Academy', 40, 60)

  doc.setFont('times', 'normal')
  doc.setFontSize(10)
  doc.text('Recibo de pago', 40, 80)

  doc.setDrawColor(180)
  doc.line(40, 95, pageWidth - 40, 95)

  doc.setFontSize(11)
  const rows = [
    ['N° de recibo', receiptNumber(sale)],
    ['Fecha', new Date(sale.created_at).toLocaleDateString('es-AR')],
    ['Alumno', sale.student_name || '—'],
    ['Email', sale.student_email || '—'],
    ['Plan', sale.plan_name || '—'],
    ['Estado', sale.status],
    ['Monto', '$' + Number(sale.amount || 0).toLocaleString('es-AR')],
  ]

  let y = 130
  rows.forEach(([label, value]) => {
    doc.setFont('times', 'bold')
    doc.text(label + ':', 40, y)
    doc.setFont('times', 'normal')
    doc.text(String(value), 200, y)
    y += 24
  })

  doc.setFontSize(9)
  doc.setTextColor(120)
  doc.text('Este comprobante fue generado digitalmente por Queen Elizabeth Academy.', 40, y + 20)

  return doc
}

export function downloadReceipt(sale) {
  const doc = buildReceiptDoc(sale)
  doc.save(`${receiptNumber(sale)}.pdf`)
}

export async function sendReceiptByEmail(saleId) {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  const res = await fetch('/api/receipts/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session?.access_token || ''}`,
    },
    body: JSON.stringify({ saleId }),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || 'No se pudo enviar el mail')
  return data
}

import { supabase } from '../lib/supabase'

export async function fetchRealStats() {
  const [salesRes, eventsRes, materialsRes] = await Promise.all([
    supabase.from('sales').select('amount, status, student_email'),
    supabase.from('material_events').select('material_id, action, student_email, created_at'),
    supabase.from('materials').select('id, title'),
  ])

  const sales = salesRes.data || []
  const events = eventsRes.data || []
  const materials = materialsRes.data || []

  const totalRevenue = sales
    .filter((s) => s.status === 'pagado')
    .reduce((sum, s) => sum + Number(s.amount), 0)
  const totalSalesCount = sales.length
  const uniqueStudents = new Set(
    [...sales.map((s) => s.student_email), ...events.map((e) => e.student_email)].filter(Boolean),
  ).size

  const viewsByMaterial = {}
  events.forEach((e) => {
    viewsByMaterial[e.material_id] = (viewsByMaterial[e.material_id] || 0) + 1
  })

  const topMaterials = Object.entries(viewsByMaterial)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([id, count]) => {
      const m = materials.find((x) => x.id === id)
      return { title: m ? m.title : 'Material eliminado', views: count }
    })

  return {
    totalRevenue,
    totalSalesCount,
    uniqueStudents,
    totalMaterialEvents: events.length,
    totalMaterials: materials.length,
    topMaterials,
  }
}

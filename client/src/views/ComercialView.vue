<script setup>
import { computed, onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import BarChart from '../components/BarChart.vue'
import { useToastStore } from '../stores/toast'
import { fetchAllSales, updateSaleStatus, fmtMoney } from '../services/sales'

const toast = useToastStore()
const sales = ref([])
const loading = ref(true)
const errorMsg = ref('')
const search = ref('')
const statusFilter = ref('')

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    sales.value = await fetchAllSales()
  } catch (err) {
    console.error(err)
    errorMsg.value = err.message
    toast.show('⚠ No se pudieron cargar las ventas')
  } finally {
    loading.value = false
  }
}
onMounted(load)

const pagado = computed(() => sales.value.filter((s) => s.status === 'pagado'))
const pendiente = computed(() => sales.value.filter((s) => s.status === 'pendiente'))

const revenuePagado = computed(() => pagado.value.reduce((sum, s) => sum + Number(s.amount), 0))
const revenuePendiente = computed(() => pendiente.value.reduce((sum, s) => sum + Number(s.amount), 0))
const avgTicket = computed(() => (pagado.value.length ? revenuePagado.value / pagado.value.length : 0))

const chartByPlan = computed(() => {
  const byPlan = {}
  pagado.value.forEach((s) => {
    const key = s.plan_name || 'Sin plan'
    byPlan[key] = (byPlan[key] || 0) + Number(s.amount)
  })
  return Object.entries(byPlan)
    .sort((a, b) => b[1] - a[1])
    .map(([label, value]) => ({ label, value, formatted: fmtMoney(value) }))
})

const chartByMonth = computed(() => {
  const months = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    months.push({
      key: `${d.getFullYear()}-${d.getMonth()}`,
      label: d.toLocaleDateString('es-AR', { month: 'short', year: '2-digit' }),
      total: 0,
    })
  }
  pagado.value.forEach((s) => {
    const d = new Date(s.created_at)
    const key = `${d.getFullYear()}-${d.getMonth()}`
    const bucket = months.find((m) => m.key === key)
    if (bucket) bucket.total += Number(s.amount)
  })
  return months.map((m) => ({ label: m.label, value: m.total, formatted: fmtMoney(m.total) }))
})

const filteredRows = computed(() => {
  let rows = sales.value
  if (statusFilter.value) rows = rows.filter((s) => s.status === statusFilter.value)
  const q = search.value.trim().toLowerCase()
  if (q) {
    rows = rows.filter(
      (s) => (s.student_name || '').toLowerCase().includes(q) || (s.student_email || '').toLowerCase().includes(q),
    )
  }
  return rows
})

async function handleStatus(saleId, status) {
  try {
    await updateSaleStatus(saleId, status)
    const sale = sales.value.find((s) => s.id === saleId)
    if (sale) sale.status = status
    toast.show(`✓ Venta marcada como "${status}"`)
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo actualizar el estado de la venta')
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Gestión Comercial</h1>
      <p class="dash__subtitle">Balances, ventas por plan e historial completo.</p>
    </div>

    <p v-if="loading" style="opacity: 0.6; margin-top: 1.5rem">Cargando ventas…</p>
    <p v-else-if="errorMsg" style="color: var(--red); margin-top: 1.5rem">⚠ {{ errorMsg }}</p>

    <template v-else>
      <div class="dash__cards" style="margin-top: 1.25rem">
        <div class="dash__card">
          <div class="dash__card-icon">✅</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Ingresos pagados</span>
            <span class="dash__card-value">{{ fmtMoney(revenuePagado) }}</span>
          </div>
        </div>
        <div class="dash__card">
          <div class="dash__card-icon">⏳</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Pendientes</span>
            <span class="dash__card-value">{{ fmtMoney(revenuePendiente) }}</span>
          </div>
        </div>
        <div class="dash__card">
          <div class="dash__card-icon">🧾</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Ventas totales</span>
            <span class="dash__card-value">{{ sales.length }}</span>
          </div>
        </div>
        <div class="dash__card">
          <div class="dash__card-icon">📊</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Ticket promedio</span>
            <span class="dash__card-value">{{ fmtMoney(avgTicket) }}</span>
          </div>
        </div>
      </div>

      <div class="dash__row" style="margin-top: 1.5rem; display: flex; gap: 1.5rem; flex-wrap: wrap">
        <div class="dash__panel" style="flex: 1; min-width: 320px">
          <h3>Ventas por plan</h3>
          <BarChart :rows="chartByPlan" empty-message="Todavía no hay ventas pagadas." />
        </div>
        <div class="dash__panel" style="flex: 1; min-width: 320px">
          <h3>Ventas por mes</h3>
          <BarChart :rows="chartByMonth" empty-message="Todavía no hay ventas pagadas." />
        </div>
      </div>

      <div class="dash__panel" style="margin-top: 1.5rem">
        <h3>Historial de ventas</h3>
        <div style="display: flex; gap: 0.75rem; margin: 1rem 0; flex-wrap: wrap">
          <input v-model="search" type="text" placeholder="Buscar por nombre o email…" />
          <select v-model="statusFilter">
            <option value="">Todos los estados</option>
            <option value="pendiente">Pendiente</option>
            <option value="pagado">Pagado</option>
            <option value="cancelado">Cancelado</option>
          </select>
        </div>
        <table class="users__table">
          <thead>
            <tr>
              <th>Alumno</th>
              <th>Plan</th>
              <th>Monto</th>
              <th>Fecha</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="!filteredRows.length">
              <td colspan="5">No hay ventas que coincidan con el filtro.</td>
            </tr>
            <tr v-for="s in filteredRows" :key="s.id">
              <td>
                <strong>{{ s.student_name || '—' }}</strong
                ><br />
                <span style="font-size: 0.75rem; opacity: 0.6">{{ s.student_email || '' }}</span>
              </td>
              <td>{{ s.plan_name || '—' }}</td>
              <td class="sales__amount">{{ fmtMoney(Number(s.amount)) }}</td>
              <td>{{ new Date(s.created_at).toLocaleDateString('es-AR') }}</td>
              <td>
                <span class="sale-status" :class="`sale-status--${s.status}`">{{ s.status }}</span>
                <select
                  class="status-select"
                  style="margin-top: 0.3rem; display: block"
                  :value="s.status"
                  @change="handleStatus(s.id, $event.target.value)"
                >
                  <option value="pendiente">Pendiente</option>
                  <option value="pagado">Pagado</option>
                  <option value="cancelado">Cancelado</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </DashboardLayout>
</template>

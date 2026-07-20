<script setup>
import { onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { fetchAllSales, updateSaleStatus, fmtMoney } from '../../services/sales'

const toast = useToastStore()
const sales = ref([])
const loading = ref(true)
const errorMsg = ref('')

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    sales.value = await fetchAllSales()
  } catch (err) {
    errorMsg.value = err.message
  } finally {
    loading.value = false
  }
}

async function handleStatus(saleId, status) {
  try {
    await updateSaleStatus(saleId, status)
    toast.show(`✓ Pago marcado como "${status}"`)
  } catch (err) {
    toast.show('⚠ No se pudo actualizar el pago')
  }
}

onMounted(load)
</script>

<template>
  <div class="dash__panel">
    <h3>Pagos</h3>
    <p v-if="loading">Cargando…</p>
    <p v-else-if="errorMsg" style="color: var(--red)">⚠ {{ errorMsg }}</p>
    <p v-else-if="!sales.length">Todavía no hay ventas registradas.</p>
    <table v-else class="users__table" style="margin-top: 0.75rem">
      <thead>
        <tr>
          <th>Alumno</th>
          <th>Plan</th>
          <th>Monto</th>
          <th>Estado</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in sales" :key="s.id">
          <td>
            <strong>{{ s.student_name || '—' }}</strong
            ><br />
            <span style="font-size: 0.75rem; opacity: 0.6">{{ s.student_email || '' }}</span>
          </td>
          <td>{{ s.plan_name || '—' }}</td>
          <td class="sales__amount">{{ fmtMoney(Number(s.amount)) }}</td>
          <td>
            <select
              class="status-select"
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

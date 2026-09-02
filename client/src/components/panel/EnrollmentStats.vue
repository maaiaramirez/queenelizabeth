<script setup>
import { computed, onMounted, ref } from 'vue'
import { fetchAllCancellations, CANCELLATION_REASONS } from '../../services/cancellations'

const props = defineProps({ totalStudents: { type: Number, default: 0 } })

const cancellations = ref([])
const loading = ref(true)

onMounted(async () => {
  try {
    cancellations.value = await fetchAllCancellations()
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
})

const activeStudents = computed(() => Math.max(props.totalStudents - cancellations.value.length, 0))

const avgSatisfaction = computed(() => {
  if (!cancellations.value.length) return null
  const sum = cancellations.value.reduce((s, c) => s + c.satisfaction, 0)
  return (sum / cancellations.value.length).toFixed(1)
})

const byReason = computed(() => {
  const counts = {}
  cancellations.value.forEach((c) => {
    counts[c.reason] = (counts[c.reason] || 0) + 1
  })
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([key, count]) => ({ label: CANCELLATION_REASONS[key] || key, count }))
})
</script>

<template>
  <div class="dash__panel">
    <h3>Alumnos: inscriptos vs bajas</h3>
    <p v-if="loading" style="opacity: 0.6">Cargando…</p>
    <template v-else>
      <div class="dash__cards" style="margin-top: 0.75rem">
        <div class="dash__card">
          <div class="dash__card-icon">🎓</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Alumnos activos</span>
            <span class="dash__card-value">{{ activeStudents }}</span>
          </div>
        </div>
        <div class="dash__card">
          <div class="dash__card-icon">📉</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Bajas registradas</span>
            <span class="dash__card-value">{{ cancellations.length }}</span>
          </div>
        </div>
        <div class="dash__card" v-if="avgSatisfaction">
          <div class="dash__card-icon">⭐</div>
          <div class="dash__card-info">
            <span class="dash__card-label">Satisfacción promedio (bajas)</span>
            <span class="dash__card-value">{{ avgSatisfaction }}/5</span>
          </div>
        </div>
      </div>

      <div v-if="byReason.length" style="margin-top: 1.25rem">
        <strong style="font-size: 0.9rem">Motivos de baja:</strong>
        <ul style="margin-top: 0.5rem; font-size: 0.88rem; opacity: 0.85">
          <li v-for="r in byReason" :key="r.label">{{ r.label }} — {{ r.count }}</li>
        </ul>
      </div>
      <p v-else style="margin-top: 1rem; font-size: 0.85rem; opacity: 0.6">Todavía no hay bajas registradas.</p>
    </template>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { fetchRealStats } from '../../services/stats'

const auth = useAuthStore()
const stats = ref(null)
const loadingStats = ref(false)

onMounted(async () => {
  // El panel de stats reales es solo para admin (RLS de `sales`); para
  // el resto de los roles no lo mostramos (igual que en app.js loadRealStats).
  if (auth.isAdmin) {
    loadingStats.value = true
    try {
      stats.value = await fetchRealStats()
    } finally {
      loadingStats.value = false
    }
  }
})

const hour = new Date().getHours()
const greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches'
</script>

<template>
  <div class="dash__header">
    <h1 class="dash__title">{{ greeting }}, {{ auth.firstName }} ☀️</h1>
    <p class="dash__subtitle">Este es tu resumen de alumno.</p>
  </div>

  <div class="dash__row" style="margin-top: 1.5rem">
    <div class="dash__col" style="flex: 1">
      <div class="dash__panel">
        <h3>Accesos rápidos</h3>
        <div style="display: flex; gap: 0.75rem; flex-wrap: wrap; margin-top: 1rem">
          <RouterLink to="/materiales" class="btn btn--primary btn--sm">📂 Ver materiales</RouterLink>
        </div>
      </div>
    </div>
  </div>

  <div v-if="auth.isAdmin" class="dash__panel" style="margin-top: 1.5rem">
    <h3>Estadísticas reales</h3>
    <p v-if="loadingStats" style="opacity: 0.6">Cargando…</p>
    <div v-else-if="stats" class="dash__cards">
      <div class="dash__card">
        <div class="dash__card-icon">💰</div>
        <div class="dash__card-info">
          <span class="dash__card-label">Ingresos</span>
          <span class="dash__card-value">${{ stats.totalRevenue.toLocaleString('es-AR') }}</span>
        </div>
      </div>
      <div class="dash__card">
        <div class="dash__card-icon">🧾</div>
        <div class="dash__card-info">
          <span class="dash__card-label">Ventas</span>
          <span class="dash__card-value">{{ stats.totalSalesCount }}</span>
        </div>
      </div>
      <div class="dash__card">
        <div class="dash__card-icon">🎓</div>
        <div class="dash__card-info">
          <span class="dash__card-label">Alumnos únicos</span>
          <span class="dash__card-value">{{ stats.uniqueStudents }}</span>
        </div>
      </div>
      <div class="dash__card">
        <div class="dash__card-icon">👁️</div>
        <div class="dash__card-info">
          <span class="dash__card-label">Vistas de material</span>
          <span class="dash__card-value">{{ stats.totalMaterialEvents }}</span>
        </div>
      </div>
    </div>
    <p v-if="stats?.topMaterials?.length" style="margin-top: 1rem; font-size: 0.85rem">
      <strong>Materiales más vistos:</strong>
      {{ stats.topMaterials.map((m) => `${m.title} (${m.views})`).join(' · ') }}
    </p>
  </div>
</template>

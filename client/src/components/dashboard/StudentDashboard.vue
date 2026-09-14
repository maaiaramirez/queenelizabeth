<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { fetchRealStats } from '../../services/stats'
import { fetchMySaleStatus } from '../../services/sales'
import { startCheckout } from '../../services/payments'
import { fetchActiveActivities } from '../../services/activities'
import ActivityGame from '../ActivityGame.vue'

const auth = useAuthStore()
const stats = ref(null)
const loadingStats = ref(false)
const pendingSale = ref(null)
const payingNow = ref(false)
const activities = ref([])
const playingActivity = ref(null)
const loadingActivities = ref(false)

async function handlePayNow() {
  if (!pendingSale.value) return
  payingNow.value = true
  try {
    const initPoint = await startCheckout({ saleId: pendingSale.value.id })
    window.location.href = initPoint
  } catch (err) {
    console.error(err)
    payingNow.value = false
  }
}

onMounted(async () => {
  if (auth.isAdmin) {
    loadingStats.value = true
    try {
      stats.value = await fetchRealStats()
    } finally {
      loadingStats.value = false
    }
  }

  try {
    const sale = await fetchMySaleStatus()
    if (sale && sale.status === 'pendiente') pendingSale.value = sale
  } catch (err) {
    console.error(err)
  }

  if (auth.role === 'student') {
    loadingActivities.value = true
    try {
      activities.value = await fetchActiveActivities()
    } catch (err) {
      console.error(err)
    } finally {
      loadingActivities.value = false
    }
  }
})

const GAME_COLORS = ['#7F77DD', '#1D9E75', '#D85A30', '#D4537E', '#378ADD']
function gameColor(i) {
  return GAME_COLORS[i % GAME_COLORS.length]
}

const hour = new Date().getHours()
const greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches'
</script>

<template>
  <div class="dash__hero">
    <div class="dash__hero-top">
      <div>
        <h1 class="dash__hero-title">{{ greeting }}, {{ auth.firstName }}</h1>
        <p class="dash__hero-subtitle">
          {{ activities.length ? `${activities.length} juegos te esperan` : 'Este es tu resumen de alumno' }}
        </p>
      </div>
    </div>
    <div class="dash__hero-actions">
      <RouterLink to="/materiales" class="btn btn--primary btn--sm">📂 Ver materiales</RouterLink>
      <RouterLink to="/test-de-nivel" class="btn btn--outline btn--sm">📝 Rendir test de nivel</RouterLink>
    </div>
  </div>

  <div
    v-if="pendingSale"
    class="dash__panel"
    style="margin-top: 1.5rem; border-left: 4px solid var(--gold); background: var(--ivory-dark)"
  >
    <p style="margin: 0; font-weight: 700; color: var(--navy)">💳 Pago pendiente</p>
    <p style="margin: 0.35rem 0 0; font-size: 0.9rem; color: var(--text-mid)">
      Tu plan <strong>{{ pendingSale.plan_name }}</strong> (${{ pendingSale.amount }}) está registrado pero todavía
      no se confirmó el pago.
    </p>
    <button class="btn btn--primary btn--sm" style="margin-top: 0.75rem" :disabled="payingNow" @click="handlePayNow">
      {{ payingNow ? 'Abriendo Mercado Pago…' : '💳 Pagar ahora' }}
    </button>
  </div>

  <div v-if="auth.role === 'student'" class="dash__hero" style="margin-top: 1.5rem">
    <h3 style="font-family: var(--font-sans); font-size: 1rem; margin-bottom: 0.15rem">🎯 Actividades extra</h3>
    <p style="opacity: 0.6; font-size: 0.85rem; margin-bottom: 1rem">Juegos cortos para practicar además de lo que suben tus docentes.</p>
    <p v-if="loadingActivities" style="opacity: 0.6">Cargando…</p>
    <p v-else-if="!activities.length" style="opacity: 0.6">Todavía no hay juegos cargados.</p>
    <div v-else style="display: flex; flex-direction: column; gap: 0.6rem">
      <button
        v-for="(a, i) in activities"
        :key="a.id"
        type="button"
        class="game-card"
        @click="playingActivity = a"
      >
        <div class="game-card__icon" :style="{ background: gameColor(i) }">🎮</div>
        <div class="game-card__info">
          <div class="game-card__title">{{ a.title }}</div>
          <div class="game-card__meta">
            {{ a.level === 'todos' ? 'Todos los niveles' : a.level }} · {{ (a.questions || []).length }} preguntas
            <template v-if="a.description"> · {{ a.description }}</template>
          </div>
        </div>
        <span class="game-card__cta">Jugar</span>
      </button>
    </div>
  </div>

  <ActivityGame v-if="playingActivity" :activity="playingActivity" @close="playingActivity = null" />

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

  <p v-if="auth.role === 'student'" style="margin-top: 2rem; text-align: center; font-size: 0.8rem; opacity: 0.55">
    <RouterLink to="/baja" style="color: inherit">¿Querés darte de baja?</RouterLink>
  </p>
</template>

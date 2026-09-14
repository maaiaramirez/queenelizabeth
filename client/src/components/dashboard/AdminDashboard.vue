<script setup>
import { computed, onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { fetchAllCoursesGrouped, assignTeacherToCourse } from '../../services/courses'
import { fetchProfileCountsByRole, fetchAllProfiles } from '../../services/profiles'
import { fetchRealStats } from '../../services/stats'
import { fetchAllCancellations } from '../../services/cancellations'

const toast = useToastStore()

const grouped = ref({})
const roleCounts = ref({ student: 0, teacher: 0, admin: 0 })
const teachers = ref([])
const loading = ref(true)
const errorMsg = ref('')
const stats = ref(null)
const cancellationsCount = ref(0)
const allProfiles = ref([])

const monthlySignups = computed(() => {
  const now = new Date()
  const months = []
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    months.push({ key: `${d.getFullYear()}-${d.getMonth()}`, label: d.toLocaleDateString('es-AR', { month: 'short' }), count: 0 })
  }
  allProfiles.value
    .filter((p) => p.role === 'student' && p.created_at)
    .forEach((p) => {
      const d = new Date(p.created_at)
      const key = `${d.getFullYear()}-${d.getMonth()}`
      const m = months.find((mm) => mm.key === key)
      if (m) m.count++
    })
  const max = Math.max(1, ...months.map((m) => m.count))
  return months.map((m) => ({ ...m, pct: Math.round((m.count / max) * 100) }))
})

const ageIcons = { starter: '🌱', medium: '🌿', elder: '🌳', sin_asignar: '❔' }
const ageLabels = { starter: 'Starter', medium: 'Medium', elder: 'Elder', sin_asignar: 'Sin grupo de edad' }

const totalCourses = computed(() =>
  Object.values(grouped.value).reduce(
    (sum, levels) => sum + Object.values(levels).reduce((s, arr) => s + arr.length, 0),
    0,
  ),
)

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [g, counts, profiles, s, cancellations] = await Promise.all([
      fetchAllCoursesGrouped(),
      fetchProfileCountsByRole(),
      fetchAllProfiles(),
      fetchRealStats().catch(() => null),
      fetchAllCancellations().catch(() => []),
    ])
    grouped.value = g
    roleCounts.value = counts
    teachers.value = profiles.filter((p) => p.role === 'teacher')
    allProfiles.value = profiles
    stats.value = s
    cancellationsCount.value = cancellations.length
  } catch (err) {
    errorMsg.value = err.message
  } finally {
    loading.value = false
  }
}

async function handleAssign(courseId, teacherId) {
  try {
    await assignTeacherToCourse(courseId, teacherId || null)
    toast.show(teacherId ? '✓ Docente asignado' : '✓ Curso marcado sin asignar')
    load()
  } catch (err) {
    toast.show('⚠ No se pudo asignar el docente')
  }
}

onMounted(load)
</script>

<template>
  <div class="dash__hero">
    <div class="dash__hero-top">
      <div>
        <h1 class="dash__hero-title">Panel de control</h1>
        <p class="dash__hero-subtitle">Todos los cursos, agrupados por edad → nivel.</p>
      </div>
    </div>
    <div class="dash__hero-actions">
      <RouterLink to="/panel" class="btn btn--primary btn--sm">🏫 Crear curso</RouterLink>
      <RouterLink to="/comercial" class="btn btn--outline btn--sm">📊 Ver reportes</RouterLink>
      <RouterLink to="/admin/usuarios" class="btn btn--outline btn--sm">👥 Gestionar usuarios</RouterLink>
    </div>
  </div>

  <div class="dash__cards" style="margin-top: 1.25rem">
    <div class="dash__card">
      <div class="dash__card-icon">👥</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Usuarios activos</span>
        <span class="dash__card-value">{{ roleCounts.student + roleCounts.teacher + roleCounts.admin }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">🎓</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Alumnos</span>
        <span class="dash__card-value">{{ roleCounts.student }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">💰</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Ingresos</span>
        <span class="dash__card-value">${{ (stats?.totalRevenue || 0).toLocaleString('es-AR') }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">📉</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Bajas registradas</span>
        <span class="dash__card-value">{{ cancellationsCount }}</span>
      </div>
    </div>
  </div>

  <div class="dash__panel" style="margin-top: 1.25rem">
    <h3 style="margin-bottom: 1rem">Inscripciones últimos 6 meses</h3>
    <div style="display: flex; align-items: flex-end; gap: 10px; height: 100px">
      <div
        v-for="m in monthlySignups"
        :key="m.key"
        :style="{ flex: 1, background: '#AFA9EC', height: Math.max(m.pct, 4) + '%', borderRadius: '4px 4px 0 0' }"
        :title="`${m.label}: ${m.count}`"
      ></div>
    </div>
    <div style="display: flex; gap: 10px; margin-top: 6px">
      <div v-for="m in monthlySignups" :key="m.key" style="flex: 1; text-align: center; font-size: 0.7rem; color: var(--text-muted); text-transform: capitalize">
        {{ m.label }}
      </div>
    </div>
  </div>

  <p v-if="loading" style="opacity: 0.6; margin-top: 1.5rem">Cargando cursos…</p>
  <p v-else-if="errorMsg" style="color: var(--red); margin-top: 1.5rem">⚠ {{ errorMsg }}</p>

  <div v-else-if="!totalCourses" class="admin-empty" style="margin-top: 1.5rem">
    📭 Todavía no hay cursos cargados. Creá el primero desde "Panel Docente".
  </div>

  <div v-else style="margin-top: 1.5rem">
    <div v-for="(levels, ageKey) in grouped" :key="ageKey" class="admin-group">
      <h4 class="admin-group__title">{{ ageIcons[ageKey] || '📁' }} {{ ageLabels[ageKey] || ageKey }}</h4>
      <div v-for="(courses, levelKey) in levels" :key="levelKey" class="admin-level-row">
        <span class="admin-level-badge">🎯 {{ levelKey }}</span>
        <div class="teacher__courses-grid">
          <div v-for="c in courses" :key="c.id" class="admin-course-card">
            <div class="admin-course-card__title">
              📗 {{ c.title }}<span v-if="c.sublevel"> · Grado {{ c.sublevel }}</span>
            </div>
            <select :value="c.teacher_id || ''" @change="handleAssign(c.id, $event.target.value)">
              <option value="">— Sin asignar —</option>
              <option v-for="t in teachers" :key="t.id" :value="t.id">
                {{ t.display_name || t.email }}
              </option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

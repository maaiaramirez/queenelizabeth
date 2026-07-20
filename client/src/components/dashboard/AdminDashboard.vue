<script setup>
import { computed, onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { fetchAllCoursesGrouped, assignTeacherToCourse } from '../../services/courses'
import { fetchProfileCountsByRole, fetchAllProfiles } from '../../services/profiles'

const toast = useToastStore()

const grouped = ref({})
const roleCounts = ref({ student: 0, teacher: 0, admin: 0 })
const teachers = ref([])
const loading = ref(true)
const errorMsg = ref('')

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
    const [g, counts, profiles] = await Promise.all([
      fetchAllCoursesGrouped(),
      fetchProfileCountsByRole(),
      fetchAllProfiles(),
    ])
    grouped.value = g
    roleCounts.value = counts
    teachers.value = profiles.filter((p) => p.role === 'teacher')
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
  <div class="dash__header">
    <h1 class="dash__title">Panel de Dirección</h1>
    <p class="dash__subtitle">Todos los cursos, agrupados por edad → nivel.</p>
  </div>

  <div class="dash__cards" style="margin-top: 1.25rem">
    <div class="dash__card">
      <div class="dash__card-icon">📗</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Cursos</span>
        <span class="dash__card-value">{{ totalCourses }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">🧑‍🏫</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Docentes</span>
        <span class="dash__card-value">{{ roleCounts.teacher }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">🎓</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Alumnos</span>
        <span class="dash__card-value">{{ roleCounts.student }}</span>
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

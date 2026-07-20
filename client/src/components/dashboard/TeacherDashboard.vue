<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { fetchCoursesForTeacher, fetchTeacherStudentCount } from '../../services/courses'

const auth = useAuthStore()
const courses = ref([])
const studentCount = ref(0)
const loading = ref(true)
const errorMsg = ref('')

const levelIcons = { A1: '🟢', A2: '🟢', B1: '🔵', B2: '🔵', C1: '🟣', C2: '🟣' }

onMounted(async () => {
  try {
    const [c, count] = await Promise.all([
      fetchCoursesForTeacher(auth.profile.id),
      fetchTeacherStudentCount(auth.profile.id).catch(() => 0),
    ])
    courses.value = c
    studentCount.value = count
  } catch (err) {
    errorMsg.value = err.message
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="dash__header">
    <h1 class="dash__title">Panel Docente — {{ auth.firstName }}</h1>
    <p class="dash__subtitle">Tus cursos asignados y tus alumnos.</p>
  </div>

  <div class="dash__cards" style="margin-top: 1.25rem">
    <div class="dash__card">
      <div class="dash__card-icon">📘</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Cursos asignados</span>
        <span class="dash__card-value">{{ courses.length }}</span>
      </div>
    </div>
    <div class="dash__card">
      <div class="dash__card-icon">🎓</div>
      <div class="dash__card-info">
        <span class="dash__card-label">Alumnos</span>
        <span class="dash__card-value">{{ studentCount }}</span>
      </div>
    </div>
  </div>

  <p v-if="loading" style="opacity: 0.6; margin-top: 1.5rem">Cargando tus cursos…</p>
  <p v-else-if="errorMsg" style="color: var(--red); margin-top: 1.5rem">⚠ {{ errorMsg }}</p>

  <div v-else-if="!courses.length" class="dash__panel" style="text-align: center; margin-top: 1.5rem">
    <div style="font-size: 2rem; margin-bottom: 0.5rem">📭</div>
    <strong style="display: block; color: var(--navy); margin-bottom: 0.25rem"
      >Todavía no tenés cursos asignados</strong
    >
    <p style="opacity: 0.65; font-size: 0.85rem">
      Pedile a un administrador que te asigne un curso desde el Panel de Dirección.
    </p>
  </div>

  <div v-else class="teacher__courses-grid" style="margin-top: 1.5rem">
    <article v-for="c in courses" :key="c.id" class="teacher__course-card">
      <div class="teacher__course-icon">📘</div>
      <h4 class="teacher__course-title">{{ c.title }}</h4>
      <div class="teacher__course-tags">
        <span v-if="c.age_group" class="teacher__course-tag">{{ c.age_group }}</span>
        <span v-if="c.level" class="teacher__course-tag">{{ levelIcons[c.level] || '📗' }} {{ c.level }}</span>
        <span v-if="c.sublevel" class="teacher__course-tag">Grado {{ c.sublevel }}</span>
      </div>
      <div class="teacher__course-footer">
        <span>Curso asignado</span>
        <RouterLink to="/panel" style="color: var(--gold)">Gestionar →</RouterLink>
      </div>
    </article>
  </div>
</template>

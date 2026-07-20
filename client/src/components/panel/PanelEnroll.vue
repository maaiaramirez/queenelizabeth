<script setup>
import { onMounted, ref, watch } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { useToastStore } from '../../stores/toast'
import { fetchCourses, fetchCoursesForTeacher } from '../../services/courses'
import { fetchAllStudents } from '../../services/profiles'
import { enrollStudent, fetchCourseStudents, unenrollStudent } from '../../services/enrollments'

const auth = useAuthStore()
const toast = useToastStore()

const courses = ref([])
const students = ref([])
const courseId = ref('')
const studentId = ref('')
const status = ref('')
const enrolled = ref([])
const enrolledLoading = ref(false)
const enrolledError = ref('')

async function loadOptions() {
  try {
    const isAdmin = auth.role === 'admin'
    const [c, s] = await Promise.all([
      isAdmin ? fetchCourses() : fetchCoursesForTeacher(auth.profile.id),
      fetchAllStudents(),
    ])
    courses.value = c
    students.value = s
    if (c.length) courseId.value = c[0].id
    if (s.length) studentId.value = s[0].id
  } catch (err) {
    console.error(err)
  }
}

async function loadEnrolled() {
  if (!courseId.value) {
    enrolled.value = []
    return
  }
  enrolledLoading.value = true
  enrolledError.value = ''
  try {
    enrolled.value = await fetchCourseStudents(courseId.value)
  } catch (err) {
    enrolledError.value = err.message
  } finally {
    enrolledLoading.value = false
  }
}

watch(courseId, loadEnrolled)

async function handleEnroll() {
  if (!courseId.value || !studentId.value) {
    toast.show('⚠ Elegí un curso y un alumno')
    return
  }
  status.value = 'Inscribiendo…'
  try {
    await enrollStudent(studentId.value, courseId.value)
    status.value = '✓ Inscripto'
    toast.show('✓ Alumno inscripto en el curso')
    await loadEnrolled()
  } catch (err) {
    status.value = '⚠ Error'
    toast.show(err.message?.includes('duplicate') ? '⚠ Ese alumno ya estaba inscripto' : '⚠ No se pudo inscribir al alumno')
  }
}

async function handleUnenroll(sId) {
  if (!confirm('¿Quitar a este alumno del curso?')) return
  try {
    await unenrollStudent(sId, courseId.value)
    toast.show('✓ Alumno dado de baja del curso')
    await loadEnrolled()
  } catch (err) {
    toast.show('⚠ No se pudo quitar al alumno')
  }
}

onMounted(async () => {
  await loadOptions()
  await loadEnrolled()
})
</script>

<template>
  <div class="dash__panel">
    <h3>Asignar alumnos a curso</h3>
    <form @submit.prevent="handleEnroll" style="margin-top: 1rem">
      <div class="form-field">
        <label>Curso</label>
        <select v-model="courseId">
          <option v-if="!courses.length" value="">Sin cursos disponibles</option>
          <option v-for="c in courses" :key="c.id" :value="c.id">{{ c.title }} ({{ c.level || '—' }})</option>
        </select>
      </div>
      <div class="form-field">
        <label>Alumno</label>
        <select v-model="studentId">
          <option v-if="!students.length" value="">No hay alumnos registrados</option>
          <option v-for="s in students" :key="s.id" :value="s.id">{{ s.display_name || s.email }}</option>
        </select>
      </div>
      <button type="submit" class="btn btn--primary btn--sm">Inscribir</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>

    <h4 style="margin-top: 1.5rem">Alumnos inscriptos</h4>
    <p v-if="!courseId" class="lib-loading">Elegí un curso arriba ↑</p>
    <p v-else-if="enrolledLoading" class="lib-loading">Cargando…</p>
    <p v-else-if="enrolledError" class="lib-error">⚠ {{ enrolledError }}</p>
    <p v-else-if="!enrolled.length" style="font-size: 0.85rem; opacity: 0.65">
      Todavía no hay alumnos inscriptos en este curso.
    </p>
    <div v-else>
      <div v-for="s in enrolled" :key="s.id" class="enrolled-row">
        <div>
          <div class="enrolled-row__name">{{ s.display_name || '—' }}</div>
          <div class="enrolled-row__email">{{ s.email || '' }}</div>
        </div>
        <button @click="handleUnenroll(s.id)">Quitar</button>
      </div>
    </div>
  </div>
</template>

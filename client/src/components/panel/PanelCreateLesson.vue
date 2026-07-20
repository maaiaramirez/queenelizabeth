<script setup>
import { onMounted, ref, watch } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { useToastStore } from '../../stores/toast'
import { fetchCourses, fetchCoursesForTeacher, createLesson } from '../../services/courses'

const emit = defineEmits(['created'])
const auth = useAuthStore()
const toast = useToastStore()

const courses = ref([])
const courseId = ref('')
const title = ref('')
const position = ref(1)
const status = ref('')
const loadError = ref('')

async function loadCourses() {
  loadError.value = ''
  try {
    const isAdmin = auth.role === 'admin'
    courses.value = isAdmin ? await fetchCourses() : await fetchCoursesForTeacher(auth.profile.id)
    if (courses.value.length) courseId.value = courses.value[0].id
  } catch (err) {
    loadError.value = '⚠ Error cargando cursos'
  }
}

async function handleCreate() {
  if (!courseId.value) {
    toast.show('⚠ Primero creá o selecciona un curso')
    return
  }
  if (!title.value.trim()) {
    toast.show('⚠ Falta el título de la lección')
    return
  }
  status.value = 'Creando…'
  try {
    await createLesson(courseId.value, title.value.trim(), Number(position.value) || 1)
    status.value = '✓ Lección creada'
    toast.show(`✓ Lección "${title.value}" creada`)
    title.value = ''
    emit('created')
  } catch (err) {
    status.value = '⚠ Error'
    toast.show('⚠ No se pudo crear la lección')
  }
}

defineExpose({ loadCourses })
onMounted(loadCourses)
</script>

<template>
  <div class="dash__panel">
    <h3>Crear lección</h3>
    <form @submit.prevent="handleCreate" style="margin-top: 1rem">
      <div class="form-field">
        <label>Curso</label>
        <select v-model="courseId">
          <option v-if="!courses.length" value="">
            {{ auth.role === 'admin' ? 'Primero creá un curso arriba ↑' : 'No tenés cursos asignados' }}
          </option>
          <option v-for="c in courses" :key="c.id" :value="c.id">{{ c.title }} ({{ c.level || '—' }})</option>
        </select>
        <span v-if="loadError" style="color: var(--red); font-size: 0.8rem">{{ loadError }}</span>
      </div>
      <div class="form-field">
        <label>Título de la lección</label>
        <input v-model="title" type="text" />
      </div>
      <div class="form-field">
        <label>Posición</label>
        <input v-model="position" type="number" min="1" />
      </div>
      <button type="submit" class="btn btn--primary btn--sm">Crear lección</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>
</template>

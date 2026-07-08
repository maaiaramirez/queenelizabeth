<script setup>
// CreateCourseView.vue — Restauración del feature "Crear Curso" (Admin)
import { reactive, ref } from 'vue'
import { useAdminStore } from '@/stores/admin'

const adminStore = useAdminStore()
const submitError = ref(null)
const submitSuccess = ref(false)

// Modelo reactivo con todos los campos necesarios para dar de alta un curso.
const form = reactive({
  days: [],              // ej: ['lunes', 'miercoles']
  startTime: '',          // '19:00'
  endTime: '',            // '20:30'
  courseType: '',         // 'viajes' | 'leyes' | 'business' | ...
  description: '',
  meetingUrl: '',         // link exacto de Zoom/Meet
})

const COURSE_TYPES = [
  { value: 'viajes', label: 'Inglés para viajes' },
  { value: 'leyes', label: 'Inglés legal' },
  { value: 'business', label: 'Business English' },
  { value: 'general', label: 'Inglés general' },
]

const DAYS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

function validate() {
  if (!form.days.length) return 'Elegí al menos un día.'
  if (!form.startTime || !form.endTime) return 'Completá el horario.'
  if (!form.courseType) return 'Elegí el tipo de curso.'
  if (!form.meetingUrl.trim()) return 'Falta el link de la videollamada.'
  return null
}

async function handleSubmit() {
  submitError.value = null
  submitSuccess.value = false

  const validationError = validate()
  if (validationError) {
    submitError.value = validationError
    return
  }

  const payload = {
    days: form.days,
    schedule: { start: form.startTime, end: form.endTime },
    course_type: form.courseType,
    description: form.description.trim(),
    meeting_url: form.meetingUrl.trim(),
  }

  try {
    await adminStore.createCourse(payload)
    submitSuccess.value = true
    resetForm()
  } catch (err) {
    submitError.value = err.message
  }
}

function resetForm() {
  form.days = []
  form.startTime = ''
  form.endTime = ''
  form.courseType = ''
  form.description = ''
  form.meetingUrl = ''
}
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <fieldset>
      <legend>Días</legend>
      <label v-for="day in DAYS" :key="day">
        <input type="checkbox" :value="day" v-model="form.days" />
        {{ day }}
      </label>
    </fieldset>

    <label>
      Hora de inicio
      <input type="time" v-model="form.startTime" />
    </label>
    <label>
      Hora de fin
      <input type="time" v-model="form.endTime" />
    </label>

    <label>
      Tipo de curso
      <select v-model="form.courseType">
        <option value="" disabled>Elegí un tipo</option>
        <option v-for="type in COURSE_TYPES" :key="type.value" :value="type.value">
          {{ type.label }}
        </option>
      </select>
    </label>

    <label>
      Descripción
      <textarea v-model="form.description"></textarea>
    </label>

    <label>
      Link de videollamada (Zoom/Meet)
      <input type="text" v-model="form.meetingUrl" placeholder="https://..." />
    </label>

    <p v-if="submitError" class="error">{{ submitError }}</p>
    <p v-if="submitSuccess" class="success">✓ Curso creado correctamente.</p>

    <button type="submit" :disabled="adminStore.isCreatingCourse">
      {{ adminStore.isCreatingCourse ? 'Creando…' : 'Crear curso' }}
    </button>
  </form>
</template>

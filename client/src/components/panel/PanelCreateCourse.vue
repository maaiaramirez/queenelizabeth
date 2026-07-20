<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { useToastStore } from '../../stores/toast'
import { createCourse } from '../../services/courses'

const emit = defineEmits(['created'])
const auth = useAuthStore()
const toast = useToastStore()

const title = ref('')
const level = ref('A1')
const ageGroup = ref('')
const sublevel = ref('')
const status = ref('')

async function handleCreate() {
  if (auth.role === 'teacher') {
    toast.show('⚠ Solo un administrador puede crear cursos.')
    return
  }
  if (!title.value.trim()) {
    toast.show('⚠ Falta el nombre del curso')
    return
  }
  status.value = 'Creando…'
  try {
    // El curso queda "sin asignar"; se asigna docente después desde el Panel de Dirección.
    await createCourse(title.value.trim(), level.value, {
      age_group: ageGroup.value || null,
      sublevel: sublevel.value || null,
      teacher_id: null,
    })
    status.value = '✓ Curso creado'
    toast.show(`✓ Curso "${title.value}" creado`)
    title.value = ''
    emit('created')
  } catch (err) {
    status.value = '⚠ Error'
    toast.show('⚠ No se pudo crear el curso')
  }
}
</script>

<template>
  <div v-if="auth.role !== 'teacher'" class="dash__panel">
    <h3>Crear curso</h3>
    <form @submit.prevent="handleCreate" style="margin-top: 1rem">
      <div class="form-field">
        <label>Título</label>
        <input v-model="title" type="text" placeholder="Ej: British English Starter" />
      </div>
      <div class="form-field">
        <label>Nivel</label>
        <select v-model="level">
          <option v-for="l in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']" :key="l" :value="l">{{ l }}</option>
        </select>
      </div>
      <div class="form-field">
        <label>Grupo de edad</label>
        <select v-model="ageGroup">
          <option value="">Sin definir</option>
          <option value="starter">Starter</option>
          <option value="medium">Medium</option>
          <option value="elder">Elder</option>
        </select>
      </div>
      <div class="form-field">
        <label>Sub-grado (opcional)</label>
        <input v-model="sublevel" type="text" placeholder="Ej: 1° grado" />
      </div>
      <button type="submit" class="btn btn--primary btn--sm">Crear curso</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>
</template>

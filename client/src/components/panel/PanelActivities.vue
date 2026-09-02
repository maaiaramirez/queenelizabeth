<script setup>
import { onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import {
  fetchAllActivitiesAdmin,
  createActivity,
  updateActivity,
  toggleActivityActive,
  deleteActivity,
  ACTIVITY_TYPE_ICONS,
} from '../../services/activities'

const toast = useToastStore()

const title = ref('')
const description = ref('')
const type = ref('juego')
const url = ref('')
const level = ref('todos')
const status = ref('')

const activities = ref([])
const loading = ref(true)
const errorMsg = ref('')

const editingId = ref(null)

async function loadActivities() {
  loading.value = true
  errorMsg.value = ''
  try {
    activities.value = await fetchAllActivitiesAdmin()
  } catch (err) {
    console.error(err)
    errorMsg.value = '⚠ Error cargando actividades.'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  editingId.value = null
  title.value = ''
  description.value = ''
  type.value = 'juego'
  url.value = ''
  level.value = 'todos'
}

function startEdit(a) {
  editingId.value = a.id
  title.value = a.title
  description.value = a.description || ''
  type.value = a.type
  url.value = a.url || ''
  level.value = a.level || 'todos'
}

async function handleSubmit() {
  if (!title.value.trim()) {
    toast.show('⚠ Falta el título')
    return
  }
  status.value = editingId.value ? 'Guardando…' : 'Creando…'
  try {
    const payload = {
      title: title.value.trim(),
      description: description.value.trim(),
      type: type.value,
      url: url.value.trim(),
      level: level.value,
    }
    if (editingId.value) {
      await updateActivity(editingId.value, payload)
      toast.show('✓ Actividad actualizada')
    } else {
      await createActivity(payload)
      toast.show('✓ Actividad creada')
    }
    resetForm()
    await loadActivities()
  } catch (err) {
    console.error(err)
    status.value = '⚠ Error al guardar'
    toast.show('⚠ No se pudo guardar. Revisá la configuración de Supabase.')
  } finally {
    status.value = ''
  }
}

async function handleToggle(a) {
  try {
    await toggleActivityActive(a.id, !a.active)
    await loadActivities()
  } catch (err) {
    toast.show('⚠ Error al cambiar estado')
  }
}

async function handleDelete(a) {
  if (!confirm('¿Borrar esta actividad? Esta acción es real y no se puede deshacer.')) return
  try {
    await deleteActivity(a.id)
    toast.show('✓ Actividad eliminada')
    await loadActivities()
  } catch (err) {
    toast.show('⚠ Error al eliminar')
  }
}

onMounted(loadActivities)
</script>

<template>
  <div class="dash__panel">
    <h3>{{ editingId ? 'Editar actividad extra' : 'Nueva actividad extra' }}</h3>
    <p style="opacity: 0.8; font-size: 0.9rem">
      Actividades adicionales para estudiantes, separadas de los materiales de curso (juegos, quizzes,
      lecturas extra, etc).
    </p>
    <form @submit.prevent="handleSubmit" style="margin-top: 1rem">
      <div class="form-field">
        <label>Título</label>
        <input v-model="title" type="text" />
      </div>
      <div class="form-field">
        <label>Descripción</label>
        <input v-model="description" type="text" />
      </div>
      <div class="form-field">
        <label>Tipo</label>
        <select v-model="type">
          <option value="juego">Juego</option>
          <option value="quiz">Quiz</option>
          <option value="video">Video</option>
          <option value="lectura">Lectura</option>
          <option value="audio">Audio</option>
          <option value="enlace">Enlace</option>
        </select>
      </div>
      <div class="form-field">
        <label>URL</label>
        <input v-model="url" type="text" placeholder="https://..." />
      </div>
      <div class="form-field">
        <label>Nivel</label>
        <select v-model="level">
          <option value="todos">Todos los niveles</option>
          <option>A1</option>
          <option>A2</option>
          <option>B1</option>
          <option>B2</option>
          <option>C1</option>
          <option>C2</option>
        </select>
      </div>
      <button type="submit" class="btn btn--primary btn--sm">{{ editingId ? 'Guardar cambios' : 'Crear actividad' }}</button>
      <button v-if="editingId" type="button" class="btn btn--ghost btn--sm" @click="resetForm">Cancelar</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>

  <div class="dash__panel" style="margin-top: 1.25rem">
    <h3>Actividades cargadas</h3>
    <p v-if="loading" class="lib-loading">Cargando…</p>
    <p v-else-if="errorMsg" class="lib-error">{{ errorMsg }}</p>
    <div v-else-if="!activities.length" class="lib-empty">
      <div class="lib-empty__icon">📭</div>Todavía no cargaste ninguna actividad.
    </div>
    <div v-else class="lib-grid">
      <div v-for="a in activities" :key="a.id" class="lib-card">
        <div class="lib-card__top">
          <div class="lib-card__icon">{{ ACTIVITY_TYPE_ICONS[a.type] || '🎯' }}</div>
          <div>
            <div class="lib-card__name">{{ a.title }} <span v-if="!a.active" style="opacity:.5">(inactiva)</span></div>
            <div class="lib-card__meta">{{ a.level === 'todos' ? 'Todos los niveles' : a.level }}</div>
            <div class="lib-card__meta">{{ new Date(a.created_at).toLocaleDateString('es-AR') }}</div>
          </div>
        </div>
        <div class="lib-card__actions">
          <button class="btn btn--ghost btn--sm" @click="startEdit(a)">✏ Editar</button>
          <button class="btn btn--ghost btn--sm" @click="handleToggle(a)">{{ a.active ? '🚫 Desactivar' : '✓ Activar' }}</button>
          <button class="danger" @click="handleDelete(a)">🗑 Borrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

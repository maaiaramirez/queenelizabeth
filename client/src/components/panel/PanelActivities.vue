<script setup>
import { onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import {
  fetchAllActivitiesAdmin,
  createActivity,
  updateActivity,
  toggleActivityActive,
  deleteActivity,
} from '../../services/activities'

const toast = useToastStore()

const title = ref('')
const description = ref('')
const level = ref('todos')
const questions = ref([emptyQuestion()])
const status = ref('')

const activities = ref([])
const loading = ref(true)
const errorMsg = ref('')
const editingId = ref(null)

function emptyQuestion() {
  return { question: '', options: ['', ''], correct_index: 0 }
}

function addQuestion() {
  questions.value.push(emptyQuestion())
}
function removeQuestion(i) {
  if (questions.value.length > 1) questions.value.splice(i, 1)
}
function addOption(q) {
  if (q.options.length < 4) q.options.push('')
}
function removeOption(q, i) {
  if (q.options.length > 2) {
    q.options.splice(i, 1)
    if (q.correct_index >= q.options.length) q.correct_index = 0
  }
}

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
  level.value = 'todos'
  questions.value = [emptyQuestion()]
}

function startEdit(a) {
  editingId.value = a.id
  title.value = a.title
  description.value = a.description || ''
  level.value = a.level || 'todos'
  questions.value = (a.questions && a.questions.length ? a.questions : [emptyQuestion()]).map((q) => ({
    question: q.question,
    options: [...q.options],
    correct_index: q.correct_index,
  }))
}

function validQuestions() {
  return questions.value.every(
    (q) => q.question.trim() && q.options.filter((o) => o.trim()).length >= 2
  )
}

async function handleSubmit() {
  if (!title.value.trim()) {
    toast.show('⚠ Falta el título')
    return
  }
  if (!validQuestions()) {
    toast.show('⚠ Cada pregunta necesita texto y al menos 2 opciones')
    return
  }
  status.value = editingId.value ? 'Guardando…' : 'Creando…'
  try {
    const payload = {
      title: title.value.trim(),
      description: description.value.trim(),
      level: level.value,
      questions: questions.value.map((q) => ({
        question: q.question.trim(),
        options: q.options.map((o) => o.trim()),
        correct_index: q.correct_index,
      })),
    }
    if (editingId.value) {
      await updateActivity(editingId.value, payload)
      toast.show('✓ Juego actualizado')
    } else {
      await createActivity(payload)
      toast.show('✓ Juego creado')
    }
    resetForm()
    await loadActivities()
  } catch (err) {
    console.error(err)
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
  if (!confirm('¿Borrar este juego? No se puede deshacer.')) return
  try {
    await deleteActivity(a.id)
    toast.show('✓ Juego eliminado')
    await loadActivities()
  } catch (err) {
    toast.show('⚠ Error al eliminar')
  }
}

onMounted(loadActivities)
</script>

<template>
  <div class="dash__panel">
    <h3>{{ editingId ? 'Editar juego' : 'Nuevo juego (multiple choice)' }}</h3>
    <p style="opacity: 0.8; font-size: 0.9rem">
      Un juego corto tipo Duolingo: el alumno responde pregunta por pregunta y ve si acertó al toque.
    </p>
    <form @submit.prevent="handleSubmit" style="margin-top: 1rem">
      <div class="form-field">
        <label>Título del juego</label>
        <input v-model="title" type="text" placeholder="Ej: British vs American English" />
      </div>
      <div class="form-field">
        <label>Descripción</label>
        <input v-model="description" type="text" />
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

      <div
        v-for="(q, qi) in questions"
        :key="qi"
        style="border: 1.5px solid var(--border); border-radius: var(--radius-md); padding: 1rem; margin-bottom: 1rem; background: var(--ivory)"
      >
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.6rem">
          <strong style="font-size: 0.85rem; color: var(--navy)">Pregunta {{ qi + 1 }}</strong>
          <button
            v-if="questions.length > 1"
            type="button"
            class="dropzone__clear"
            title="Borrar pregunta"
            @click="removeQuestion(qi)"
          >
            ✕
          </button>
        </div>
        <div class="form-field">
          <input v-model="q.question" type="text" placeholder="Texto de la pregunta" />
        </div>
        <div v-for="(opt, oi) in q.options" :key="oi" style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem">
          <input type="radio" :name="'correct-' + qi" :checked="q.correct_index === oi" @change="q.correct_index = oi" style="width: auto" />
          <input v-model="q.options[oi]" type="text" :placeholder="`Opción ${oi + 1}`" style="flex: 1; margin: 0" />
          <button v-if="q.options.length > 2" type="button" class="dropzone__clear" @click="removeOption(q, oi)">✕</button>
        </div>
        <button v-if="q.options.length < 4" type="button" class="btn btn--ghost btn--sm" @click="addOption(q)">+ Opción</button>
        <span style="font-size: 0.75rem; opacity: 0.6; margin-left: 0.5rem">Marcá con el círculo cuál es la correcta</span>
      </div>

      <button type="button" class="btn btn--ghost btn--sm" style="margin-bottom: 1rem" @click="addQuestion">+ Agregar pregunta</button>
      <br />
      <button type="submit" class="btn btn--primary btn--sm">{{ editingId ? 'Guardar cambios' : 'Crear juego' }}</button>
      <button v-if="editingId" type="button" class="btn btn--ghost btn--sm" @click="resetForm">Cancelar</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>

  <div class="dash__panel" style="margin-top: 1.25rem">
    <h3>Juegos cargados</h3>
    <p v-if="loading" class="lib-loading">Cargando…</p>
    <p v-else-if="errorMsg" class="lib-error">{{ errorMsg }}</p>
    <div v-else-if="!activities.length" class="lib-empty">
      <div class="lib-empty__icon">📭</div>Todavía no cargaste ningún juego.
    </div>
    <div v-else class="lib-grid">
      <div v-for="a in activities" :key="a.id" class="lib-card">
        <div class="lib-card__top">
          <div class="lib-card__icon">🎮</div>
          <div>
            <div class="lib-card__name">{{ a.title }} <span v-if="!a.active" style="opacity:.5">(inactivo)</span></div>
            <div class="lib-card__meta">{{ a.level === 'todos' ? 'Todos los niveles' : a.level }} · {{ (a.questions || []).length }} preguntas</div>
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

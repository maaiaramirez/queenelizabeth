#!/bin/bash
set -e
echo "Corré esto parado en la raíz del repo"
mkdir -p client/src/components/panel
cat > client/src/services/levelTest.js << 'LEVELTESTJS_EOF'
import { supabase } from '../lib/supabase'

async function authHeader() {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session) throw new Error('Necesitás estar logueado para rendir el test.')
  return { Authorization: `Bearer ${session.access_token}` }
}

export async function fetchLevelTestQuestions() {
  const headers = await authHeader()
  const res = await fetch('/api/level-test/questions', { headers })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error || 'No se pudieron cargar las preguntas del test.')
  }
  const { questions } = await res.json()
  return questions || []
}

export async function submitLevelTest({ answers, cheatEvents, startedAt }) {
  const headers = await authHeader()
  const res = await fetch('/api/level-test/submit', {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ answers, cheatEvents, startedAt }),
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error || 'No se pudo enviar el test.')
  }
  const { result } = await res.json()
  return result
}

export async function fetchMyLastLevelTestResult() {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return null
  const { data, error } = await supabase
    .from('level_test_results')
    .select('*')
    .eq('student_id', user.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (error) throw error
  return data
}

export async function fetchAllLevelTestResults() {
  const { data, error } = await supabase
    .from('level_test_results')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

// ── Administración de preguntas (solo admin, vía RLS) ──
export async function fetchAllQuestionsAdmin() {
  const { data, error } = await supabase
    .from('level_test_questions')
    .select('id, level, skill, question, options, correct_index, audio_url, is_active, created_at')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function createQuestion(payload) {
  const { data, error } = await supabase.from('level_test_questions').insert([payload]).select()
  if (error) throw error
  return data
}

export async function updateQuestion(id, changes) {
  const { data, error } = await supabase.from('level_test_questions').update(changes).eq('id', id).select()
  if (error) throw error
  return data
}

export async function deleteQuestion(id) {
  const { error } = await supabase.from('level_test_questions').delete().eq('id', id)
  if (error) throw error
}
LEVELTESTJS_EOF

cat > client/src/components/panel/PanelLevelTestQuestions.vue << 'PANELQUESTIONS_EOF'
<script setup>
import { onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { fetchAllQuestionsAdmin, createQuestion, updateQuestion, deleteQuestion } from '../../services/levelTest'

const toast = useToastStore()

const level = ref('A1')
const skill = ref('grammar')
const question = ref('')
const options = ref(['', '', '', ''])
const correctIndex = ref(0)
const audioUrl = ref('')
const status = ref('')

const questions = ref([])
const loading = ref(true)
const editingId = ref(null)
const filterLevel = ref('todos')

function resetForm() {
  editingId.value = null
  level.value = 'A1'
  skill.value = 'grammar'
  question.value = ''
  options.value = ['', '', '', '']
  correctIndex.value = 0
  audioUrl.value = ''
}

function startEdit(q) {
  editingId.value = q.id
  level.value = q.level
  skill.value = q.skill
  question.value = q.question
  options.value = [...q.options, '', '', '', ''].slice(0, 4)
  correctIndex.value = q.correct_index
  audioUrl.value = q.audio_url || ''
}

async function loadQuestions() {
  loading.value = true
  try {
    questions.value = await fetchAllQuestionsAdmin()
  } catch (err) {
    console.error(err)
    toast.show('⚠ Error cargando preguntas')
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  const cleanOptions = options.value.map((o) => o.trim()).filter(Boolean)
  if (!question.value.trim() || cleanOptions.length < 2) {
    toast.show('⚠ Falta el texto o al menos 2 opciones')
    return
  }
  status.value = 'Guardando…'
  try {
    const payload = {
      level: level.value,
      skill: skill.value,
      question: question.value.trim(),
      options: cleanOptions,
      correct_index: correctIndex.value,
      audio_url: audioUrl.value.trim() || null,
    }
    if (editingId.value) {
      await updateQuestion(editingId.value, payload)
      toast.show('✓ Pregunta actualizada')
    } else {
      await createQuestion(payload)
      toast.show('✓ Pregunta creada')
    }
    resetForm()
    await loadQuestions()
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo guardar')
  } finally {
    status.value = ''
  }
}

async function handleToggleActive(q) {
  try {
    await updateQuestion(q.id, { is_active: !q.is_active })
    await loadQuestions()
  } catch (err) {
    toast.show('⚠ Error al cambiar estado')
  }
}

async function handleDelete(q) {
  if (!confirm('¿Borrar esta pregunta?')) return
  try {
    await deleteQuestion(q.id)
    toast.show('✓ Pregunta eliminada')
    await loadQuestions()
  } catch (err) {
    toast.show('⚠ Error al eliminar')
  }
}

onMounted(loadQuestions)
</script>

<template>
  <div class="dash__panel">
    <h3>{{ editingId ? 'Editar pregunta' : 'Nueva pregunta del Test de Nivel' }}</h3>
    <form @submit.prevent="handleSubmit" style="margin-top: 1rem">
      <div style="display: flex; gap: 1rem">
        <div class="form-field" style="flex: 1">
          <label>Nivel</label>
          <select v-model="level">
            <option>A1</option><option>A2</option><option>B1</option>
            <option>B2</option><option>C1</option><option>C2</option>
          </select>
        </div>
        <div class="form-field" style="flex: 1">
          <label>Habilidad</label>
          <select v-model="skill">
            <option value="grammar">Gramática</option>
            <option value="vocabulary">Vocabulario</option>
            <option value="reading">Lectura</option>
            <option value="listening">Escucha</option>
          </select>
        </div>
      </div>
      <div class="form-field">
        <label>Pregunta</label>
        <input v-model="question" type="text" />
      </div>
      <div v-for="(opt, i) in options" :key="i" style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem">
        <input type="radio" :checked="correctIndex === i" @change="correctIndex = i" style="width: auto" />
        <input v-model="options[i]" type="text" :placeholder="`Opción ${i + 1}${i >= 2 ? ' (opcional)' : ''}`" style="flex: 1; margin: 0" />
      </div>
      <span style="font-size: 0.75rem; opacity: 0.6">Marcá con el círculo cuál opción es la correcta</span>
      <div class="form-field" style="margin-top: 0.75rem">
        <label>Audio URL (opcional, para listening)</label>
        <input v-model="audioUrl" type="text" placeholder="https://..." />
      </div>
      <button type="submit" class="btn btn--primary btn--sm">{{ editingId ? 'Guardar cambios' : 'Crear pregunta' }}</button>
      <button v-if="editingId" type="button" class="btn btn--ghost btn--sm" @click="resetForm">Cancelar</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>

  <div class="dash__panel" style="margin-top: 1.25rem">
    <div style="display: flex; justify-content: space-between; align-items: center">
      <h3>Banco de preguntas ({{ questions.length }})</h3>
      <select v-model="filterLevel" style="width: auto; padding: 0.4rem 0.6rem">
        <option value="todos">Todos los niveles</option>
        <option>A1</option><option>A2</option><option>B1</option>
        <option>B2</option><option>C1</option><option>C2</option>
      </select>
    </div>
    <p v-if="loading" style="opacity: 0.6; margin-top: 1rem">Cargando…</p>
    <div v-else style="margin-top: 1rem; display: flex; flex-direction: column; gap: 0.6rem">
      <div
        v-for="q in questions.filter((q) => filterLevel === 'todos' || q.level === filterLevel)"
        :key="q.id"
        class="lesson__item"
      >
        <div class="lesson__thumb">{{ q.skill === 'listening' ? '🎧' : q.skill === 'reading' ? '📖' : q.skill === 'vocabulary' ? '🔤' : '📝' }}</div>
        <div class="lesson__info" style="flex: 1">
          <strong>{{ q.question }} <span v-if="!q.is_active" style="opacity: 0.5">(inactiva)</span></strong>
          <span>{{ q.level }} · {{ q.skill }}</span>
        </div>
        <button class="btn btn--ghost btn--sm" @click="startEdit(q)">✏</button>
        <button class="btn btn--ghost btn--sm" @click="handleToggleActive(q)">{{ q.is_active ? '🚫' : '✓' }}</button>
        <button class="danger" @click="handleDelete(q)">🗑</button>
      </div>
      <p v-if="!questions.length" style="opacity: 0.6">Todavía no hay preguntas cargadas.</p>
    </div>
  </div>
</template>
PANELQUESTIONS_EOF

cat > client/src/views/PanelView.vue << 'PANELVIEW_EOF'
<script setup>
import { ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import PanelCreateCourse from '../components/panel/PanelCreateCourse.vue'
import PanelCreateLesson from '../components/panel/PanelCreateLesson.vue'
import PanelMaterials from '../components/panel/PanelMaterials.vue'
import PanelSales from '../components/panel/PanelSales.vue'
import PanelEnroll from '../components/panel/PanelEnroll.vue'
import PanelLevelTestResults from '../components/panel/PanelLevelTestResults.vue'
import PanelActivities from '../components/panel/PanelActivities.vue'
import PanelLevelTestQuestions from '../components/panel/PanelLevelTestQuestions.vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const lessonPanel = ref(null)

// Cuando se crea un curso, refrescamos las opciones del selector de lecciones
function onCourseCreated() {
  lessonPanel.value?.loadCourses()
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Panel Docente</h1>
      <p class="dash__subtitle">Cursos, lecciones, materiales, pagos e inscripciones.</p>
    </div>

    <div class="dash__row" style="margin-top: 1.25rem; display: flex; gap: 1.5rem; flex-wrap: wrap">
      <div class="dash__col" style="flex: 1; min-width: 320px">
        <PanelCreateCourse @created="onCourseCreated" />
      </div>
      <div class="dash__col" style="flex: 1; min-width: 320px">
        <PanelCreateLesson ref="lessonPanel" />
      </div>
    </div>

    <div style="margin-top: 1.5rem">
      <PanelMaterials />
    </div>

    <div style="margin-top: 1.5rem">
      <PanelEnroll />
    </div>

    <div style="margin-top: 1.5rem">
      <PanelSales />
    </div>

    <div style="margin-top: 1.5rem">
      <PanelLevelTestResults />
    </div>

    <div v-if="auth.role === 'admin'" style="margin-top: 1.5rem">
      <PanelActivities />
    </div>

    <div v-if="auth.role === 'admin'" style="margin-top: 1.5rem">
      <PanelLevelTestQuestions />
    </div>
  </DashboardLayout>
</template>
PANELVIEW_EOF

rm -f "$0"
git add -A
git commit -m "feat: panel admin para gestionar preguntas del Test de Nivel (CRUD, antes solo via SQL)"
git push origin main
echo "Listo. Manual Deploy -> Deploy latest commit en Render."

<script setup>
// LevelTestView.vue — Test Nivelador Automatizado (post-pago)
// Anti-cheat: visibilitychange/blur dispara auto-envío. contextmenu y
// selección de texto bloqueados. Timer estricto de 30s por pregunta.

import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { useLevelTestStore } from '@/stores/levelTest'
import { assignCourseAndTutor } from '@/services/api'

const router = useRouter()
const levelTestStore = useLevelTestStore()

// ── Estado del examen ────────────────────────────────────────
const questions = ref([]) // se carga en onMounted desde la API
const currentIndex = ref(0)
const answers = ref([]) // respuesta por índice de pregunta (o null si vacía)
const isSubmitting = ref(false)
const wasAutoSubmitted = ref(false)

const currentQuestion = computed(() => questions.value[currentIndex.value] || null)
const isLastQuestion = computed(() => currentIndex.value === questions.value.length - 1)

// ── Temporizador (30s por pregunta) ──────────────────────────
const SECONDS_PER_QUESTION = 30
const timeLeft = ref(SECONDS_PER_QUESTION)
let timerHandle = null

function startTimer() {
  clearTimer()
  timeLeft.value = SECONDS_PER_QUESTION
  timerHandle = setInterval(() => {
    timeLeft.value -= 1
    if (timeLeft.value <= 0) {
      // Se acabó el tiempo: guarda lo que haya (o null) y avanza sola.
      goToNextQuestion()
    }
  }, 1000)
}

function clearTimer() {
  if (timerHandle) {
    clearInterval(timerHandle)
    timerHandle = null
  }
}

// ── Navegación entre preguntas ────────────────────────────────
function selectAnswer(optionId) {
  answers.value[currentIndex.value] = optionId
}

function goToNextQuestion() {
  // Si no hay respuesta seleccionada, queda registrada como null (vacía).
  if (answers.value[currentIndex.value] === undefined) {
    answers.value[currentIndex.value] = null
  }

  if (isLastQuestion.value) {
    clearTimer()
    finishTest()
    return
  }

  currentIndex.value += 1
  startTimer()
}

// ── Anti-cheat: pérdida de foco → auto-envío inmediato ───────
function handleVisibilityOrBlur() {
  if (document.visibilityState === 'hidden' && !isSubmitting.value) {
    wasAutoSubmitted.value = true
    finishTest({ forced: true })
  }
}

function handleWindowBlur() {
  if (!isSubmitting.value) {
    wasAutoSubmitted.value = true
    finishTest({ forced: true })
  }
}

// Bloquea click derecho y selección/copiado de texto dentro del examen.
function blockContextMenu(e) {
  e.preventDefault()
}
function blockSelection(e) {
  e.preventDefault()
}
function blockCopy(e) {
  e.preventDefault()
}

// ── Procesamiento final del resultado ────────────────────────
async function finishTest({ forced = false } = {}) {
  if (isSubmitting.value) return // evita doble envío (timer + blur casi simultáneos)
  isSubmitting.value = true
  clearTimer()

  // Si se corta a mitad de pregunta (por el blur), la respuesta actual
  // también queda registrada como vacía si no se había marcado nada.
  if (answers.value[currentIndex.value] === undefined) {
    answers.value[currentIndex.value] = null
  }

  const level = calculateLevel(answers.value, questions.value)

  // Estado global en Pinia
  levelTestStore.setResult({
    level,
    answers: answers.value,
    autoSubmitted: forced,
    completedAt: new Date().toISOString(),
  })

  try {
    // Asignación inmediata de curso + tutor según el nivel obtenido.
    const assignment = await assignCourseAndTutor({ level })
    levelTestStore.setAssignment(assignment)
    router.push({ name: 'student-dashboard' })
  } catch (err) {
    levelTestStore.setError(err.message)
    // Aun si falla la asignación automática, no dejamos al alumno trabado
    // repitiendo el examen: lo mandamos a un estado de "pendiente de revisión".
    router.push({ name: 'student-dashboard', query: { pendingAssignment: '1' } })
  } finally {
    isSubmitting.value = false
  }
}

function calculateLevel(userAnswers, testQuestions) {
  const correctCount = userAnswers.reduce((acc, answer, idx) => {
    const question = testQuestions[idx]
    return answer !== null && question && answer === question.correctOptionId ? acc + 1 : acc
  }, 0)

  const ratio = testQuestions.length ? correctCount / testQuestions.length : 0
  if (ratio >= 0.85) return 'C1'
  if (ratio >= 0.65) return 'B2'
  if (ratio >= 0.45) return 'B1'
  if (ratio >= 0.25) return 'A2'
  return 'A1'
}

// ── Ciclo de vida ─────────────────────────────────────────────
onMounted(async () => {
  questions.value = await levelTestStore.fetchQuestions()
  answers.value = new Array(questions.value.length)
  startTimer()

  document.addEventListener('visibilitychange', handleVisibilityOrBlur)
  window.addEventListener('blur', handleWindowBlur)
  document.addEventListener('contextmenu', blockContextMenu)
  document.addEventListener('selectstart', blockSelection)
  document.addEventListener('copy', blockCopy)
})

onBeforeUnmount(() => {
  clearTimer()
  document.removeEventListener('visibilitychange', handleVisibilityOrBlur)
  window.removeEventListener('blur', handleWindowBlur)
  document.removeEventListener('contextmenu', blockContextMenu)
  document.removeEventListener('selectstart', blockSelection)
  document.removeEventListener('copy', blockCopy)
})
</script>

<template>
  <div class="level-test" v-if="currentQuestion">
    <div class="level-test__timer">{{ timeLeft }}s</div>
    <p class="level-test__progress">Pregunta {{ currentIndex + 1 }} / {{ questions.length }}</p>

    <h2>{{ currentQuestion.text }}</h2>

    <ul class="level-test__options">
      <li
        v-for="option in currentQuestion.options"
        :key="option.id"
        :class="{ selected: answers[currentIndex] === option.id }"
        @click="selectAnswer(option.id)"
      >
        {{ option.label }}
      </li>
    </ul>

    <button :disabled="isSubmitting" @click="goToNextQuestion">
      {{ isLastQuestion ? 'Finalizar' : 'Siguiente' }}
    </button>
  </div>
</template>

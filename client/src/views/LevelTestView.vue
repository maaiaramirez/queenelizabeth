<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { fetchLevelTestQuestions, submitLevelTest } from '../services/levelTest'
import { useToastStore } from '../stores/toast'

const router = useRouter()
const toast = useToastStore()

const stage = ref('intro')
const errorMsg = ref('')

const questions = ref([])
const currentIndex = ref(0)
const answers = ref({})
const cheatEvents = ref([])
const startedAt = ref(null)

const result = ref(null)

const TEST_SECONDS = 20 * 60
const secondsLeft = ref(TEST_SECONDS)
let timerHandle = null

const currentQuestion = computed(() => questions.value[currentIndex.value] || null)
const progressPct = computed(() =>
  questions.value.length ? Math.round(((currentIndex.value + 1) / questions.value.length) * 100) : 0,
)
const selectedForCurrent = computed(() =>
  currentQuestion.value ? answers.value[currentQuestion.value.id] : undefined,
)
const isLastQuestion = computed(() => currentIndex.value === questions.value.length - 1)

const timeLabel = computed(() => {
  const m = Math.floor(secondsLeft.value / 60)
  const s = secondsLeft.value % 60
  return `${m}:${String(s).padStart(2, '0')}`
})

function logCheatEvent(type) {
  cheatEvents.value.push({ type, at: new Date().toISOString() })
}

function handleVisibility() {
  if (stage.value !== 'running') return
  if (document.hidden) {
    logCheatEvent('visibility')
    toast.show('⚠ Se detectó un cambio de pestaña. Quedó registrado.')
  }
}
function handleBlur() {
  if (stage.value !== 'running') return
  logCheatEvent('blur')
}
function handleCopyPaste(e) {
  if (stage.value !== 'running') return
  e.preventDefault()
  logCheatEvent(e.type)
}
function handleContextMenu(e) {
  if (stage.value !== 'running') return
  e.preventDefault()
}
function handleKeydown(e) {
  if (stage.value !== 'running') return
  const key = e.key?.toLowerCase()
  const blocked =
    key === 'f12' ||
    (e.ctrlKey && e.shiftKey && ['i', 'j', 'c'].includes(key)) ||
    (e.metaKey && e.altKey && ['i', 'j', 'c'].includes(key)) ||
    (e.ctrlKey && key === 'u')
  if (blocked) {
    e.preventDefault()
    logCheatEvent('devtools_attempt')
  }
}
function handleFullscreenChange() {
  if (stage.value !== 'running') return
  if (!document.fullscreenElement) {
    logCheatEvent('fullscreen_exit')
  }
}

function attachAntiCheatListeners() {
  document.addEventListener('visibilitychange', handleVisibility)
  window.addEventListener('blur', handleBlur)
  document.addEventListener('copy', handleCopyPaste)
  document.addEventListener('paste', handleCopyPaste)
  document.addEventListener('cut', handleCopyPaste)
  document.addEventListener('contextmenu', handleContextMenu)
  document.addEventListener('keydown', handleKeydown)
  document.addEventListener('fullscreenchange', handleFullscreenChange)
}
function detachAntiCheatListeners() {
  document.removeEventListener('visibilitychange', handleVisibility)
  window.removeEventListener('blur', handleBlur)
  document.removeEventListener('copy', handleCopyPaste)
  document.removeEventListener('paste', handleCopyPaste)
  document.removeEventListener('cut', handleCopyPaste)
  document.removeEventListener('contextmenu', handleContextMenu)
  document.removeEventListener('keydown', handleKeydown)
  document.removeEventListener('fullscreenchange', handleFullscreenChange)
}

function startTimer() {
  timerHandle = setInterval(() => {
    secondsLeft.value -= 1
    if (secondsLeft.value <= 0) {
      clearInterval(timerHandle)
      finishTest(true)
    }
  }, 1000)
}
function stopTimer() {
  if (timerHandle) clearInterval(timerHandle)
  timerHandle = null
}

async function startTest() {
  errorMsg.value = ''
  try {
    questions.value = await fetchLevelTestQuestions()
    if (!questions.value.length) {
      errorMsg.value = 'Todavía no hay preguntas cargadas para el test de nivel.'
      return
    }
    try {
      await document.documentElement.requestFullscreen?.()
    } catch {
      // seguimos sin fullscreen
    }
    startedAt.value = new Date().toISOString()
    currentIndex.value = 0
    answers.value = {}
    cheatEvents.value = []
    secondsLeft.value = TEST_SECONDS
    stage.value = 'running'
    attachAntiCheatListeners()
    startTimer()
  } catch (err) {
    console.error(err)
    errorMsg.value = err.message || 'No se pudo iniciar el test.'
  }
}

function selectOption(index) {
  if (!currentQuestion.value) return
  answers.value[currentQuestion.value.id] = index
}

function goNext() {
  if (selectedForCurrent.value === undefined) {
    toast.show('Elegí una opción para continuar.')
    return
  }
  if (isLastQuestion.value) {
    finishTest(false)
  } else {
    currentIndex.value += 1
  }
}

async function finishTest(auto) {
  stopTimer()
  detachAntiCheatListeners()
  if (document.fullscreenElement) {
    try {
      await document.exitFullscreen()
    } catch {
      // no-op
    }
  }
  stage.value = 'submitting'
  try {
    const payloadAnswers = questions.value
      .filter((q) => answers.value[q.id] !== undefined)
      .map((q) => ({ question_id: q.id, selected_index: answers.value[q.id] }))

    result.value = await submitLevelTest({
      answers: payloadAnswers,
      cheatEvents: cheatEvents.value,
      startedAt: startedAt.value,
    })
    stage.value = 'done'
    if (auto) toast.show('⏱ Se acabó el tiempo, enviamos tus respuestas.')
  } catch (err) {
    console.error(err)
    errorMsg.value = err.message || 'No se pudo enviar el test.'
    stage.value = 'error'
  }
}

onBeforeUnmount(() => {
  stopTimer()
  detachAntiCheatListeners()
})
</script>

<template>
  <div class="auth-page" style="max-width: 640px">
    <div v-if="stage === 'intro'" style="text-align: center">
      <span style="font-size: 2rem; color: var(--gold)">👑</span>
      <h2 style="font-family: var(--font-serif); color: var(--navy)">Test de Nivel</h2>
      <p style="color: var(--text-mid); margin: 0.75rem 0 1.5rem">
        {{ questions.length ? questions.length : '12' }} preguntas de gramática y vocabulario, 20 minutos.
        Una vez que empieces, no vas a poder salir de pantalla completa ni cambiar de pestaña sin que quede
        registrado.
      </p>
      <p v-if="errorMsg" class="form-error">{{ errorMsg }}</p>
      <button class="btn btn--primary" style="width: 100%" @click="startTest">Empezar test</button>
    </div>

    <div v-else-if="stage === 'running' && currentQuestion">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem">
        <span style="font-size: 0.8rem; color: var(--text-muted)">
          Pregunta {{ currentIndex + 1 }} / {{ questions.length }} · Nivel {{ currentQuestion.level }}
        </span>
        <span style="font-weight: 700; color: var(--navy)">⏱ {{ timeLabel }}</span>
      </div>

      <div style="height: 6px; background: var(--ivory-dark); border-radius: 999px; overflow: hidden; margin-bottom: 1.5rem">
        <div
          :style="{ width: progressPct + '%', height: '100%', background: 'var(--gold)', transition: 'width .25s' }"
        ></div>
      </div>

      <h3 style="font-family: var(--font-serif); color: var(--navy); margin-bottom: 1.25rem">
        {{ currentQuestion.question }}
      </h3>

      <div style="display: flex; flex-direction: column; gap: 0.6rem; margin-bottom: 1.5rem">
        <button
          v-for="(opt, i) in currentQuestion.options"
          :key="i"
          type="button"
          class="btn"
          :class="selectedForCurrent === i ? 'btn--primary' : 'btn--plan'"
          style="text-align: left; width: 100%"
          @click="selectOption(i)"
        >
          {{ opt }}
        </button>
      </div>

      <button class="btn btn--primary" style="width: 100%" @click="goNext">
        {{ isLastQuestion ? 'Finalizar test' : 'Siguiente' }}
      </button>
    </div>

    <div v-else-if="stage === 'submitting'" style="text-align: center; padding: 2rem 0">
      <p style="color: var(--text-mid)">Corrigiendo tu test…</p>
    </div>

    <div v-else-if="stage === 'done' && result" style="text-align: center">
      <span style="font-size: 2rem; color: var(--gold)">🎓</span>
      <h2 style="font-family: var(--font-serif); color: var(--navy)">¡Listo!</h2>
      <p style="color: var(--text-mid); margin: 0.75rem 0 0.25rem">Tu nivel asignado es:</p>
      <p style="font-size: 2rem; font-weight: 800; color: var(--navy); margin: 0 0 1rem">
        {{ result.level_assigned }}
      </p>
      <p style="color: var(--text-muted); margin-bottom: 1.5rem">
        {{ result.score }} de {{ result.total_questions }} respuestas correctas.
      </p>
      <button class="btn btn--primary" style="width: 100%" @click="router.push({ name: 'dashboard' })">
        Ir a mi panel
      </button>
    </div>

    <div v-else-if="stage === 'error'" style="text-align: center">
      <p class="form-error">{{ errorMsg }}</p>
      <button class="btn btn--primary" style="width: 100%" @click="stage = 'intro'">Volver a intentar</button>
    </div>
  </div>
</template>

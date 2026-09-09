<script setup>
import { computed, ref } from 'vue'

const props = defineProps({ activity: { type: Object, required: true } })
const emit = defineEmits(['close'])

const current = ref(0)
const selected = ref(null)
const answered = ref(false)
const correctCount = ref(0)
const finished = ref(false)

const questions = props.activity.questions || []
const currentQ = computed(() => questions[current.value])
const isLast = computed(() => current.value === questions.length - 1)

function choose(i) {
  if (answered.value) return
  selected.value = i
  answered.value = true
  if (i === currentQ.value.correct_index) correctCount.value++
}

function next() {
  if (isLast.value) {
    finished.value = true
    return
  }
  current.value++
  selected.value = null
  answered.value = false
}

function restart() {
  current.value = 0
  selected.value = null
  answered.value = false
  correctCount.value = 0
  finished.value = false
}

function optionClass(i) {
  if (!answered.value) return ''
  if (i === currentQ.value.correct_index) return 'game-opt--correct'
  if (i === selected.value) return 'game-opt--wrong'
  return ''
}
</script>

<template>
  <div class="auth__overlay" style="display: flex" @click.self="emit('close')">
    <div class="auth__modal" style="max-height: 90vh; overflow-y: auto">
      <button class="auth__close" aria-label="Cerrar" @click="emit('close')">✕</button>
      <div class="auth__panel">
        <template v-if="!finished">
          <div class="auth__header" style="margin-bottom: 1rem">
            <h2 class="auth__title" style="font-size: 1.2rem">{{ activity.title }}</h2>
            <p class="auth__subtitle">Pregunta {{ current + 1 }} de {{ questions.length }}</p>
          </div>
          <div style="height: 6px; background: var(--border); border-radius: 99px; margin-bottom: 1.5rem; overflow: hidden">
            <div
              style="height: 100%; background: var(--gold); border-radius: 99px; transition: width 0.3s"
              :style="{ width: `${((current + (answered ? 1 : 0)) / questions.length) * 100}%` }"
            ></div>
          </div>

          <p style="font-size: 1.05rem; font-weight: 600; color: var(--navy); margin-bottom: 1.25rem">
            {{ currentQ.question }}
          </p>

          <div style="display: flex; flex-direction: column; gap: 0.6rem; margin-bottom: 1.25rem">
            <button
              v-for="(opt, i) in currentQ.options"
              :key="i"
              type="button"
              class="game-opt"
              :class="optionClass(i)"
              :disabled="answered"
              @click="choose(i)"
            >
              {{ opt }}
            </button>
          </div>

          <div v-if="answered" style="margin-bottom: 1rem">
            <p v-if="selected === currentQ.correct_index" style="color: #16a34a; font-weight: 600">✓ ¡Correcto!</p>
            <p v-else style="color: var(--red); font-weight: 600">
              ✕ No era esa — la correcta es "{{ currentQ.options[currentQ.correct_index] }}"
            </p>
          </div>

          <button v-if="answered" class="btn btn--primary auth__submit" @click="next">
            {{ isLast ? 'Ver resultado' : 'Siguiente →' }}
          </button>
        </template>

        <template v-else>
          <div style="text-align: center">
            <div style="font-size: 2.5rem; margin-bottom: 0.5rem">
              {{ correctCount === questions.length ? '🏆' : correctCount >= questions.length / 2 ? '🎉' : '💪' }}
            </div>
            <h2 style="font-family: var(--font-serif); color: var(--navy); margin-bottom: 0.5rem">
              {{ correctCount }} / {{ questions.length }} correctas
            </h2>
            <p style="opacity: 0.75; margin-bottom: 1.5rem">
              {{
                correctCount === questions.length
                  ? '¡Perfecto! Dominás este tema.'
                  : correctCount >= questions.length / 2
                  ? '¡Bien! Seguí practicando para mejorar.'
                  : 'Vale la pena repasar este tema de nuevo.'
              }}
            </p>
            <button class="btn btn--primary" style="margin-right: 0.5rem" @click="restart">🔁 Jugar de nuevo</button>
            <button class="btn btn--ghost" @click="emit('close')">Cerrar</button>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

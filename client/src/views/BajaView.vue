<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { CANCELLATION_REASONS, submitCancellation } from '../services/cancellations'

const router = useRouter()
const toast = useToastStore()

const satisfaction = ref(0)
const reason = ref('')
const reasonDetail = ref('')
const comments = ref('')
const submitting = ref(false)
const done = ref(false)
const confirmStep = ref(false)

async function handleSubmit() {
  if (!satisfaction.value) {
    toast.show('⚠ Elegí un puntaje de satisfacción')
    return
  }
  if (!reason.value) {
    toast.show('⚠ Elegí un motivo')
    return
  }
  if (!confirmStep.value) {
    confirmStep.value = true
    return
  }
  submitting.value = true
  try {
    await submitCancellation({
      reason: reason.value,
      reasonDetail: reasonDetail.value.trim(),
      satisfaction: satisfaction.value,
      comments: comments.value.trim(),
    })
    done.value = true
    toast.show('✓ Baja registrada')
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo registrar la baja. Probá de nuevo.')
    confirmStep.value = false
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Dar de baja tu cuenta</h1>
      <p class="dash__subtitle">Antes de irte, contanos qué falló — nos ayuda a mejorar.</p>
    </div>

    <div class="dash__panel" style="margin-top: 1.25rem; max-width: 560px">
      <template v-if="done">
        <h3>Listo, tu baja quedó registrada 💙</h3>
        <p style="opacity: 0.8; margin: 0.75rem 0 1.25rem">
          Gracias por contarnos tu experiencia. Si en algún momento querés volver, las puertas están
          abiertas.
        </p>
        <button class="btn btn--primary" @click="router.push({ name: 'dashboard' })">Volver al inicio</button>
      </template>

      <template v-else>
        <div class="form-field">
          <label>¿Qué tan conforme estuviste con Queen Elizabeth Academy?</label>
          <div style="display: flex; gap: 0.5rem; margin-top: 0.4rem">
            <button
              v-for="n in 5"
              :key="n"
              type="button"
              class="btn btn--sm"
              :class="satisfaction === n ? 'btn--primary' : 'btn--ghost'"
              @click="satisfaction = n"
            >
              {{ n }}
            </button>
          </div>
          <span style="font-size: 0.78rem; opacity: 0.6">1 = muy insatisfecho · 5 = muy satisfecho</span>
        </div>

        <div class="form-field" style="margin-top: 1rem">
          <label>¿Por qué te vas?</label>
          <select v-model="reason">
            <option disabled value="">Elegí un motivo…</option>
            <option v-for="(label, key) in CANCELLATION_REASONS" :key="key" :value="key">{{ label }}</option>
          </select>
        </div>

        <div v-if="reason === 'otro'" class="form-field" style="margin-top: 0.75rem">
          <label>Contanos un poco más</label>
          <input v-model="reasonDetail" type="text" placeholder="Motivo específico" />
        </div>

        <div class="form-field" style="margin-top: 0.75rem">
          <label>Comentarios (opcional)</label>
          <textarea v-model="comments" rows="3" placeholder="¿Algo que quieras agregar?"></textarea>
        </div>

        <div v-if="!confirmStep">
          <button class="btn btn--primary" style="margin-top: 1rem" :disabled="submitting" @click="handleSubmit">
            Continuar
          </button>
        </div>
        <div v-else style="margin-top: 1rem; padding: 0.9rem; border-radius: 10px; background: var(--ivory-dark)">
          <p style="font-size: 0.9rem; margin-bottom: 0.75rem">
            ⚠ Esto va a dar de baja tu cuenta y marcar tu estado de pago como <strong>cancelado</strong>. ¿Confirmás?
          </p>
          <button class="btn btn--primary btn--sm" :disabled="submitting" @click="handleSubmit">
            {{ submitting ? 'Procesando…' : 'Sí, confirmar baja' }}
          </button>
          <button class="btn btn--ghost btn--sm" :disabled="submitting" @click="confirmStep = false">
            Volver
          </button>
        </div>
      </template>
    </div>
  </DashboardLayout>
</template>

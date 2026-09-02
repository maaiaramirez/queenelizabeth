<script setup>
import { ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { downloadReceipt, sendReceiptByEmail } from '../../services/receipts'
import { fmtMoney } from '../../services/sales'

const props = defineProps({ sale: { type: Object, required: true } })
const emit = defineEmits(['close'])

const toast = useToastStore()
const sending = ref(false)

function handleDownload() {
  downloadReceipt(props.sale)
}

async function handleSend() {
  sending.value = true
  try {
    await sendReceiptByEmail(props.sale.id)
    toast.show('✓ Recibo enviado por mail')
  } catch (err) {
    console.error(err)
    toast.show('⚠ ' + err.message)
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <div class="auth__overlay" style="display: flex" @click.self="emit('close')">
    <div class="auth__modal">
      <button class="auth__close" aria-label="Cerrar" @click="emit('close')">✕</button>
      <div class="auth__panel">
        <div class="auth__header">
          <span class="auth__crown" aria-hidden="true">♛</span>
          <h2 class="auth__title">Recibo virtual</h2>
          <p class="auth__subtitle">REC-{{ sale.id.slice(0, 8).toUpperCase() }}</p>
        </div>

        <div style="text-align: left; font-size: 0.92rem; line-height: 1.9">
          <div><strong>Alumno:</strong> {{ sale.student_name || '—' }}</div>
          <div><strong>Email:</strong> {{ sale.student_email || '—' }}</div>
          <div><strong>Plan:</strong> {{ sale.plan_name || '—' }}</div>
          <div><strong>Fecha:</strong> {{ new Date(sale.created_at).toLocaleDateString('es-AR') }}</div>
          <div><strong>Estado:</strong> {{ sale.status }}</div>
          <div style="font-size: 1.1rem; margin-top: 0.5rem">
            <strong>Monto:</strong> {{ fmtMoney(sale.amount) }}
          </div>
        </div>

        <button class="btn btn--primary auth__submit" @click="handleDownload">⬇ Descargar PDF</button>
        <button class="btn btn--ghost auth__submit" style="margin-top: 0.5rem" :disabled="sending" @click="handleSend">
          {{ sending ? 'Enviando…' : '✉ Enviar por mail' }}
        </button>
      </div>
    </div>
  </div>
</template>

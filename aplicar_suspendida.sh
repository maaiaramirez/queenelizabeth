#!/bin/bash
set -e
echo "Corré este script parado en la raíz del repo"
mkdir -p client/src/components client/src/views
cat > client/src/components/DashboardLayout.vue << 'DASHLAYOUT_VUE_EOF'
<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { rolLabel } from '../services/auth'

const auth = useAuthStore()
const router = useRouter()

const suspended = auth.role === 'student' && auth.profile?.payment_status === 'cancelado'

async function handleLogout() {
  await auth.logout()
  router.push({ name: 'home' })
}

// data-roles del link original -> a quién se le muestra
const links = [
  { to: '/dashboard', icon: '⊞', label: 'Resumen', roles: null },
  { to: '/materiales', icon: '📂', label: 'Materiales', roles: null },
  { to: '/test-de-nivel', icon: '📝', label: 'Test de Nivel', roles: null },
  { to: '/biblioteca', icon: '🗂️', label: 'Biblioteca de Materiales', roles: ['teacher', 'admin'] },
  { to: '/panel', icon: '🛠️', label: 'Panel Docente', roles: ['teacher', 'admin'] },
  { to: '/comercial', icon: '💼', label: 'Gestión Comercial', roles: ['admin'] },
  { to: '/admin/usuarios', icon: '👥', label: 'Usuarios', roles: ['admin'] },
]
</script>

<template>
  <div v-if="suspended" class="dashboard" style="display: flex; align-items: center; justify-content: center; min-height: 100vh; background: var(--navy)">
    <div class="dash__panel" style="max-width: 420px; text-align: center">
      <div style="font-size: 2.5rem; margin-bottom: 0.5rem">🔒</div>
      <h2 style="color: var(--navy); margin-bottom: 0.5rem">Cuenta suspendida</h2>
      <p style="opacity: 0.75; margin-bottom: 1.5rem">
        Tu cuenta está suspendida debido a una baja. Si creés que esto es un error o querés reactivarla,
        contactá a la academia.
      </p>
      <button class="btn btn--primary" @click="handleLogout">Salir</button>
    </div>
  </div>

  <div v-else class="dashboard">
    <aside class="sidebar">
      <div class="sidebar__user">
        <div class="sidebar__avatar">{{ auth.initials }}</div>
        <div class="sidebar__user-info">
          <strong>{{ auth.firstName }}</strong>
          <span>{{ rolLabel(auth.role) }}</span>
        </div>
      </div>
      <nav class="sidebar__nav" aria-label="Menú">
        <RouterLink
          v-for="link in links"
          :key="link.to"
          v-show="!link.roles || link.roles.includes(auth.role)"
          :to="link.to"
          class="sidebar__link"
          active-class="sidebar__link--active"
        >
          <span class="sidebar__icon" aria-hidden="true">{{ link.icon }}</span> {{ link.label }}
        </RouterLink>
      </nav>
    </aside>

    <main class="dash__main">
      <slot />
    </main>
  </div>
</template>
DASHLAYOUT_VUE_EOF

cat > client/src/views/BajaView.vue << 'BAJAVIEW_VUE_EOF'
<script setup>
import { ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { useAuthStore } from '../stores/auth'
import { CANCELLATION_REASONS, submitCancellation } from '../services/cancellations'

const toast = useToastStore()
const auth = useAuthStore()

const satisfaction = ref(0)
const reason = ref('')
const reasonDetail = ref('')
const comments = ref('')
const submitting = ref(false)
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
    toast.show('✓ Baja registrada')
    await auth.refreshProfile()
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
      </div>
  </DashboardLayout>
</template>
BAJAVIEW_VUE_EOF

rm -f "$0"
git add -A
git commit -m "feat: cuenta suspendida tras la baja (bloquea dashboard, muestra boton Salir)"
git push origin main
echo "Listo. Acordate: en Render tenés que hacer Manual Deploy -> Deploy latest commit."

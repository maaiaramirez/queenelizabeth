<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import { rolLabel } from '../services/auth'

const auth = useAuthStore()
const toast = useToastStore()
const router = useRouter()

async function handleSignOut() {
  try {
    await auth.logout()
    toast.show('Sesión cerrada · ¡Hasta pronto!')
    router.push({ name: 'home' })
  } catch (e) {
    toast.show('⚠ Error al cerrar sesión')
  }
}
</script>

<template>
  <header class="public-topbar">
    <RouterLink :to="{ name: auth.isLoggedIn ? 'dashboard' : 'home' }">
      <strong>👑 Queen Elizabeth Academy</strong>
    </RouterLink>

    <div class="public-topbar__actions">
      <template v-if="!auth.isLoggedIn">
        <RouterLink to="/login" class="btn btn--ghost btn--sm">Ingresar</RouterLink>
        <RouterLink to="/register" class="btn btn--gold btn--sm">Crear cuenta</RouterLink>
      </template>
      <template v-else>
        <div class="user-chip">
          <span class="user-chip__avatar">{{ auth.initials }}</span>
          <span>{{ auth.firstName }} · {{ rolLabel(auth.role) }}</span>
        </div>
        <RouterLink to="/dashboard" class="btn btn--outline-navy btn--sm">Dashboard</RouterLink>
        <button class="btn btn--ghost btn--sm" @click="handleSignOut">Salir</button>
      </template>
    </div>
  </header>
</template>

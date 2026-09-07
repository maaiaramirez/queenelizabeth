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

<script setup>
import { useAuthStore } from '../stores/auth'
import { rolLabel } from '../services/auth'

const auth = useAuthStore()

// data-roles del link original -> a quién se le muestra
const links = [
  { to: '/dashboard', icon: '⊞', label: 'Resumen', roles: null },
  { to: '/materiales', icon: '📂', label: 'Materiales', roles: null },
  { to: '/biblioteca', icon: '🗂️', label: 'Biblioteca de Materiales', roles: ['teacher', 'admin'] },
  { to: '/panel', icon: '🛠️', label: 'Panel Docente', roles: ['teacher', 'admin'] },
  { to: '/comercial', icon: '💼', label: 'Gestión Comercial', roles: ['admin'] },
  { to: '/admin/usuarios', icon: '👥', label: 'Usuarios', roles: ['admin'] },
]
</script>

<template>
  <div class="dashboard">
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

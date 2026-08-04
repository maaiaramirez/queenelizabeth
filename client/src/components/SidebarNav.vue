<script setup>
/**
 * Sidebar del dashboard. Filtra links por rol usando data-roles del HTML original.
 * TODO: reemplazar `props.user` por el usuario real del store de auth.
 */
defineProps({
  user: {
    type: Object,
    default: () => ({ name: 'Valentina S.', initials: 'VS', level: 'B1', plan: 'Scholar', role: 'student' }),
  },
})

const links = [
  { section: 'overview', icon: '⊞', label: 'Resumen', roles: null, to: { name: 'dashboard' } },
  { section: 'lessons', icon: '📖', label: 'Mis Lecciones', roles: ['student'], to: { name: 'leccion' } },
  { section: 'live', icon: '🎥', label: 'Clases en Vivo', roles: ['student'], to: null },
  { section: 'library', icon: '🎧', label: 'Biblioteca', roles: ['student'], to: null },
  { section: 'materiales', icon: '📂', label: 'Materiales', roles: null, to: { name: 'materiales' } },
  { section: 'admin', icon: '🛠️', label: 'Panel Docente', roles: ['teacher', 'admin'], to: { name: 'admin' } },
  { section: 'comercial', icon: '💼', label: 'Gestión Comercial', roles: ['admin'], to: { name: 'comercial' } },
  { section: 'tutoring', icon: '📅', label: 'Tutorías', roles: ['student'], to: null },
  { section: 'community', icon: '💬', label: 'Comunidad', roles: ['student'], to: null },
  { section: 'badges', icon: '🏅', label: 'Royal Badges', roles: ['student'], to: null },
]

function visible(link, role) {
  return !link.roles || link.roles.includes(role)
}
</script>

<template>
  <aside class="sidebar">
    <div class="sidebar__user">
      <div class="sidebar__avatar">{{ user.initials }}</div>
      <div class="sidebar__user-info">
        <strong>{{ user.name }}</strong>
        <span>Nivel {{ user.level }} · {{ user.plan }}</span>
      </div>
    </div>
    <nav class="sidebar__nav" aria-label="Menú del estudiante">
      <template v-for="link in links" :key="link.section">
        <router-link
          v-if="visible(link, user.role) && link.to"
          :to="link.to"
          class="sidebar__link"
          active-class="sidebar__link--active"
        >
          <span class="sidebar__icon" aria-hidden="true">{{ link.icon }}</span> {{ link.label }}
        </router-link>
        <a v-else-if="visible(link, user.role)" href="#" class="sidebar__link" @click.prevent>
          <span class="sidebar__icon" aria-hidden="true">{{ link.icon }}</span> {{ link.label }}
        </a>
      </template>
      <a href="https://classroom.google.com" target="_blank" rel="noopener" class="sidebar__link">
        <span class="sidebar__icon" aria-hidden="true">🔗</span> Ir a Moodle/Classroom
      </a>
    </nav>
    <div v-if="user.role === 'student'" class="sidebar__streak">
      <div class="streak__flame" role="img" aria-label="Fuego">🔥</div>
      <div>
        <strong>12 días seguidos</strong>
        <span>Sigue así — ¡te faltan 2 días para el badge!</span>
      </div>
    </div>
  </aside>
</template>

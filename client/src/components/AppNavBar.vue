<script setup>
/**
 * Nav superior compartida por todas las páginas internas
 * (dashboard, lección, materiales, comercial, admin).
 * La landing tiene su propia nav con anchors — esto es para el resto.
 *
 * TODO: reemplazar `authStore` por tu composable/store real (Pinia, etc.)
 */
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
// import { useAuthStore } from '@/stores/auth' // TODO: descomentar y usar el store real

const router = useRouter()
const menuOpen = ref(false)

// TODO: reemplazar por store real. Placeholder de ejemplo:
const user = ref(null) // null = invitado. Si hay sesión: { name, role, initials }

const roleLabel = computed(() => {
  const map = { student: 'Alumna', teacher: 'Docente', admin: 'Admin' }
  return user.value ? (map[user.value.role] || user.value.role) : ''
})

function toggleMenu() {
  menuOpen.value = !menuOpen.value
}

function openAuthModal(tab) {
  // TODO: conectar con el estado global del AuthModal (ver AuthModal.vue)
  window.dispatchEvent(new CustomEvent('open-auth-modal', { detail: { tab } }))
}

async function handleSignOut() {
  // TODO: authStore.signOut()
  user.value = null
  router.push({ name: 'landing' })
}
</script>

<template>
  <nav class="nav" id="nav">
    <div class="nav__inner">
      <router-link :to="{ name: 'landing' }" class="nav__logo">
        <span class="nav__logo-crown" aria-hidden="true">♛</span>
        <span class="nav__logo-text">Queen <em>Elizabeth</em></span>
      </router-link>

      <ul class="nav__links" :class="{ open: menuOpen }">
        <li><router-link :to="{ name: 'landing', hash: '#metodologia' }">Metodología</router-link></li>
        <li><router-link :to="{ name: 'landing', hash: '#tutores' }">Tutores</router-link></li>
        <li><router-link :to="{ name: 'landing', hash: '#niveles' }">Niveles</router-link></li>
        <li><router-link :to="{ name: 'landing', hash: '#testimonios' }">Testimonios</router-link></li>
      </ul>

      <div class="nav__actions" :class="{ open: menuOpen }">
        <div v-if="!user" id="navGuest">
          <button class="btn btn--ghost" @click="openAuthModal('login')">Iniciar Sesión</button>
          <button class="btn btn--primary" @click="openAuthModal('register')">Registrarse</button>
        </div>
        <div v-else id="navUser" style="display:flex;align-items:center;gap:.75rem">
          <div class="nav__user-chip">
            <span class="nav__user-avatar">{{ user.initials }}</span>
            <span id="navUserName">{{ user.name }}</span>
            <span class="nav__role-badge">{{ roleLabel }}</span>
          </div>
          <router-link :to="{ name: 'dashboard' }" class="btn btn--ghost btn--sm">Mi Cuenta</router-link>
          <button class="btn btn--ghost btn--sm" @click="handleSignOut">Salir</button>
        </div>
      </div>

      <button class="nav__hamburger" aria-label="Abrir menú de navegación" @click="toggleMenu">
        <span></span><span></span><span></span>
      </button>
    </div>
  </nav>
</template>

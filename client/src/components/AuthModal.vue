<script setup>
/**
 * Modal de Login / Registro / Gestión de Usuarios.
 * Se abre escuchando el evento global 'open-auth-modal' disparado
 * desde AppNavBar (ver openAuthModal). Podés cambiarlo por props/store
 * si preferís control explícito del padre.
 *
 * TODO: reemplazar handleLogin/handleRegister por llamadas reales a Supabase.
 */
import { ref, onMounted, onUnmounted } from 'vue'

const isOpen = ref(false)
const activeTab = ref('login') // 'login' | 'register' | 'users'
const isAdmin = ref(false) // TODO: derivar del store de auth para mostrar tab "Usuarios"

const loginEmail = ref('')
const loginPassword = ref('')
const loginError = ref('')
const loginLoading = ref(false)

const regName = ref('')
const regEmail = ref('')
const regPassword = ref('')
const regRole = ref('student')
const regError = ref('')
const regInfo = ref('')
const regLoading = ref(false)

const users = ref([]) // TODO: cargar desde Supabase cuando isAdmin && activeTab === 'users'

function open(tab = 'login') {
  activeTab.value = tab
  isOpen.value = true
}
function close() {
  isOpen.value = false
  loginError.value = ''
  regError.value = ''
  regInfo.value = ''
}
function onOverlayClick(e) {
  if (e.target === e.currentTarget) close()
}
function switchTab(tab) {
  activeTab.value = tab
}

function onExternalOpen(e) {
  open(e.detail?.tab || 'login')
}
onMounted(() => window.addEventListener('open-auth-modal', onExternalOpen))
onUnmounted(() => window.removeEventListener('open-auth-modal', onExternalOpen))

async function handleLogin() {
  loginError.value = ''
  if (!loginEmail.value || !loginPassword.value) {
    loginError.value = 'Completá email y contraseña.'
    return
  }
  loginLoading.value = true
  try {
    // TODO: await supabase.auth.signInWithPassword({ email: loginEmail.value, password: loginPassword.value })
    close()
  } catch (err) {
    loginError.value = err.message || 'No se pudo iniciar sesión.'
  } finally {
    loginLoading.value = false
  }
}

async function handleRegister() {
  regError.value = ''
  regInfo.value = ''
  if (!regName.value || !regEmail.value || regPassword.value.length < 6) {
    regError.value = 'Revisá los datos (contraseña mínimo 6 caracteres).'
    return
  }
  regLoading.value = true
  try {
    // TODO: await supabase.auth.signUp(...) + insertar perfil con regRole.value
    regInfo.value = 'Cuenta creada. Ya podés iniciar sesión.'
    switchTab('login')
  } catch (err) {
    regError.value = err.message || 'No se pudo crear la cuenta.'
  } finally {
    regLoading.value = false
  }
}

defineExpose({ open, close })
</script>

<template>
  <div class="auth__overlay" :class="{ open: isOpen }" @click="onOverlayClick">
    <div class="auth__modal" role="dialog" aria-modal="true" aria-labelledby="authModalTitle">
      <div class="auth__handle" aria-hidden="true"></div>

      <div class="auth__tabs">
        <button class="auth__tab" :class="{ 'auth__tab--active': activeTab === 'login' }" @click="switchTab('login')">Iniciar Sesión</button>
        <button class="auth__tab" :class="{ 'auth__tab--active': activeTab === 'register' }" @click="switchTab('register')">Registrarse</button>
        <button v-if="isAdmin" class="auth__tab" :class="{ 'auth__tab--active': activeTab === 'users' }" @click="switchTab('users')">👥 Usuarios</button>
      </div>
      <button class="auth__close" aria-label="Cerrar" @click="close">✕</button>

      <!-- LOGIN -->
      <div v-if="activeTab === 'login'" class="auth__panel">
        <div class="auth__header">
          <span class="auth__crown" aria-hidden="true">♛</span>
          <h2 class="auth__title" id="authModalTitle">Bienvenido de nuevo</h2>
          <p class="auth__subtitle">Accedé a tu campus de inglés británico</p>
        </div>
        <div class="auth__fields">
          <label>Email<input v-model="loginEmail" type="email" placeholder="tu@email.com" autocomplete="email" /></label>
          <label>Contraseña<input v-model="loginPassword" type="password" placeholder="••••••••" autocomplete="current-password" /></label>
        </div>
        <p class="auth__error">{{ loginError }}</p>
        <button class="btn btn--primary auth__submit" :disabled="loginLoading" @click="handleLogin">
          {{ loginLoading ? 'Ingresando…' : 'Ingresar' }}
        </button>
        <p class="auth__switch">¿No tenés cuenta? <a href="#" @click.prevent="switchTab('register')">Registrate aquí</a></p>
      </div>

      <!-- REGISTRO -->
      <div v-else-if="activeTab === 'register'" class="auth__panel">
        <div class="auth__header">
          <span class="auth__crown" aria-hidden="true">♛</span>
          <h2 class="auth__title">Crear cuenta</h2>
          <p class="auth__subtitle">Empezá tu camino al inglés británico</p>
        </div>
        <div class="auth__fields">
          <label>Nombre completo<input v-model="regName" type="text" placeholder="Tu nombre" autocomplete="name" /></label>
          <label>Email<input v-model="regEmail" type="email" placeholder="tu@email.com" autocomplete="email" /></label>
          <label>Contraseña<input v-model="regPassword" type="password" placeholder="Mínimo 6 caracteres" autocomplete="new-password" /></label>
          <label>Rol
            <select v-model="regRole">
              <option value="student">Alumno</option>
              <option value="teacher">Docente</option>
              <option value="admin">Administrador</option>
            </select>
          </label>
        </div>
        <p class="auth__error">{{ regError }}</p>
        <p class="auth__info">{{ regInfo }}</p>
        <button class="btn btn--primary auth__submit" :disabled="regLoading" @click="handleRegister">
          {{ regLoading ? 'Creando…' : 'Crear cuenta' }}
        </button>
        <p class="auth__switch">¿Ya tenés cuenta? <a href="#" @click.prevent="switchTab('login')">Iniciá sesión</a></p>
      </div>

      <!-- GESTIÓN DE USUARIOS (solo admin) -->
      <div v-else class="auth__panel">
        <div class="auth__header">
          <h2 class="auth__title">Gestión de Usuarios</h2>
          <p class="auth__subtitle">Administrá roles y cuentas del sistema</p>
        </div>
        <div class="users__table-wrap">
          <table class="users__table" v-if="users.length">
            <thead>
              <tr><th>Nombre</th><th>Email</th><th>Rol</th><th></th></tr>
            </thead>
            <tbody>
              <tr v-for="u in users" :key="u.id">
                <td>{{ u.name }}</td>
                <td>{{ u.email }}</td>
                <td><span class="role-tag" :class="`role-tag--${u.role}`">{{ u.role }}</span></td>
                <td><button class="btn--danger">Quitar</button></td>
              </tr>
            </tbody>
          </table>
          <p v-else style="opacity:.6">Cargando usuarios…</p>
        </div>
      </div>
    </div>
  </div>
</template>

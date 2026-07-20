<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import { traducirError } from '../services/auth'

const auth = useAuthStore()
const toast = useToastStore()

const name = ref('')
const email = ref('')
const password = ref('')
const role = ref('student')
const errorMsg = ref('')
const infoMsg = ref('')
const loading = ref(false)

async function handleRegister() {
  errorMsg.value = ''
  infoMsg.value = ''
  if (!name.value || !email.value || !password.value) {
    errorMsg.value = 'Completá todos los campos.'
    return
  }
  if (password.value.length < 6) {
    errorMsg.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }
  loading.value = true
  try {
    await auth.register(email.value.trim(), password.value, name.value.trim(), role.value)
    infoMsg.value = '✓ Cuenta creada. Revisá tu email para confirmarla (o ingresá si la confirmación está desactivada).'
    toast.show('✓ Usuario creado: ' + name.value)
    name.value = ''
    email.value = ''
    password.value = ''
  } catch (err) {
    errorMsg.value = traducirError(err.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <div style="text-align: center; margin-bottom: 1.5rem">
      <span style="font-size: 2rem; color: var(--gold)">👑</span>
      <h2 style="font-family: var(--font-serif); color: var(--navy)">Crear cuenta</h2>
    </div>

    <form @submit.prevent="handleRegister">
      <div class="form-field">
        <label for="regName">Nombre completo</label>
        <input id="regName" v-model="name" type="text" />
      </div>
      <div class="form-field">
        <label for="regEmail">Email</label>
        <input id="regEmail" v-model="email" type="email" autocomplete="email" />
      </div>
      <div class="form-field">
        <label for="regPassword">Contraseña</label>
        <input id="regPassword" v-model="password" type="password" autocomplete="new-password" />
      </div>
      <div class="form-field">
        <label for="regRole">Rol</label>
        <select id="regRole" v-model="role">
          <option value="student">Alumno</option>
          <option value="teacher">Docente</option>
          <option value="admin">Admin</option>
        </select>
      </div>
      <p class="form-error">{{ errorMsg }}</p>
      <p class="form-info">{{ infoMsg }}</p>
      <button type="submit" class="btn btn--primary" style="width: 100%" :disabled="loading">
        {{ loading ? 'Creando cuenta…' : 'Crear cuenta' }}
      </button>
    </form>

    <p style="text-align: center; margin-top: 1.25rem; font-size: 0.85rem">
      ¿Ya tenés cuenta? <RouterLink to="/login">Ingresá acá</RouterLink>
    </p>
  </div>
</template>

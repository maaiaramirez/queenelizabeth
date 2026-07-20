<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import { traducirError } from '../services/auth'

const auth = useAuthStore()
const toast = useToastStore()
const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const errorMsg = ref('')
const loading = ref(false)

async function handleLogin() {
  errorMsg.value = ''
  if (!email.value || !password.value) {
    errorMsg.value = 'Completá email y contraseña.'
    return
  }
  loading.value = true
  try {
    await auth.login(email.value.trim(), password.value)
    toast.show('✓ Sesión iniciada · Bienvenido/a de vuelta')
    router.push(route.query.redirect || { name: 'dashboard' })
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
      <h2 style="font-family: var(--font-serif); color: var(--navy)">Ingresar</h2>
    </div>

    <form @submit.prevent="handleLogin">
      <div class="form-field">
        <label for="loginEmail">Email</label>
        <input id="loginEmail" v-model="email" type="email" autocomplete="email" />
      </div>
      <div class="form-field">
        <label for="loginPassword">Contraseña</label>
        <input id="loginPassword" v-model="password" type="password" autocomplete="current-password" />
      </div>
      <p class="form-error">{{ errorMsg }}</p>
      <button type="submit" class="btn btn--primary" style="width: 100%" :disabled="loading">
        {{ loading ? 'Ingresando…' : 'Ingresar' }}
      </button>
    </form>

    <p style="text-align: center; margin-top: 1.25rem; font-size: 0.85rem">
      ¿No tenés cuenta? <RouterLink to="/register">Creá una acá</RouterLink>
    </p>
  </div>
</template>

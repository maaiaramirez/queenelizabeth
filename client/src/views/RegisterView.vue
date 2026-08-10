<script setup>
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import { traducirError } from '../services/auth'
import { supabase } from '../lib/supabase'
import { registerPendingSale } from '../services/sales'

const route = useRoute()
const auth = useAuthStore()
const toast = useToastStore()

const name = ref('')
const email = ref('')
const password = ref('')
const role = ref('student')
const errorMsg = ref('')
const infoMsg = ref('')
const loading = ref(false)

const planSlug = ref(route.query.plan ? String(route.query.plan) : '')
const plan = ref(null)
const loadingPlan = ref(false)

onMounted(async () => {
  if (!planSlug.value) return
  loadingPlan.value = true
  try {
    const { data, error } = await supabase
      .from('plans')
      .select('*')
      .eq('slug', planSlug.value)
      .eq('is_active', true)
      .maybeSingle()
    if (error) throw error
    plan.value = data
  } catch (err) {
    console.error(err)
  } finally {
    loadingPlan.value = false
  }
})

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
    const finalRole = planSlug.value ? 'student' : role.value

    const signUpData = await auth.register(email.value.trim(), password.value, name.value.trim(), finalRole)

    const newUserId = signUpData?.user?.id
    if (planSlug.value && newUserId) {
      try {
        await registerPendingSale({
          planId: planSlug.value,
          planName: plan.value?.name || planSlug.value,
          amount: plan.value?.price ?? 0,
          studentName: name.value.trim(),
          studentEmail: email.value.trim(),
          studentUserId: newUserId,
        })
      } catch (saleErr) {
        console.error('No se pudo registrar la venta pendiente:', saleErr)
        toast.show('⚠ Cuenta creada, pero no se pudo registrar la venta pendiente. Avisale al admin.')
      }
    }

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

    <div
      v-if="planSlug"
      class="form-field"
      style="background: var(--ivory-dark); border-radius: 10px; padding: 0.9rem 1rem; margin-bottom: 1.25rem"
    >
      <p v-if="loadingPlan" style="opacity: 0.6; margin: 0">Cargando plan…</p>
      <template v-else-if="plan">
        <p style="margin: 0; font-size: 0.8rem; opacity: 0.7">Plan elegido</p>
        <p style="margin: 0.15rem 0 0; font-weight: 700; color: var(--navy)">{{ plan.name }} · ${{ plan.price }}/mes</p>
      </template>
      <template v-else>
        <p style="margin: 0; font-size: 0.85rem; opacity: 0.75">
          Plan seleccionado: <strong>{{ planSlug }}</strong>
        </p>
      </template>
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
      <div v-if="!planSlug" class="form-field">
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

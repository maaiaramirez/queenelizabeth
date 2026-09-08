<script setup>
import { onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { fetchAllProfiles, updateUserRole, deleteUserProfile, updatePaymentStatus } from '../services/profiles'

const toast = useToastStore()

const profiles = ref([])
const loading = ref(false)
const ROLES = ['student', 'teacher', 'admin']
const ROLE_LABELS = { student: 'Alumno', teacher: 'Docente', admin: 'Admin' }

function isActive(profile) {
  return profile.payment_status !== 'cancelado'
}

async function loadProfiles() {
  loading.value = true
  try {
    profiles.value = await fetchAllProfiles()
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo cargar la lista de usuarios.')
  } finally {
    loading.value = false
  }
}

async function handleRoleChange(profile, event) {
  const newRole = event.target.value
  const previous = profile.role
  try {
    await updateUserRole(profile.id, newRole)
    profile.role = newRole
    toast.show(`✓ Rol actualizado: ${profile.display_name} ahora es ${ROLE_LABELS[newRole]}`)
  } catch (err) {
    console.error(err)
    event.target.value = previous
    toast.show('⚠ No se pudo actualizar el rol.')
  }
}

async function handleDelete(profile) {
  if (!confirm(`¿Borrar la cuenta de ${profile.display_name} (${profile.email})? Esta acción no se puede deshacer.`)) return
  try {
    await deleteUserProfile(profile.id)
    toast.show(`✓ Cuenta de ${profile.display_name} eliminada.`)
    await loadProfiles()
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo borrar la cuenta.')
  }
}

async function handleToggleActive(profile) {
  const goingActive = !isActive(profile)
  const newStatus = goingActive ? 'pendiente' : 'cancelado'
  if (!goingActive && !confirm(`¿Desactivar la cuenta de ${profile.display_name}? Va a quedar suspendida.`)) return
  try {
    await updatePaymentStatus(profile.id, newStatus)
    profile.payment_status = newStatus
    toast.show(goingActive ? `✓ ${profile.display_name} reactivado` : `✓ ${profile.display_name} desactivado`)
  } catch (err) {
    console.error(err)
    toast.show('⚠ No se pudo cambiar el estado.')
  }
}

onMounted(loadProfiles)
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Usuarios</h1>
      <p class="dash__subtitle">Gestión de roles y cuentas.</p>
    </div>

    <div class="dash__panel" style="margin-top: 1.5rem">
      <p v-if="loading" style="opacity: 0.6">Cargando…</p>
      <table v-else style="width: 100%; border-collapse: collapse">
        <thead>
          <tr style="text-align: left; border-bottom: 1px solid rgba(0,0,0,.08)">
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Usuario
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Cambiar rol
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Rol actual
            </th>
            <th style="padding: 0.6rem 0; font-size: 0.75rem; letter-spacing: 0.04em; opacity: 0.6; text-transform: uppercase">
              Estado
            </th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in profiles" :key="p.id" style="border-bottom: 1px solid rgba(0,0,0,.05)">
            <td style="padding: 0.75rem 0">
              <strong style="display: block; color: var(--navy)">{{ p.display_name }}</strong>
              <span style="font-size: 0.85rem; opacity: 0.6">{{ p.email }}</span>
            </td>
            <td>
              <select :value="p.role" @change="handleRoleChange(p, $event)">
                <option v-for="r in ROLES" :key="r" :value="r">{{ ROLE_LABELS[r] }}</option>
              </select>
            </td>
            <td>
              <span
                style="
                  font-size: 0.75rem;
                  font-weight: 700;
                  letter-spacing: 0.03em;
                  padding: 0.25rem 0.6rem;
                  border-radius: 999px;
                  background: var(--ivory-dark);
                  color: var(--navy);
                  text-transform: uppercase;
                "
              >
                {{ ROLE_LABELS[p.role] || p.role }}
              </span>
            </td>
            <td>
              <span
                :style="{
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  letterSpacing: '0.03em',
                  padding: '0.25rem 0.6rem',
                  borderRadius: '999px',
                  textTransform: 'uppercase',
                  background: isActive(p) ? '#e3f5ea' : '#fbe4e4',
                  color: isActive(p) ? '#1e7e42' : '#c0392b',
                }"
              >
                {{ isActive(p) ? 'Activo' : 'Desactivado' }}
              </span>
            </td>
            <td style="text-align: right">
              <button
                class="btn btn--sm"
                style="margin-right: 0.4rem"
                @click="handleToggleActive(p)"
              >
                {{ isActive(p) ? '🚫 Desactivar' : '✓ Reactivar' }}
              </button>
              <button class="btn btn--sm" style="border-color: #c0392b; color: #c0392b" @click="handleDelete(p)">
                🗑 Borrar
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </DashboardLayout>
</template>

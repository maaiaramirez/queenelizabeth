<script setup>
import { onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { fetchAllProfiles, updateUserRole, deleteUserProfile } from '../services/profiles'
import { rolLabel } from '../services/auth'

const toast = useToastStore()
const profiles = ref([])
const loading = ref(true)
const errorMsg = ref('')

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    profiles.value = await fetchAllProfiles()
  } catch (err) {
    errorMsg.value = err.message
  } finally {
    loading.value = false
  }
}
onMounted(load)

async function handleRoleChange(userId, newRole) {
  try {
    await updateUserRole(userId, newRole)
    toast.show('✓ Rol actualizado a ' + rolLabel(newRole))
    await load()
  } catch (err) {
    toast.show('⚠ No se pudo cambiar el rol')
  }
}

async function handleDelete(userId, name) {
  if (!confirm(`¿Eliminar el perfil de ${name}? Esta acción no se puede deshacer.`)) return
  try {
    await deleteUserProfile(userId)
    toast.show('✓ Usuario eliminado')
    await load()
  } catch (err) {
    toast.show('⚠ No se pudo eliminar el usuario')
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Usuarios</h1>
      <p class="dash__subtitle">Gestión de roles y cuentas.</p>
    </div>

    <div class="dash__panel" style="margin-top: 1.25rem">
      <p v-if="loading" style="opacity: 0.6">Cargando…</p>
      <p v-else-if="errorMsg" style="color: var(--red)">⚠ {{ errorMsg }}</p>
      <p v-else-if="!profiles.length">No hay usuarios todavía.</p>
      <table v-else class="users__table">
        <thead>
          <tr>
            <th>Usuario</th>
            <th>Cambiar rol</th>
            <th>Rol actual</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in profiles" :key="p.id">
            <td>
              <strong>{{ p.display_name || '—' }}</strong
              ><br />
              <span style="font-size: 0.75rem; color: var(--text-muted)">{{ p.email }}</span>
            </td>
            <td>
              <select class="role-select" :value="p.role" @change="handleRoleChange(p.id, $event.target.value)">
                <option value="student">Alumno</option>
                <option value="teacher">Docente</option>
                <option value="admin">Admin</option>
              </select>
            </td>
            <td>
              <span class="role-tag" :class="`role-tag--${p.role}`">{{ rolLabel(p.role) }}</span>
            </td>
            <td>
              <button class="btn--danger" @click="handleDelete(p.id, p.display_name || p.email)">🗑</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </DashboardLayout>
</template>

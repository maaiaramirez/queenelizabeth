<script setup>
import { onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'

const profiles = ref([])
const loading = ref(false)
const ROLES = ['student', 'teacher', 'admin']

async function loadProfiles() {
  loading.value = true
  const { data, error } = await supabase.from('profiles').select('id, email, display_name, role')
  if (!error) profiles.value = data
  loading.value = false
}

async function updateRole(userId, newRole) {
  const { error } = await supabase.from('profiles').update({ role: newRole }).eq('id', userId)
  if (!error) await loadProfiles()
}

onMounted(loadProfiles)
</script>

<template>
  <div class="auth-page" style="max-width: 700px">
    <h2 style="font-family: var(--font-serif); color: var(--navy)">Usuarios</h2>
    <p v-if="loading" style="opacity: 0.6">Cargando…</p>
    <table v-else style="width: 100%; border-collapse: collapse">
      <tr v-for="p in profiles" :key="p.id">
        <td style="padding: 0.5rem 0">{{ p.display_name }} ({{ p.email }})</td>
        <td>
          <select :value="p.role" @change="updateRole(p.id, $event.target.value)">
            <option v-for="r in ROLES" :key="r" :value="r">{{ r }}</option>
          </select>
        </td>
      </tr>
    </table>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { fetchAllLevelTestResults } from '../../services/levelTest'
import { fetchAllStudents } from '../../services/profiles'

const results = ref([])
const students = ref([])
const loading = ref(true)
const errorMsg = ref('')
const search = ref('')

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [resultsData, studentsData] = await Promise.all([fetchAllLevelTestResults(), fetchAllStudents()])
    results.value = resultsData
    students.value = studentsData
  } catch (err) {
    console.error(err)
    errorMsg.value = err.message
  } finally {
    loading.value = false
  }
}
onMounted(load)

const studentById = computed(() => Object.fromEntries(students.value.map((s) => [s.id, s])))

const rows = computed(() =>
  results.value.map((r) => ({
    ...r,
    student: studentById.value[r.student_id] || null,
  })),
)

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return rows.value
  return rows.value.filter(
    (r) =>
      (r.student?.display_name || '').toLowerCase().includes(q) ||
      (r.student?.email || '').toLowerCase().includes(q),
  )
})
</script>

<template>
  <div class="dash__panel">
    <h3>Resultados del Test de Nivel</h3>
    <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0.25rem 0 1rem">
      Un resultado por alumno (el test es de una sola vez).
    </p>
    <input
      v-model="search"
      type="text"
      placeholder="Buscar alumno por nombre o email…"
      style="margin-bottom: 1rem"
    />
    <p v-if="loading" style="opacity: 0.6">Cargando resultados…</p>
    <p v-else-if="errorMsg" style="color: var(--red)">⚠ {{ errorMsg }}</p>
    <p v-else-if="!filteredRows.length">Todavía no hay resultados del test de nivel.</p>
    <table v-else class="users__table">
      <thead>
        <tr>
          <th>Alumno</th>
          <th>Nivel asignado</th>
          <th>Puntaje</th>
          <th>Fecha</th>
          <th>Anti-cheat</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in filteredRows" :key="r.id">
          <td>
            <strong>{{ r.student?.display_name || '—' }}</strong
            ><br />
            <span style="font-size: 0.75rem; opacity: 0.6">{{ r.student?.email || '' }}</span>
          </td>
          <td>
            <span class="role-tag role-tag--student" style="font-weight: 700">{{ r.level_assigned || '—' }}</span>
          </td>
          <td>{{ r.score }} / {{ r.total_questions }}</td>
          <td>{{ new Date(r.completed_at || r.created_at).toLocaleDateString('es-AR') }}</td>
          <td>
            <span v-if="r.flagged_cheat" class="sale-status sale-status--deuda" title="Se detectaron eventos sospechosos durante el test">
              ⚠ {{ r.cheat_events?.length || 0 }} evento{{ r.cheat_events?.length === 1 ? '' : 's' }}
            </span>
            <span v-else class="sale-status sale-status--pagado">Limpio</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

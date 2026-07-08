<script setup>
// TeacherDashboard.vue
// Punto 3: mapeo/asignación de alumnos + fix de numeración + gráfico Chart.js

import { ref, onMounted, onBeforeUnmount } from 'vue'
import Chart from 'chart.js/auto'
import { fetchAssignedStudents, fetchAttendanceStats } from '@/services/api'

const assignedStudents = ref([]) // [{ id, name, courseName, ... }]
const chartCanvas = ref(null)
let chartInstance = null

onMounted(async () => {
  assignedStudents.value = await fetchAssignedStudents()
  const stats = await fetchAttendanceStats()
  renderPerformanceChart(stats)
})

onBeforeUnmount(() => {
  chartInstance?.destroy()
})

function renderPerformanceChart(stats) {
  // stats: [{ label: 'Semana 1', value: 82 }, { label: 'Semana 2', value: 75 }, ...]
  chartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: stats.map((s) => s.label),
      datasets: [
        {
          label: 'Asistencia / Progreso (%)',
          data: stats.map((s) => s.value),
        },
      ],
    },
    options: {
      responsive: true,
      indexAxis: 'x', // barras verticales
      scales: { y: { beginAtZero: true, max: 100 } },
    },
  })
}
</script>

<template>
  <section>
    <h2>Alumnos asignados</h2>

    <!--
      BUG ORIGINAL: usar el índice del v-for como :key y como número mostrado
      ("Curso #{{ index + 1 }}") provoca desfases apenas se filtra, ordena o
      borra un elemento: Vue reutiliza los nodos por posición, no por
      identidad, y el número mostrado deja de corresponder al alumno real.

      FIX: la :key va con el ID único del dato (student.id), que es estable
      sin importar el orden. El número visible se calcula aparte, a partir
      de una posición real dentro del array ya renderizado, no del índice
      interno de reconciliación de Vue.
    -->
    <ol>
      <li v-for="(student, index) in assignedStudents" :key="student.id">
        <span class="course-number">Curso #{{ index + 1 }}</span>
        <strong>{{ student.name }}</strong> — {{ student.courseName }}
      </li>
    </ol>

    <h2>Rendimiento del grupo</h2>
    <canvas ref="chartCanvas"></canvas>
  </section>
</template>

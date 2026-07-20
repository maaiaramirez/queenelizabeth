<script setup>
import { ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import PanelCreateCourse from '../components/panel/PanelCreateCourse.vue'
import PanelCreateLesson from '../components/panel/PanelCreateLesson.vue'
import PanelMaterials from '../components/panel/PanelMaterials.vue'
import PanelSales from '../components/panel/PanelSales.vue'
import PanelEnroll from '../components/panel/PanelEnroll.vue'

const lessonPanel = ref(null)

// Cuando se crea un curso, refrescamos las opciones del selector de lecciones
function onCourseCreated() {
  lessonPanel.value?.loadCourses()
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Panel Docente</h1>
      <p class="dash__subtitle">Cursos, lecciones, materiales, pagos e inscripciones.</p>
    </div>

    <div class="dash__row" style="margin-top: 1.25rem; display: flex; gap: 1.5rem; flex-wrap: wrap">
      <div class="dash__col" style="flex: 1; min-width: 320px">
        <PanelCreateCourse @created="onCourseCreated" />
      </div>
      <div class="dash__col" style="flex: 1; min-width: 320px">
        <PanelCreateLesson ref="lessonPanel" />
      </div>
    </div>

    <div style="margin-top: 1.5rem">
      <PanelMaterials />
    </div>

    <div style="margin-top: 1.5rem">
      <PanelEnroll />
    </div>

    <div style="margin-top: 1.5rem">
      <PanelSales />
    </div>
  </DashboardLayout>
</template>

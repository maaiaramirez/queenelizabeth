<script setup>
import { onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useToastStore } from '../stores/toast'
import { fetchAllMaterials, getMaterialPublicUrl, logMaterialEvent, TYPE_ICONS } from '../services/materials'

const toast = useToastStore()
const materials = ref([])
const loading = ref(true)
const errorMsg = ref('')

onMounted(async () => {
  try {
    materials.value = await fetchAllMaterials()
  } catch (err) {
    console.error(err)
    errorMsg.value = '⚠ No se pudo conectar con Supabase.'
  } finally {
    loading.value = false
  }
})

function urlFor(m) {
  return m.type === 'link' ? m.external_url : getMaterialPublicUrl(m.file_path)
}

async function open(m, action) {
  const url = urlFor(m)
  if (!url) {
    toast.show('⚠ Este material no tiene archivo o enlace válido')
    return
  }
  await logMaterialEvent(m.id, action)
  window.open(url, '_blank')
  toast.show(action === 'download' ? '⬇ Descarga registrada' : '👁 Vista registrada')
}
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Materiales</h1>
      <p class="dash__subtitle">Recursos subidos por tus docentes.</p>
    </div>

    <div class="dash__panel" style="margin-top: 1.25rem">
      <p v-if="loading">Cargando materiales…</p>
      <p v-else-if="errorMsg" style="color: var(--red)">{{ errorMsg }}</p>
      <p v-else-if="!materials.length">
        Todavía no hay materiales subidos. El docente puede subir desde el Panel Docente.
      </p>
      <div v-else>
        <div v-for="m in materials" :key="m.id" class="lesson__item" style="cursor: default">
          <div class="lesson__thumb">{{ TYPE_ICONS[m.type] || '📁' }}</div>
          <div class="lesson__info" style="flex: 1">
            <strong>{{ m.title }}</strong>
            <span>
              {{ m.lessons?.courses?.title || 'Sin curso' }} · {{ m.lessons?.title || 'General' }}
              <template v-if="m.description"> · {{ m.description }}</template>
            </span>
          </div>
          <button class="btn btn--ghost btn--sm" @click="open(m, 'view')">👁 Ver</button>
          <button class="btn btn--primary btn--sm" @click="open(m, 'download')">⬇ Descargar</button>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useToastStore } from '../../stores/toast'
import { fetchCourses, fetchLessons } from '../../services/courses'
import { fetchAllMaterials, uploadMaterial, deleteMaterial, TYPE_ICONS } from '../../services/materials'

const toast = useToastStore()

const lessonOptions = ref([]) // { id, label }
const lessonId = ref('')
const title = ref('')
const type = ref('pdf')
const file = ref(null)
const externalUrl = ref('')
const description = ref('')
const status = ref('')

const materials = ref([])
const materialsLoading = ref(true)
const materialsError = ref('')

async function loadLessonOptions() {
  try {
    const courses = await fetchCourses()
    const opts = []
    for (const course of courses) {
      const lessons = await fetchLessons(course.id)
      lessons.forEach((l) => opts.push({ id: l.id, label: `${course.title} → ${l.title}` }))
    }
    lessonOptions.value = opts
    if (opts.length) lessonId.value = opts[0].id
  } catch (err) {
    console.error(err)
  }
}

async function loadMaterials() {
  materialsLoading.value = true
  materialsError.value = ''
  try {
    materials.value = await fetchAllMaterials()
  } catch (err) {
    console.error(err)
    materialsError.value = '⚠ Error cargando materiales.'
  } finally {
    materialsLoading.value = false
  }
}

function onFileChange(e) {
  file.value = e.target.files[0] || null
}

async function handleUpload() {
  if (!title.value.trim()) {
    toast.show('⚠ Falta el título')
    return
  }
  if (type.value !== 'link' && !file.value) {
    toast.show('⚠ Selecciona un archivo o cambia el tipo a "Enlace externo"')
    return
  }
  if (type.value === 'link' && !externalUrl.value.trim()) {
    toast.show('⚠ Falta la URL externa')
    return
  }
  status.value = 'Subiendo…'
  try {
    await uploadMaterial({
      file: file.value,
      lessonId: lessonId.value || null,
      title: title.value.trim(),
      type: type.value,
      description: description.value.trim(),
      externalUrl: externalUrl.value.trim(),
    })
    status.value = '✓ Subido correctamente'
    toast.show('✓ Material subido a Supabase')
    title.value = ''
    description.value = ''
    externalUrl.value = ''
    file.value = null
    await loadMaterials()
  } catch (err) {
    console.error(err)
    status.value = '⚠ Error al subir'
    toast.show('⚠ No se pudo subir. Revisá la configuración de Supabase.')
  }
}

async function handleDelete(m) {
  if (!confirm('¿Borrar este material? Esta acción es real y no se puede deshacer.')) return
  try {
    await deleteMaterial(m.id, m.file_path || null)
    toast.show('✓ Material eliminado')
    await loadMaterials()
  } catch (err) {
    toast.show('⚠ Error al eliminar')
  }
}

defineExpose({ loadLessonOptions })
onMounted(() => {
  loadLessonOptions()
  loadMaterials()
})
</script>

<template>
  <div class="dash__panel">
    <h3>Subir material</h3>
    <form @submit.prevent="handleUpload" style="margin-top: 1rem">
      <div class="form-field">
        <label>Lección (opcional)</label>
        <select v-model="lessonId">
          <option value="">Sin lecciones — crea una arriba primero</option>
          <option v-for="opt in lessonOptions" :key="opt.id" :value="opt.id">{{ opt.label }}</option>
        </select>
      </div>
      <div class="form-field">
        <label>Título</label>
        <input v-model="title" type="text" />
      </div>
      <div class="form-field">
        <label>Tipo</label>
        <select v-model="type">
          <option value="pdf">PDF</option>
          <option value="video">Video</option>
          <option value="audio">Audio</option>
          <option value="doc">Word/PowerPoint</option>
          <option value="link">Enlace externo</option>
        </select>
      </div>
      <div v-if="type !== 'link'" class="form-field">
        <label>Archivo</label>
        <input type="file" @change="onFileChange" />
      </div>
      <div v-else class="form-field">
        <label>URL externa</label>
        <input v-model="externalUrl" type="text" placeholder="https://..." />
      </div>
      <div class="form-field">
        <label>Descripción (opcional)</label>
        <input v-model="description" type="text" />
      </div>
      <button type="submit" class="btn btn--primary btn--sm">Subir</button>
      <span style="margin-left: 0.75rem; font-size: 0.85rem; opacity: 0.7">{{ status }}</span>
    </form>
  </div>

  <div class="dash__panel" style="margin-top: 1.25rem">
    <h3>Materiales subidos</h3>
    <p v-if="materialsLoading" class="lib-loading">Cargando…</p>
    <p v-else-if="materialsError" class="lib-error">{{ materialsError }}</p>
    <div v-else-if="!materials.length" class="lib-empty">
      <div class="lib-empty__icon">📭</div>Todavía no subiste ningún material.
    </div>
    <div v-else class="lib-grid">
      <div v-for="m in materials" :key="m.id" class="lib-card">
        <div class="lib-card__top">
          <div class="lib-card__icon">{{ TYPE_ICONS[m.type] || '📁' }}</div>
          <div>
            <div class="lib-card__name">{{ m.title }}</div>
            <div class="lib-card__meta">
              {{ m.lessons?.courses?.title || 'Sin curso' }} · {{ m.lessons?.title || 'General' }}
            </div>
            <div class="lib-card__meta">{{ new Date(m.created_at).toLocaleDateString('es-AR') }}</div>
          </div>
        </div>
        <div class="lib-card__actions">
          <button class="danger" @click="handleDelete(m)">🗑 Borrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

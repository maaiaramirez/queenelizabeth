<script setup>
import { computed, onMounted, ref } from 'vue'
import DashboardLayout from '../components/DashboardLayout.vue'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import {
  getFolders,
  getItems,
  createFolder,
  renameFolder,
  deleteFolder,
  uploadFileItem,
  createLinkItem,
  deleteItem,
  openItem,
  ICONS,
} from '../services/library'

const auth = useAuthStore()
const toast = useToastStore()
const canEdit = computed(() => auth.role === 'admin')

const currentFolderId = ref(null)
const breadcrumb = ref([]) // [{id, name}]
const folders = ref([])
const items = ref([])
const loading = ref(false)
const errorMsg = ref('')

// dialogs
const showNewFolder = ref(false)
const showUpload = ref(false)
const showLink = ref(false)

const newFolderName = ref('')
const uploadType = ref('pdf')
const uploadFile = ref(null)
const uploadLessonId = ref('')
const uploadBusy = ref(false)

const linkType = ref('video')
const linkName = ref('')
const linkUrl = ref('')
const linkLessonId = ref('')

async function render() {
  loading.value = true
  errorMsg.value = ''
  try {
    ;[folders.value, items.value] = await Promise.all([
      getFolders(currentFolderId.value),
      getItems({ folderId: currentFolderId.value }),
    ])
  } catch (e) {
    errorMsg.value = e.message
  } finally {
    loading.value = false
  }
}

function enterFolder(id, name) {
  breadcrumb.value.push({ id, name })
  currentFolderId.value = id
  render()
}

function goToBreadcrumb(idx) {
  if (idx === -1) {
    breadcrumb.value = []
    currentFolderId.value = null
  } else {
    breadcrumb.value = breadcrumb.value.slice(0, idx + 1)
    currentFolderId.value = breadcrumb.value[idx].id
  }
  render()
}

async function handleCreateFolder() {
  if (!newFolderName.value.trim()) return
  try {
    await createFolder(newFolderName.value.trim(), currentFolderId.value)
    newFolderName.value = ''
    showNewFolder.value = false
    render()
  } catch (e) {
    toast.show('Error creando carpeta: ' + e.message)
  }
}

async function handleRenameFolder(f) {
  const newName = prompt('Nuevo nombre:', f.name)
  if (!newName) return
  try {
    await renameFolder(f.id, newName.trim())
    render()
  } catch (e) {
    toast.show('Error al renombrar: ' + e.message)
  }
}

async function handleDeleteFolder(f) {
  if (!confirm('¿Borrar esta carpeta? Las subcarpetas también se borran.')) return
  try {
    await deleteFolder(f.id)
    render()
  } catch (e) {
    toast.show('Error al borrar: ' + e.message)
  }
}

function onUploadFileChange(e) {
  uploadFile.value = e.target.files[0] || null
}

async function handleUploadFile() {
  if (!uploadFile.value) {
    toast.show('Elegí un archivo')
    return
  }
  uploadBusy.value = true
  try {
    await uploadFileItem({
      file: uploadFile.value,
      type: uploadType.value,
      folderId: currentFolderId.value,
      lessonId: uploadLessonId.value.trim() || null,
    })
    uploadFile.value = null
    uploadLessonId.value = ''
    showUpload.value = false
    render()
  } catch (e) {
    toast.show('Error subiendo archivo: ' + e.message)
  } finally {
    uploadBusy.value = false
  }
}

async function handleAddLink() {
  if (!linkName.value.trim() || !linkUrl.value.trim()) {
    toast.show('Completá nombre y URL')
    return
  }
  try {
    await createLinkItem({
      name: linkName.value.trim(),
      type: linkType.value,
      url: linkUrl.value.trim(),
      folderId: currentFolderId.value,
      lessonId: linkLessonId.value.trim() || null,
    })
    linkName.value = ''
    linkUrl.value = ''
    linkLessonId.value = ''
    showLink.value = false
    render()
  } catch (e) {
    toast.show('Error agregando link: ' + e.message)
  }
}

async function handleOpen(item) {
  try {
    await openItem(item)
  } catch (e) {
    toast.show('Error al abrir el archivo: ' + e.message)
  }
}

async function handleDeleteItem(item) {
  if (!confirm(`¿Borrar "${item.name}"?`)) return
  try {
    await deleteItem(item)
    render()
  } catch (e) {
    toast.show('Error al eliminar: ' + e.message)
  }
}

onMounted(render)
</script>

<template>
  <DashboardLayout>
    <div class="dash__header">
      <h1 class="dash__title">Biblioteca de materiales</h1>
      <p class="dash__subtitle">{{ canEdit ? 'Administración' : 'Solo lectura' }}</p>
    </div>

    <div class="lib-breadcrumb" style="margin-top: 1rem">
      <span @click="goToBreadcrumb(-1)" style="cursor: pointer">🏠 Raíz</span>
      <template v-for="(b, idx) in breadcrumb" :key="b.id">
        <span class="lib-breadcrumb__sep">/</span>
        <span @click="goToBreadcrumb(idx)" style="cursor: pointer">{{ b.name }}</span>
      </template>
    </div>

    <div v-if="canEdit" class="lib-toolbar" style="margin: 1rem 0">
      <button class="btn btn--gold btn--sm" @click="showNewFolder = true">📁 Nueva carpeta</button>
      <button class="btn btn--primary btn--sm" @click="showUpload = true">⬆ Subir archivo</button>
      <button class="btn btn--outline-navy btn--sm" @click="showLink = true">🔗 Agregar video/link</button>
    </div>

    <p v-if="loading" class="lib-loading">Cargando…</p>
    <p v-else-if="errorMsg" class="lib-error">⚠ {{ errorMsg }}</p>

    <template v-else>
      <div v-if="folders.length">
        <p class="lib-section-label">Carpetas</p>
        <div class="lib-grid">
          <div v-for="f in folders" :key="f.id" class="lib-card lib-card--folder" @click="enterFolder(f.id, f.name)">
            <div class="lib-card__top">
              <div class="lib-card__icon">📁</div>
              <div class="lib-card__name">{{ f.name }}</div>
            </div>
            <div v-if="canEdit" class="lib-card__actions" @click.stop>
              <button @click="handleRenameFolder(f)">✏️ Renombrar</button>
              <button class="danger" @click="handleDeleteFolder(f)">🗑 Borrar</button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="items.length" style="margin-top: 1.25rem">
        <p class="lib-section-label">Materiales</p>
        <div class="lib-grid">
          <div v-for="i in items" :key="i.id" class="lib-card">
            <div class="lib-card__top">
              <div class="lib-card__icon">{{ ICONS[i.type] || '📦' }}</div>
              <div>
                <div class="lib-card__name">{{ i.name }}</div>
                <div v-if="i.lesson_id" class="lib-card__meta">Lección: {{ i.lesson_id }}</div>
              </div>
            </div>
            <div class="lib-card__actions">
              <button @click="handleOpen(i)">{{ canEdit ? '👁 Abrir' : '⬇ Abrir / Descargar' }}</button>
              <button v-if="canEdit" class="danger" @click="handleDeleteItem(i)">🗑 Borrar</button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!folders.length && !items.length" class="lib-empty">
        <div class="lib-empty__icon">📭</div>
        Esta carpeta está vacía.
      </div>
    </template>

    <!-- Dialog: nueva carpeta -->
    <dialog v-if="showNewFolder" open>
      <h3>Nueva carpeta</h3>
      <label
        >Nombre
        <input v-model="newFolderName" type="text" placeholder="Ej: Nivel B1" />
      </label>
      <div class="lib-toolbar">
        <button class="btn btn--outline-navy btn--sm" @click="showNewFolder = false">Cancelar</button>
        <button class="btn btn--primary btn--sm" @click="handleCreateFolder">Crear</button>
      </div>
    </dialog>

    <!-- Dialog: subir archivo -->
    <dialog v-if="showUpload" open>
      <h3>Subir archivo</h3>
      <label
        >Tipo
        <select v-model="uploadType">
          <option value="pdf">PDF</option>
          <option value="image">Imagen</option>
          <option value="audio">Audio</option>
          <option value="document">Word/PowerPoint</option>
        </select>
      </label>
      <label
        >Archivo
        <input type="file" @change="onUploadFileChange" />
      </label>
      <label
        >Asociar a lección (opcional, ID)
        <input v-model="uploadLessonId" type="text" placeholder="lesson id (opcional)" />
      </label>
      <div class="lib-toolbar">
        <button class="btn btn--outline-navy btn--sm" @click="showUpload = false">Cancelar</button>
        <button class="btn btn--primary btn--sm" :disabled="uploadBusy" @click="handleUploadFile">
          {{ uploadBusy ? 'Subiendo…' : 'Subir' }}
        </button>
      </div>
    </dialog>

    <!-- Dialog: agregar link/video -->
    <dialog v-if="showLink" open>
      <h3>Agregar video o link externo</h3>
      <label
        >Tipo
        <select v-model="linkType">
          <option value="video">Video (YouTube/Vimeo)</option>
          <option value="link">Link externo</option>
        </select>
      </label>
      <label
        >Nombre
        <input v-model="linkName" type="text" />
      </label>
      <label
        >URL
        <input v-model="linkUrl" type="text" placeholder="https://..." />
      </label>
      <label
        >Asociar a lección (opcional, ID)
        <input v-model="linkLessonId" type="text" placeholder="lesson id (opcional)" />
      </label>
      <div class="lib-toolbar">
        <button class="btn btn--outline-navy btn--sm" @click="showLink = false">Cancelar</button>
        <button class="btn btn--primary btn--sm" @click="handleAddLink">Agregar</button>
      </div>
    </dialog>
  </DashboardLayout>
</template>

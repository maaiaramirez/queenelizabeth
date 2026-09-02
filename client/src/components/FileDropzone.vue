<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
  modelValue: { type: [File, null], default: null },
  accept: { type: String, default: '' },
  hint: { type: String, default: 'Hacé clic o arrastrá el archivo acá' },
})
const emit = defineEmits(['update:modelValue'])

const dragging = ref(false)
const inputRef = ref(null)

const ICONS = {
  pdf: '📄',
  image: '🖼️',
  video: '🎬',
  audio: '🎧',
  doc: '📝',
  default: '📁',
}

function iconFor(file) {
  if (!file) return ICONS.default
  const t = file.type || ''
  if (t.includes('pdf')) return ICONS.pdf
  if (t.startsWith('image/')) return ICONS.image
  if (t.startsWith('video/')) return ICONS.video
  if (t.startsWith('audio/')) return ICONS.audio
  if (t.includes('word') || t.includes('presentation') || t.includes('sheet')) return ICONS.doc
  return ICONS.default
}

const icon = computed(() => (props.modelValue ? iconFor(props.modelValue) : '⬆️'))

function fmtSize(bytes) {
  if (!bytes) return ''
  const kb = bytes / 1024
  if (kb < 1024) return `${kb.toFixed(0)} KB`
  return `${(kb / 1024).toFixed(1)} MB`
}

function openPicker() {
  inputRef.value?.click()
}

function onInputChange(e) {
  const f = e.target.files[0] || null
  emit('update:modelValue', f)
}

function onDrop(e) {
  dragging.value = false
  const f = e.dataTransfer.files[0] || null
  if (f) emit('update:modelValue', f)
}

function clearFile(e) {
  e.stopPropagation()
  emit('update:modelValue', null)
  if (inputRef.value) inputRef.value.value = ''
}
</script>

<template>
  <div
    class="dropzone"
    :class="{ 'dropzone--dragging': dragging, 'dropzone--filled': modelValue }"
    role="button"
    tabindex="0"
    @click="openPicker"
    @keydown.enter="openPicker"
    @dragover.prevent="dragging = true"
    @dragleave.prevent="dragging = false"
    @drop.prevent="onDrop"
  >
    <div class="dropzone__icon">{{ icon }}</div>
    <div class="dropzone__body">
      <template v-if="modelValue">
        <div class="dropzone__title">Archivo listo</div>
        <div class="dropzone__filename">{{ modelValue.name }} · {{ fmtSize(modelValue.size) }}</div>
      </template>
      <template v-else>
        <div class="dropzone__title">{{ hint }}</div>
        <div class="dropzone__hint">PDF, Word, imágenes, audio o video</div>
      </template>
    </div>
    <button v-if="modelValue" type="button" class="dropzone__clear" title="Quitar archivo" @click="clearFile">✕</button>
    <input ref="inputRef" class="dropzone__input" type="file" :accept="accept" @change="onInputChange" @click.stop />
  </div>
</template>

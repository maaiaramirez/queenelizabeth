<script setup>
import { useToastStore } from '../stores/toast'
const toastStore = useToastStore()
</script>

<template>
  <div class="toast-host">
    <div v-for="t in toastStore.toasts" :key="t.id" class="toast visible">
      {{ t.message }}
    </div>
  </div>
</template>

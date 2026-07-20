<script setup>
import { onMounted } from 'vue'
import NavBar from './components/NavBar.vue'
import ToastHost from './components/ToastHost.vue'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()
onMounted(() => auth.init())
</script>

<template>
  <div class="app-shell">
    <NavBar />
    <RouterView />
    <ToastHost />
  </div>
</template>

<script setup>
import { RouterLink } from 'vue-router'
</script>

<template>
  <div style="min-height: 100vh; background: var(--navy-deep); display: flex; align-items: center; justify-content: center; text-align: center; padding: 2rem">
    <div>
      <div style="font-size: 3rem; color: var(--gold); margin-bottom: 1rem">♛</div>
      <h1 style="font-family: var(--font-serif); font-size: 2.5rem; color: var(--white); margin-bottom: 0.75rem">404</h1>
      <p style="color: rgba(255,255,255,.6); margin-bottom: 2rem">Esta página no existe.</p>
      <RouterLink to="/" class="btn btn--primary">Volver al inicio</RouterLink>
    </div>
  </div>
</template>

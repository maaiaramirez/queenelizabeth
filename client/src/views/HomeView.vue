<script setup>
import { useAuthStore } from '../stores/auth'
const auth = useAuthStore()
</script>

<template>
  <section style="max-width: 720px; margin: 4rem auto; text-align: center; padding: 0 1.5rem">
    <h1 style="font-family: var(--font-serif); color: var(--navy); font-size: 2.2rem; margin-bottom: 1rem">
      👑 Queen Elizabeth Academy
    </h1>
    <p style="opacity: 0.75; margin-bottom: 2rem">
      Plataforma de gestión de cursos, materiales y alumnos.
    </p>
    <div style="display: flex; gap: 0.75rem; justify-content: center">
      <RouterLink v-if="!auth.isLoggedIn" to="/login" class="btn btn--primary">Ingresar</RouterLink>
      <RouterLink v-if="!auth.isLoggedIn" to="/register" class="btn btn--outline-navy">Crear cuenta</RouterLink>
      <RouterLink v-else to="/dashboard" class="btn btn--primary">Ir a mi Dashboard →</RouterLink>
    </div>
    <p style="opacity: 0.5; font-size: 0.8rem; margin-top: 2.5rem">
      Nota: la landing de marketing original (planes, testimonios, demo de lección interactiva) no forma
      parte de esta migración incremental — sigue viva en el sitio clásico hasta que se decida portarla.
    </p>
  </section>
</template>

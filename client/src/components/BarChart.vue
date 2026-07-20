<script setup>
const props = defineProps({
  rows: { type: Array, required: true }, // [{ label, value, formatted }]
  emptyMessage: { type: String, default: 'No hay datos.' },
})
const max = () => Math.max(...props.rows.map((r) => r.value), 1)
</script>

<template>
  <p v-if="!rows.length" class="barchart__empty">{{ emptyMessage }}</p>
  <div v-else>
    <div v-for="r in rows" :key="r.label" class="barchart__row">
      <span class="barchart__label">{{ r.label }}</span>
      <div class="barchart__track">
        <div class="barchart__fill" :style="{ width: (r.value / max()) * 100 + '%' }"></div>
      </div>
      <span class="barchart__value">{{ r.formatted }}</span>
    </div>
  </div>
</template>

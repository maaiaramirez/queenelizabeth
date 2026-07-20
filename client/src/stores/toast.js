import { defineStore } from 'pinia'

let nextId = 1

export const useToastStore = defineStore('toast', {
  state: () => ({
    toasts: [], // { id, message }
  }),
  actions: {
    show(message, duration = 3500) {
      const id = nextId++
      this.toasts.push({ id, message })
      setTimeout(() => {
        this.toasts = this.toasts.filter((t) => t.id !== id)
      }, duration)
    },
  },
})

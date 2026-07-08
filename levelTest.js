// stores/levelTest.js
import { defineStore } from 'pinia'
import { fetchLevelTestQuestions } from '@/services/api'

export const useLevelTestStore = defineStore('levelTest', {
  state: () => ({
    result: null, // { level, answers, autoSubmitted, completedAt }
    assignment: null, // { courseId, tutorId, schedule, zoomUrl, ... }
    error: null,
  }),

  getters: {
    isCompleted: (state) => state.result !== null,
  },

  actions: {
    async fetchQuestions() {
      this.error = null
      try {
        return await fetchLevelTestQuestions()
      } catch (err) {
        this.error = err.message
        return []
      }
    },

    setResult(result) {
      this.result = result
    },

    setAssignment(assignment) {
      this.assignment = assignment
    },

    setError(message) {
      this.error = message
    },
  },
})

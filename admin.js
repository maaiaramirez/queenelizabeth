// stores/admin.js
import { defineStore } from 'pinia'
import { createCourse } from '@/services/api'

export const useAdminStore = defineStore('admin', {
  state: () => ({
    courses: [],
    isCreatingCourse: false,
    createCourseError: null,
  }),

  actions: {
    async createCourse(payload) {
      this.isCreatingCourse = true
      this.createCourseError = null
      try {
        const newCourse = await createCourse(payload)
        this.courses.push(newCourse)
        return newCourse
      } catch (err) {
        this.createCourseError = err.message
        throw err
      } finally {
        this.isCreatingCourse = false
      }
    },
  },
})

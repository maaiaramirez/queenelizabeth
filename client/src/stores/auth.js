import { defineStore } from 'pinia'
import {
  getCurrentUser,
  getCurrentProfile,
  onAuthStateChange,
  signInUser,
  signUpUser,
  signOutUser,
} from '../services/auth'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    profile: null, // reemplaza CurrentProfile
    initialized: false,
    loading: false,
  }),
  getters: {
    isLoggedIn: (state) => !!state.profile,
    role: (state) => state.profile?.role || null,
    isAdmin: (state) => state.profile?.role === 'admin',
    isTeacher: (state) => state.profile?.role === 'teacher',
    isTeacherOrAdmin: (state) => state.profile?.role === 'teacher' || state.profile?.role === 'admin',
    firstName: (state) => {
      const base = state.profile?.display_name || state.profile?.email?.split('@')[0] || ''
      return base.split(' ')[0]
    },
    initials: (state) => {
      const base = state.profile?.display_name || state.profile?.email || ''
      return base
        .split(' ')
        .map((w) => w[0])
        .slice(0, 2)
        .join('')
        .toUpperCase()
    },
  },
  actions: {
    async init() {
      if (this.initialized) return
      this.initialized = true

      onAuthStateChange(async (_event, session) => {
        if (session?.user) {
          await this.refreshProfile()
        } else {
          this.profile = null
        }
      })

      const user = await getCurrentUser()
      if (user) await this.refreshProfile()
    },
    async refreshProfile() {
      this.profile = await getCurrentProfile()
      return this.profile
    },
    async login(email, password) {
      this.loading = true
      try {
        await signInUser(email, password)
        await this.refreshProfile()
      } finally {
        this.loading = false
      }
    },
    async register(email, password, displayName, role = 'student') {
      this.loading = true
      try {
        await signUpUser(email, password, displayName, role)
      } finally {
        this.loading = false
      }
    },
    async logout() {
      await signOutUser()
      this.profile = null
    },
  },
})

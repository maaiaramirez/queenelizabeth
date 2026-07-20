<script setup>
import { useAuthStore } from '../stores/auth'
import DashboardLayout from '../components/DashboardLayout.vue'
import StudentDashboard from '../components/dashboard/StudentDashboard.vue'
import TeacherDashboard from '../components/dashboard/TeacherDashboard.vue'
import AdminDashboard from '../components/dashboard/AdminDashboard.vue'

const auth = useAuthStore()
</script>

<template>
  <DashboardLayout>
    <StudentDashboard v-if="auth.role === 'student'" />
    <TeacherDashboard v-else-if="auth.role === 'teacher'" />
    <AdminDashboard v-else-if="auth.role === 'admin'" />
  </DashboardLayout>
</template>

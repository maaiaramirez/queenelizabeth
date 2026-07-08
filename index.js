// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/',
    redirect: '/login',
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { public: true },
  },

  // ── Onboarding: test nivelador (accesible apenas se paga, antes de tener rol asignado a un curso) ──
  {
    path: '/onboarding/nivelacion',
    name: 'level-test',
    component: () => import('@/views/onboarding/LevelTestView.vue'),
    meta: { roles: ['student'], requiresPaidAccount: true },
  },

  // ── Alumno ──
  {
    path: '/alumno',
    component: () => import('@/layouts/StudentLayout.vue'),
    meta: { roles: ['student'] },
    children: [
      {
        path: '',
        name: 'student-dashboard',
        component: () => import('@/views/student/StudentDashboard.vue'),
      },
      {
        path: 'tareas',
        name: 'student-tasks',
        component: () => import('@/views/student/StudentTasks.vue'),
      },
      {
        path: 'materiales',
        name: 'student-library',
        component: () => import('@/views/student/StudentLibrary.vue'),
      },
    ],
  },

  // ── Docente ──
  {
    path: '/docente',
    component: () => import('@/layouts/TeacherLayout.vue'),
    meta: { roles: ['teacher'] },
    children: [
      {
        path: '',
        name: 'teacher-dashboard',
        component: () => import('@/views/teacher/TeacherDashboard.vue'),
      },
      {
        path: 'materiales',
        name: 'teacher-library',
        component: () => import('@/views/teacher/TeacherLibrary.vue'),
      },
    ],
  },

  // ── Admin ──
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    meta: { roles: ['admin'] },
    children: [
      {
        path: '',
        name: 'admin-dashboard',
        component: () => import('@/views/admin/AdminDashboard.vue'),
      },
      {
        path: 'cursos/nuevo',
        name: 'admin-create-course',
        component: () => import('@/views/admin/CreateCourseView.vue'),
      },
      {
        path: 'biblioteca',
        name: 'admin-library',
        component: () => import('@/views/admin/AdminLibrary.vue'),
      },
      {
        path: 'usuarios',
        name: 'admin-users',
        component: () => import('@/views/admin/AdminUsers.vue'),
      },
    ],
  },

  // ── Fallback ──
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: { public: true },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// ── Guard de navegación por rol ─────────────────────────────
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore()

  // Rutas públicas (login, 404): siempre accesibles.
  if (to.meta.public) return next()

  // Asegura que la sesión ya se haya hidratado (Supabase / token en localStorage)
  // antes de decidir. Evita "flash" de redirect en el primer load / refresh de página.
  if (!auth.isInitialized) {
    await auth.initSession()
  }

  // Sin sesión → login, guardando a dónde quería ir.
  if (!auth.user) {
    return next({ name: 'login', query: { redirect: to.fullPath } })
  }

  // Ruta que exige haber completado el test nivelador y aún no lo hizo:
  // lo mandamos SIEMPRE a hacerlo, salvo que ya esté yendo ahí.
  if (
    auth.role === 'student' &&
    !auth.hasCompletedLevelTest &&
    to.name !== 'level-test'
  ) {
    return next({ name: 'level-test' })
  }

  // Ruta con roles permitidos definidos: chequeo de RBAC.
  const allowedRoles = to.meta.roles
  if (allowedRoles && !allowedRoles.includes(auth.role)) {
    // Rol no autorizado → lo mandamos a SU propio dashboard, no a un error genérico.
    return next({ name: `${auth.role}-dashboard` })
  }

  return next()
})

export default router

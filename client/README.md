# Queen Elizabeth Academy — Vue 3 + Pinia (migración)

Migración incremental del sitio original (app.js/backend.js/index.html vanilla JS)
a Vue 3 + Pinia, conectada a la misma base de Supabase real (mismas tablas,
mismos nombres de columna, mismos buckets de Storage).

## Qué quedó migrado (funcional, 1:1 con la lógica real)

- **Auth**: login, registro, logout, perfil actual, roles (`stores/auth.js`,
  `services/auth.js`) — reemplaza el bloque de `app.js` líneas 838-874 +
  `backend.js` líneas 14-131.
- **Dashboard por rol**: alumno / docente / admin (`views/DashboardView.vue`
  + `components/dashboard/*`), con las estadísticas reales para admin.
- **Materiales (alumno)**: listado, ver/descargar con registro de eventos
  (`views/MaterialsView.vue`).
- **Panel Docente**: crear curso (solo admin), crear lección, subir/listar/
  borrar materiales, pagos simplificados, asignar/quitar alumnos de un curso
  (`views/PanelView.vue` + `components/panel/*`).
- **Gestión Comercial** (solo admin): balances, gráfico por plan, gráfico por
  mes (últimos 6 meses), tabla de ventas con búsqueda y filtro por estado
  (`views/ComercialView.vue`).
- **Usuarios** (solo admin): cambiar rol, eliminar perfil (`views/AdminUsersView.vue`).
- **Biblioteca de materiales** (carpetas): navegación por carpetas,
  crear/renombrar/borrar carpeta, subir archivo, agregar link/video, abrir/
  borrar item. Editable para `admin`, solo lectura para `teacher`
  (`views/LibraryView.vue`, puerto 1:1 de `library.js`).

## Qué quedó explícitamente afuera de este alcance (según lo acordado)

- La **landing de marketing** (hero, planes, testimonios) del `index.html`
  original — sigue siendo contenido estático, no lógica de negocio.
- La **demo interactiva de lección** (pasos RP, reconocimiento de voz,
  ejercicios de gramática, badges, partículas de confeti) — es gamificación/
  contenido de demo, no toca datos reales en Supabase.

Si en algún momento se quiere portar esto también, es un View nuevo aparte
(`LessonView.vue`) que puede sumarse sin tocar nada de lo ya migrado.

## Cómo correrlo

```bash
cp .env.example .env   # ya viene con la URL/key pública que usaba el sitio viejo
npm install
npm run dev             # http://localhost:5173
```

Para producción:

```bash
npm run build            # genera /dist
npm run preview          # sirve /dist localmente para probarlo
```

`server.js` (el backend Express original) puede seguir sirviendo esta carpeta
`dist/` como estático igual que antes — solo hay que apuntar
`express.static()` a `dist` en vez de a `public`, o copiar el contenido de
`dist` a `public` en el build de Render.

## Estructura

```
src/
  lib/supabase.js        cliente único de Supabase
  services/               funciones puras (mismo nombre/firma que backend.js/library.js)
  stores/                 Pinia: auth, toast
  router/                 rutas + guards por rol
  components/             NavBar, DashboardLayout (sidebar), ToastHost, BarChart
  components/dashboard/   sub-vistas del dashboard por rol
  components/panel/       sub-paneles de "Panel Docente"
  views/                  una vista por ruta
```

## Notas sobre RLS / seguridad

No cambié ninguna policy de Supabase — el front confía en las mismas reglas
de Row Level Security que ya tenías (por ejemplo, `sales` solo la puede leer
un admin, el resto ve vacío en vez de error).

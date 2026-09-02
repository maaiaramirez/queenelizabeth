-- Tabla de actividades extra para estudiantes (separadas de "materials")
create table if not exists extra_activities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  type text not null default 'juego', -- juego | quiz | video | lectura | audio | enlace
  url text,
  level text not null default 'todos', -- todos | A1 | A2 | B1 | B2 | C1 | C2
  active boolean not null default true,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

alter table extra_activities enable row level security;

-- Cualquier usuario autenticado puede leer actividades activas
create policy "extra_activities_select_active"
  on extra_activities for select
  to authenticated
  using (active = true);

-- Solo admin/teacher pueden insertar, actualizar o borrar (vía backend con service role,
-- o ajustá esto a tu política real de roles en profiles)
create policy "extra_activities_admin_all"
  on extra_activities for all
  to authenticated
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role in ('admin', 'teacher')
    )
  )
  with check (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role in ('admin', 'teacher')
    )
  );

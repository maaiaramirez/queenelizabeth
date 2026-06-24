-- ════════════════════════════════════════════════════════════
-- QUEEN ELIZABETH ACADEMY — Setup de Supabase
-- Pegar este script completo en: Supabase → SQL Editor → New query → Run
-- Es seguro ejecutarlo una sola vez (crea todo desde cero).
-- ════════════════════════════════════════════════════════════

-- Extensión necesaria para generar UUIDs
create extension if not exists "pgcrypto";

-- ── CURSOS ─────────────────────────────────────────
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  level text,                       -- A1, A2, B1, B2, C1, C2
  created_at timestamptz default now()
);

-- ── LECCIONES ──────────────────────────────────────
create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete cascade,
  title text not null,
  position int default 0,
  created_at timestamptz default now()
);

-- ── MATERIALES (PDF / video / audio / link) ───────
create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade,
  title text not null,
  type text check (type in ('pdf','video','audio','link','doc')) not null,
  file_path text,              -- ruta dentro del bucket 'materials' (si es archivo subido)
  external_url text,           -- url externa (si es type = 'link')
  description text,
  uploaded_by text default 'docente',
  created_at timestamptz default now()
);

-- ── EVENTOS DE USO (esto da las estadísticas REALES) ─
create table if not exists material_events (
  id uuid primary key default gen_random_uuid(),
  material_id uuid references materials(id) on delete cascade,
  student_name text,
  student_email text,
  action text check (action in ('view','download')) not null,
  created_at timestamptz default now()
);

-- ── PLANES COMERCIALES ─────────────────────────────
create table if not exists plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric not null,
  period text default 'mes',
  description text
);

-- ── VENTAS / INSCRIPCIONES (esto alimenta el módulo comercial) ─
create table if not exists sales (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references plans(id),
  plan_name text,
  student_name text not null,
  student_email text not null,
  amount numeric not null,
  status text default 'pendiente' check (status in ('pendiente','pagado','cancelado')),
  created_at timestamptz default now()
);

-- ════════════════════════════════════════════════════════════
-- DATOS INICIALES (seed) — opcional, podés editarlos o borrarlos
-- ════════════════════════════════════════════════════════════
insert into courses (title, level) values
  ('Inglés Británico — Intermedio B1', 'B1')
on conflict do nothing;

insert into lessons (course_id, title, position)
select id, 'The British Vowel System', 1 from courses where title = 'Inglés Británico — Intermedio B1'
on conflict do nothing;

insert into plans (name, price, period, description) values
  ('Explorer', 29, 'mes', 'Acceso a niveles A1–B1, biblioteca de audio RP, 2 tutorías/mes'),
  ('Scholar', 59, 'mes', 'Acceso completo A1–C2, biblioteca BBC, 8 tutorías/mes, voz RP'),
  ('Royal', 99, 'mes', 'Todo lo de Scholar + tutor dedicado + sesiones ilimitadas')
on conflict do nothing;

-- ════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- NOTA IMPORTANTE: estas políticas son abiertas (cualquiera con la
-- clave pública "anon" puede leer y escribir) porque el sitio todavía
-- no tiene login de usuarios. Es la forma más simple de tener datos
-- REALES rápido. Cuando agregues autenticación de Supabase, hay que
-- reemplazar estas políticas por unas que validen auth.uid().
-- ════════════════════════════════════════════════════════════
alter table courses enable row level security;
alter table lessons enable row level security;
alter table materials enable row level security;
alter table material_events enable row level security;
alter table plans enable row level security;
alter table sales enable row level security;

create policy "lectura pública courses" on courses for select using (true);
create policy "lectura pública lessons" on lessons for select using (true);
create policy "lectura pública materials" on materials for select using (true);
create policy "lectura pública plans" on plans for select using (true);

-- Escritura abierta para el panel docente (sin login todavía)
create policy "escritura courses" on courses for insert with check (true);
create policy "escritura lessons" on lessons for insert with check (true);
create policy "escritura materials" on materials for insert with check (true);
create policy "borrado materials" on materials for delete using (true);

-- Eventos de uso: cualquiera puede insertar (queda el registro real),
-- pero solo se puede leer agregado desde la app de estadísticas.
create policy "insertar eventos" on material_events for insert with check (true);
create policy "leer eventos" on material_events for select using (true);

-- Ventas: cualquiera puede insertar (al elegir un plan) y leer (para el panel de estadísticas)
create policy "insertar ventas" on sales for insert with check (true);
create policy "leer ventas" on sales for select using (true);

-- ════════════════════════════════════════════════════════════
-- STORAGE: bucket para los archivos de materiales (PDF, audio, video)
-- ════════════════════════════════════════════════════════════
insert into storage.buckets (id, name, public)
values ('materials', 'materials', true)
on conflict (id) do nothing;

create policy "lectura pública storage materials"
on storage.objects for select
using ( bucket_id = 'materials' );

create policy "subida pública storage materials"
on storage.objects for insert
with check ( bucket_id = 'materials' );

create policy "borrado storage materials"
on storage.objects for delete
using ( bucket_id = 'materials' );

-- ════════════════════════════════════════════════════════════
-- LISTO. Verificá en Table Editor que aparezcan: courses, lessons,
-- materials, material_events, plans, sales — y en Storage el bucket "materials".
-- ════════════════════════════════════════════════════════════

-- Permitir 'cancelado' como estado de pago (para alumnos que se dan de baja)
alter table public.profiles drop constraint if exists profiles_payment_status_check;
alter table public.profiles add constraint profiles_payment_status_check
  check (payment_status = any (array['pagado'::text, 'pendiente'::text, 'deuda'::text, 'cancelado'::text]));

-- Tabla de bajas de alumnos (encuesta de satisfacción + motivo)
create table if not exists cancellations (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.profiles(id),
  student_name text,
  student_email text,
  reason text not null, -- precio | tiempo | no_cumplio_expectativas | cambio_metodo | otro
  reason_detail text,
  satisfaction integer not null check (satisfaction between 1 and 5),
  comments text,
  created_at timestamptz not null default now()
);

alter table cancellations enable row level security;

-- Un alumno puede insertar su propia baja
create policy "cancellations_insert_own"
  on cancellations for insert
  to authenticated
  with check (student_id = auth.uid());

-- Admin/teacher pueden ver todas las bajas
create policy "cancellations_select_admin"
  on cancellations for select
  to authenticated
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role in ('admin', 'teacher')
    )
  );

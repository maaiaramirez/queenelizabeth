-- Permite borrar un perfil aunque tenga datos relacionados.
-- Regla aplicada:
--   - Inscripciones y eventos de materiales del alumno: se borran en cascada (son del alumno).
--   - Ventas, materiales subidos, carpetas/items de biblioteca, cursos (como docente),
--     actividades extra y bajas registradas: se CONSERVAN como historial, solo se
--     desvincula la referencia al usuario (queda en null).

-- El borrado real ahora se hace sobre auth.users (vía backend con service role),
-- así que profiles tiene que caer en cascada cuando se borra el usuario de Auth.
alter table public.profiles drop constraint if exists profiles_id_fkey;
alter table public.profiles add constraint profiles_id_fkey
  foreign key (id) references auth.users(id) on delete cascade;

alter table public.enrollments drop constraint if exists enrollments_student_id_fkey;
alter table public.enrollments add constraint enrollments_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete cascade;

alter table public.material_events drop constraint if exists material_events_student_id_fkey;
alter table public.material_events add constraint material_events_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete cascade;

alter table public.courses drop constraint if exists courses_teacher_id_fkey;
alter table public.courses add constraint courses_teacher_id_fkey
  foreign key (teacher_id) references public.profiles(id) on delete set null;

alter table public.materials drop constraint if exists materials_uploaded_by_fkey;
alter table public.materials add constraint materials_uploaded_by_fkey
  foreign key (uploaded_by) references public.profiles(id) on delete set null;

alter table public.library_folders drop constraint if exists library_folders_created_by_fkey;
alter table public.library_folders add constraint library_folders_created_by_fkey
  foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.library_items drop constraint if exists library_items_uploaded_by_fkey;
alter table public.library_items add constraint library_items_uploaded_by_fkey
  foreign key (uploaded_by) references public.profiles(id) on delete set null;

alter table public.sales drop constraint if exists sales_student_id_fkey;
alter table public.sales add constraint sales_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete set null;

alter table public.cancellations drop constraint if exists cancellations_student_id_fkey;
alter table public.cancellations add constraint cancellations_student_id_fkey
  foreign key (student_id) references public.profiles(id) on delete set null;

alter table public.extra_activities add column if not exists created_by uuid;
alter table public.extra_activities drop constraint if exists extra_activities_created_by_fkey;
alter table public.extra_activities add constraint extra_activities_created_by_fkey
  foreign key (created_by) references public.profiles(id) on delete set null;

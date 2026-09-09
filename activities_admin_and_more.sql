-- Solo admin puede crear/editar/borrar juegos (antes también podía teacher)
drop policy if exists "extra_activities_admin_all" on public.extra_activities;
create policy "extra_activities_admin_only"
  on public.extra_activities for all
  to authenticated
  using (
    exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin')
  )
  with check (
    exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin')
  );

-- Más juegos de fonética (RP), en la línea del que ya venía cargado
insert into public.extra_activities (title, description, level, active, questions) values
(
  'Pares mínimos: vocales cortas y largas',
  'La distinción de duración vocálica cambia el significado en RP.',
  'B1',
  true,
  '[
    {"question": "SHIP y SHEEP se diferencian por:", "options": ["El sonido inicial \"sh\"", "La duración de la vocal (/ɪ/ vs /iː/)"], "correct_index": 1},
    {"question": "¿Qué palabra tiene la vocal larga /iː/?", "options": ["BIT", "BEAT"], "correct_index": 1},
    {"question": "¿Cuál es la transcripción correcta de FLEECE?", "options": ["/fliːs/", "/flɪs/"], "correct_index": 0},
    {"question": "En RP, la vocal de TRAP (/æ/) es:", "options": ["Corta y abierta", "Larga y cerrada"], "correct_index": 0}
  ]'::jsonb
),
(
  'La R no rótica y la TH',
  'Dos de los rasgos más distintivos del acento RP.',
  'B2',
  true,
  '[
    {"question": "En RP, la \"r\" al final de CAR se pronuncia:", "options": ["Sí, siempre", "No, salvo antes de vocal (linking r)"], "correct_index": 1},
    {"question": "El sonido \"th\" de THINK se transcribe:", "options": ["/θ/ sorda", "/ð/ sonora"], "correct_index": 0},
    {"question": "El sonido \"th\" de THIS se transcribe:", "options": ["/θ/ sorda", "/ð/ sonora"], "correct_index": 1},
    {"question": "¿Cuál palabra NO tiene \"r\" pronunciada en RP?", "options": ["RED", "CAR"], "correct_index": 1}
  ]'::jsonb
),
(
  'Diagrama vocálico RP: identificá el símbolo',
  'Asociá cada símbolo IPA con su palabra clave.',
  'B2',
  true,
  '[
    {"question": "¿Qué símbolo corresponde a la vocal de GOOSE?", "options": ["/uː/", "/ʊ/"], "correct_index": 0},
    {"question": "¿Qué símbolo corresponde a la vocal de LOT?", "options": ["/ɒ/", "/ɔː/"], "correct_index": 0},
    {"question": "¿Qué símbolo corresponde a la vocal de STRUT?", "options": ["/ʌ/", "/ə/"], "correct_index": 0},
    {"question": "¿Qué símbolo corresponde a la vocal de THOUGHT?", "options": ["/ɔː/", "/ɒ/"], "correct_index": 0}
  ]'::jsonb
);

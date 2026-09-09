alter table public.extra_activities add column if not exists questions jsonb not null default '[]'::jsonb;

insert into public.extra_activities (title, description, level, active, questions) values
(
  'British vs American English',
  'Elegí la opción correcta en inglés británico.',
  'B1',
  true,
  '[
    {"question": "Choose the British English sentence:", "options": ["Did you eat yet?", "Have you eaten yet?"], "correct_index": 1},
    {"question": "Choose the British English spelling:", "options": ["organize", "organise"], "correct_index": 1},
    {"question": "Choose the British English word for elevator:", "options": ["lift", "elevator"], "correct_index": 0},
    {"question": "Choose the British English spelling:", "options": ["color", "colour"], "correct_index": 1}
  ]'::jsonb
),
(
  'Received Pronunciation: vocales',
  'Identificá el sonido vocálico correcto en cada palabra.',
  'B1',
  true,
  '[
    {"question": "¿Qué vocal tiene BATH en RP?", "options": ["/æ/ corta", "/ɑː/ larga"], "correct_index": 1},
    {"question": "¿La \"r\" final de WATER se pronuncia en RP?", "options": ["Sí, siempre", "No, es un acento no rótico"], "correct_index": 1},
    {"question": "SHIP y SHEEP se diferencian por:", "options": ["La consonante inicial", "La duración de la vocal"], "correct_index": 1}
  ]'::jsonb
),
(
  'Vocabulario básico A1',
  'Preguntas de vocabulario para empezar.',
  'A1',
  true,
  '[
    {"question": "\"Good morning\" significa:", "options": ["Buenas noches", "Buenos días"], "correct_index": 1},
    {"question": "¿Cómo se dice \"gracias\"?", "options": ["Please", "Thank you"], "correct_index": 1},
    {"question": "¿Cuál es el plural de \"child\"?", "options": ["childs", "children"], "correct_index": 1}
  ]'::jsonb
);

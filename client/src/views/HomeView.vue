<script setup>
import { useAuthStore } from '../stores/auth'
const auth = useAuthStore()
</script>

<template>
  <div id="page-landing" class="page active">

    <!-- HERO -->
    <header class="hero">
      <div class="hero__bg-pattern"></div>
      <div class="hero__content">
        <div class="hero__eyebrow">
          <span class="hero__flag" role="img" aria-label="Bandera del Reino Unido">🇬🇧</span>
          <span>Academia Premium · Fundada en Londres</span>
        </div>
        <h1 class="hero__title">
          Domina el inglés<br /><em>como un londinense</em>
        </h1>
        <p class="hero__subtitle">
          La única academia hispanohablante especializada en inglés británico auténtico — Received
          Pronunciation, cultura de la BBC y tutores nativos del Reino Unido.
        </p>
        <div class="hero__actions">
          <RouterLink :to="auth.isLoggedIn ? { name: 'dashboard' } : { name: 'register' }" class="btn btn--primary btn--large">
            Explorar el Campus →
          </RouterLink>
          <RouterLink :to="{ name: 'home', hash: '#metodologia' }" class="btn btn--outline btn--large">
            Ver una Lección de Muestra
          </RouterLink>
        </div>
        <div class="hero__stats">
          <div class="hero__stat">
            <span class="hero__stat-number">4,200+</span>
            <span class="hero__stat-label">Estudiantes activos</span>
          </div>
          <div class="hero__stat-divider"></div>
          <div class="hero__stat">
            <span class="hero__stat-number">98%</span>
            <span class="hero__stat-label">Tasa de satisfacción</span>
          </div>
          <div class="hero__stat-divider"></div>
          <div class="hero__stat">
            <span class="hero__stat-number">32</span>
            <span class="hero__stat-label">Tutores nativos del RU</span>
          </div>
        </div>
      </div>
      <div class="hero__visual">
        <div class="hero__crest">
          <div class="crest__outer">
            <div class="crest__inner">
              <span class="crest__crown" aria-hidden="true">♛</span>
              <span class="crest__text">AUCTORITATE</span>
              <span class="crest__text crest__text--bottom">BRITANNIAE</span>
            </div>
          </div>
          <div class="crest__ribbon">Est. MMXV · London</div>
        </div>
      </div>
    </header>

    <!-- METODOLOGÍA BRITÁNICA -->
    <section class="section metodologia" id="metodologia">
      <div class="container">
        <div class="section__header">
          <span class="section__eyebrow">Nuestra Diferencia</span>
          <h2 class="section__title">Metodología Británica</h2>
          <p class="section__desc">
            El inglés británico no es solo un acento. Es un sistema lingüístico completo con su propia
            lógica, cultura y elegancia que abre puertas en el mundo académico y profesional global.
          </p>
        </div>

        <div class="metod__grid">
          <article class="metod__card metod__card--featured">
            <div class="metod__icon" role="img" aria-label="Micrófono">🎙️</div>
            <h3>Received Pronunciation</h3>
            <p>
              Aprende la pronunciación estándar del inglés de la BBC y las universidades de Oxford y
              Cambridge — la variante más reconocida y respetada a nivel internacional.
            </p>
            <ul class="metod__list">
              <li>Vocales largas y cortas del inglés RP</li>
              <li>El "th" suave y la "r" no rótica</li>
              <li>Entonación y ritmo del discurso formal</li>
            </ul>
          </article>
          <article class="metod__card">
            <div class="metod__icon" role="img" aria-label="Libros">📚</div>
            <h3>Literatura y Medios</h3>
            <p>
              Lecturas de Dickens, Austen y Orwell. Podcast originales de la BBC. Transcripciones del
              Parlamento. El idioma vivo en sus mejores manifestaciones.
            </p>
          </article>
          <article class="metod__card">
            <div class="metod__icon" role="img" aria-label="Templo clásico">🏛️</div>
            <h3>Contexto Cultural</h3>
            <p>
              El vocabulario, las expresiones idiomáticas y la etiqueta comunicativa que realmente se
              usan en el Reino Unido — en el trabajo, la academia y la vida diaria.
            </p>
          </article>
          <article class="metod__card">
            <div class="metod__icon" role="img" aria-label="Balanza">⚖️</div>
            <h3>RP vs. Americano</h3>
            <p>
              Aprenderás de forma sistemática las diferencias en ortografía (colour/color), vocabulario
              (lift/elevator) y gramática — para comunicarte con precisión en cualquier contexto.
            </p>
          </article>
          <article class="metod__card">
            <div class="metod__icon" role="img" aria-label="Birrete de graduación">🎓</div>
            <h3>Marcos MCER A1–C2</h3>
            <p>
              Contenido perfectamente alineado con el Marco Común Europeo de Referencia. Progresión
              clara, objetivos medibles y certificación al completar cada nivel.
            </p>
          </article>
          <article class="metod__card">
            <div class="metod__icon" role="img" aria-label="Apretón de manos">🤝</div>
            <h3>Tutoría Personal</h3>
            <p>
              Cada estudiante tiene acceso a sesiones 1 a 1 con tutores nativos del Reino Unido para
              práctica conversacional, revisión de pronunciación y guía personalizada.
            </p>
          </article>
        </div>

        <!-- COMPARATIVA UK vs USA -->
        <div class="compare">
          <h3 class="compare__title">¿Inglés Británico o Americano?</h3>
          <div class="compare__table">
            <div class="compare__col compare__col--uk">
              <div class="compare__label">
                <span role="img" aria-label="Bandera de Reino Unido">🇬🇧</span> Inglés Británico (RP)
              </div>
              <div class="compare__row">colour · honour · favour</div>
              <div class="compare__row">lift · flat · post</div>
              <div class="compare__row">Have you eaten yet?</div>
              <div class="compare__row">I've just arrived</div>
              <div class="compare__row">at the weekend</div>
            </div>
            <div class="compare__vs" aria-hidden="true">VS</div>
            <div class="compare__col compare__col--us">
              <div class="compare__label">
                <span role="img" aria-label="Bandera de Estados Unidos">🇺🇸</span> Inglés Americano
              </div>
              <div class="compare__row">color · honor · favor</div>
              <div class="compare__row">elevator · apartment · mail</div>
              <div class="compare__row">Did you eat yet?</div>
              <div class="compare__row">I just arrived</div>
              <div class="compare__row">on the weekend</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- NIVELES MCER -->
    <section class="section niveles" id="niveles">
      <div class="container">
        <div class="section__header">
          <span class="section__eyebrow">Estructura Académica</span>
          <h2 class="section__title">Del A1 al C2</h2>
          <p class="section__desc">
            Seis niveles progresivos, cada uno con su propia identidad visual, objetivos MCER y
            colección de Royal Badges.
          </p>
        </div>
        <div class="niveles__track">
          <div class="nivel__item" data-level="A1">
            <div class="nivel__badge">A1</div>
            <div class="nivel__info">
              <h4>Beginner</h4>
              <p>Primeras palabras, saludos y frases cotidianas con acento correcto desde el principio.</p>
            </div>
          </div>
          <div class="nivel__connector"></div>
          <div class="nivel__item" data-level="A2">
            <div class="nivel__badge">A2</div>
            <div class="nivel__info">
              <h4>Elementary</h4>
              <p>Conversaciones básicas, vocabulario de la vida diaria y cultura británica introductoria.</p>
            </div>
          </div>
          <div class="nivel__connector"></div>
          <div class="nivel__item" data-level="B1">
            <div class="nivel__badge">B1</div>
            <div class="nivel__info">
              <h4>Intermediate</h4>
              <p>Textos de la BBC, podcasts auténticos y comprensión de idioms británicos.</p>
            </div>
          </div>
          <div class="nivel__connector"></div>
          <div class="nivel__item" data-level="B2">
            <div class="nivel__badge">B2</div>
            <div class="nivel__info">
              <h4>Upper-Intermediate</h4>
              <p>Literatura clásica, debate de actualidad y pronunciación avanzada de RP.</p>
            </div>
          </div>
          <div class="nivel__connector"></div>
          <div class="nivel__item" data-level="C1">
            <div class="nivel__badge">C1</div>
            <div class="nivel__info">
              <h4>Advanced</h4>
              <p>Discurso profesional, escritura académica y preparación para IELTS/Cambridge.</p>
            </div>
          </div>
          <div class="nivel__connector"></div>
          <div class="nivel__item" data-level="C2">
            <div class="nivel__badge nivel__badge--crown">C2 ♛</div>
            <div class="nivel__info">
              <h4>Mastery</h4>
              <p>Dominio completo. Nativo funcional. Certificado con sello real de la academia.</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- TUTORES -->
    <section class="section tutores" id="tutores">
      <div class="container">
        <div class="section__header">
          <span class="section__eyebrow">Nuestro Equipo</span>
          <h2 class="section__title">Tutores Nativos del Reino Unido</h2>
          <p class="section__desc">
            Cada tutor es nativo del RU, con formación pedagógica certificada y pasión por transmitir la
            riqueza del inglés británico.
          </p>
        </div>
        <div class="tutores__grid">
          <article class="tutor__card">
            <div class="tutor__avatar tutor__avatar--1">
              <span class="tutor__initials">EH</span>
            </div>
            <div class="tutor__flag" role="img" aria-label="Bandera de Inglaterra">🏴󠁧󠁢󠁥󠁮󠁧󠁿</div>
            <h3 class="tutor__name">Eleanor Hartley</h3>
            <span class="tutor__origin">Oxford, England</span>
            <p class="tutor__bio">
              MA en Lingüística Aplicada, Universidad de Oxford. Especialista en Received Pronunciation
              y preparación para Cambridge IELTS.
            </p>
            <div class="tutor__tags">
              <span>RP Avanzado</span>
              <span>IELTS</span>
              <span>Literatura</span>
            </div>
          </article>
          <article class="tutor__card">
            <div class="tutor__avatar tutor__avatar--2">
              <span class="tutor__initials">JM</span>
            </div>
            <div class="tutor__flag" role="img" aria-label="Bandera de Escocia">🏴󠁧󠁢󠁳󠁣󠁴󠁿</div>
            <h3 class="tutor__name">James MacAllister</h3>
            <span class="tutor__origin">Edinburgh, Scotland</span>
            <p class="tutor__bio">
              Licenciado en Literatura Inglesa por la Universidad de Edimburgo. 8 años de experiencia
              enseñando en academias premium de Europa.
            </p>
            <div class="tutor__tags">
              <span>Literatura</span>
              <span>Business English</span>
              <span>Debate</span>
            </div>
          </article>
          <article class="tutor__card">
            <div class="tutor__avatar tutor__avatar--3">
              <span class="tutor__initials">SC</span>
            </div>
            <div class="tutor__flag" role="img" aria-label="Bandera de Gales">🏴󠁧󠁢󠁷󠁬󠁳󠁿</div>
            <h3 class="tutor__name">Sophie Clarke</h3>
            <span class="tutor__origin">Cardiff, Wales</span>
            <p class="tutor__bio">
              Certificada CELTA, ex-corresponsal de la BBC. Aporta el idioma vivo de los medios
              británicos a sus clases con una pedagogía dinámica y creativa.
            </p>
            <div class="tutor__tags">
              <span>BBC English</span>
              <span>Conversación</span>
              <span>Medios</span>
            </div>
          </article>
          <article class="tutor__card">
            <div class="tutor__avatar tutor__avatar--4">
              <span class="tutor__initials">RB</span>
            </div>
            <div class="tutor__flag" role="img" aria-label="Bandera del Reino Unido">🇬🇧</div>
            <h3 class="tutor__name">Richard Bennett</h3>
            <span class="tutor__origin">London, England</span>
            <p class="tutor__bio">
              Doctorado en Fonética por la Universidad de Londres. Investigador de RP y autor de "The
              Sound of Britain", libro de referencia en pronunciación.
            </p>
            <div class="tutor__tags">
              <span>Fonética</span>
              <span>Académico</span>
              <span>C1/C2</span>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- ROYAL BADGES PREVIEW -->
    <section class="section badges-preview">
      <div class="container">
        <div class="section__header">
          <span class="section__eyebrow">Sistema de Logros</span>
          <h2 class="section__title">Royal Badges</h2>
          <p class="section__desc">
            Gana insignias reales al completar niveles, racha de práctica y hitos especiales de
            pronunciación y cultura.
          </p>
        </div>
        <div class="badges__showcase">
          <div class="badge__item" data-tooltip="Completar el nivel A1">
            <div class="badge__medal badge__medal--bronze">
              <span class="badge__icon" role="img" aria-label="Brote verde">🌱</span>
            </div>
            <span class="badge__name">The Newcomer</span>
            <span class="badge__level">A1 Complete</span>
          </div>
          <div class="badge__item" data-tooltip="Primera sesión con tutor nativo">
            <div class="badge__medal badge__medal--silver">
              <span class="badge__icon" role="img" aria-label="Micrófono">🎙️</span>
            </div>
            <span class="badge__name">The Orator</span>
            <span class="badge__level">First Tutor Session</span>
          </div>
          <div class="badge__item badge__item--featured" data-tooltip="Completar los 6 niveles MCER">
            <div class="badge__medal badge__medal--gold">
              <span class="badge__icon" aria-hidden="true">♛</span>
            </div>
            <span class="badge__name">The Royal Scholar</span>
            <span class="badge__level">C2 Mastery</span>
          </div>
          <div class="badge__item" data-tooltip="7 días de práctica consecutivos">
            <div class="badge__medal badge__medal--silver">
              <span class="badge__icon" role="img" aria-label="Fuego">🔥</span>
            </div>
            <span class="badge__name">The Devoted</span>
            <span class="badge__level">7-Day Streak</span>
          </div>
          <div class="badge__item" data-tooltip="Pronunciación perfecta en 10 ejercicios">
            <div class="badge__medal badge__medal--bronze">
              <span class="badge__icon" role="img" aria-label="Cabeza hablando">🗣️</span>
            </div>
            <span class="badge__name">The Speaker</span>
            <span class="badge__level">RP Mastery</span>
          </div>
          <div class="badge__item" data-tooltip="Completar todos los British Culture Tips">
            <div class="badge__medal badge__medal--gold">
              <span class="badge__icon" role="img" aria-label="Templo clásico">🏛️</span>
            </div>
            <span class="badge__name">The Culturist</span>
            <span class="badge__level">All Culture Tips</span>
          </div>
        </div>
      </div>
    </section>

    <!-- TESTIMONIOS -->
    <section class="section testimonios" id="testimonios">
      <div class="container">
        <div class="section__header">
          <span class="section__eyebrow">Historias Reales</span>
          <h2 class="section__title">Nuestros Estudiantes Hablan</h2>
        </div>
        <div class="test__grid">
          <div class="test__card">
            <div class="test__stars" aria-label="Calificación de 5 estrellas">★★★★★</div>
            <blockquote class="test__quote">
              "Después de 6 meses con Queen Elizabeth, conseguí el trabajo de mis sueños en una firma de
              abogados con sede en Londres. Mi entrevistador dijo que mi inglés era 'impeccably
              British'."
            </blockquote>
            <div class="test__author">
              <div class="test__avatar test__avatar--1"></div>
              <div>
                <strong>Valentina Ríos</strong>
                <span>Bogotá, Colombia · Nivel C1</span>
              </div>
            </div>
            <div class="test__badge-earned"><span role="img" aria-label="Trofeo">🏆</span> Royal Scholar Badge</div>
          </div>
          <div class="test__card test__card--featured">
            <div class="test__stars" aria-label="Calificación de 5 estrellas">★★★★★</div>
            <blockquote class="test__quote">
              "La diferencia con otras academias es abismal. Aquí aprendes el inglés que realmente se
              habla en la BBC, en el Parlamento y en las universidades más prestigiosas del mundo."
            </blockquote>
            <div class="test__author">
              <div class="test__avatar test__avatar--2"></div>
              <div>
                <strong>Andrés Morales</strong>
                <span>Ciudad de México · Nivel B2</span>
              </div>
            </div>
            <div class="test__badge-earned"><span role="img" aria-label="Micrófono">🎙️</span> The Orator Badge</div>
          </div>
          <div class="test__card">
            <div class="test__stars" aria-label="Calificación de 5 estrellas">★★★★★</div>
            <blockquote class="test__quote">
              "Mis hijos estudian con Queen Elizabeth desde nivel A1. La tutora Eleanor es
              extraordinaria — los niños aman cada clase y ya pueden ver películas en inglés sin
              subtítulos."
            </blockquote>
            <div class="test__author">
              <div class="test__avatar test__avatar--3"></div>
              <div>
                <strong>Luciana Fernández</strong>
                <span>Buenos Aires, Argentina · Nivel A2/B1</span>
              </div>
            </div>
            <div class="test__badge-earned"><span role="img" aria-label="Brote verde">🌱</span> The Newcomer Badge</div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA SECTION -->
    <section class="section cta-section" id="cta-section">
      <div class="container">
        <div class="cta__inner">
          <span class="cta__crown" aria-hidden="true">♛</span>
          <h2 class="cta__title">Tu acento cambia.<br /><em>Tu mundo también.</em></h2>
          <p class="cta__desc">
            Únete a más de 4,200 estudiantes que ya hablan el inglés de Oxford, la BBC y el West End.
            Primera semana sin costo.
          </p>
          <div class="cta__plans">
            <div class="plan__card">
              <h3 class="plan__name">Explorer</h3>
              <div class="plan__price"><span>$</span>29<span>/mes</span></div>
              <ul class="plan__features">
                <li>✓ Acceso a niveles A1–B1</li>
                <li>✓ Biblioteca de audio RP</li>
                <li>✓ 2 sesiones de tutoría/mes</li>
                <li>✓ Royal Badges básicos</li>
              </ul>
              <RouterLink :to="{ name: 'register', query: { plan: 'explorer' } }" class="btn btn--plan">Empezar Gratis</RouterLink>
            </div>
            <div class="plan__card plan__card--featured">
              <div class="plan__badge-featured">⭐ Más Popular</div>
              <h3 class="plan__name">Scholar</h3>
              <div class="plan__price"><span>$</span>59<span>/mes</span></div>
              <ul class="plan__features">
                <li>✓ Acceso completo A1–C2</li>
                <li>✓ Biblioteca BBC + Literatura</li>
                <li>✓ 8 sesiones de tutoría/mes</li>
                <li>✓ Todos los Royal Badges</li>
                <li>✓ Reconocimiento de voz RP</li>
                <li>✓ Foro de comunidad</li>
              </ul>
              <RouterLink :to="{ name: 'register', query: { plan: 'scholar' } }" class="btn btn--primary btn--plan">Unirme al Scholar</RouterLink>
            </div>
            <div class="plan__card">
              <h3 class="plan__name">Royal</h3>
              <div class="plan__price"><span>$</span>99<span>/mes</span></div>
              <ul class="plan__features">
                <li>✓ Todo lo de Scholar</li>
                <li>✓ Tutor dedicado personal</li>
                <li>✓ Sesiones ilimitadas 1-a-1</li>
                <li>✓ Certificado con sello real</li>
                <li>✓ Prioridad en grupos small</li>
              </ul>
              <RouterLink :to="{ name: 'register', query: { plan: 'royal' } }" class="btn btn--plan btn--gold">Acceso Royal</RouterLink>
            </div>
          </div>
          <p class="cta__guarantee">🔒 Garantía de 30 días. Sin compromisos anuales. Cancela cuando quieras.</p>
        </div>
      </div>
    </section>

    <!-- FOOTER -->
    <footer class="footer">
      <div class="container">
        <div class="footer__inner">
          <div class="footer__brand">
            <span class="footer__logo">♛ Queen <em>Elizabeth</em></span>
            <p>
              Academia premium de inglés británico. Metodología RP auténtica, tutores nativos del Reino
              Unido y una comunidad global de estudiantes excelentes.
            </p>
            <div class="footer__social">
              <a href="#" aria-label="Visitar nuestro perfil de Twitter">𝕏</a>
              <a href="#" aria-label="Visitar nuestro perfil de Instagram">📷</a>
              <a href="#" aria-label="Visitar nuestro canal de YouTube">▶</a>
            </div>
          </div>
          <div class="footer__links">
            <h4>Academia</h4>
            <RouterLink :to="{ name: 'home', hash: '#metodologia' }">Metodología</RouterLink>
            <RouterLink :to="{ name: 'home', hash: '#tutores' }">Tutores</RouterLink>
            <RouterLink :to="{ name: 'home', hash: '#niveles' }">Niveles MCER</RouterLink>
            <a href="#">Royal Badges</a>
          </div>
          <div class="footer__links">
            <h4>Estudiante</h4>
            <RouterLink :to="auth.isLoggedIn ? { name: 'dashboard' } : { name: 'login' }">Mi Dashboard</RouterLink>
            <RouterLink :to="{ name: 'materiales' }">Materiales</RouterLink>
            <a href="#">Agendar Tutoría</a>
            <a href="#">Comunidad</a>
          </div>
          <div class="footer__links">
            <h4>Soporte</h4>
            <a href="#">Centro de Ayuda</a>
            <a href="#">Términos de Uso</a>
            <a href="#">Privacidad</a>
            <a href="#">Contacto</a>
          </div>
        </div>
        <div class="footer__bottom">
          <p>© 2026 Queen Elizabeth Academy · London · Todos los derechos reservados.</p>
          <div class="footer__certifications">
            <span>🎓 Cambridge Affiliate</span>
            <span>📜 MCER Certified</span>
            <span>🏆 BBC Partner</span>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

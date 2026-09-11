/*
  Il menu a panino.

  ⚑ **Progressivo, non obbligatorio.** Il bottone arriva dal server con l'attributo
  `hidden`, e solo questo script lo toglie. Se lo script non arriva — rete lenta, blocco,
  errore — la navigazione resta quella di prima: tutte le voci visibili, che vanno a capo.
  Un sito la cui navigazione dipende da JavaScript e' un sito che a volte non si puo'
  navigare.

  ⚑ Nessuna libreria e nessun modulo: sono quaranta righe e girano su qualunque browser
  degli ultimi dieci anni. Il sito non carica niente da terze parti (vedi la cookie policy),
  e valeva anche per questo.
*/

(function () {
  'use strict';

  var bottone = document.getElementById('panino');
  var menu = document.getElementById('menu-principale');
  var barra = document.querySelector('.topbar');
  if (!bottone || !menu || !barra) return;

  // Le due etichette viaggiano in attributi data-, messi dal server: sono tradotte, e il
  // JavaScript non deve conoscere nessuna lingua.
  var etichettaApri = bottone.getAttribute('data-apri') || '';
  var etichettaChiudi = bottone.getAttribute('data-chiudi') || '';

  bottone.hidden = false;

  function imposta(aperto) {
    barra.classList.toggle('topbar--aperta', aperto);
    bottone.setAttribute('aria-expanded', aperto ? 'true' : 'false');
    bottone.setAttribute('aria-label', aperto ? etichettaChiudi : etichettaApri);
  }

  bottone.addEventListener('click', function () {
    imposta(bottone.getAttribute('aria-expanded') !== 'true');
  });

  // ☠ Chiudere dopo il clic su una voce non e' un vezzo: quasi tutti i link della barra
  // sono ancore verso un punto della **stessa** pagina (`/#app`, `#personalizzato`). Senza
  // questa riga il pannello resta aperto sopra il contenuto a cui si e' appena saltati, e
  // sembra che il link non abbia funzionato.
  //
  // ☠ Si controlla che sia un **link**: il bottoncino che apre il sottomenu delle app vive
  // dentro lo stesso pannello, e chiuderlo al suo clic renderebbe il sottomenu impossibile
  // da vedere, perche' sparirebbe nello stesso istante in cui si apre.
  menu.addEventListener('click', function (evento) {
    if (evento.target.closest('a')) imposta(false);
  });

  // Il sottomenu delle app dentro il pannello.
  //
  // ⚑ A tendina e non sempre aperto: con quattro app in catalogo il pannello diventerebbe
  // una lista lunga in cui le voci principali si perdono fra quelle secondarie. Chiuso di
  // partenza, il menu resta leggibile a colpo d'occhio qualunque cosa contenga.
  var interruttore = menu.querySelector('.nav__interruttore');
  var voceApp = menu.querySelector('.nav__voce--conSottomenu');

  if (interruttore && voceApp) {
    interruttore.addEventListener('click', function () {
      var aperto = interruttore.getAttribute('aria-expanded') !== 'true';
      interruttore.setAttribute('aria-expanded', aperto ? 'true' : 'false');
      voceApp.classList.toggle('nav__voce--aperta', aperto);
    });
  }

  // Esc chiude e riporta il fuoco sul bottone, altrimenti resta dentro un pannello chiuso.
  document.addEventListener('keydown', function (evento) {
    if (evento.key === 'Escape' && barra.classList.contains('topbar--aperta')) {
      imposta(false);
      bottone.focus();
    }
  });

  // Ruotando il telefono, o allargando la finestra, il pannello sparisce per via del CSS ma
  // `aria-expanded` resterebbe "true": uno screen reader annuncerebbe un menu aperto che non
  // c'e'.
  window.addEventListener('resize', function () {
    if (bottone.offsetParent === null) imposta(false);
  });
})();

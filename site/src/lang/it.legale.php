<?php

/**
 * I corpi delle pagine legali, in italiano.
 *
 * ☠ Si usa NOWDOC (`<<<'HTML'`) e non HEREDOC: nel nowdoc PHP non interpreta niente, per
 * cui un eventuale `$` in un testo resta un `$` e i segnaposto `{denominazione}` restano
 * intatti. Con l'heredoc un `$` seguito da una lettera diventerebbe una variabile
 * inesistente, e la frase perderebbe una parola senza nessun errore.
 *
 * ☠ Questi testi descrivono il software **vero**. Le affermazioni sono verificabili nel
 * codice: i dati delle app stanno nel database locale, l'unica cosa che lascia il
 * dispositivo e' la verifica dell'acquisto, e il server delle licenze conserva le colonne
 * elencate in `server/src/db/schema.sql`. Se il codice cambia, queste pagine cambiano lo
 * stesso giorno, in **entrambe** le lingue.
 */

declare(strict_types=1);

return [

'legale.note-legali.corpo' => <<<'HTML'
<h2>Titolare del sito</h2>

<div class="scroll-x">
  <table>
    <tr><th>Denominazione</th><td>{denominazione}</td></tr>
    <tr><th>Titolare</th><td>{titolare}</td></tr>
    <tr><th>Sede</th><td>{indirizzo}, {cap} {citta} ({provincia}), {paese}</td></tr>
    <tr><th>Partita IVA e Codice Fiscale</th><td>{piva}</td></tr>
    <tr><th>Email</th><td><a href="mailto:{email}">{email}</a></td></tr>
    <tr><th>PEC</th><td><a href="mailto:{pec}">{pec}</a></td></tr>
    <tr><th>Sito</th><td>{sito}</td></tr>
  </table>
</div>

<h2>Oggetto del sito</h2>

<p>
  Questo sito presenta le applicazioni per Android e iPhone sviluppate e distribuite dal
  titolare sopra indicato, e mette a disposizione un modulo per richiedere assistenza,
  segnalare malfunzionamenti e chiedere informazioni su servizi di sviluppo software su
  misura.
</p>

<p>
  Il sito <strong>non è un negozio</strong>: non vi si conclude alcun contratto di acquisto e
  non vi si effettuano pagamenti. La distribuzione delle applicazioni e la vendita delle
  relative funzioni aggiuntive avvengono esclusivamente attraverso Google Play, gestito da
  Google Ireland Limited, e App Store, gestito da Apple Distribution International Ltd. Le
  condizioni economiche, il diritto di recesso e la procedura di rimborso relativi a tali
  acquisti sono regolati dai termini dello store da cui hai acquistato, come indicato
  nelle <a href="{url_termini}">condizioni di servizio</a>.
</p>

<h2>Proprietà intellettuale</h2>

<p>
  I testi, la grafica, i loghi, le icone, il codice sorgente delle applicazioni e ogni altro
  contenuto di questo sito sono di proprietà del titolare, salvo dove diversamente indicato,
  e sono protetti dalla normativa sul diritto d'autore. Ne è vietata la riproduzione, anche
  parziale, senza autorizzazione scritta.
</p>

<p>
  Android, Google Play e il logo Google Play sono marchi di Google LLC. La loro citazione ha
  finalità esclusivamente descrittiva e non implica alcun rapporto di affiliazione,
  sponsorizzazione o approvazione da parte di Google.
</p>

<p>
  Apple, iPhone e App Store sono marchi di Apple Inc., registrati negli Stati Uniti e in altri
  Paesi. Vale quanto detto sopra: la citazione è descrittiva e non implica alcun rapporto con
  Apple.
</p>

<h2>Segnalazione di contenuti</h2>

<p>
  Per segnalare un contenuto che si ritenga lesivo di un proprio diritto è possibile scrivere
  a <a href="mailto:{email}">{email}</a> oppure, per comunicazioni con valore legale, alla
  casella PEC <a href="mailto:{pec}">{pec}</a>. Le segnalazioni ricevute vengono esaminate e,
  se fondate, il contenuto viene rimosso senza indugio.
</p>

<h2>Legge applicabile e foro competente</h2>

<p>
  Il rapporto con gli utenti di questo sito è regolato dalla legge italiana. Per le
  controversie con soggetti che agiscono al di fuori della propria attività commerciale
  (consumatori) è competente il giudice del luogo di residenza o domicilio del consumatore,
  se situato in Italia. In tutti gli altri casi è competente in via esclusiva il Foro di
  Viterbo.
</p>

<div class="box">
  <p>
    Le informazioni sul trattamento dei dati personali sono contenute nell'<a href="{url_privacy}">informativa
    privacy</a>. Le informazioni sui cookie sono nella <a href="{url_cookie}">cookie policy</a>.
  </p>
</div>
HTML,

'legale.privacy.corpo' => <<<'HTML'
<div class="toc">
  <strong>In breve</strong>
  <ol>
    <li>Le app funzionano senza account e senza registrazione.</li>
    <li>I dati che inserisci nelle app restano nella memoria del telefono.</li>
    <li>Non usiamo strumenti di analisi, profilazione o pubblicità, né nel sito né nelle app.</li>
    <li>L'unico dato che esce dal telefono riguarda la verifica dell'acquisto della versione Pro.</li>
    <li>Il modulo di contatto raccoglie solo quello che scrivi tu.</li>
  </ol>
</div>

<h2>1. Titolare del trattamento</h2>

<p>
  <strong>{denominazione}</strong>, {indirizzo}, {cap} {citta} ({provincia}), {paese} —
  P. IVA e C.F. {piva}.
</p>
<p>
  Per esercitare i tuoi diritti o per qualunque domanda su questa informativa scrivi a
  <a href="mailto:{email}">{email}</a> oppure, via posta certificata, a
  <a href="mailto:{pec}">{pec}</a>.
</p>
<p>
  Non è stato nominato un responsabile della protezione dei dati (DPO): non ricorre nessuno
  dei casi in cui l'articolo 37 del Regolamento lo rende obbligatorio.
</p>

<h2>2. Navigazione sul sito</h2>

<h3>Dati di connessione</h3>

<p>
  Il server che ospita questo sito registra, come fa qualunque server web, le richieste che
  riceve: indirizzo IP, data e ora, indirizzo della pagina richiesta, esito della richiesta,
  tipo di browser e sistema operativo dichiarati. Questi dati non sono associati a un utente
  identificato e non vengono usati per costruire profili.
</p>

<div class="scroll-x">
  <table>
    <tr><th>Finalità</th><td>Funzionamento tecnico del sito, diagnosi dei guasti, sicurezza e difesa da abusi.</td></tr>
    <tr><th>Base giuridica</th><td>Legittimo interesse del titolare a erogare e proteggere il servizio (art. 6.1.f).</td></tr>
    <tr><th>Conservazione</th><td>Massimo 30 giorni, poi cancellazione automatica dei file di log.</td></tr>
  </table>
</div>

<h3>Lingua e cookie</h3>

<p>
  Il sito non utilizza cookie di profilazione, non include strumenti di analisi statistica e
  non carica alcuna risorsa da server di terze parti: font, fogli di stile e immagini sono
  serviti dallo stesso dominio. Gli unici cookie impostati sono due cookie tecnici: quello
  che ricorda la lingua scelta e quello di sessione della pagina dei contatti.
</p>

<p>
  Alla prima visita, se non hai ancora scelto una lingua, il sito legge l'intestazione
  <code>Accept-Language</code> inviata dal browser per decidere se mostrarti la versione
  italiana o quella inglese. È una lettura istantanea, il valore non viene conservato e non
  viene usato per nessun'altra finalità. Per il dettaglio vedi la
  <a href="{url_cookie}">cookie policy</a>.
</p>

<h2>3. Modulo di contatto</h2>

<p>
  Quando invii il modulo raccogliamo <strong>nome, indirizzo email, argomento, app
  eventualmente indicata e testo del messaggio</strong>. Non c'è nessun altro campo, e nulla
  viene dedotto o arricchito da fonti esterne.
</p>

<div class="scroll-x">
  <table>
    <tr><th>Finalità</th><td>Rispondere alla tua richiesta e, se necessario, gestire la segnalazione fino alla sua risoluzione.</td></tr>
    <tr><th>Base giuridica</th><td>Consenso, che presti spuntando la casella prima dell'invio (art. 6.1.a). Per le richieste relative a un servizio in corso, esecuzione di misure precontrattuali o contrattuali (art. 6.1.b).</td></tr>
    <tr><th>Conferimento</th><td>Facoltativo, ma senza nome, email e testo non è possibile rispondere.</td></tr>
    <tr><th>Conservazione</th><td>24 mesi dall'ultimo scambio di messaggi, salvo che la conservazione sia necessaria per adempimenti di legge o per la difesa di un diritto in giudizio.</td></tr>
  </table>
</div>

<p>
  Ogni messaggio ricevuto viene registrato sul nostro server e, se la casella di posta è
  configurata, inoltrato all'indirizzo aziendale. Registriamo inoltre, per un'ora, un valore
  derivato dal tuo indirizzo IP attraverso una funzione di hash: serve unicamente a limitare
  gli invii ripetuti provenienti dalla stessa connessione. L'indirizzo IP in chiaro non viene
  conservato.
</p>

<h2>4. Le applicazioni</h2>

<h3>Quello che resta sul tuo telefono</h3>

<p>
  Le app SMP MicroApps <strong>non richiedono registrazione e non hanno account</strong>.
  Tutto quello che inserisci — nel caso di TrashCan: calendari, tipi di rifiuto, regole di
  raccolta, eccezioni, orari dei promemoria e preferenze — è salvato in un database locale
  nella memoria del dispositivo, protetto dall'isolamento fra applicazioni previsto da
  Android e da iOS. Questi dati non ci vengono trasmessi, non li vediamo e non possiamo recuperarli
  per te: se disinstalli l'app senza aver fatto un'esportazione, si perdono.
</p>

<p>
  Le notifiche sono pianificate dal sistema operativo del telefono e il loro contenuto non
  transita da nessun server. Non utilizziamo notifiche push remote. Il widget legge gli
  stessi dati locali.
</p>

<p>
  La funzione di esportazione produce un file che <strong>scegli tu</strong> dove salvare o a
  chi inviare. In quel momento i dati escono dall'app perché lo hai chiesto tu, e da quel
  momento il trattamento dipende dal servizio che hai scelto per conservarli o condividerli.
</p>

<p>
  Alcune app usano la <strong>fotocamera</strong> o le <strong>foto</strong> del telefono, e
  solo quando lo chiedi tu: Film Tracker per le foto dei rullini, QR Me per leggere un codice QR
  inquadrandolo o scegliendo un'immagine. Le immagini sono elaborate <strong>esclusivamente sul
  telefono</strong>: la lettura dei codici QR avviene con una libreria inclusa nell'app, che non
  si collega a nessun servizio esterno, e nessuna immagine viene inviata a noi o a terzi.
</p>

<p>
  Full Freezer permette di <strong>dettare</strong> cosa metti nel congelatore. Il riconoscimento
  della voce avviene <strong>esclusivamente sul telefono</strong>, con il riconoscimento vocale
  locale del sistema: la voce non viene inviata né a noi, né ad Apple, né a Google. Se il tuo
  telefono non offre il riconoscimento locale, la dettatura semplicemente non è disponibile e resta
  il campo di testo. Il microfono si attiva solo mentre stai dettando.
</p>

<h3>Acquisto e verifica della versione Pro</h3>

<p>
  L'acquisto della versione Pro avviene interamente su Google Play, se usi Android, o su App
  Store, se usi iPhone. Non riceviamo e non trattiamo i tuoi dati di pagamento: la carta, i dati
  di fatturazione e l'identità dell'acquirente restano a Google o ad Apple, che operano come
  titolari autonomi del trattamento. Vedi la
  <a href="https://policies.google.com/privacy" rel="noopener">informativa privacy di
  Google</a> e quella <a href="https://www.apple.com/it/legal/privacy/" rel="noopener">di
  Apple</a>.
</p>

<p>
  Su Android, per vendere la versione Pro, l'app contiene la <strong>libreria ufficiale di
  Google Play per gli acquisti</strong> (Google Play Billing), che Google richiede a chi vende
  contenuti digitali su Google Play. Quando apri la schermata d'acquisto o ripristini un
  acquisto, questa libreria comunica direttamente con Google Play e può inviare a Google
  informazioni tecniche sul funzionamento del servizio d'acquisto. Questi dati vanno a Google, che
  li tratta come titolare autonomo secondo la propria informativa: noi non li riceviamo. È
  l'unico componente di terze parti delle app che comunica con l'esterno, ed è legato solo
  all'acquisto.
</p>

<p>
  <strong>Su iPhone</strong> l'app non comunica con nessun nostro server: l'acquisto lo
  verifica il telefono stesso con Apple, e noi non riceviamo nulla. Le righe che seguono, fino
  al codice di trasferimento compreso, valgono soltanto per Android.
</p>

<p>
  <strong>Su Android</strong>, per riconoscere un acquisto valido e per impedire che una licenza
  venga riutilizzata su un numero indefinito di dispositivi, l'app comunica con un nostro
  server. I dati trattati in questa fase sono:
</p>

<div class="scroll-x">
  <table>
    <tr>
      <th>Identificativo di installazione</th>
      <td>Un codice casuale generato dall'app al primo avvio. Non deriva da alcun
        identificativo del dispositivo, non è l'ID pubblicitario di Android, non permette di
        risalire a te e cambia se disinstalli e reinstalli l'app.</td>
    </tr>
    <tr>
      <th>Token di acquisto e numero d'ordine</th>
      <td>Rilasciati da Google Play al momento dell'acquisto. Servono a verificare presso
        Google che l'acquisto sia reale e non sia stato rimborsato.</td>
    </tr>
    <tr>
      <th>Identificativo dell'app, prodotto acquistato, stato e date</th>
      <td>Per sapere a che cosa hai diritto e da quando.</td>
    </tr>
    <tr>
      <th>Versione dell'app e piattaforma</th>
      <td>Per diagnosticare i problemi legati a una versione specifica.</td>
    </tr>
  </table>
</div>

<div class="box">
  <p>
    <strong>Non trattiamo il tuo indirizzo email, il tuo nome, il tuo account Google o il tuo
    ID Apple.</strong>
    Il nostro archivio degli acquisti non contiene dati che permettano di identificarti:
    contiene un codice casuale e la prova che a quel codice corrisponde un acquisto valido.
  </p>
</div>

<div class="scroll-x">
  <table>
    <tr><th>Finalità</th><td>Verificare l'acquisto, erogare le funzioni acquistate, gestire rimborsi e revoche, prevenire gli abusi delle licenze.</td></tr>
    <tr><th>Base giuridica</th><td>Esecuzione del contratto relativo alla fornitura del contenuto digitale acquistato (art. 6.1.b) e legittimo interesse alla prevenzione delle frodi (art. 6.1.f).</td></tr>
    <tr><th>Conservazione</th><td>Per tutta la durata della licenza, che è permanente, e per i successivi 10 anni ai fini degli obblighi contabili e di difesa in giudizio.</td></tr>
  </table>
</div>

<h3>Codice di trasferimento</h3>

<p>
  Se cambi telefono e anche account Google, l'app permette di generare un codice temporaneo
  per spostare la licenza sul nuovo dispositivo. Il codice è casuale, scade dopo sette
  giorni, si può usare una sola volta ed è collegato unicamente all'identificativo di
  installazione. Non contiene e non rivela alcun dato personale.
</p>

<h3>Nessuna analisi d'uso</h3>

<p>
  Le app non contengono strumenti di analisi (Firebase Analytics, Crashlytics o equivalenti),
  non raccolgono statistiche su come le usi, non registrano le schermate che apri e non
  contengono pubblicità né identificatori pubblicitari. L'unica eccezione al principio «i dati
  restano sul telefono» è l'acquisto della versione Pro descritto sopra.
</p>

<h2>5. A chi comunichiamo i dati</h2>

<p>
  I dati non vengono venduti, ceduti né comunicati a terzi per finalità commerciali. Possono
  accedervi, nei limiti di quanto necessario allo svolgimento del servizio:
</p>

<ul>
  <li><strong>Il fornitore di hosting</strong> del sito e del server delle licenze, che agisce
    come responsabile del trattamento ai sensi dell'art. 28 del Regolamento. I server sono
    situati nell'Unione Europea.</li>
  <li><strong>Google Ireland Limited</strong>, in qualità di titolare autonomo, per tutto ciò
    che riguarda la distribuzione dell'app e l'acquisto sul Play Store.</li>
  <li><strong>Apple Distribution International Ltd</strong>, in qualità di titolare autonomo,
    per tutto ciò che riguarda la distribuzione dell'app e l'acquisto su App Store.</li>
  <li><strong>Il fornitore del servizio di posta elettronica</strong> attraverso cui
    transitano i messaggi inviati dal modulo di contatto.</li>
  <li>Autorità pubbliche, quando la comunicazione sia imposta da una norma di legge o da un
    provvedimento dell'autorità.</li>
</ul>

<h2>6. Trasferimenti fuori dallo Spazio economico europeo</h2>

<p>
  Il trattamento avviene di regola all'interno dell'Unione Europea. La verifica degli acquisti
  comporta un'interrogazione ai sistemi di Google o di Apple, che possono trattare dati anche
  negli Stati Uniti: tale trasferimento avviene sulla base della decisione di adeguatezza della Commissione
  europea relativa al quadro UE-USA per la protezione dei dati, e in via residuale sulla base
  delle clausole contrattuali tipo adottate dalla Commissione.
</p>

<h2>7. Processi decisionali automatizzati</h2>

<p>
  Non effettuiamo profilazione né processi decisionali automatizzati che producano effetti
  giuridici su di te o incidano in modo analogamente significativo sulla tua persona, ai sensi
  dell'art. 22 del Regolamento.
</p>

<h2>8. I tuoi diritti</h2>

<p>Nei limiti previsti dagli articoli da 15 a 22 del Regolamento hai diritto di:</p>

<ul>
  <li>sapere se trattiamo dati che ti riguardano e ottenerne copia (accesso);</li>
  <li>far correggere dati inesatti o completare dati incompleti (rettifica);</li>
  <li>ottenere la cancellazione dei dati, quando non sussista un obbligo di conservarli;</li>
  <li>chiedere che il trattamento sia limitato, in attesa di una verifica;</li>
  <li>opporti al trattamento fondato sul legittimo interesse;</li>
  <li>ricevere i dati in formato strutturato e leggibile da dispositivo automatico (portabilità);</li>
  <li>revocare in ogni momento il consenso prestato, senza che ciò pregiudichi la liceità del
    trattamento svolto fino a quel momento.</li>
</ul>

<div class="box">
  <p>
    <strong>Un limite pratico, detto chiaramente.</strong> Sull'archivio degli acquisti non
    conserviamo dati che permettano di identificarti: se ci scrivi chiedendo l'accesso o la
    cancellazione, non siamo in grado di collegare la tua richiesta a una riga di quel registro
    senza che tu ci fornisca l'identificativo di installazione o il numero d'ordine di Google
    Play. È l'ipotesi prevista dall'art. 11 del Regolamento. Se ci fornisci tali riferimenti,
    procediamo.
  </p>
</div>

<p>
  Le richieste vanno inviate a <a href="mailto:{email}">{email}</a>. Rispondiamo senza
  ingiustificato ritardo e comunque entro un mese, prorogabile di due mesi nei casi complessi,
  dandotene notizia.
</p>

<h2>9. Reclamo all'autorità di controllo</h2>

<p>
  Se ritieni che il trattamento dei tuoi dati violi il Regolamento puoi proporre reclamo al
  <strong>Garante per la protezione dei dati personali</strong>, Piazza Venezia 11, 00187 Roma
  — <a href="https://www.garanteprivacy.it" rel="noopener">garanteprivacy.it</a> — oppure
  ricorrere all'autorità giudiziaria. Se risiedi in un altro Stato dell'Unione Europea puoi
  rivolgerti all'autorità di controllo del tuo Paese.
</p>

<h2>10. Minori</h2>

<p>
  Le app e il sito non sono rivolti specificamente ai minori e non raccolgono
  consapevolmente dati di minori di quattordici anni. Se ritieni che un minore ci abbia
  inviato dati personali attraverso il modulo di contatto, scrivici: li cancelleremo.
</p>

<h2>11. Modifiche</h2>

<p>
  Questa informativa può essere aggiornata per adeguarla a modifiche del servizio o della
  normativa. La versione vigente è sempre quella pubblicata a questo indirizzo, con la data di
  ultimo aggiornamento indicata in testa alla pagina. Le modifiche sostanziali che riguardino
  trattamenti basati sul consenso ti verranno comunicate prima di essere applicate.
</p>
HTML,

'legale.cookie.corpo' => <<<'HTML'
<h2>1. Che cosa sono i cookie</h2>

<p>
  I cookie sono piccoli file di testo che un sito salva nel browser di chi lo visita, per
  essere riletti nelle visite successive. Servono a ricordare informazioni fra una pagina e
  l'altra. La stessa disciplina si applica a tecnologie equivalenti, come il local storage del
  browser o i pixel di tracciamento.
</p>

<h2>2. I cookie di questo sito</h2>

<p>Questo sito utilizza <strong>due soli cookie</strong>, entrambi tecnici e di prima parte.</p>

<div class="scroll-x">
  <table>
    <tr>
      <th>Nome</th>
      <th>Quando viene impostato</th>
      <th>A cosa serve</th>
      <th>Durata</th>
    </tr>
    <tr>
      <td><code>ma_lang</code></td>
      <td>Su ogni pagina</td>
      <td>Ricorda se stai leggendo il sito in italiano o in inglese, così alla visita
        successiva non devi riscegliere e non vieni più reindirizzato in automatico.</td>
      <td>1 anno</td>
    </tr>
    <tr>
      <td><code>smpmicroapps</code></td>
      <td>Solo aprendo la pagina <a href="{url_contatti}">Contatti</a></td>
      <td>Collega il modulo alla sessione del browser per verificare che l'invio provenga
        davvero dal modulo di questo sito, e non da una pagina di terzi che lo invia a tua
        insaputa. Senza, il modulo sarebbe esposto agli attacchi di tipo CSRF.</td>
      <td>Fino alla chiusura del browser</td>
    </tr>
  </table>
</div>

<p>
  Si tratta in entrambi i casi di cookie tecnici: uno memorizza una preferenza espressa
  dall'utente, l'altro è strettamente necessario a erogare un servizio richiesto dall'utente.
  Ai sensi dell'art. 122 del Codice privacy e delle Linee guida del Garante del 10 giugno 2021
  <strong>non richiedono consenso preventivo</strong>, e per questo il sito non mostra alcun
  banner.
</p>

<h2>3. La scelta automatica della lingua</h2>

<p>
  Alla prima visita, finché il cookie <code>ma_lang</code> non esiste, il sito legge
  l'intestazione <code>Accept-Language</code> che il browser invia insieme a ogni richiesta e
  che riflette la lingua impostata nel sistema. Se preferisci l'inglese vieni portato alla
  versione inglese; altrimenti resti su quella italiana. L'intestazione viene letta e subito
  scartata: non viene conservata, non viene registrata e non viene usata per nient'altro.
</p>

<p>
  La scelta si cambia in qualunque momento con la bandierina in alto a destra, e da quel
  momento vale la tua e non più quella del browser.
</p>

<h2>4. Quello che questo sito non fa</h2>

<ul>
  <li>Non usa cookie di profilazione né cookie pubblicitari.</li>
  <li>Non usa strumenti di analisi statistica, di prima o di terza parte.</li>
  <li>Non carica font, fogli di stile, script o immagini da server esterni: ogni risorsa è
    servita dallo stesso dominio, quindi nessun terzo riceve il tuo indirizzo IP visitando
    queste pagine.</li>
  <li>Non incorpora video, mappe, pulsanti social o widget di altri servizi.</li>
  <li>Non traccia la navigazione fra siti diversi e non partecipa a circuiti pubblicitari.</li>
</ul>

<div class="box">
  <p>
    I link che portano fuori da questo sito, per esempio quelli alle schede dell'app su Google
    Play e su App Store, conducono a pagine gestite da altri soggetti, che applicano le proprie politiche sui
    cookie. Una volta uscito da qui, valgono le loro regole.
  </p>
</div>

<h2>5. Le applicazioni</h2>

<p>
  Le app SMP MicroApps non sono pagine web e non usano cookie. Le preferenze dell'app sono
  salvate nella memoria locale del dispositivo e non sono leggibili da nessun altro programma
  né da noi.
</p>

<h2>6. Come gestire i cookie dal browser</h2>

<p>
  Ogni browser permette di visualizzare, bloccare o cancellare i cookie dalle proprie
  impostazioni di privacy. Bloccando i cookie tecnici di questo sito le pagine restano
  leggibili, ma succedono due cose: la lingua scelta non viene ricordata fra una visita e
  l'altra, e <strong>il modulo di contatto smette di funzionare</strong>, perché senza il
  cookie di sessione il controllo anti-CSRF non può riuscire e l'invio viene rifiutato. In quel
  caso puoi scrivere direttamente a <a href="mailto:{email}">{email}</a>.
</p>

<h2>7. Titolare</h2>

<p>
  {denominazione}, {indirizzo}, {cap} {citta} ({provincia}) — P. IVA e C.F. {piva}. Per
  informazioni: <a href="mailto:{email}">{email}</a>. Vedi anche l'<a href="{url_privacy}">informativa
  privacy</a>.
</p>
HTML,

'legale.termini.corpo' => <<<'HTML'
<h2>1. Chi siamo e a cosa si applicano queste condizioni</h2>

<p>
  Le presenti condizioni regolano l'uso del sito {sito} e delle applicazioni per Android e
  iPhone distribuite con il marchio SMP MicroApps da <strong>{denominazione}</strong>, {indirizzo},
  {cap} {citta} ({provincia}), P. IVA e C.F. {piva} (di seguito «il fornitore»).
</p>

<p>
  Usando il sito o le applicazioni accetti queste condizioni. Se non le accetti, non usare il
  servizio e disinstalla l'applicazione.
</p>

<h2>2. Il sito non vende nulla</h2>

<p>
  Questo sito ha funzione esclusivamente informativa. Le applicazioni si scaricano e si
  acquistano su <strong>Google Play</strong> o su <strong>App Store</strong>, e il contratto di
  acquisto si conclude fra te e <strong>Google Ireland Limited</strong> o <strong>Apple
  Distribution International Ltd</strong>, che agiscono come rivenditori. Il fornitore non incassa
  direttamente il prezzo, non emette la ricevuta d'acquisto e non ha accesso ai tuoi dati di
  pagamento.
</p>

<div class="box">
  <p>
    Di conseguenza <strong>rimborsi, storni e diritto di recesso sull'acquisto si richiedono
    allo store da cui hai acquistato</strong>: a Google Play secondo le procedure di Google, ad
    App Store secondo quelle di Apple (reportaproblem.apple.com). Se hai un problema che lo
    store non risolve, scrivici lo stesso: possiamo intervenire sul piano tecnico
    e, dove ci è consentito, sollecitare la pratica.
  </p>
</div>

<h2>3. Licenza d'uso del software</h2>

<p>
  Le applicazioni non ti vengono vendute: ti viene concessa una licenza d'uso
  <strong>personale, non esclusiva, non trasferibile e non sublicenziabile</strong>, valida per
  un tempo indeterminato, per installarle e usarle sui dispositivi che ti appartengono o che
  sono sotto il tuo controllo.
</p>

<p>L'acquisto della versione Pro sblocca funzioni aggiuntive dell'applicazione. È:</p>

<ul>
  <li><strong>un acquisto singolo</strong>, non un abbonamento: non si rinnova e non scade;</li>
  <li><strong>legato al tuo account Google Play o al tuo ID Apple</strong>, non al singolo
    telefono: cambiando dispositivo puoi ripristinarlo dal medesimo account. Un acquisto fatto
    su Google Play non vale su iPhone, e viceversa: sono due store distinti;</li>
  <li><strong>riferito alla singola applicazione</strong>: l'acquisto di un'app non sblocca le
    altre del catalogo.</li>
</ul>

<p>Non è consentito:</p>

<ul>
  <li>decompilare, disassemblare o tentare di ricavare il codice sorgente, salvo nei limiti
    inderogabili dell'art. 64-quater della legge 633/1941;</li>
  <li>modificare l'applicazione, o distribuirne versioni derivate o modificate;</li>
  <li>rivendere, noleggiare, prestare o cedere la licenza a terzi;</li>
  <li>aggirare le limitazioni della versione gratuita o i controlli sulla licenza, né diffondere
    strumenti o istruzioni che consentano ad altri di farlo;</li>
  <li>usare le applicazioni per scopi illeciti o in violazione di diritti altrui.</li>
</ul>

<h2>4. Il codice di trasferimento</h2>

<p>
  Per i casi in cui non sia possibile il ripristino tramite Google Play — tipicamente il cambio
  di account Google — le applicazioni per Android offrono un codice temporaneo per spostare la licenza su un
  altro dispositivo. È uno strumento di assistenza, soggetto a limiti di validità, di numero e di
  frequenza. L'uso del codice per condividere la licenza con terzi costituisce violazione del
  punto 3 e consente al fornitore di revocare la licenza.
</p>

<h2>5. Aggiornamenti e continuità del servizio</h2>

<p>
  Il fornitore può aggiornare le applicazioni per correggere difetti, adeguarsi a nuove versioni
  di Android e di iOS o migliorarne il funzionamento. Può altresì modificare, sospendere o cessare la
  distribuzione di un'applicazione, dandone preavviso quando ragionevolmente possibile.
</p>

<p>
  Le applicazioni funzionano <strong>senza connessione a internet</strong> per tutte le loro
  funzioni principali: l'eventuale cessazione dei servizi online del fornitore non impedisce di
  continuare a usare l'app già installata e già sbloccata. La verifica della licenza serve ad
  attivare la versione Pro, non a farla funzionare ogni giorno.
</p>

<h2>6. Garanzia legale di conformità</h2>

<p>
  Nei confronti dei consumatori resta ferma la garanzia legale di conformità del contenuto
  digitale prevista dagli articoli 135-octies e seguenti del Codice del consumo (d.lgs.
  206/2005). Se l'applicazione non è conforme a quanto descritto, hai diritto al ripristino della
  conformità e, nei casi previsti, alla riduzione del prezzo o alla risoluzione del contratto,
  secondo le procedure dello store da cui hai acquistato. Nessuna clausola di queste condizioni limita tali diritti.
</p>

<h2>7. Responsabilità</h2>

<p>
  Il fornitore risponde secondo la legge dei danni cagionati da dolo o colpa grave e in tutti i
  casi in cui la legge non ammette limitazioni. Per il resto vale quanto indicato nella
  <a href="{url_responsabilita}">limitazione di responsabilità</a>, che costituisce parte
  integrante di queste condizioni.
</p>

<h2>8. Dati personali</h2>

<p>
  Il trattamento dei dati personali è descritto nell'<a href="{url_privacy}">informativa
  privacy</a>. Le applicazioni conservano i dati che inserisci nella memoria del tuo
  dispositivo: <strong>il backup è una tua responsabilità</strong>, e le app mettono a
  disposizione una funzione di esportazione proprio per questo.
</p>

<h2>9. Assistenza</h2>

<p>
  L'assistenza si richiede dal <a href="{url_contatti}">modulo di contatto</a> o scrivendo a
  <a href="mailto:{email}">{email}</a>. Non sono previsti tempi di risposta contrattualmente
  garantiti; l'obiettivo dichiarato è rispondere entro due giorni lavorativi.
</p>

<h2>10. Modifiche alle condizioni</h2>

<p>
  Queste condizioni possono essere modificate. La versione vigente è quella pubblicata a questo
  indirizzo, con la data di ultimo aggiornamento in testa alla pagina. Le modifiche non si
  applicano retroattivamente agli acquisti già effettuati, quando ne alterino in senso
  sfavorevole il contenuto essenziale.
</p>

<h2>11. Legge applicabile, foro e risoluzione delle controversie</h2>

<p>
  Si applica la legge italiana. Per i consumatori è competente il foro del luogo di residenza o
  domicilio; negli altri casi è competente in via esclusiva il Foro di Viterbo.
</p>

<p>
  Il consumatore può inoltre ricorrere alla piattaforma europea di risoluzione delle controversie
  online, disponibile all'indirizzo
  <a href="https://ec.europa.eu/consumers/odr" rel="noopener">ec.europa.eu/consumers/odr</a>, o
  agli organismi di mediazione competenti.
</p>
HTML,

'legale.responsabilita.corpo' => <<<'HTML'
<h2>1. Le informazioni delle app dipendono da te e dal tuo Comune</h2>

<p>
  Le applicazioni elaborano i dati che <strong>inserisci tu</strong>. Nel caso di TrashCan, il
  calendario della raccolta differenziata non viene scaricato da nessun archivio ufficiale: lo
  configuri tu sulla base di quanto comunicato dal tuo Comune o dal gestore del servizio di
  igiene urbana.
</p>

<div class="box">
  <p>
    <strong>Ne consegue che l'applicazione non può garantire che la raccolta avvenga nei giorni
    indicati.</strong> Calendari, festività, sospensioni e variazioni straordinarie sono decisi
    dall'ente competente e possono cambiare senza preavviso. In caso di dubbio fa fede sempre e
    solo la comunicazione ufficiale del Comune o del gestore. Il fornitore non risponde di
    sanzioni, disguidi o mancati ritiri derivanti da un calendario configurato in modo non
    aggiornato o non corretto.
  </p>
</div>

<h2>2. Le notifiche dipendono dal sistema operativo</h2>

<p>
  I promemoria sono pianificati attraverso i servizi di notifica di Android e di iOS. La loro consegna
  puntuale non è garantita dall'applicazione e può essere impedita o ritardata da fattori che
  l'app non controlla: risparmio energetico, ottimizzazione della batteria, modalità «non
  disturbare», sospensione dell'app da parte del sistema, riavvii del dispositivo,
  personalizzazioni del produttore o revoca dei permessi.
</p>

<p>
  <strong>Il promemoria è un aiuto, non un sistema di allerta affidabile.</strong> Non va
  utilizzato per scopi in cui un avviso mancato produca conseguenze rilevanti.
</p>

<h2>3. I dati stanno sul tuo dispositivo</h2>

<p>
  Tutto ciò che inserisci è salvato nella memoria del telefono. Non ne conserviamo copia e non
  possiamo recuperarlo per te. Perdita o rottura del dispositivo, disinstallazione dell'app,
  cancellazione dei dati dell'applicazione o ripristino di fabbrica comportano la
  <strong>perdita definitiva</strong> di quanto inserito.
</p>

<p>
  Le applicazioni offrono una funzione di esportazione proprio per questo. Effettuare copie di
  sicurezza e conservarle è responsabilità dell'utente.
</p>

<h2>4. Assenza di difetti</h2>

<p>
  Il software viene sviluppato e collaudato con la diligenza professionale esigibile, ma nessun
  programma è esente da difetti. Le applicazioni sono fornite «così come sono» per quanto riguarda
  l'idoneità a scopi particolari non espressamente dichiarati, ferma restando la garanzia legale
  di conformità spettante ai consumatori, richiamata al punto 6 delle
  <a href="{url_termini}">condizioni di servizio</a>.
</p>

<h2>5. Contenuti del sito e collegamenti esterni</h2>

<p>
  I contenuti di questo sito hanno finalità informativa e possono essere aggiornati o modificati
  in qualunque momento. Le descrizioni delle funzioni si riferiscono alla versione più recente
  delle applicazioni: una versione precedente installata sul tuo dispositivo può comportarsi
  diversamente.
</p>

<p>
  I collegamenti verso siti di terzi sono forniti per comodità. Il fornitore non controlla tali
  siti e non risponde dei loro contenuti, della loro disponibilità né delle politiche che vi si
  applicano.
</p>

<h2>6. Limiti della limitazione</h2>

<p>Nulla di quanto scritto sopra esclude o limita la responsabilità del fornitore:</p>

<ul>
  <li>per dolo o colpa grave, ai sensi dell'art. 1229 del codice civile;</li>
  <li>per morte o lesioni personali cagionate da un suo comportamento;</li>
  <li>nei casi in cui la legge, in particolare la normativa a tutela dei consumatori, non ammette
    esclusioni o limitazioni;</li>
  <li>per la garanzia legale di conformità dovuta al consumatore.</li>
</ul>

<p>
  Ove una clausola di questa pagina risultasse nulla o inefficace, le restanti conservano piena
  validità.
</p>

<h2>7. Contatti</h2>

<p>
  Per qualunque chiarimento: <a href="mailto:{email}">{email}</a> — {denominazione},
  {indirizzo}, {cap} {citta} ({provincia}).
</p>
HTML,

];

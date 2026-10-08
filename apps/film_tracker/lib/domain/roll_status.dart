import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

/// La macchina a stati del rullino (develop_microapps.md F6.3). Dart puro.
///
/// ⚑ **Serve a guidare la UI, non a punire l'utente**: `FilmRepository.setRollStatus` rifiuta
/// le transizioni non ammesse, ma accetta `force: true`, perche' la realta' e' piu'
/// disordinata del modello (un rullino ritrovato in un cassetto, un laboratorio che sviluppa
/// e stampa in un colpo solo).

/// Lo stato di un rullino (`film_rolls.status`).
enum RollStatus {
  /// In macchina, si sta scattando.
  loaded('loaded'),

  /// Finito di scattare, ancora da consegnare.
  exposed('exposed'),

  /// Consegnato al laboratorio.
  sentForDevelopment('sentForDevelopment'),

  /// Negativi (o diapositive) tornati.
  developed('developed'),

  /// Stampe tornate.
  printed('printed'),

  /// Chiuso dall'utente.
  archived('archived');

  const RollStatus(this.key);

  /// Valore stabile salvato nel database. **Non si rinomina mai.**
  final String key;

  static RollStatus? byKey(String? key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

/// Le tre sezioni della home (F6.8).
enum RollSection { inCamera, atLab, archive }

/// Un evento di laboratorio ridotto a quello che serve a [RollStatusMachine.suggestFrom]:
/// le date e, per lo sviluppo, se e' fatto in casa.
///
/// ⚑ Non e' la riga di Drift (`Development`, `PrintOrder`): il dominio non dipende dal
/// database. La conversione e' `toLabEvent()` in `lib/data/database.dart`.
@immutable
class LabEvent {
  const LabEvent({this.submittedAt, this.returnedAt, this.selfDeveloped = false});

  final CivilDate? submittedAt;
  final CivilDate? returnedAt;

  /// Sviluppo in casa (`developments.selfDeveloped`). Sempre false per le stampe.
  final bool selfDeveloped;

  /// Il risultato e' in mano all'utente.
  ///
  /// ⚑ Uno sviluppo **in casa** e' concluso per definizione, con o senza date: lo si
  /// registra dopo averlo fatto, e non e' mai "in laboratorio".
  bool get isReturned => returnedAt != null || selfDeveloped;

  @override
  bool operator ==(Object other) =>
      other is LabEvent &&
      other.submittedAt == submittedAt &&
      other.returnedAt == returnedAt &&
      other.selfDeveloped == selfDeveloped;

  @override
  int get hashCode => Object.hash(submittedAt, returnedAt, selfDeveloped);

  @override
  String toString() => 'LabEvent($submittedAt -> $returnedAt${selfDeveloped ? ', in casa' : ''})';
}

/// Le transizioni ammesse, il suggerimento dello stato dagli eventi e la sezione della home.
///
/// ⚑ Rispetto alla firma del piano (F6.3) mancano due cose, **di proposito**:
/// - `labelFor`: niente stringhe nel dominio, l'etichetta la risolve la UI dagli ARB con
///   [RollStatus.key] (come `fuelName` in Scorte Calore);
/// - le righe Drift come parametri di [suggestFrom]: riceve [LabEvent] e i due campi del
///   rullino che servono, cosi' si prova con valori scritti a mano.
class RollStatusMachine {
  const RollStatusMachine();

  /// Da ciascuno stato, gli stati raggiungibili. Lo stesso stato non e' una transizione.
  ///
  /// ⚑ `printed -> developed` e `archived -> developed/printed` sono ammesse: la stampa e'
  /// un evento separato e ripetibile, e un rullino ristampato mesi dopo non deve restare
  /// bloccato in uno stato terminale (F6.3). `sentForDevelopment -> exposed` annulla una
  /// consegna segnata per sbaglio.
  static const Map<RollStatus, Set<RollStatus>> allowedTransitions = {
    RollStatus.loaded: {RollStatus.exposed, RollStatus.archived},
    RollStatus.exposed: {RollStatus.sentForDevelopment, RollStatus.developed, RollStatus.archived},
    RollStatus.sentForDevelopment: {RollStatus.developed, RollStatus.exposed, RollStatus.archived},
    RollStatus.developed: {RollStatus.printed, RollStatus.archived},
    RollStatus.printed: {RollStatus.archived, RollStatus.developed},
    RollStatus.archived: {RollStatus.developed, RollStatus.printed},
  };

  bool canTransition(RollStatus from, RollStatus to) =>
      allowedTransitions[from]?.contains(to) ?? false;

  /// Lo stato che gli eventi registrati **suggeriscono**. Non lo impone: la UI propone il
  /// cambio solo se e' diverso da [current] (e di solito se [canTransition] lo ammette).
  ///
  /// Regole, nell'ordine (vince la prima che si applica):
  /// 1. [current] `archived` resta `archived`: l'archiviazione e' una scelta esplicita
  ///    dell'utente, e uno sviluppo registrato dopo non deve riproporre di toglierla;
  /// 2. una stampa con `returnedAt` -> `printed`;
  /// 3. uno sviluppo tornato ([LabEvent.isReturned]: con `returnedAt`, o fatto in casa) ->
  ///    `developed`;
  /// 4. uno sviluppo registrato e non tornato -> `sentForDevelopment` (con o senza
  ///    `submittedAt`: averlo registrato vuol dire averlo consegnato);
  /// 5. nessun evento: `loaded` con [finishedAt] -> `exposed`; altrimenti [current]. ⚑ Senza
  ///    eventi non si suggerisce mai di tornare indietro: uno stato messo a mano resta.
  ///
  /// Una stampa consegnata e non tornata non sposta nulla: il rullino resta `developed`.
  RollStatus suggestFrom({
    required RollStatus current,
    CivilDate? finishedAt,
    LabEvent? development,
    List<LabEvent> prints = const [],
  }) {
    if (current == RollStatus.archived) return RollStatus.archived;
    if (prints.any((p) => p.returnedAt != null)) return RollStatus.printed;
    if (development != null) {
      return development.isReturned ? RollStatus.developed : RollStatus.sentForDevelopment;
    }
    if (current == RollStatus.loaded && finishedAt != null) return RollStatus.exposed;
    return current;
  }

  /// `loaded`/`exposed` -> In macchina; `sentForDevelopment` -> In laboratorio;
  /// `developed`/`printed`/`archived` -> Archivio (F6.3).
  RollSection sectionFor(RollStatus status) => switch (status) {
    RollStatus.loaded || RollStatus.exposed => RollSection.inCamera,
    RollStatus.sentForDevelopment => RollSection.atLab,
    RollStatus.developed || RollStatus.printed || RollStatus.archived => RollSection.archive,
  };

  /// Gli stati che cadono nella sezione [section]: l'inverso di [sectionFor], per le query.
  Set<RollStatus> statusesIn(RollSection section) => {
    for (final s in RollStatus.values)
      if (sectionFor(s) == section) s,
  };
}

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../domain/aging.dart';

/// Il piano delle notifiche di Full Freezer, **calcolato senza toccare il sistema**
/// (develop_microapps.md F4.9). Chi lo consegna ad Android e iOS e' `FreezerScheduler`.

/// Ogni quanto arriva il riepilogo.
enum DigestFrequency { weekly, biweekly, monthly }

/// L'ora del riepilogo e il giorno: la domenica alle 18, quando si pensa alla settimana.
const int digestHour = 18;
const int digestWeekday = DateTime.sunday;

/// L'ora dell'avviso "quasi vuoto": il sabato mattina, quando si pianifica la spesa.
const int emptyAlertHour = 10;
const int emptyAlertWeekday = DateTime.saturday;

/// Le prossime date del riepilogo, da [today] in avanti (compreso, se e' il giorno giusto:
/// chi apre l'app la domenica alle 9 riceve il riepilogo delle 18).
///
/// ⚑ Abbastanza da coprire circa due mesi: l'app ripianifica a ogni apertura e a ogni
/// modifica, ma chi non la apre per un mese deve ricevere lo stesso i suoi riepiloghi.
List<CivilDate> digestDates(CivilDate today, DigestFrequency frequency) {
  var first = today;
  while (first.weekday != digestWeekday) {
    first = first.addDays(1);
  }
  final (step, count) = switch (frequency) {
    DigestFrequency.weekly => (7, 8),
    DigestFrequency.biweekly => (14, 4),
    DigestFrequency.monthly => (28, 3),
  };
  return [for (var i = 0; i < count; i++) first.addDays(step * i)];
}

/// Quello che il riepilogo di un giorno deve dire.
@immutable
class DigestContent {
  const DigestContent({required this.oldCount, required this.oldest, required this.oldestDays});

  /// Quanti alimenti avranno superato il promemoria quel giorno.
  final int oldCount;

  /// Il piu' vecchio fra quelli (il nome) e i suoi giorni quel giorno.
  final String oldest;
  final int oldestDays;
}

/// Il contenuto del riepilogo per il giorno [on], o null se quel giorno non ci sara' niente
/// da dire (allora la notifica non si pianifica: develop_microapps.md F4.9, "se non ci sono
/// prodotti in stato old, la notifica non viene mostrata").
///
/// ☠ **Il testo si calcola per il giorno della consegna, non per oggi.** Il plugin non puo'
/// calcolare niente al momento della consegna: il testo e' fissato quando si pianifica. Il
/// riepilogo di fra tre settimane deve quindi contare gli alimenti che **fra tre settimane**
/// avranno superato il promemoria, con i giorni di allora. Con il conteggio di oggi, il
/// terzo riepilogo direbbe "137 giorni" invece di 158, e mancherebbe tutto quello che nel
/// frattempo e' invecchiato. Resta impreciso solo per cio' che l'utente consuma o aggiunge
/// nel frattempo, ed e' per questo che si ripianifica a ogni modifica.
DigestContent? digestFor(Iterable<Item> stored, CivilDate on, {AgingCalculator aging = const AgingCalculator()}) {
  Item? oldest;
  var oldestDays = -1;
  var count = 0;
  for (final item in stored) {
    final info = aging.evaluate(
      frozenAt: CivilDate.parse(item.frozenAt),
      reminderAfterDays: item.reminderAfterDays,
      categoryKey: item.category,
      today: on,
    );
    if (info.level != AgingLevel.old) continue;
    count++;
    if (info.days > oldestDays) {
      oldestDays = info.days;
      oldest = item;
    }
  }
  if (oldest == null) return null;
  return DigestContent(oldCount: count, oldest: oldest.name, oldestDays: oldestDays);
}

/// Quando consegnare un avviso di capienza scattato in [now].
///
/// - **quasi pieno**: subito (pochi secondi dopo: il tempo di uscire dall'app), perche'
///   serve adesso, mentre si sta per congelare altro;
/// - **quasi vuoto**: il sabato successivo alle 10. Arrivare mentre si toglie l'ultima cosa
///   non serve a niente; arrivare quando si pianifica la spesa si' (F4.9).
DateTime alertTime({required bool full, required DateTime now}) {
  if (full) return now.add(const Duration(seconds: 10));
  var day = DateTime(now.year, now.month, now.day, emptyAlertHour);
  while (day.weekday != emptyAlertWeekday || !day.isAfter(now)) {
    day = day.add(const Duration(days: 1));
    day = DateTime(day.year, day.month, day.day, emptyAlertHour);
  }
  return day;
}

/// Un avviso di capienza in attesa, conservato nelle preferenze finche' non e' passato.
///
/// ⚑ Perche' conservarlo: `NotificationService.replaceSchedule` cancella tutto cio' che non
/// e' nel piano. Un avviso "quasi vuoto" pianificato per sabato verrebbe cancellato dalla
/// prima ripianificazione dei riepiloghi; tenendolo qui, ogni ripianificazione lo rimette
/// nel piano finche' la sua ora non e' passata.
@immutable
class PendingAlert {
  const PendingAlert({required this.freezerId, required this.full, required this.when});

  final int freezerId;
  final bool full;
  final DateTime when;

  String encode() => '$freezerId|${full ? 'full' : 'empty'}|${when.millisecondsSinceEpoch}';

  static PendingAlert? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final id = int.tryParse(parts[0]);
    final ms = int.tryParse(parts[2]);
    if (id == null || ms == null) return null;
    return PendingAlert(freezerId: id, full: parts[1] == 'full', when: DateTime.fromMillisecondsSinceEpoch(ms));
  }

  /// Id stabile: lo stesso avviso ripianificato sovrascrive se stesso invece di duplicarsi.
  int get notificationId =>
      NotificationIds.forOccurrence(freezerId, CivilDate.fromDateTime(when), full ? 1 : 2);
}

/// L'id del riepilogo del giorno [on]: stabile, per lo stesso motivo.
int digestId(CivilDate on) => NotificationIds.forOccurrence(0, on, 9);

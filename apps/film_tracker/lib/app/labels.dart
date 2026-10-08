import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/film_types.dart';
import '../domain/roll_status.dart';
import '../l10n/generated/app_localizations.dart';

/// I nomi visibili di stati, formati e processi, dagli ARB; date e importi come li legge una
/// persona.
///
/// ⚑ Il dominio (`lib/domain/`) conosce solo le chiavi stabili: i nomi stanno qui perche'
/// cambiano con la lingua, e il dominio deve restare Dart puro e testabile senza Flutter
/// (stesso schema di `fuelName` in Scorte Calore). Gli switch sono esaustivi di proposito:
/// un valore nuovo in un enum non compila finche' non ha la sua etichetta.

/// Il nome dello stato del rullino ("In macchina", "In laboratorio"...).
String statusName(L l, RollStatus s) => switch (s) {
  RollStatus.loaded => l.status_loaded,
  RollStatus.exposed => l.status_exposed,
  RollStatus.sentForDevelopment => l.status_sentForDevelopment,
  RollStatus.developed => l.status_developed,
  RollStatus.printed => l.status_printed,
  RollStatus.archived => l.status_archived,
};

/// Il nome del formato ("35 mm", "120", "Grande formato").
String formatName(L l, FilmFormat f) => switch (f) {
  FilmFormat.mm35 => l.roll_format_mm35,
  FilmFormat.medium120 => l.roll_format_medium120,
  FilmFormat.mm110 => l.roll_format_mm110,
  FilmFormat.large => l.roll_format_large,
  FilmFormat.other => l.roll_format_other,
};

/// Il nome del processo di sviluppo ("C-41", "Bianco e nero").
String processName(L l, FilmProcess p) => switch (p) {
  FilmProcess.c41 => l.roll_process_c41,
  FilmProcess.e6 => l.roll_process_e6,
  FilmProcess.bw => l.roll_process_bw,
  FilmProcess.ecn2 => l.roll_process_ecn2,
  FilmProcess.other => l.roll_process_other,
};

/// Una data per esteso e corta: "8 ott 2026" / "Oct 8, 2026".
String formatDay(L l, CivilDate d) => DateFormat.yMMMd(l.localeName).format(d.toLocalMidnight());

/// Un mese con l'anno: "ott 2026" / "Oct 2026".
String formatMonth(L l, CivilDate d) => DateFormat.yMMM(l.localeName).format(d.toLocalMidnight());

/// Il periodo di un rullino: dal caricamento alla fine ("set 2026", "set 2026 – ott 2026").
/// Null se non c'e' nessuna data.
String? formatPeriod(L l, CivilDate? from, CivilDate? to) {
  if (from == null && to == null) return null;
  final a = from == null ? null : formatMonth(l, from);
  final b = to == null ? null : formatMonth(l, to);
  if (a == null) return b;
  if (b == null || a == b) return a;
  return '$a – $b';
}

/// Un importo in centesimi con il simbolo, nella lingua dell'app ("8,50 €").
String formatCents(L l, int cents) => Money.cents(cents).format(locale: l.localeName);

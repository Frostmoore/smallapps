import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import 'scorte_widget.dart';

/// Tiene il widget allineato ai dati: si ricostruisce quando cambiano le fonti o una stima, e
/// a ogni ricostruzione ripubblica. Lo tiene vivo `app.dart` con un `ref.watch`.
///
/// ⚑ Un provider e non una chiamata in ogni schermata che salva: le misure si scrivono da
/// piu' punti (foglio di aggiornamento, storico, ripristino di un backup) e chi scrive
/// domani una pagina nuova non deve ricordarsi del widget.
final widgetSyncProvider = Provider<void>((ref) {
  final sources = ref.watch(sourcesProvider).value;
  if (sources == null) return;
  final hero = ref.watch(heroSourceProvider);
  // La fonte in testata nell'app e' la prima anche nel widget (il piccolo mostra solo quella).
  final ordinate = [if (hero != null) hero, for (final s in sources) if (s.id != hero?.id) s];
  final stime = {for (final s in ordinate) s.id: ref.watch(estimateProvider(s.id))};
  unawaited(
    ScorteWidget.publish(
      sources: ordinate,
      estimateOf: (id) => stime[id],
      formatShortDate: (d, locale) => DateFormat.MMMd(locale).format(d.toLocalMidnight()),
    ),
  );
});

/// Una volta per avvio: i ridisegni delle 00:05 su Android.
final widgetRefreshProvider = Provider<void>((ref) {
  unawaited(ScorteWidget.scheduleDailyRefresh());
});

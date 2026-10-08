import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../app/locale_resolution.dart';
import '../data/database.dart';
import '../domain/consumption.dart';
import '../l10n/generated/app_localizations.dart';

/// Il widget della schermata iniziale (develop_microapps.md F5.0 punto 3): per ogni fonte
/// attiva, i giorni di autonomia e la data di riordino. Gratuito (ADR-019).
///
/// ⚑ **ADR-018, come in Full Freezer**: il payload porta la **data di esaurimento** e la data
/// di riordino, non "N giorni". I giorni li conta il widget (provider Kotlin con
/// `LocalDate.now()`, timeline di WidgetKit), cosi' scendono ogni notte anche se l'app non
/// viene aperta. La data di esaurimento parte dall'ultima misura (`ConsumptionCalculator`),
/// quindi senza misure nuove non slitta in avanti.
///
/// ☠ Un widget Android non puo' usare Flutter per disegnarsi: qui si preparano solo testi,
/// il disegno lo fa un layout XML (`RemoteViews`) su Android e SwiftUI su iOS.
abstract final class ScorteWidget {
  /// `true` dove il widget esiste: Android e iOS. Sul desktop dei test il canale solleva.
  static bool get available =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// ☠ Ripetuto in tre posti che devono restare uguali: qui, `ios/Runner/Runner.entitlements`
  /// e `ios/ScorteCaloreWidget/ScorteCaloreWidget.entitlements`.
  static const String iosGroup = 'group.com.smp.scortecalore';

  /// Il `kind` dichiarato in `ios/ScorteCaloreWidget/ScorteCaloreWidget.swift`.
  static const String iosName = 'ScorteCaloreWidget';

  /// La classe Kotlin **con il package** (con il solo nome il plugin la cerca sotto
  /// l'applicationId e non la trova con un suffisso di debug: lezione di TrashCan).
  static const String androidName = 'com.smp.scortecalore.ScorteCaloreWidgetProvider';

  // Le chiavi devono coincidere con ScorteCaloreWidgetProvider.kt e ScorteCaloreWidget.swift.
  static const String keyTitle = 'title';
  static const String keyRows = 'rows';
  static const String keyToday = 'days_today';
  static const String keyDaysTemplate = 'days_template';
  static const String keyReorderTemplate = 'reorder_template';
  static const String keyReorderNow = 'reorder_now';
  static const String keyNeedMore = 'need_more';
  static const String keyEmpty = 'empty';

  /// Separatore fra i campi di una riga: `US`, che nessuna tastiera produce (un nome come
  /// "Stufa | sala" spezzerebbe le colonne con `|`).
  static const String fieldSeparator = '\u001F';

  /// Il segnaposto del numero e della data nei modelli di testo.
  static const String countPlaceholder = '{n}';
  static const String datePlaceholder = '{d}';

  /// Quante fonti mostra il widget al massimo (il medio ne mostra tre, il piccolo una).
  static const int rowCount = 3;

  /// Una riga: `nome US esaurimento US riordino US riordinoBreve`, con le date `AAAA-MM-GG`
  /// vuote se la stima non c'e' (servono altre misure). `riordinoBreve` e' la data di
  /// riordino gia' scritta nella lingua dell'app ("1 dic"): formattarla in Kotlin e Swift
  /// vorrebbe dire rifare la localizzazione in tre linguaggi. Pura, per i test.
  @visibleForTesting
  static String buildRow({required String name, required ConsumptionEstimate? estimate, required String reorderShort}) {
    final pronta = estimate != null && estimate.isActionable && estimate.depletionDate != null;
    return [
      name.replaceAll('\n', ' '),
      pronta ? estimate.depletionDate!.toIso() : '',
      pronta && estimate.reorderDate != null ? estimate.reorderDate!.toIso() : '',
      pronta ? reorderShort : '',
    ].join(fieldSeparator);
  }

  /// Il modello di un testo con un numero, ricavato dal testo dell'app con un numero
  /// sentinella: il widget dice i giorni esattamente come l'app (stesso metodo di Full Freezer).
  @visibleForTesting
  static String daysTemplate(L l) => l.home_daysWord(987654) == l.home_daysWord(2)
      ? '$countPlaceholder ${l.home_daysWord(2)}'
      : '$countPlaceholder ${l.home_daysWord(987654)}';

  /// Ricalcola il contenuto e lo consegna al sistema. Gira all'avvio e a ogni modifica.
  static Future<void> publish({
    required List<FuelSource> sources,
    required ConsumptionEstimate? Function(int sourceId) estimateOf,
    required String Function(CivilDate date, String localeName) formatShortDate,
  }) async {
    if (!available) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) await HomeWidget.setAppGroupId(iosGroup);
      final l = lookupL(resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales, kSupportedLocales));
      final rows = <String>[
        for (final s in sources.take(rowCount))
          if (estimateOf(s.id) case final e)
            buildRow(
              name: s.name,
              estimate: e,
              reorderShort: e?.reorderDate == null ? '' : formatShortDate(e!.reorderDate!, l.localeName),
            ),
      ];
      await HomeWidget.saveWidgetData<String>(keyTitle, l.widget_title);
      await HomeWidget.saveWidgetData<String>(keyToday, l.widget_runsOutToday);
      await HomeWidget.saveWidgetData<String>(keyDaysTemplate, daysTemplate(l));
      await HomeWidget.saveWidgetData<String>(keyReorderTemplate, l.widget_reorderBy(datePlaceholder));
      await HomeWidget.saveWidgetData<String>(keyReorderNow, l.widget_reorderNow);
      await HomeWidget.saveWidgetData<String>(keyNeedMore, l.widget_needMore);
      await HomeWidget.saveWidgetData<String>(keyEmpty, l.widget_empty);
      await HomeWidget.saveWidgetData<String>(keyRows, rows.join('\n'));
      await HomeWidget.updateWidget(qualifiedAndroidName: androidName, iOSName: iosName);
    } on Object catch (error) {
      // Il widget non deve mai far fallire un salvataggio o l'avvio.
      MicroLog.d('widget non aggiornato: $error');
    }
  }

  /// Ridisegno quotidiano poco dopo mezzanotte. **Solo Android**: i giorni li conta il
  /// provider, ma solo quando il sistema gli chiede di ridisegnare. ☠ Senza
  /// `HomeWidgetScheduledUpdateReceiver` nel manifest l'allarme non arriva a nessuno.
  /// Su iOS non serve: la timeline ha una voce per ciascuno dei prossimi giorni.
  static Future<void> scheduleDailyRefresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final now = DateTime.now();
    final times = <DateTime>[for (var d = 1; d <= 365; d++) DateTime(now.year, now.month, now.day + d, 0, 5)];
    try {
      await HomeWidget.scheduleWidgetUpdates(times, qualifiedAndroidName: androidName);
    } on Object catch (error) {
      MicroLog.d('aggiornamenti del widget non programmati: $error');
    }
  }
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../app/category_glyphs.dart';
import '../app/locale_resolution.dart';
import '../data/database.dart';
import '../domain/aging.dart';
import '../domain/categories.dart';
import '../l10n/generated/app_localizations.dart';

/// Il widget della schermata iniziale (develop_microapps.md F4.11): i tre alimenti che
/// stanno nel freezer da piu' tempo, con i giorni, e quanti ce ne sono in tutto.
///
/// ⚑ **ADR-018 applicato all'anzianita'.** I giorni cambiano a mezzanotte anche se nessuno
/// apre l'app, e Dart gira solo con l'app aperta. Quindi il payload **non contiene "N
/// giorni"**: contiene la data di congelamento di ogni riga, e i giorni li calcola il widget
/// (il provider Kotlin con `LocalDate.now()`, l'estensione iOS nella sua timeline). Cosi' il
/// numero non invecchia mai.
///
/// ⚑ **Perche' "i piu' vecchi" e non "da usare presto" della home.** "Da usare presto"
/// dipende dalla data di oggi (un alimento ci entra il giorno in cui supera il promemoria),
/// quindi andrebbe ricalcolato ogni notte, e a calcolarlo dovrebbe essere il widget. L'ordine
/// per data di congelamento invece **non cambia mai col passare dei giorni**: i tre piu'
/// vecchi di oggi sono i tre piu' vecchi di domani finche' qualcuno non tocca i dati, e
/// toccare i dati vuol dire aprire l'app, che ripubblica. Il colore "vecchio" (arancione) lo
/// decide il widget confrontando i giorni con il promemoria della riga, che viaggia nel
/// payload.
///
/// ☠ **Un widget Android non puo' usare Flutter per disegnarsi** (lezione di TrashCan): qui
/// si preparano solo stringhe e PNG, il disegno lo fa un layout XML (`RemoteViews`) su
/// Android e SwiftUI su iOS.
abstract final class FreezerWidget {
  /// `true` dove il widget esiste: Android e iOS. Sul desktop dei test il canale solleva, e
  /// l'eccezione dentro un `unawaited` all'avvio nasconderebbe la prima schermata.
  static bool get available =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Il gruppo condiviso fra app ed estensione su iOS.
  ///
  /// ☠ Ripetuto in tre posti che devono restare uguali: qui, `ios/Runner/Runner.entitlements`
  /// e `ios/FullFreezerWidget/FullFreezerWidget.entitlements`. Senza il gruppo registrato
  /// sul portale Apple, `saveWidgetData` scrive in un contenitore nullo: nessun errore,
  /// widget vuoto.
  static const String iosGroup = 'group.com.smp.fullfreezer';

  /// Il `kind` dichiarato in `ios/FullFreezerWidget/FullFreezerWidget.swift`. Se divergono,
  /// l'app chiede di ricaricare un widget che non esiste, e non lo dice nessuno.
  static const String iosName = 'FullFreezerWidget';

  /// La classe Kotlin **con il package**: con il solo nome il plugin la cerca sotto
  /// l'applicationId, e con un suffisso `.debug` non la trova piu' (lezione di TrashCan).
  static const String androidName = 'com.smp.fullfreezer.FullFreezerWidgetProvider';

  // Le chiavi devono coincidere con FullFreezerWidgetProvider.kt e FullFreezerWidget.swift.
  static const String keyTitle = 'title';
  static const String keyCount = 'count';
  static const String keyEmpty = 'empty';
  static const String keyRows = 'rows';
  static const String keyToday = 'days_today';
  static const String keyDaysTemplate = 'days_template';
  static const String iconKeyPrefix = 'icon_';

  /// Separatore fra i campi di una riga: `US`, che nessuna tastiera produce. Con `|` un
  /// alimento chiamato "Pollo | cosce" sfaserebbe le colonne (lezione di TrashCan).
  static const String fieldSeparator = '\u001F';

  /// Il segnaposto del numero nel modello dei giorni ("{n} gg").
  static const String countPlaceholder = '{n}';

  /// Quante righe mostra il widget.
  static const int rowCount = 3;

  /// Il lato del PNG delle icone, in pixel: il widget lo mostra a ~20dp, e 72 px reggono
  /// anche uno schermo 3x.
  static const int iconSide = 72;

  /// Il deep link del tocco sul widget: apre "Da usare prima".
  static final Uri tapUri = Uri.parse('fullfreezer:///use-soon');

  /// Le righe del payload, una per alimento: `frozenAt US nome US iconKey US promemoria`.
  ///
  /// Il promemoria e' vuoto quando non c'e' (ne' sull'alimento ne' sulla categoria): il
  /// widget allora non colora mai la riga. Pura, per i test.
  @visibleForTesting
  static List<String> buildRows(List<Item> stored, List<CustomCategory> custom) {
    const aging = AgingCalculator();
    final sorted = [...stored]
      ..sort((a, b) {
        final byDate = a.frozenAt.compareTo(b.frozenAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return [
      for (final i in sorted.take(rowCount))
        [
          i.frozenAt,
          // Un a capo nel nome spezzerebbe la riga (le righe sono separate da a capo).
          i.name.replaceAll('\n', ' '),
          _iconKeyOf(i.category, custom),
          '${i.reminderAfterDays ?? aging.defaultReminderFor(i.category) ?? ''}',
        ].join(fieldSeparator),
    ];
  }

  static String _iconKeyOf(String? category, List<CustomCategory> custom) {
    final id = customCategoryId(category);
    if (id == null) return ItemCategories.byKey(category)?.iconKey ?? 'other';
    return custom.where((c) => c.id == id).firstOrNull?.iconKey ?? 'other';
  }

  /// Ricalcola il contenuto e lo consegna al sistema. Gira all'avvio e a ogni modifica
  /// dei dati (`notificationSyncProvider`).
  static Future<void> publish({required List<Item> stored, required List<CustomCategory> custom}) async {
    if (!available) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) await HomeWidget.setAppGroupId(iosGroup);
      final l = lookupL(resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales, kSupportedLocales));
      final rows = buildRows(stored, custom);

      await HomeWidget.saveWidgetData<String>(keyTitle, l.home_useSoon.toUpperCase());
      await HomeWidget.saveWidgetData<String>(keyCount, l.home_itemCount(stored.length));
      await HomeWidget.saveWidgetData<String>(keyEmpty, l.home_emptyTitle);
      await HomeWidget.saveWidgetData<String>(keyToday, l.item_daysShort(0));
      await HomeWidget.saveWidgetData<String>(keyDaysTemplate, daysTemplate(l));
      await HomeWidget.saveWidgetData<String>(keyRows, rows.join('\n'));

      final icons = {for (final r in rows) r.split(fieldSeparator)[2]};
      for (final key in icons) {
        try {
          await HomeWidget.saveFile('$iconKeyPrefix$key', await renderIcon(key), extension: 'png');
        } on Object catch (error) {
          // L'icona e' un ornamento: senza, il widget mostra nome e giorni.
          MicroLog.d('icona del widget "$key" non disegnata: $error');
        }
      }

      await HomeWidget.updateWidget(qualifiedAndroidName: androidName, iOSName: iosName);
    } on Object catch (error) {
      // Il widget non deve mai far fallire un salvataggio o l'avvio.
      MicroLog.d('widget non aggiornato: $error');
    }
  }

  /// Il modello dei giorni con [countPlaceholder] al posto del numero ("{n} gg").
  ///
  /// ⚑ Si ricava dal testo dell'app con un numero sentinella invece di scriverlo una seconda
  /// volta: cosi' il widget dice i giorni esattamente come le righe della home, e una
  /// traduzione corretta in `testi.py` corregge entrambi.
  @visibleForTesting
  static String daysTemplate(L l) => l.item_daysShort(987654).replaceAll('987654', countPlaceholder);

  /// L'icona disegnata della categoria, bianca su trasparente: la tinge il widget.
  @visibleForTesting
  static Future<Uint8List> renderIcon(String iconKey) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    CategoryGlyphPainter(iconKey, const Color(0xFFFFFFFF)).paint(canvas, Size.square(iconSide.toDouble()));
    final image = await recorder.endRecording().toImage(iconSide, iconSide);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('icona non convertita in PNG');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Ridisegno quotidiano poco dopo mezzanotte. **Solo Android**: il provider ricalcola i
  /// giorni da se', ma solo quando il sistema gli chiede di ridisegnare, e senza questo
  /// risveglio alle 00:05 il widget direbbe "12 gg" fino al prossimo avvio dell'app.
  ///
  /// ☠ Senza `HomeWidgetScheduledUpdateReceiver` nel manifest l'allarme scatta e non arriva
  /// a nessuno (lezione di TrashCan). Il plugin arma un allarme per volta e riarma il
  /// successivo, quindi un anno di orari e' solo un elenco in una preferenza.
  ///
  /// Su iOS non serve: l'estensione consegna a WidgetKit una timeline con una voce per
  /// ciascuno dei prossimi giorni.
  static Future<void> scheduleDailyRefresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final now = DateTime.now();
    final times = <DateTime>[for (var d = 1; d <= 365; d++) DateTime(now.year, now.month, now.day + d, 0, 5)];
    try {
      await HomeWidget.scheduleWidgetUpdates(times, qualifiedAndroidName: androidName);
    } on Object catch (error) {
      // Succede quando il widget non e' sulla schermata: e' il caso normale.
      MicroLog.d('aggiornamenti del widget non programmati: $error');
    }
  }
}

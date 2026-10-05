import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trashcan/app/app_config.dart';
import 'package:trashcan/app/routes.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/l10n/generated/app_localizations.dart';
import 'package:trashcan/main.dart' as app;

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Percorre l'app e segnala ogni schermata da fotografare.
///
/// Non verifica niente: produce gli screenshot delle schede di Play e App Store. Lo
/// scatto lo fa il computer che guida il dispositivo (`tool/screenshots_ios.sh`,
/// `tool/screenshots_android.ps1`), quando legge `SCATTO:<nome>` nell'output.
///
/// ⚑ **Perché lo scatto lo fa il computer e non il test.** `binding.takeScreenshot`
/// fotografa solo la superficie di Flutter: niente barra di stato, e una scheda di store
/// con lo schermo tagliato in alto sembra un'app rotta. Lo strumento di sistema invece
/// fotografa lo schermo intero, con la barra di stato già messa in posa alle 9:41.
///
/// ⚑ **Perché i testi vengono dal catalogo delle traduzioni.** Il test di primo avvio cerca
/// i pulsanti per testo inglese scritto a mano, e su un dispositivo in italiano si pianta
/// invece di fallire: è costato un quarto d'ora il 4 ottobre 2026. Qui la lingua la sceglie
/// il test con `localesTestValue`, e ogni testo cercato viene da `lookupL`, quindi lo
/// stesso codice gira in italiano e in inglese senza toccare le impostazioni del telefono.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(Locale(lingua));

    // Si parte da zero, come nel test di primo avvio: stesso database, stesse preferenze.
    final config = buildTrashcanConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, 'trashcan.sqlite'));
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${dbFile.path}$suffix');
      if (file.existsSync()) file.deleteSync();
    }

    // ☠ Anche l'acquisto si azzera. Il Pro comprato da un giro precedente vive in
    //   `entitlement.json`, che non e' ne' nelle preferenze ne' nel database: senza questa
    //   riga il secondo giro trovava il Pro gia' sbloccato, il pulsante per comprarlo non
    //   c'era, e il test aspettava un tocco impossibile.
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    /// Ferma l'app sulla schermata e chiede al computer di fotografarla.
    Future<void> scatto(String nome) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      // ignore: avoid_print
      print('SCATTO:$nome');
      // Il tempo per lo scatto: il computer legge l'output, aspetta un attimo che lo
      // schermo sia fermo, e fotografa. Quattro secondi bastano su simulatore ed emulatore.
      await Future<void>.delayed(const Duration(seconds: 4));
    }

    Future<void> vai(String percorso) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(percorso);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // ── Il wizard, con un calendario realistico ─────────────────────────────
    await tester.tap(find.text(l.onboarding_start));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.common_next));
    await tester.pumpAndSettle();

    // ☠ Il passo del nome lascia il campo di testo col fuoco, e su iOS la tastiera resta
    //   aperta sopra i passi successivi: il primo giro di screenshot aveva mezzo schermo
    //   occupato dalla tastiera in due immagini su sette.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    for (final nome in [
      l.waste_organic,
      l.waste_paper,
      l.waste_plastic,
      l.waste_glass,
      l.waste_unsorted,
    ]) {
      await tester.tap(find.text(nome));
      await tester.pump();
    }
    await scatto('tipi');
    await tester.tap(find.text(l.common_next));
    await tester.pumpAndSettle();

    // I giorni: l'organico domani, cosi' la home e il widget hanno qualcosa da dire
    // stasera, e gli altri nei giorni dopo, cosi' l'elenco e' pieno.
    //
    // ⚑ I riquadri dei giorni si trovano per posizione: sette per ogni tipo, nell'ordine
    //   dei tipi scelti. Per testo non si potrebbe, perche' in italiano martedi' e
    //   mercoledi' hanno la stessa iniziale.
    final domani = CivilDate.today().addDays(1);
    int giorno(int scarto) => domani.addDays(scarto).weekday;
    final scelte = <int, List<int>>{
      0: [giorno(0), giorno(3)], // organico, due volte la settimana
      1: [giorno(1)], // carta
      2: [giorno(2)], // plastica
      3: [giorno(5)], // vetro
      4: [giorno(4)], // indifferenziato
    };
    final riquadri = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_DayToggle');
    for (final MapEntry(key: riga, value: giorni) in scelte.entries) {
      for (final g in giorni) {
        final riquadro = riquadri.at(riga * 7 + g - 1);
        await tester.ensureVisible(riquadro);
        await tester.pumpAndSettle();
        await tester.tap(riquadro);
        await tester.pump();
      }
    }
    // Si torna in cima: toccando le righe in basso la griglia scorre, e la prima riga
    // usciva tagliata a meta'.
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await scatto('giorni');

    await tester.tap(find.text(l.onboarding_finish));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── Le schermate dell'app ───────────────────────────────────────────────
    await scatto('home');

    final db = AppDatabase.open();
    addTearDown(db.close);
    final calendario = (await db.allCalendars()).single;
    final bundle = (await db.loadBundle(calendario.id))!;
    final organico = bundle.wasteTypes.first;

    // ☠ Le regole non hanno una pagina propria: si modificano dentro la scheda del tipo
    //   di rifiuto. `Routes.ruleNew` esiste come costante ma non e' registrata nel router,
    //   e andarci produce la pagina d'errore di go_router, che il primo giro di questo test
    //   ha fotografato come se fosse una schermata dell'app.
    await vai(Routes.wasteTypeEdit.replaceFirst(':wasteTypeId', '${organico.id}'));
    await scatto('regola');

    // ── Il Pro, comprato col gateway finto delle build di debug ──────────────
    //
    // ⚑ Niente screenshot del paywall: mostrerebbe un prezzo, e il prezzo cambia da paese
    //   a paese e da negozio a negozio. Una scheda inglese con scritto "2,39 €" e' sbagliata
    //   per quasi tutti quelli che la leggono. Il Pro si racconta con quello che sblocca.
    //
    // Il paywall non è un percorso: si apre dai lucchetti. Si passa da quello dei
    // promemoria, che e' il motivo principale per cui si compra.
    await vai(Routes.notifications);
    await tester.tap(find.text(l.gate_seePro));
    await tester.pumpAndSettle();
    // Questo **non** va nelle schede, per il motivo detto sopra. Serve ad Apple: per
    // approvare un acquisto in-app App Store Connect vuole lo screenshot della schermata
    // in cui lo si compra, e su quello il prezzo e' giusto che si veda.
    await scatto('paywall-revisione');
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Il messaggio "Grazie, Pro sbloccato" resta qualche secondo: lo si toglie prima dello
    // scatto, altrimenti copre il fondo della schermata.
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await vai(Routes.settings);
    await scatto('impostazioni-pro');

    // ── Il widget, solo su Android ───────────────────────────────────────────────────
    //
    // ⚑ Si chiede al launcher di aggiungerlo, come farebbe l'utente dalle impostazioni.
    //   La finestra di conferma e' del sistema, fuori dalla portata di Flutter: la conferma
    //   lo script quando legge `FISSA:widget`, poi va alla schermata principale e fotografa.
    //   Il widget mostra le righe che l'app ha appena pubblicato, quindi nella lingua di
    //   questo giro. Su iOS i widget li mette solo l'utente: l'immagine si compone a parte
    //   con `tool/anteprima_widget_ios.swift`.
    if (defaultTargetPlatform == TargetPlatform.android) {
      // ☠ `scrollUntilVisible` e non `ensureVisible`: la voce sta in fondo a un elenco
      //   che Flutter costruisce solo quando ci si scorre sopra. Prima di scorrere non
      //   esiste, `ensureVisible` non ha niente da rendere visibile, e il primo giro si e'
      //   fermato qui per venti minuti.
      final voce = find.text(l.widget_addTitle);
      await tester.scrollUntilVisible(voce, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(voce);
      await tester.pump();
      // ignore: avoid_print
      print('FISSA:widget');
      await Future<void>.delayed(const Duration(seconds: 25));
    }

    // ignore: avoid_print
    print('SCATTI:FINE');
  });
}

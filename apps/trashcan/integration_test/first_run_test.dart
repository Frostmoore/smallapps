import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trashcan/app/app_config.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/main.dart' as app;

/// Il primo avvio, dall'installazione al promemoria pianificato.
///
/// ⚑ Perché serve un test su dispositivo quando ci sono già duecento test a tavolino: i
/// difetti più costosi di questa app non stanno nella logica, stanno nelle giunture fra
/// Flutter e Android. Le notifiche non arrivavano perché mancavano due receiver nel
/// manifest; il widget restava vuoto perché un intero Dart arriva in Kotlin come Long;
/// nessuno poteva comprare perché un servizio chiudeva un gateway che non possedeva.
/// Nessuno di questi tre difetti è visibile in un test a tavolino, e tutti e tre avrebbero
/// raggiunto gli utenti.
///
/// Questo test percorre la strada che percorre un utente nuovo e controlla il solo esito
/// che conta: che alla fine ci sia un promemoria pianificato per la raccolta di domani.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primo avvio: wizard, home, promemoria pianificato', (tester) async {
    // ☠ Si riparte da zero. Un test di integrazione gira sull'app installata, con i dati
    // che ci sono: senza questa pulizia il wizard non compare, il test salta al ramo
    // sbagliato e passa senza aver verificato niente. Un test che passa per il motivo
    // sbagliato è peggio di nessun test.
    final config = buildTrashcanConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();

    // ☠ Il file del database si risolve come lo risolve `AppDatabase.open()`, cioe' con
    // `getApplicationDocumentsDirectory()`. La prima versione di questo test lo cercava in
    // `AppPaths.support`, che e' un'altra cartella: la cancellazione non trovava niente,
    // non falliva, e il test partiva sui dati gia' presenti trovandosi la home invece del
    // wizard. Due percorsi per lo stesso file sono un modo garantito di pulire la cosa
    // sbagliata senza accorgersene.
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, 'trashcan.sqlite'));
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${dbFile.path}$suffix');
      if (file.existsSync()) file.deleteSync();
    }

    // ☠ `await`, non un semplice lancio: `main()` finisce dopo `runApp`, e senza
    // aspettarlo il primo `pumpAndSettle` gira su un albero che non esiste ancora. Il test
    // muore in cinque secondi con "did not complete", che non dice niente sulla causa.
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Passo 1: la schermata di benvenuto.
    expect(find.textContaining('Never miss'), findsOneWidget);
    await tester.tap(find.text('Set up my calendar'));
    await tester.pumpAndSettle();

    // Passo 2: il nome del calendario, già compilato.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Passo 3: i tipi di rifiuto.
    await tester.tap(find.text('Organic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Passo 4: il giorno di raccolta. Si sceglie **domani**, così la home deve per forza
    // mostrare qualcosa nel blocco della sera.
    final tomorrow = CivilDate.today().addDays(1);
    final initials = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    await tester.tap(find.text(initials[tomorrow.weekday - 1]).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // La home mostra la raccolta di domani nel blocco della sera.
    expect(find.text('TONIGHT'), findsOneWidget);
    expect(find.text('Organic'), findsWidgets);
    expect(find.text('Nothing to take out tonight'), findsNothing);

    // E i dati sono finiti davvero nel database: è l'unica prova che il wizard ha scritto
    // qualcosa invece di limitarsi a disegnare.
    //
    // Drift avverte che il database viene aperto una seconda volta, e ha ragione a
    // segnalarlo: due istanze con esecutori diversi sulle stesse tabelle possono corrompere
    // il file **in scrittura**. Qui si legge soltanto, ad app ferma, e più letture
    // concorrenti su SQLite sono sicure. La lettura resta perché senza di essa il test
    // proverebbe solo che la home disegna quello che ha in memoria.
    final db = AppDatabase.open();
    addTearDown(db.close);
    final calendars = await db.allCalendars();
    expect(calendars, hasLength(1));
    final bundle = await db.loadBundle(calendars.single.id);
    expect(bundle!.wasteTypes, hasLength(1));
    expect(bundle.rules, hasLength(1));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:trashcan/services/trashcan_widget.dart';

/// Il formato delle righe che il widget legge a mezzanotte.
///
/// ⚑ Perché questi test esistono: il difetto che hanno chiuso non era visibile in nessuna
/// schermata e non produceva nessun errore. Il widget mostrava il giorno sbagliato dalle
/// 00:05 in poi, e tornava giusto appena si apriva l'app — cioè spariva esattamente quando
/// lo si andava a guardare. L'ha trovato il proprietario, non un test, e questi test
/// servono a non ritrovarselo.
///
/// ☠ Qui non si costruisce il contenuto vero: `publish` ha bisogno del database, del
/// canale di piattaforma e di un motore di rasterizzazione, e in un test diventerebbe un
/// blocco da dieci minuti (vedi la trappola di `test/widget/harness.dart`). Si verifica
/// il **contratto del formato**, che è la parte che Kotlin deve poter rileggere e l'unica
/// che può divergere in silenzio.
void main() {
  group('formato delle righe', () {
    test('i separatori sono caratteri di controllo, non stampabili', () {
      // ☠ Se qualcuno li cambiasse in `|` o `;`, un tipo di rifiuto chiamato
      // "Carta | Cartone" spaccherebbe la riga e il widget mostrerebbe i campi sfasati:
      // il colore al posto del nome, la data al posto del colore. Nessun errore, solo un
      // widget che dice sciocchezze.
      expect(TrashcanWidget.fieldSeparator, '\u001F');
      expect(TrashcanWidget.lineSeparator, '\u001E');

      for (final separatore in [
        TrashcanWidget.fieldSeparator,
        TrashcanWidget.lineSeparator,
      ]) {
        final codice = separatore.codeUnitAt(0);
        expect(codice, lessThan(0x20), reason: 'deve essere un carattere di controllo');
        expect(separatore.length, 1);
      }
    });

    test('i separatori sono diversi fra loro e diversi dall a capo', () {
      final tutti = {
        TrashcanWidget.fieldSeparator,
        TrashcanWidget.lineSeparator,
        TrashcanWidget.newline,
      };
      expect(tutti.length, 3, reason: 'tre ruoli diversi, tre caratteri diversi');
    });
  });

  group('orizzonte', () {
    test('si precalcola un decennio', () {
      // ☠ Non è un numero decorativo. È per quanti giorni il widget resta giusto senza che
      // nessuno apra l'app, ed è stato scelto due volte: trenta giorni, poi un anno per
      // paura del costo di costruzione, infine dieci anni dopo aver reso quel costo
      // trascurabile. Chi lo abbassasse riaprirebbe il difetto, solo più in là.
      expect(TrashcanWidget.giorniPrecalcolati, 3650);
    });

    test('i giorni precalcolati coprono piu dei giorni elencati', () {
      // Una riga elenca `giorniElencati` raccolte successive. Se l'orizzonte fosse più
      // corto dell'elenco, l'ultima riga sarebbe strutturalmente incompleta.
      expect(
        TrashcanWidget.giorniPrecalcolati,
        greaterThan(TrashcanWidget.giorniElencati),
      );
    });

    test('la chiave delle icone ha un prefisso che non collide con le altre', () {
      // Le preferenze contengono sia le chiavi fisse sia una voce per ogni icona. Un
      // prefisso che coincidesse con una chiave fissa la sovrascriverebbe.
      final fisse = <String>{
        TrashcanWidget.keyDays,
        TrashcanWidget.keyTonightLabel,
        TrashcanWidget.keyCalendarName,
        TrashcanWidget.keyUpcomingEmpty,
        TrashcanWidget.keyStale,
      };
      for (final chiave in fisse) {
        expect(
          chiave.startsWith(TrashcanWidget.iconKeyPrefix),
          isFalse,
          reason: '"$chiave" verrebbe scambiata per un percorso di icona',
        );
      }
    });
  });

  /// ☠ Il difetto del 2026-10-10: «alle 00:00 deve cambiare da solo». Gli istanti erano
  /// alle 00:05, e Android 14+ senza il permesso degli allarmi esatti li consegnava alla
  /// fine di una finestra di un'ora: il widget cambiava verso l'una. Questi test fissano la
  /// regola che li sostituisce. La stessa regola e' ripetuta in
  /// `TrashcanWidgetProvider.riarmaMezzanotti`, in Kotlin.
  group('istanti di risveglio', () {
    /// La fine della finestra di un allarme inesatto armato [alle] per l'istante [t], come
    /// la calcola `AlarmManagerService.maxTriggerTime`: il 75% del preavviso, al massimo
    /// un'ora, zero sotto i dieci secondi.
    DateTime fineFinestra(DateTime alle, DateTime t) {
      final preavviso = t.difference(alle);
      if (preavviso < const Duration(seconds: 10)) return t;
      final finestra = preavviso * TrashcanWidget.quotaFinestra;
      return t.add(
        finestra > TrashcanWidget.finestraMassima ? TrashcanWidget.finestraMassima : finestra,
      );
    }

    DateTime mezzanotteDopo(DateTime giorno) =>
        DateTime(giorno.year, giorno.month, giorno.day + 1);

    test('due per giorno: un preavviso prima e il finale a mezzanotte e pochi secondi', () {
      final adesso = DateTime(2026, 10, 10, 15);
      final istanti = TrashcanWidget.istantiDiRisveglio(adesso, giorni: 3);

      expect(istanti, [
        DateTime(2026, 10, 10, 23, 0, 30),
        DateTime(2026, 10, 11, 0, 0, 5),
        DateTime(2026, 10, 11, 23, 0, 30),
        DateTime(2026, 10, 12, 0, 0, 5),
        DateTime(2026, 10, 12, 23, 0, 30),
        DateTime(2026, 10, 13, 0, 0, 5),
      ]);
    });

    test('l orizzonte e quello delle righe', () {
      final istanti = TrashcanWidget.istantiDiRisveglio(DateTime(2026, 10, 10, 15));
      expect(istanti, hasLength(TrashcanWidget.giorniPrecalcolati * 2));
      expect(istanti.toSet(), hasLength(istanti.length), reason: 'nessun doppione');
      for (var i = 1; i < istanti.length; i++) {
        expect(istanti[i].isAfter(istanti[i - 1]), isTrue, reason: 'in ordine');
      }
    });

    test('mai piu alle 00:05: il finale e a mezzanotte e pochi secondi', () {
      final istanti = TrashcanWidget.istantiDiRisveglio(DateTime(2026, 1, 1, 12), giorni: 400);
      final finali = [for (var i = 1; i < istanti.length; i += 2) istanti[i]];
      for (final istante in finali) {
        expect(istante.isUtc, isFalse, reason: 'deve essere ora locale');
        expect((istante.hour, istante.minute), (0, 0), reason: '$istante');
        expect(istante.second, TrashcanWidget.secondiDopoMezzanotte);
      }
      expect(TrashcanWidget.secondiDopoMezzanotte, inInclusiveRange(1, 30));
      expect(TrashcanWidget.secondiFineFinestra, inInclusiveRange(1, 60));
    });

    test('il preavviso armato un giorno prima viene consegnato subito dopo mezzanotte', () {
      // ⚑ E' il cuore della correzione: Android 14+ consegna l'allarme inesatto alla FINE
      // della finestra. Il plugin arma il preavviso di domani quando scatta quello di oggi,
      // cioe' intorno alla mezzanotte di oggi: quasi un giorno di anticipo.
      final istanti = TrashcanWidget.istantiDiRisveglio(DateTime(2026, 10, 10, 15), giorni: 3);
      final armatoAlle = DateTime(2026, 10, 11, 0, 0, 30);
      final preavviso = istanti[2];
      final consegna = fineFinestra(armatoAlle, preavviso);

      final mezzanotte = DateTime(2026, 10, 12);
      expect(consegna.isAfter(mezzanotte), isTrue, reason: 'deve cadere nel giorno nuovo');
      expect(consegna.difference(mezzanotte), const Duration(seconds: 30));
    });

    test('il primo preavviso e tarato su quando lo si arma: sempre poco dopo mezzanotte', () {
      // Aprire l'app alle 22:30 non deve far cadere la consegna alle 23:23, cioe' prima di
      // mezzanotte: il preavviso si avvicina perche' la finestra, piu' corta, finisca giusta.
      for (final adesso in [
        DateTime(2026, 10, 10, 8),
        DateTime(2026, 10, 10, 21, 40, 30),
        DateTime(2026, 10, 10, 22, 30),
        DateTime(2026, 10, 10, 23, 50),
        DateTime(2026, 10, 10, 23, 58, 30),
      ]) {
        final primo = TrashcanWidget.istantiDiRisveglio(adesso, giorni: 1).first;
        final consegna = fineFinestra(adesso, primo);
        final mezzanotte = mezzanotteDopo(adesso);
        expect(primo.isAfter(adesso), isTrue, reason: 'armato alle $adesso');
        expect(
          consegna.difference(mezzanotte).inSeconds,
          inInclusiveRange(29, 31),
          reason: 'armato alle $adesso: consegna alle $consegna',
        );
      }
    });

    test('a meno di un minuto dalla fine voluta il preavviso non serve', () {
      final adesso = DateTime(2026, 10, 10, 23, 59, 45);
      final istanti = TrashcanWidget.istantiDiRisveglio(adesso, giorni: 1);
      expect(istanti, [DateTime(2026, 10, 11, 0, 0, 5)]);
    });

    test('le date dei finali sono consecutive: nessun giorno saltato o ripetuto', () {
      // Due anni pieni: almeno quattro cambi d'ora nel fuso della macchina e il 29 febbraio
      // 2028.
      final istanti = TrashcanWidget.istantiDiRisveglio(DateTime(2026, 10, 10), giorni: 800);
      final finali = [for (var i = 1; i < istanti.length; i += 2) istanti[i]];
      for (var i = 1; i < finali.length; i++) {
        final atteso = mezzanotteDopo(finali[i - 1]);
        expect(
          (finali[i].year, finali[i].month, finali[i].day),
          (atteso.year, atteso.month, atteso.day),
        );
      }
    });

    test('il 25 ottobre 2026 dura quanto deve, e la mezzanotte dopo resta a mezzanotte', () {
      // ☠ In Italia quella notte l'orologio torna indietro di un'ora: la giornata dura 25
      // ore. Sommando 24 ore, da li' in poi tutti i risvegli cadrebbero un'ora prima. Si
      // verifica l'ora sul quadrante e la distanza reale, che dipende dal fuso della
      // macchina: 25 ore a Roma, 24 dove l'ora non cambia.
      final istanti = TrashcanWidget.istantiDiRisveglio(DateTime(2026, 10, 24, 9), giorni: 3);
      final del25 = istanti[1];
      final del26 = istanti[3];
      expect((del25.month, del25.day, del25.hour), (10, 25, 0));
      expect((del26.month, del26.day, del26.hour), (10, 26, 0));
      final salto = del25.timeZoneOffset - del26.timeZoneOffset;
      expect(del26.difference(del25), const Duration(hours: 24) + salto);

      final preavviso26 = istanti[2];
      expect((preavviso26.day, preavviso26.hour, preavviso26.minute), (25, 23, 0));
    });
  });
}

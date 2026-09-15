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
}

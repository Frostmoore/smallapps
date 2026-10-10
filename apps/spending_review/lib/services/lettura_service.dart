import 'dart:io';

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/lettura/bilancia_parser.dart';
import '../domain/lettura/cartellino_parser.dart';
import '../domain/lettura/scontrino_parser.dart';
import '../domain/lettura/unisci_parti.dart';

/// Cosa ha dato la lettura di un cartellino (F12.1.13). La pagina della fotocamera lo restituisce
/// con `pop`, e `SpesaPage` apre il foglio giusto.
sealed class RisultatoCartellino {
  const RisultatoCartellino();
}

/// Un cartellino (o piu') interpretato: si apre il foglio di conferma.
@immutable
final class LettoCartellino extends RisultatoCartellino {
  const LettoCartellino(this.lettura);

  final LetturaCartellino lettura;
}

/// Un'etichetta della bilancia (riconosciuta da sola o forzata): foglio della bilancia.
@immutable
final class LettaBilancia extends RisultatoCartellino {
  const LettaBilancia(this.lettura);

  final LetturaBilancia lettura;
}

/// Niente di utile. [forseAMano]: il motore ha letto del testo ma nessun prezzo, il caso tipico
/// dello scritto a mano (c04, c05, c25: zero cifre lette), e l'app lo dice («usa il tastierino»).
@immutable
final class NienteLetto extends RisultatoCartellino {
  const NienteLetto({required this.forseAMano});

  final bool forseAMano;
}

/// Il motore OCR non c'e' o non legge su questo telefono: si ripiega sul tastierino, mai un crash.
final class OcrAssente extends RisultatoCartellino {
  const OcrAssente();
}

/// Uno scontrino letto, anche in piu' foto (F12.1.12, `ScontrinoCameraPage`).
///
/// ⚑ Tipo in piu' rispetto alla specsheet (che faceva tornare a `scontrino()` la sola
/// `LetturaScontrino`): il confronto deve poter dire «Ho unito 2 foto senza trovare il punto di
/// unione» (F12.1.12, `ConfrontoPage` punto 5), e quell'informazione nasce in `UnisciParti`, non
/// nel parser. Viaggia come `extra` di `/scontrino/confronto` e `/scontrino/registra`.
@immutable
final class ScontrinoLetto {
  const ScontrinoLetto({required this.lettura, this.giunzioniTrovate = const []});

  final LetturaScontrino lettura;

  /// Per ogni giunzione fra due foto consecutive, se il punto di unione e' stato trovato.
  final List<bool> giunzioniTrovate;

  /// Le foto lette.
  int get parti => giunzioniTrovate.length + 1;

  /// Giunzioni non trovate: forse righe doppie o mancanti.
  int get giunzioniMancanti => giunzioniTrovate.where((g) => !g).length;
}

/// Foto → motore OCR → parser (develop_microapps.md F12.1.13).
///
/// ☠ **Le foto si cancellano sempre**, letta o no, anche con un errore (nel `finally`): e' la
/// regola di privacy dello scontrino (s13, dati della carta). Si cancellano anche quelle scelte
/// dalla galleria, ma solo la **copia** temporanea che `image_picker` crea: [cancellabile]
/// protegge gli originali dell'utente (un percorso fuori dalle cartelle temporanee dell'app non
/// si tocca mai).
/// ⚑ Il testo OCR grezzo non esce da qui: vive in memoria il tempo del parser. Nel database
/// arrivano solo le righe interpretate e confermate (F12.1.10).
class LetturaService {
  LetturaService({
    required this.motore,
    this.cartellinoParser = const CartellinoParser(),
    this.bilanciaParser = const BilanciaParser(),
    this.scontrinoParser = const ScontrinoParser(),
    DateTime Function() ora = DateTime.now,
    Future<bool> Function(String percorso)? cancellabile,
    // ignore: prefer_initializing_formals
  }) : _ora = ora,
       _cancellabile = cancellabile ?? _nelleCartelleTemporanee;

  final OcrEngine motore;
  final CartellinoParser cartellinoParser;
  final BilanciaParser bilanciaParser;
  final ScontrinoParser scontrinoParser;
  final DateTime Function() _ora;
  final Future<bool> Function(String percorso) _cancellabile;

  /// Foto → OCR (modo cartellino) → bilancia se riconosciuta (o [forzaBilancia]), altrimenti
  /// cartellino. La foto si CANCELLA nel `finally`.
  ///
  /// ⚑ La bilancia si riconosce da sola dalla «firma» (peso con 3 decimali e una tripla
  /// peso × €/kg ≈ totale, `BilanciaParser.riconosce`): niente terzo tasto (F12.0 punto 4).
  Future<RisultatoCartellino> cartellino(String percorso, {required bool forzaBilancia}) async {
    try {
      final List<RigaOcr> righe;
      try {
        righe = await motore.leggi(percorso, modo: OcrModo.cartellino);
      } on OcrNonDisponibile catch (e) {
        MicroLog.w('OCR assente: $e');
        return const OcrAssente();
      }
      if (forzaBilancia || bilanciaParser.riconosce(righe)) {
        final b = bilanciaParser.interpreta(righe);
        if (b != null && b.utile) return LettaBilancia(b);
        // Forzata ma illeggibile: si prova comunque come cartellino (l'interruttore era sbagliato).
      }
      final c = cartellinoParser.interpreta(righe);
      if (c.vuota) return NienteLetto(forseAMano: righe.any((r) => r.testo.trim().isNotEmpty));
      return LettoCartellino(c);
    } finally {
      await _cancella(percorso);
    }
  }

  /// Le parti in ordine (dall'alto in basso); OCR in modo scontrino per ognuna; `UnisciParti`;
  /// `ScontrinoParser`. Le foto si CANCELLANO tutte nel `finally`.
  /// ☠ Lancia [OcrNonDisponibile] se il motore manca: la pagina lo dice e resta il tastierino.
  Future<ScontrinoLetto> scontrino(List<String> percorsi) async {
    try {
      final parti = <List<RigaOcr>>[];
      for (final percorso in percorsi) {
        parti.add(await motore.leggi(percorso, modo: OcrModo.scontrino));
      }
      final unite = UnisciParti.unisci(parti);
      final lettura = scontrinoParser.interpreta(unite.righe, oggi: _ora());
      return ScontrinoLetto(lettura: lettura, giunzioniTrovate: unite.giunzioniTrovate);
    } finally {
      for (final percorso in percorsi) {
        await _cancella(percorso);
      }
    }
  }

  Future<void> _cancella(String percorso) async {
    try {
      if (!await _cancellabile(percorso)) {
        MicroLog.w('foto fuori dalle cartelle temporanee: non la cancello');
        return;
      }
      final f = File(percorso);
      if (f.existsSync()) await f.delete();
    } on Object catch (e) {
      MicroLog.w('foto non cancellata: $e');
    }
  }

  /// Vero se [percorso] sta nella cartella temporanea o nella cache dell'app: li' scrivono lo
  /// scatto (`camera`), il ritaglio (`Fotocamera`) e le copie di `image_picker`.
  static Future<bool> _nelleCartelleTemporanee(String percorso) async {
    final cartelle = <String>[(await getTemporaryDirectory()).path];
    try {
      cartelle.add((await getApplicationCacheDirectory()).path);
    } on Object {
      // Piattaforma senza cache separata: basta la temporanea.
    }
    final assoluto = p.normalize(File(percorso).absolute.path);
    return cartelle.any((c) => p.isWithin(p.normalize(Directory(c).absolute.path), assoluto));
  }
}

import 'package:meta/meta.dart';
import 'package:micro_ocr/riga_ocr.dart';

import 'numeri_ocr.dart';

/// Una riga come la vede una persona: i riquadri OCR che stanno alla stessa altezza, da sinistra
/// a destra (F12.1.6).
@immutable
final class RigaVisiva {
  const RigaVisiva(this.pezzi, {this.sogliaDestra = 0.6});

  /// Da sinistra a destra.
  final List<RigaOcr> pezzi;

  /// La x (0..1 dell'immagine) oltre cui deve finire un numero per stare nella colonna dei prezzi.
  ///
  /// ⚑ La specsheet dice «oltre il 60% della larghezza» (dell'immagine). `RigheVisive.raggruppa`
  /// la calcola invece sul **testo**: il 60% fra il bordo sinistro e quello destro di tutte le
  /// righe lette. Uno scontrino fotografato con margini (o in una foto larga, s04) ha la colonna
  /// dei prezzi al 55% dell'immagine ma al 95% del testo.
  final double sogliaDestra;

  /// I pezzi uniti con uno spazio.
  String get testo => pezzi.map((p) => p.testo).join(' ');

  /// L'unione dei riquadri.
  Riquadro get riquadro {
    var l = 1.0, t = 1.0, r = 0.0, b = 0.0;
    for (final p in pezzi) {
      final q = p.riquadro;
      if (q.sinistra < l) l = q.sinistra;
      if (q.alto < t) t = q.alto;
      if (q.destra > r) r = q.destra;
      if (q.basso > b) b = q.basso;
    }
    return Riquadro(sinistra: l, alto: t, larghezza: r - l, altezza: b - t);
  }

  /// La confidenza media dei pezzi, pesata sulla lunghezza del testo. ⚑ Non la minima: un
  /// frammento di due caratteri letto male («(c» in s15) non deve squalificare la riga intera.
  double get confidenza {
    var somma = 0.0, peso = 0;
    for (final p in pezzi) {
      final n = p.testo.isEmpty ? 1 : p.testo.length;
      somma += p.confidenza * n;
      peso += n;
    }
    return peso == 0 ? 0 : somma / peso;
  }

  /// Tutti i numeri espliciti della riga (prezzi e pesi), da sinistra a destra.
  List<NumeroOcr> get numeri => [for (final p in pezzi) ...NumeriOcr.espliciti(p)];

  /// L'ultimo numero esplicito a 2 decimali il cui riquadro finisce oltre [sogliaDestra]: la
  /// colonna dei prezzi.
  NumeroOcr? get importoADestra {
    NumeroOcr? ultimo;
    for (final n in numeri) {
      if (n.forma == FormaNumero.esplicito && n.riquadro.destra > sogliaDestra) ultimo = n;
    }
    return ultimo;
  }

  @override
  String toString() => 'RigaVisiva("$testo")';
}

/// Il raggruppamento dei riquadri in righe visive (F12.1.6).
abstract final class RigheVisive {
  /// Ordina per centro verticale; un riquadro entra nella riga corrente se la sua
  /// `sovrapposizioneVerticale` con la **fascia media** della riga e' ≥ 0,5, altrimenti ne apre
  /// una nuova.
  ///
  /// ⚑ Serve perche' PP-OCR spezza una riga in piu' riquadri (descrizione | IVA | prezzo) mentre
  /// Vision spesso la da' intera: dopo questo passo i due motori producono le stesse righe.
  /// ⚑ **Fascia media** (media degli alti e dei bassi dei pezzi gia' nella riga) e non l'unione:
  /// su uno scontrino storto (s03, s09) l'unione cresce a ogni pezzo e finisce per inghiottire la
  /// riga sotto; la media resta alta quanto una riga e segue l'inclinazione.
  static List<RigaVisiva> raggruppa(List<RigaOcr> righe) {
    if (righe.isEmpty) return const [];
    final ordinate = [...righe]..sort((a, b) => a.riquadro.centroY.compareTo(b.riquadro.centroY));
    var minX = 1.0, maxX = 0.0;
    for (final r in righe) {
      if (r.riquadro.sinistra < minX) minX = r.riquadro.sinistra;
      if (r.riquadro.destra > maxX) maxX = r.riquadro.destra;
    }
    final soglia = minX + 0.6 * (maxX - minX);

    final gruppi = <List<RigaOcr>>[];
    var sommaAlti = 0.0, sommaBassi = 0.0;
    for (final r in ordinate) {
      final n = gruppi.isEmpty ? 0 : gruppi.last.length;
      final fascia = n == 0
          ? null
          : Riquadro(sinistra: 0, alto: sommaAlti / n, larghezza: 1, altezza: (sommaBassi - sommaAlti) / n);
      if (fascia != null && r.riquadro.sovrapposizioneVerticale(fascia) >= 0.5) {
        gruppi.last.add(r);
        sommaAlti += r.riquadro.alto;
        sommaBassi += r.riquadro.basso;
      } else {
        gruppi.add([r]);
        sommaAlti = r.riquadro.alto;
        sommaBassi = r.riquadro.basso;
      }
    }
    return [
      for (final g in gruppi)
        RigaVisiva(
          List.unmodifiable(g..sort((a, b) => a.riquadro.sinistra.compareTo(b.riquadro.sinistra))),
          sogliaDestra: soglia,
        ),
    ];
  }
}

import 'package:micro_ocr/riga_ocr.dart';

import '../nomi.dart';
import 'righe_visive.dart';

/// La fusione di piu' foto dello stesso scontrino (F12.1.6): uno scontrino di 40 righe in una foto
/// sola ha i caratteri troppo piccoli, e l'utente lo fotografa in 2–4 pezzi dall'alto in basso.
abstract final class UnisciParti {
  /// Ogni parte e' l'OCR di una foto, dall'alto in basso. Si concatenano le righe visive; se le
  /// ultime k righe della parte i coincidono con le prime k della parte i+1 (k ≥ 2, stesso
  /// importo e testo con similarita' ≥ 0,8), si tolgono i doppioni. Ritorna anche, per ogni
  /// giunzione, se e' stata trovata.
  ///
  /// ⚑ Le coordinate di ogni parte si **impilano**: alla parte i si somma i all'asse y (ogni parte
  /// occupa l'intervallo [i, i+1]), cosi' `RigheVisive` funziona sul tutto senza sapere delle foto.
  /// ☠ Una giunzione non trovata vuol dire «forse ci sono righe doppie o mancanti»: il confronto
  /// lo dice («Ho unito 2 foto senza trovare il punto di unione…»).
  static ({List<RigaOcr> righe, List<bool> giunzioniTrovate}) unisci(List<List<RigaOcr>> parti) {
    final righe = <RigaOcr>[];
    final giunzioni = <bool>[];
    List<RigaVisiva>? precedenti;
    for (var i = 0; i < parti.length; i++) {
      final visive = RigheVisive.raggruppa(parti[i]);
      var salta = 0;
      final prima = precedenti;
      if (prima != null) {
        salta = _sovrapposte(prima, visive);
        giunzioni.add(salta >= 2);
        if (salta < 2) salta = 0;
      }
      for (final v in visive.skip(salta)) {
        for (final p in v.pezzi) {
          final q = p.riquadro;
          righe.add(RigaOcr(
            testo: p.testo,
            riquadro: Riquadro(sinistra: q.sinistra, alto: q.alto + i, larghezza: q.larghezza, altezza: q.altezza),
            confidenza: p.confidenza,
          ));
        }
      }
      precedenti = visive;
    }
    return (righe: List.unmodifiable(righe), giunzioniTrovate: List.unmodifiable(giunzioni));
  }

  /// Il k piu' grande per cui le ultime k righe di [a] coincidono con le prime k di [b] (0 se
  /// nessuno).
  static int _sovrapposte(List<RigaVisiva> a, List<RigaVisiva> b) {
    final massimo = a.length < b.length ? a.length : b.length;
    for (var k = massimo; k >= 1; k--) {
      var tutte = true;
      for (var j = 0; j < k; j++) {
        if (!_uguali(a[a.length - k + j], b[j])) {
          tutte = false;
          break;
        }
      }
      if (tutte) return k;
    }
    return 0;
  }

  static bool _uguali(RigaVisiva x, RigaVisiva y) {
    if (x.importoADestra?.valore != y.importoADestra?.valore) return false;
    if (x.testo == y.testo) return true;
    return Nomi.similarita(x.testo, y.testo) >= 0.8;
  }
}

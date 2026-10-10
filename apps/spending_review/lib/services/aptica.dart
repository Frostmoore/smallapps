import 'dart:async';

import 'package:flutter/services.dart';

/// Le vibrazioni brevi di Spending Review (develop_microapps.md F12.1.13), spegnibili da
/// Impostazioni (`SrSettingKeys.vibrazione`).
///
/// ⚑ Perche' esistono: l'app si usa con una mano, col carrello nell'altra, spesso senza guardare
/// lo schermo fino in fondo. Una vibrazione diversa per «tasto preso», «tasto rifiutato», «riga
/// aggiunta» e «soglia del budget passata» dice cosa e' successo senza leggere.
///
/// ⚑ Una classe con [attiva] e non quattro funzioni globali: i test la sostituiscono con
/// `ApticaRegistrata` e contano le chiamate, senza il canale di piattaforma.
class Aptica {
  Aptica({required this.attiva});

  /// Spenta = nessuna chiamata al sistema (preferenza dell'utente).
  final bool attiva;

  /// Ogni tasto del tastierino: il tocco piu' leggero che esista.
  void tasto() => _fai(HapticFeedback.selectionClick);

  /// Un tasto rifiutato (terza cifra dopo la virgola, «+» con valore zero, ×× ...): forte, si
  /// distingue al primo colpo da un tasto preso.
  void rifiuto() => _fai(HapticFeedback.heavyImpact);

  /// Passata la soglia dell'80% o del 100% del budget: una volta per soglia e per spesa.
  void soglia() => _fai(HapticFeedback.mediumImpact);

  /// Una riga entrata nella spesa (il «+», un cartellino confermato).
  void aggiunto() => _fai(HapticFeedback.lightImpact);

  void _fai(Future<void> Function() effetto) {
    if (!attiva) return;
    // ☠ Mai attesa e mai un errore verso l'interfaccia: un telefono senza motore di vibrazione
    // (o un emulatore) non deve rallentare ne' rompere il tastierino.
    unawaited(effetto().catchError((Object _) {}));
  }
}

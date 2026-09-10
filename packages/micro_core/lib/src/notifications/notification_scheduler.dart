import 'dart:async';

import '../prefs/settings_store.dart';

/// Chi sa ricostruire da zero l'intero piano di notifiche di un'app.
///
/// ⚑ Perché un'interfaccia in `micro_core` e non una classe per app e basta: tutte e
/// quattro le app ripianificano allo stesso modo (ADR-009) e lo fanno dagli stessi punti,
/// cioè al ritorno in primo piano e dopo ogni modifica ai dati. Avere una forma comune
/// permette di scrivere quel richiamo una volta sola invece di quattro, e soprattutto di
/// non dimenticarne uno: una notifica che non viene ripianificata non produce nessun
/// errore, semplicemente non arriva.
abstract interface class NotificationScheduler {
  /// Ricalcola il piano completo e lo sostituisce a quello attuale.
  Future<void> rescheduleAll();

  /// Cancella tutto, senza ricalcolare.
  Future<void> cancelAll();
}

/// Decide se vale la pena ripianificare adesso.
///
/// ☠ Trappola disinnescata: ripianificare costa fino a 64 cancellazioni e 64
/// pianificazioni, ognuna delle quali attraversa il canale con Android. Farlo a ogni
/// ritorno in primo piano rende l'apertura dell'app visibilmente lenta su un telefono di
/// fascia bassa, e non serve a niente: il piano dipende dai dati, e i dati non cambiano
/// mentre l'app è in secondo piano. Chi modifica i dati chiama comunque
/// [NotificationScheduler.rescheduleAll] con `force: true` attraverso il proprio scheduler.
class RescheduleGuard {
  const RescheduleGuard(this.settings, {this.minInterval = const Duration(hours: 1)});

  final SettingsStore settings;
  final Duration minInterval;

  /// `true` se è passato abbastanza tempo dall'ultima ripianificazione.
  ///
  /// Il tempo si legge dalle preferenze e non da un campo in memoria: l'app viene uccisa e
  /// riaperta di continuo, e un contatore in memoria si azzererebbe a ogni avvio, cioè
  /// proprio nel caso che questo controllo dovrebbe coprire.
  bool shouldReschedule({DateTime? now}) {
    final last = settings.getInstant(SettingKeys.lastRescheduleAt);
    if (last == null) return true;
    final moment = now ?? DateTime.now();
    // Un orologio spostato all'indietro (cambio manuale, fuso, ripristino da backup)
    // renderebbe la differenza negativa e bloccherebbe le ripianificazioni per ore.
    if (moment.isBefore(last)) return true;
    return moment.difference(last) >= minInterval;
  }

  Future<void> markRescheduled({DateTime? now}) =>
      settings.setInstant(SettingKeys.lastRescheduleAt, now ?? DateTime.now());
}

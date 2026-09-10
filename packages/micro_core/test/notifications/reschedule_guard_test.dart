import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Il guardiano che decide se vale la pena ripianificare le notifiche.
///
/// ⚑ Perché merita dei test: sbagliarlo in un verso rende l'apertura dell'app lenta a ogni
/// ritorno in primo piano; sbagliarlo nell'altro blocca le ripianificazioni e le notifiche
/// smettono di arrivare senza nessun errore. Entrambi i modi di sbagliare sono invisibili
/// finché non è tardi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsStore settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    settings = await SettingsStore.create(namespace: 'guard_test');
  });

  test('la prima volta si ripianifica sempre', () {
    expect(RescheduleGuard(settings).shouldReschedule(), isTrue);
  });

  test('subito dopo una ripianificazione non se ne fa un-altra', () async {
    final guard = RescheduleGuard(settings);
    final now = DateTime(2026, 9, 10, 12);
    await guard.markRescheduled(now: now);

    expect(guard.shouldReschedule(now: now.add(const Duration(minutes: 5))), isFalse);
    expect(guard.shouldReschedule(now: now.add(const Duration(minutes: 59))), isFalse);
  });

  test('passata l-ora si ripianifica', () async {
    final guard = RescheduleGuard(settings);
    final now = DateTime(2026, 9, 10, 12);
    await guard.markRescheduled(now: now);

    expect(guard.shouldReschedule(now: now.add(const Duration(hours: 1))), isTrue);
    expect(guard.shouldReschedule(now: now.add(const Duration(hours: 3))), isTrue);
  });

  test('un orologio spostato indietro non blocca le ripianificazioni', () async {
    // ☠ Cambio manuale dell'ora, cambio di fuso, ripristino da backup: la differenza
    // diventa negativa. Senza il controllo esplicito, `difference >= minInterval` sarebbe
    // falsa e l'app smetterebbe di ripianificare per tutto il tempo dello scarto.
    final guard = RescheduleGuard(settings);
    final now = DateTime(2026, 9, 10, 12);
    await guard.markRescheduled(now: now);

    expect(guard.shouldReschedule(now: now.subtract(const Duration(hours: 5))), isTrue);
  });

  test('l-intervallo minimo e- configurabile', () async {
    final guard = RescheduleGuard(settings, minInterval: const Duration(minutes: 10));
    final now = DateTime(2026, 9, 10, 12);
    await guard.markRescheduled(now: now);

    expect(guard.shouldReschedule(now: now.add(const Duration(minutes: 9))), isFalse);
    expect(guard.shouldReschedule(now: now.add(const Duration(minutes: 10))), isTrue);
  });

  test('lo stato sopravvive alla ricostruzione dello store', () async {
    // Il momento si legge dalle preferenze e non da un campo in memoria: l'app viene
    // uccisa e riaperta di continuo, e un contatore in memoria si azzererebbe a ogni
    // avvio, cioe' proprio nel caso che questo controllo dovrebbe coprire.
    final now = DateTime(2026, 9, 10, 12);
    await RescheduleGuard(settings).markRescheduled(now: now);

    final reopened = await SettingsStore.create(namespace: 'guard_test');
    expect(
      RescheduleGuard(reopened).shouldReschedule(now: now.add(const Duration(minutes: 5))),
      isFalse,
    );
  });
}

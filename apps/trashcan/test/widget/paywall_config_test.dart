import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/app/feature_limits.dart';
import 'package:trashcan/app/paywall_config.dart';
import 'package:trashcan/l10n/generated/app_localizations.dart';

/// Il paywall deve vendere tutto quello che il piano gratuito non dà.
///
/// ⚑ Perché questo vale più di un test che disegna la pagina: il difetto probabile non è
/// "il paywall non si vede", che si scopre al primo avvio. È "abbiamo messo una funzione
/// dietro il Pro e non l'abbiamo elencata fra i benefici". Da quel momento l'utente incontra
/// un blocco che non sa a cosa serva, e il paywall che gli si apre davanti non nomina
/// nemmeno la cosa che stava cercando di fare. Nessun errore, solo un acquisto in meno.
///
/// La verifica è meccanica: si confronta l'elenco dei benefici con la mappa dei limiti.
/// Aggiungere una chiave bloccata senza il suo beneficio fa fallire questo test.
void main() {
  final l = lookupL(const Locale('en'));
  final config = buildTrashcanPaywall(l);

  test('ogni funzione bloccata nel piano gratuito compare fra i benefici', () {
    final locked = <FeatureKey>{
      for (final entry in trashcanFeatureLimits.entries)
        if (entry.value.isLockedForFree) entry.key,
    };
    final sold = config.benefits.map((b) => b.key).toSet();

    expect(
      locked.difference(sold),
      isEmpty,
      reason: 'funzioni bloccate e non vendute: chi le incontra vede un blocco senza spiegazione',
    );
  });

  test('il limite sui calendari e venduto, anche se non e un blocco netto', () {
    // unlimitedEntities non e' "locked": nel piano gratuito un calendario c'e'. Ma il
    // secondo e' la ragione principale per cui qualcuno paga, quindi deve stare
    // nell'elenco, e per primo.
    expect(config.benefits.first.key, FeatureKey.unlimitedEntities);
  });

  test('nessun beneficio duplicato', () {
    final keys = config.benefits.map((b) => b.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('nessun testo vuoto: un beneficio senza descrizione non vende niente', () {
    for (final benefit in config.benefits) {
      expect(benefit.title.trim(), isNotEmpty, reason: '${benefit.key}');
      expect(benefit.description.trim(), isNotEmpty, reason: '${benefit.key}');
    }
    expect(config.headline.trim(), isNotEmpty);
    expect(config.subhead.trim(), isNotEmpty);
    expect(config.oneTimeNotice.trim(), isNotEmpty);
  });

  test('il bottone mostra il prezzo quando lo store lo fornisce, e regge se manca', () {
    // Lo store puo' non rispondere: senza rete, o con Play non disponibile. In quel caso
    // il bottone deve dire comunque qualcosa di sensato invece di "Sblocca Pro - null".
    expect(config.buyLabel('2,99 €'), contains('2,99'));
    expect(config.buyLabel(null), isNotEmpty);
    expect(config.buyLabel(null), isNot(contains('null')));
  });

  test('la frase sul pagamento unico c-e: e il motivo per cui si compra', () {
    // Chi sceglie un'app a pagamento unico invece di una in abbonamento lo fa per questo.
    // Nasconderlo e' lasciare soldi sul tavolo.
    expect(config.oneTimeNotice.toLowerCase(), contains('no subscription'));
  });
}

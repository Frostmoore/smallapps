import '../domain/offerta.dart';
import '../domain/riga_spesa.dart';
import '../l10n/generated/app_localizations.dart';

/// I testi visibili costruiti dal dominio, dagli ARB (develop_microapps.md F12.1.3).
///
/// ⚑ Il dominio (`lib/domain/`) non ha testi: i nomi stanno qui perche' cambiano con la lingua, e
/// il dominio resta Dart puro. Gli switch sono esaustivi di proposito: un'offerta nuova non compila
/// finche' non ha la sua etichetta. Le etichette lunghe delle offerte («3x2 · 1,26 cad. se ne
/// prendi 3») arrivano con il foglio di conferma (F12.4).

/// Il nome di una riga come si mostra: «Articolo» se vuoto, «Sconto» se e' uno sconto senza nome.
String nomeRiga(L l, RigaSpesa r) {
  if (r.nome.trim().isNotEmpty) return r.nome;
  return r.eSconto ? l.riga_sconto : l.riga_senzaNome;
}

/// Il testo breve di un'offerta sotto la riga: «3x2», «−30%», «−50% sul 2°»; null per quelle solo
/// informative (prezzo barrato, prezzo con carta), che la riga non deve ripetere.
/// ⚑ Senza l10n: numeri e simboli si leggono uguali in italiano e in inglese.
String? offertaBreve(Offerta? o) => switch (o) {
  null => null,
  OffertaNxM(:final prendi, :final paghi) => '${prendi}x$paghi',
  OffertaPercentuale(:final percento) => '−$percento%',
  OffertaSecondoAPercento(:final percento) => '−$percento% 2°',
  OffertaPrezzoBarrato() => null,
  OffertaPrezzoConCarta() => null,
};

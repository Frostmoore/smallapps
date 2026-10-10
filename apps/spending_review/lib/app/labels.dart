import 'package:micro_core/micro_core.dart';

import '../domain/offerta.dart';
import '../domain/quantita.dart';
import '../domain/riga_spesa.dart';
import '../l10n/generated/app_localizations.dart';

/// I testi visibili costruiti dal dominio, dagli ARB (develop_microapps.md F12.1.3).
///
/// ⚑ Il dominio (`lib/domain/`) non ha testi: i nomi stanno qui perche' cambiano con la lingua, e
/// il dominio resta Dart puro. Gli switch sono esaustivi di proposito: un'offerta nuova non compila
/// finche' non ha la sua etichetta.
///
/// ⚑ **Gli importi si scrivono sempre con la virgola** («2,49»), anche in inglese: l'app e' in
/// euro e il tastierino «alla cassa» mostra la virgola (TastierinoState.display, costruito senza
/// intl). Un «2.49» nella lista sotto un «2,49» nel display sarebbe una seconda lingua dei numeri.

/// Il nome di una riga come si mostra: «Articolo» se vuoto, «Sconto» se e' uno sconto senza nome.
String nomeRiga(L l, RigaSpesa r) {
  if (r.nome.trim().isNotEmpty) return r.nome;
  return r.eSconto ? l.riga_sconto : l.riga_senzaNome;
}

/// «43,70», «−1,50». ⚑ Il meno tipografico (U+2212), come il tasto del tastierino.
String importo(Money m) {
  final c = m.cents.abs();
  final testo = '${c ~/ 100},${(c % 100).toString().padLeft(2, '0')}';
  return m.isNegative ? '−$testo' : testo;
}

/// I budget tondi senza centesimi: «60», ma «60,50».
String importoTondo(Money m) => m.cents % 100 == 0 ? '${m.cents ~/ 100}' : importo(m);

/// «+1,65» / «−16,30» / «0,00»: le differenze (residuo del budget, confronto).
String importoConSegno(Money m) => (m.isZero || m.isNegative) ? importo(m) : '+${importo(m)}';

/// Grammi o millilitri come chili o litri: 258 → «0,258».
String millesimiTesto(int millesimi) => '${millesimi ~/ 1000},${(millesimi % 1000).toString().padLeft(3, '0')}';

/// «kg» o «l».
String unitaTesto(UnitaMisura u) => switch (u) {
  UnitaMisura.kg => 'kg',
  UnitaMisura.l => 'l',
};

/// Il testo breve di un'offerta sotto la riga: «3x2», «−30%», «−50% 2°»; null per quelle solo
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

/// Il testo di un'offerta per il CSV e il dettaglio: anche quelle informative.
String? offertaTesto(L l, Offerta? o) => switch (o) {
  null => null,
  OffertaNxM() || OffertaPercentuale() || OffertaSecondoAPercento() => offertaBreve(o),
  OffertaPrezzoBarrato(:final prezzoPieno) => l.offerta_anziche(importo(prezzoPieno)),
  OffertaPrezzoConCarta(:final prezzoSenzaCarta) => l.offerta_conCarta(importo(prezzoSenzaCarta)),
};

/// La pillola del foglio di conferma (F12.1.12): «3x2 · 1,26 cad. se ne prendi 3», «−30% alla
/// cassa · 0,69», «Anziche' 2,99 · risparmi 1,50», «Con carta · senza carta 2,49».
String offertaLunga(L l, Offerta o, Money prezzo) => switch (o) {
  OffertaNxM(:final prendi, :final paghi) =>
    l.offerta_nxmLunga('${prendi}x$paghi', importo(o.effettivo(prezzo)), prendi),
  OffertaPercentuale(:final percento) => l.offerta_percentoLunga(percento, importo(o.scontato(prezzo))),
  OffertaSecondoAPercento(:final percento) => l.offerta_secondoLunga(percento),
  OffertaPrezzoBarrato(:final prezzoPieno) =>
    l.offerta_barratoLunga(importo(prezzoPieno), importo(prezzoPieno - prezzo)),
  OffertaPrezzoConCarta(:final prezzoSenzaCarta) => l.offerta_cartaLunga(importo(prezzoSenzaCarta)),
};

/// La riga piccola sotto il nome nella lista: «3 × 2,49», «0,258 kg × 29,90 €/kg», «3x2»…
/// null se non serve (un pezzo, nessuna offerta).
String? dettaglioRiga(RigaSpesa r) {
  final parti = <String>[];
  switch (r.quantita) {
    case Pezzi(:final n):
      if (n > 1) parti.add('$n × ${importo(r.prezzoUnitario)}');
    case AMisura(:final millesimi, :final unita):
      final u = unitaTesto(unita);
      parti.add('${millesimiTesto(millesimi)} $u × ${importo(r.prezzoUnitario)} €/$u');
  }
  final o = offertaBreve(r.offerta);
  if (o != null) parti.add(o);
  return parti.isEmpty ? null : parti.join(' · ');
}

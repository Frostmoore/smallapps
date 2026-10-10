import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';

import '../app/providers.dart' show SrSettingKeys;
import '../data/database.dart';
import '../data/spesa_repository.dart';
import '../domain/offerta.dart';
import '../domain/quantita.dart';
import '../domain/riga_spesa.dart';
import '../domain/spesa.dart';

/// Dati di esempio per provare l'app e per gli screenshot e il video degli store.
///
/// `flutter run --dart-define=SR_DEMO=true`
///
/// ⚑ Perche' esistono: la spesa con il budget gia' a meta', lo storico di qualche mese in piu'
/// negozi e le statistiche col budget del mese si vedono solo dopo mesi d'uso, e da fuori (test
/// d'integrazione) non si scrivono date nel passato. Stesso principio di QR Me (`QM_DEMO`) e Film
/// Tracker (`FT_DEMO`).
///
/// ⚑ Il Pro **non** si attiva qui: come in QR Me lo compra il test d'integrazione con il gateway
/// finto (che in debug c'e' gia'), cosi' lo stesso giro fotografa anche il paywall per la
/// revisione di Apple. Le spese chiuse sono piu' di 5 anche senza Pro: il limite del gratis lo
/// applica la LETTURA (risposta D1), non il database.
///
/// ☠ Mai in release: anche compilato con il define, in release non fa niente.
const bool demoRequested = bool.fromEnvironment('SR_DEMO');

bool get demoEnabled => demoRequested && !kReleaseMode;

/// Il budget della spesa in corso e quello abituale: 40 € (la spesa d'esempio e' a 26,61, due
/// terzi della barra: verde, con il residuo ben leggibile).
const int kDemoBudgetCents = 4000;

/// Il tetto del mese (Pro, risposta D3): 400 €.
const int kDemoBudgetMeseCents = 40000;

/// Una riga d'esempio in due lingue (pubblica perche' lo e' [kDemoInCorso]).
typedef DemoRiga = ({String it, String en, Quantita q, int cents, Offerta? offerta, int? stampato, OrigineRiga o});

DemoRiga _pz(String it, String en, int cents, {int n = 1, Offerta? offerta, OrigineRiga o = OrigineRiga.tastierino}) =>
    (it: it, en: en, q: Pezzi(n), cents: cents, offerta: offerta, stampato: null, o: o);

/// La spesa in corso: nove righe da tutte e tre le strade (tastierino, cartellino con offerta,
/// bilancia). ⚑ Le stesse righe, con gli stessi importi, le ritrova lo scontrino finto degli
/// screenshot (`integration_test/letture_finte.dart`): li' il caffe' costa 4,29 invece del 3,49
/// del cartellino e c'e' il sacchetto, cosi' il confronto mostra le due righe sospette tipiche.
final List<DemoRiga> kDemoInCorso = [
  _pz('Latte intero 1 L', 'Whole milk 1 L', 129, n: 2),
  _pz('Pasta di semola 500 g', 'Durum wheat pasta 500 g', 89,
      n: 3, offerta: const OffertaNxM(prendi: 3, paghi: 2), o: OrigineRiga.cartellino),
  _pz('Caffè macinato 250 g', 'Ground coffee 250 g', 349,
      offerta: OffertaPrezzoBarrato(Money.cents(429)), o: OrigineRiga.cartellino),
  (
    it: 'Pomodori ciliegini',
    en: 'Cherry tomatoes',
    q: const AMisura(486, UnitaMisura.kg),
    cents: 390,
    offerta: null,
    stampato: 190,
    o: OrigineRiga.bilancia,
  ),
  _pz('Mozzarella 125 g', 'Mozzarella 125 g', 99, n: 2, o: OrigineRiga.cartellino),
  _pz('Olio extravergine 1 L', 'Extra virgin olive oil 1 L', 899, o: OrigineRiga.cartellino),
  _pz('Detersivo piatti', 'Dish soap', 149),
  (
    it: 'Banane',
    en: 'Bananas',
    q: const AMisura(1120, UnitaMisura.kg),
    cents: 179,
    offerta: null,
    stampato: 200,
    o: OrigineRiga.bilancia,
  ),
  _pz('Pane comune', 'Bread', 240),
];

/// Il catalogo da cui si compongono le spese dello storico (nome it, nome en, centesimi).
const List<(String, String, int)> _catalogo = [
  ('Latte intero 1 L', 'Whole milk 1 L', 129),
  ('Pane comune', 'Bread', 240),
  ('Uova fresche x6', 'Fresh eggs x6', 219),
  ('Pasta di semola 500 g', 'Durum wheat pasta 500 g', 89),
  ('Passata di pomodoro', 'Tomato passata', 99),
  ('Mozzarella 125 g', 'Mozzarella 125 g', 99),
  ('Parmigiano 200 g', 'Parmesan 200 g', 459),
  ('Prosciutto cotto 120 g', 'Cooked ham 120 g', 279),
  ('Petto di pollo', 'Chicken breast', 612),
  ('Mele golden', 'Golden apples', 245),
  ('Insalata mista', 'Mixed salad', 159),
  ('Yogurt greco x4', 'Greek yogurt x4', 299),
  ('Caffè macinato 250 g', 'Ground coffee 250 g', 429),
  ('Biscotti frollini', 'Shortbread biscuits', 229),
  ('Olio extravergine 1 L', 'Extra virgin olive oil 1 L', 899),
  ('Acqua naturale x6', 'Still water x6', 189),
  ('Detersivo lavatrice', 'Laundry detergent', 699),
  ('Carta igienica x8', 'Toilet paper x8', 349),
  ('Salmone affumicato', 'Smoked salmon', 549),
  ('Gelato vaniglia', 'Vanilla ice cream', 389),
];

/// I negozi dello storico, inventati (niente insegne vere nelle schede degli store).
const List<(String, String)> _negozi = [
  ('Supermercato Sole', 'Sunny Market'),
  ('Discount Rondine', 'Swallow Discount'),
  ('Mercato di quartiere', 'Corner Market'),
];

/// Riempie il database se e' vuoto e imposta il budget abituale e quello del mese.
///
/// Lo storico: una spesa ogni 3-4 giorni negli ultimi ~5 mesi (circa 45), a rotazione nei tre
/// negozi, piccole (6-9 righe) e grandi (15-20 righe): 350-450 € al mese, meta' con un budget (qualcuna sforata: le
/// statistiche contano gli sforamenti). In cima, la spesa in corso iniziata 25 minuti fa con il
/// budget di 40 €. ⚑ Numeri pseudo-casuali ma **fissi** (un generatore lineare con seme costante):
/// gli screenshot rifatti domani devono mostrare gli stessi totali.
Future<void> seedDemoData(SpendingDatabase db, SettingsStore settings, {bool english = false}) async {
  if (!demoEnabled) return;
  if ((await db.select(db.spese).get()).isNotEmpty) return;
  final now = DateTime.now();
  var seme = 20261010;
  int caso(int n) {
    seme = (seme * 1103515245 + 12345) & 0x7fffffff;
    return (seme >> 8) % n;
  }

  final base = SpesaRepository(db);
  final negozi = [for (final (it, en) in _negozi) await base.negozioPerNome(english ? en : it)];

  var giorni = 158;
  var i = 0;
  while (giorni >= 2) {
    final quando = DateTime(now.year, now.month, now.day, 10 + caso(8), caso(60)).subtract(Duration(days: giorni));
    final repo = SpesaRepository(db, ora: () => quando);
    final grande = i % 3 == 0;
    final righe = grande ? 15 + caso(6) : 6 + caso(4);
    for (var k = 0; k < righe; k++) {
      final (it, en, cents) = _catalogo[caso(_catalogo.length)];
      await repo.aggiungiRiga(RigaSpesa(
        nome: english ? en : it,
        quantita: Pezzi(1 + (caso(4) == 0 ? 1 : 0)),
        prezzoUnitario: Money.cents(cents),
        origine: caso(3) == 0 ? OrigineRiga.tastierino : OrigineRiga.cartellino,
      ));
    }
    if (i.isOdd || grande) {
      // ⚑ Budget un po' sotto il totale atteso una volta su tre: qualche sforamento vero.
      await repo.impostaBudget(Money.cents(grande ? (caso(3) == 0 ? 5500 : 8000) : (caso(3) == 0 ? 2500 : 4000)));
    }
    await repo.chiudi(
      data: CivilDate.fromDateTime(quando),
      negozioId: negozi[i % negozi.length],
      fonte: FonteRighe.contate,
    );
    giorni -= 3 + caso(2);
    i++;
  }

  final inizio = now.subtract(const Duration(minutes: 25));
  final repo = SpesaRepository(db, ora: () => inizio);
  await repo.assicuraInCorso(budgetPredefinito: Money.cents(kDemoBudgetCents));
  for (final r in kDemoInCorso) {
    await repo.aggiungiRiga(RigaSpesa(
      nome: english ? r.en : r.it,
      quantita: r.q,
      prezzoUnitario: Money.cents(r.cents),
      offerta: r.offerta,
      totaleStampato: r.stampato == null ? null : Money.cents(r.stampato!),
      origine: r.o,
    ));
  }

  await settings.setInt(SrSettingKeys.budgetPredefinito, kDemoBudgetCents);
  await settings.setInt(SrSettingKeys.budgetMensile, kDemoBudgetMeseCents);
}

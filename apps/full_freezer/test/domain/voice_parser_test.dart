import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/domain/units.dart';
import 'package:full_freezer/domain/voice_parser.dart';

/// F4.12/F4.13: il parser vocale su venti frasi reali, italiane e inglesi.
void main() {
  const it = VoiceItemParser(locale: 'it');

  // (frase, nome, quantita', unita', categoria)
  const casi = <(String, String, double?, String?, String?)>[
    ('due porzioni di lasagne', 'Lasagne', 2, Units.portions, 'prepared'),
    ('3 hamburger', 'Hamburger', 3, Units.pieces, 'meat_red'),
    ('mezzo chilo di macinato', 'Macinato', 0.5, Units.kilograms, 'meat_red'),
    ('un chilo e mezzo di cosce di pollo', 'Cosce di pollo', 1.5, Units.kilograms, 'meat_white'),
    ('500 grammi di piselli', 'Piselli', 500, Units.grams, 'vegetables'),
    ('500 g di gamberi', 'Gamberi', 500, Units.grams, 'fish'),
    ('due etti di prosciutto', 'Prosciutto', 200, Units.grams, null),
    ('una confezione di bastoncini di pesce', 'Bastoncini di pesce', 1, Units.packs, 'fish'),
    ('quattro pezzi di pane', 'Pane', 4, Units.pieces, 'bread'),
    ('un litro di brodo', 'Brodo', 1, Units.liters, 'prepared'),
    ("una vaschetta d'agnello", 'Agnello', 1, Units.packs, 'meat_red'),
    ('1,5 kg di salsicce', 'Salsicce', 1.5, Units.kilograms, 'meat_red'),
    ('spezzatino', 'Spezzatino', null, null, 'meat_red'),
    ('Ragù della nonna', 'Ragù della nonna', null, null, 'prepared'),
    ('two portions of chili', 'Chili', 2, Units.portions, 'prepared'),
    ('a bag of peas', 'Peas', 1, Units.packs, 'vegetables'),
    ('half a kilo of mince', 'Mince', 0.5, Units.kilograms, 'meat_red'),
    ('3 chicken breasts', 'Chicken breasts', 3, Units.pieces, 'meat_white'),
    ('a kilo and a half of beef', 'Beef', 1.5, Units.kilograms, 'meat_red'),
    // "ice" e' escluso apposta dal dizionario (category_guess.dart): nessuna categoria.
    ('ice cream', 'Ice cream', null, null, null),
  ];

  for (final (frase, nome, quantita, unita, categoria) in casi) {
    test('"$frase"', () {
      final p = it.parse(frase);
      expect(p.name, nome);
      expect(p.quantity, quantita);
      expect(p.unit, unita);
      expect(p.categoryKey, categoria);
    });
  }

  test('una quantita\' senza nome non e\' un errore: la frase intera va nel nome', () {
    final p = it.parse('due porzioni');
    expect(p.name, 'Due porzioni');
    expect(p.quantity, isNull);
    expect(p.confidence, 0);
  });

  test('la confidenza segue quanto si e\' capito', () {
    expect(it.parse('due porzioni di lasagne').confidence, 1);
    expect(it.parse('3 hamburger').confidence, 0.8);
    expect(it.parse('spezzatino').confidence, 0.5);
    expect(it.parse('   ').name, '');
  });
}

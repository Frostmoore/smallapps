import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_encoder.dart';

/// `QrCodeToDomain.content`: i campi salvati rotti ripiegano sul payload, che e' la verita' del QR.
void main() {
  const wifi = WifiContent(ssid: 'Casa', password: 'segreta123');
  final payload = QrEncoder.encode(wifi);

  QrCode row(String? fieldsJson, {String kind = 'wifi', String? p}) => QrCode(
    id: 1,
    kind: kind,
    payload: p ?? payload,
    fieldsJson: fieldsJson,
    title: 'Casa',
    source: QrSource.typed,
    isFavorite: false,
    createdAt: 0,
    lastUsedAt: 0,
  );

  test('campi buoni: si usano i campi', () {
    expect(
      row('{"ssid":"Altro","password":"x","security":"wpa","hidden":false}').content,
      const WifiContent(ssid: 'Altro', password: 'x'),
    );
  });

  test('JSON illeggibile: si ripiega sul payload', () {
    expect(row('{rotto').content, wifi);
  });

  // ☠ Il difetto trovato rileggendo l'atlante: JSON valido ma con i campi sbagliati.
  for (final f in [
    '{"foo":1}',
    '{"ssid":3}',
    '{"ssid":"Casa","security":"boh"}',
    '[1,2]',
    '"testo"',
    'null',
  ]) {
    test('JSON valido ma campi sbagliati ($f): si ripiega sul payload, non si lancia', () {
      expect(row(f).content, wifi);
    });
  }

  test('contatto con campi sbagliati: il payload vCard decodificato', () {
    const c = ContactContent(name: 'Mario Rossi', phone: '+39333');
    expect(row('{"name":null}', kind: 'contact', p: QrEncoder.encode(c)).content, c);
  });
}

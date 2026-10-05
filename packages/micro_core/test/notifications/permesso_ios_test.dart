import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Il rifiuto di iOS quando manca il permesso delle notifiche.
///
/// ⚑ L'eccezione e' quella vera, copiata dal registro del simulatore del 2026-10-05: e' cosi'
/// che arriva dal plugin quando si pianifica una notifica senza permesso.
void main() {
  test('il rifiuto di iOS per permesso mancante viene riconosciuto', () {
    final rifiuto = PlatformException(
      code: 'Error 2003',
      message: 'Repository could not save notification. Source is not authorized.',
      details: 'UNErrorDomain',
    );
    expect(NotificationService.rifiutoDiPermesso(rifiuto), isTrue);
  });

  test('gli altri errori non vengono scambiati per un permesso mancante', () {
    // Se questo test cadesse, un difetto vero di pianificazione verrebbe ingoiato in silenzio.
    final altro = PlatformException(code: 'invalid_icon', message: 'icona non trovata');
    expect(NotificationService.rifiutoDiPermesso(altro), isFalse);
  });
}

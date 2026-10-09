import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/services/app_settings.dart';

/// `AppSettings`: le impostazioni dell'app con la fotocamera negata, anche su Android, senza
/// dipendenze nuove (canale nostro verso `MainActivity.kt`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(AppSettings.channel, null));

  test('il nome del canale e\' quello di MainActivity.kt', () {
    expect(AppSettings.channel.name, 'com.smp.qrme/app_settings');
  });

  test('Android: chiama il metodo «open» del canale e ne restituisce la risposta', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(AppSettings.channel, (call) async {
      calls.add(call.method);
      return true;
    });
    const s = AppSettings(platform: TargetPlatform.android);
    expect(await s.open(), isTrue);
    expect(calls, ['open']);
  });

  test('Android: canale assente o in errore → false, non un\'eccezione', () async {
    const s = AppSettings(platform: TargetPlatform.android);
    expect(await s.open(), isFalse, reason: 'nessun gestore: MissingPluginException');
    messenger.setMockMethodCallHandler(
      AppSettings.channel,
      (_) async => throw PlatformException(code: 'boh'),
    );
    expect(await s.open(), isFalse);
  });

  test('iOS: app-settings: con url_launcher, nessun canale', () async {
    final opened = <Uri>[];
    final s = AppSettings(
      platform: TargetPlatform.iOS,
      launcher: (u) async {
        opened.add(u);
        return true;
      },
    );
    expect(await s.open(), isTrue);
    expect(opened.single.toString(), 'app-settings:');
  });

  test('altre piattaforme: false', () async {
    expect(await const AppSettings(platform: TargetPlatform.windows).open(), isFalse);
  });
}

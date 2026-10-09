import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_share/micro_share.dart';

import '../data/database.dart';
import '../data/qr_repository.dart';
import '../domain/qr_style.dart';
import '../services/content_actions.dart';
import '../services/logo_renderer.dart';
import '../services/qr_renderer.dart';
import '../services/readability_check.dart';
import '../services/screen_boost.dart';
import '../services/share_router.dart';
import 'entitlement.dart' show appVersion;

/// I provider radice dell'app (§8.T).
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di modulo
/// non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che servono solo
/// a una schermata. Con i provider l'inizializzazione e' pigra e ogni test inietta il proprio
/// doppio con un `override`. Stesso schema di Film Tracker.

/// Sovrascritti in `main()`: senza, l'app non parte.
final appConfigProvider = Provider<MicroAppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider va sovrascritto in main()'),
);

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider va sovrascritto in main()'),
);

final settingsProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsProvider va sovrascritto in main()'),
);

/// Le chiavi delle preferenze proprie di QR Me (quelle comuni sono in `SettingKeys`).
abstract final class QrSettingKeys {
  /// Cronologia accesa (default) o spenta (F17.0 punto 7).
  static const String historyEnabled = 'history_enabled';
}

/// Il tema scelto dall'utente, persistito.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      // ⚑ Scuro di default: la grafica «A · Neon» scelta dal proprietario (F17.6, 2026-10-09)
      // e' disegnata sul nero. Il QR resta leggibile: sta sempre su un pannello chiaro.
      _ => ThemeMode.dark,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// La cronologia accesa o spenta (F17.0 punto 7), persistita.
///
/// ⚑ Spenta, le pagine non chiamano `QrRepository.recordShown`: il QR si mostra da
/// `QrDisplayArgs` in memoria. Il repository non lo sa e non deve saperlo.
class HistoryEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsProvider).getBool(QrSettingKeys.historyEnabled, orElse: true);

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(settingsProvider).setBool(QrSettingKeys.historyEnabled, enabled);
  }
}

final historyEnabledProvider = NotifierProvider<HistoryEnabledNotifier, bool>(
  HistoryEnabledNotifier.new,
);

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<QrDatabase>((ref) {
  final db = QrDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// Le immagini dell'app: i loghi foto (bucket `QrLogoFiles.bucket`).
final imageStoreProvider = Provider<ImageStore>(
  (ref) => ImageStore(paths: ref.watch(appPathsProvider)),
);

final repositoryProvider = Provider<QrRepository>(
  (ref) => QrRepository(ref.watch(databaseProvider), images: ref.watch(imageStoreProvider)),
);

// ── Stream per la UI ─────────────────────────────────────────────────────────

/// La cronologia, dal piu' recente.
final historyProvider = StreamProvider<List<QrCode>>(
  (ref) => ref.watch(repositoryProvider).watchHistory(),
);

/// I preferiti, per titolo.
final favoritesProvider = StreamProvider<List<QrCode>>(
  (ref) => ref.watch(repositoryProvider).watchFavorites(),
);

/// Quanti preferiti: il conteggio per `FeatureKey.unlimitedEntities`.
final favoriteCountProvider = StreamProvider<int>(
  (ref) => ref.watch(repositoryProvider).watchFavoriteCount(),
);

/// Una riga per id (la pagina del QR salvato); null se cancellata.
final qrCodeProvider = StreamProvider.family<QrCode?, int>(
  (ref, id) => ref.watch(repositoryProvider).watchById(id),
);

// ── Servizi (lib/services/, F17.1.7) ─────────────────────────────────────────
//
// ⚑ Tutti dietro un provider: i test di widget li sostituiscono con doppi finti (scanner,
// luminosita', url_launcher, galleria), perche' sotto `flutter test` non c'e' nessun plugin.

final qrRendererProvider = Provider<QrRenderer>((ref) => const QrRenderer());

final logoRendererProvider = Provider<LogoRenderer>((ref) => const LogoRenderer());

/// Lo scanner su un file immagine (`analyzeImage`): «Da immagine», condivisione, verifica.
final qrImageReaderProvider = Provider<QrImageReader>((ref) => const MobileScannerImageReader());

final readabilityCheckProvider = Provider<ReadabilityCheck>(
  (ref) =>
      ReadabilityCheck(ref.watch(qrImageReaderProvider), renderer: ref.watch(qrRendererProvider)),
);

final screenBoostProvider = Provider<ScreenBoost>((ref) => const ScreenBoost());

final contentActionsProvider = Provider<ContentActions>((ref) => const ContentActions());

/// La cassetta delle condivisioni (F17.1.8). Nei test: `FakeShareInbox`.
final shareInboxProvider = Provider<ShareInbox>((ref) => RsiShareInbox());

/// ⚑ Uno solo per tutta l'app: il filtro dei doppioni (F17.1.11 punto 5) ricorda l'ultima
/// condivisione, e due istanze non si vedrebbero a vicenda.
final shareRouterProvider = Provider<ShareRouter>(
  (ref) => ShareRouter(reader: ref.watch(qrImageReaderProvider)),
);

/// Sceglie un'immagine dalla galleria e ne restituisce il percorso (null se l'utente annulla).
/// ⚑ Il selettore di sistema: nessun permesso su Android 13+ e su iOS (F17.1.2).
typedef PickImage = Future<String?> Function();

final pickImageProvider = Provider<PickImage>(
  (ref) =>
      () async => (await ImagePicker().pickImage(source: ImageSource.gallery))?.path,
);

/// Il servizio di backup di micro_core, con le cartelle dell'app e la sua versione.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

/// La chiave dell'immagine di un logo: il logo e i colori del suo piatto e del suo disegno.
typedef LogoKey = ({QrLogo logo, int background, int foreground});

/// Il lato in pixel a cui si disegna il logo: abbastanza per il PNG da 1024 (22% = 225 px).
const int kLogoPixels = 256;

/// L'immagine del logo, pronta per `QrRenderer` (null senza logo o con un logo illeggibile).
///
/// ⚑ Un provider e non un calcolo nel build: il disegno e' asincrono (TextPainter in un
/// PictureRecorder, decodifica della foto), e la stessa immagine serve all'anteprima, alla
/// pagina del QR e al PNG senza ridisegnarla.
final logoImageProvider = FutureProvider.autoDispose.family<ui.Image?, LogoKey>((ref, key) async {
  if (key.logo is NoLogo) return null;
  return ref
      .watch(logoRendererProvider)
      .render(
        key.logo,
        backgroundArgb: key.background,
        foregroundArgb: key.foreground,
        sizePx: kLogoPixels,
        images: ref.watch(imageStoreProvider),
      );
});

/// La chiave del logo per [style].
LogoKey logoKeyOf(QrStyle style) =>
    (logo: style.logo, background: style.background, foreground: style.foreground);

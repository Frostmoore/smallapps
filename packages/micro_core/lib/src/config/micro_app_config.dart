import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Quale implementazione di acquisto usare (ADR-006).
enum BillingMode {
  /// Gateway finto, in memoria e deterministico. Serve a sviluppare e testare tutto il
  /// flusso del paywall senza aver caricato l'app su un canale di Play Console.
  fake,

  /// Google Play Billing vero.
  play,
}

/// La configurazione di un'app delle MicroApps.
///
/// Vive in `micro_core` perche' la **forma** e' identica in tutte e quattro le app:
/// cambiano solo i valori. Ogni app dichiara la propria istanza in
/// `lib/app/app_config.dart` e la inietta nel `ProviderScope`.
///
/// `micro_core` non conosce nessuna app: qui non c'e' nessun elenco di appId, nessun
/// `switch` sul nome. Aggiungere una quinta app non richiede di toccare questo file.
@immutable
class MicroAppConfig {
  const MicroAppConfig({
    required this.appId,
    required this.appName,
    required this.proSku,
    required this.seedColor,
    required this.fontFamily,
    required this.defaultBrightness,
    required this.billingMode,
    this.displayFontFamily,
    this.licenseBaseUrl,
    this.appSecret = '',
  });

  /// Costruisce la configurazione leggendo i `--dart-define` dell'ambiente di build.
  ///
  /// | define | valori | significato |
  /// |---|---|---|
  /// | `BILLING` | `fake` \| `play` | quale gateway usare; senza define, `fake` in debug e `play` in release |
  /// | `MA_LICENSE_URL` | URL | base del License Server; assente = nessuna verifica lato server |
  /// | `MA_APP_SECRET` | stringa | segreto HMAC per firmare le chiamate (ADR-014) |
  ///
  /// Produrre una release con il gateway finto significherebbe regalare il Pro a
  /// chiunque tocchi il pulsante: [assertUsableInRelease] esiste per rendere quello
  /// sbaglio impossibile da spedire.
  factory MicroAppConfig.fromEnvironment({
    required String appId,
    required String appName,
    required String proSku,
    required Color seedColor,
    required String fontFamily,
    required Brightness defaultBrightness,
    String? displayFontFamily,
  }) {
    const billingRaw = String.fromEnvironment('BILLING');
    const licenseUrlRaw = String.fromEnvironment('MA_LICENSE_URL');
    const secret = String.fromEnvironment('MA_APP_SECRET');

    final mode = switch (billingRaw) {
      'fake' => BillingMode.fake,
      'play' => BillingMode.play,
      _ => kReleaseMode ? BillingMode.play : BillingMode.fake,
    };

    return MicroAppConfig(
      appId: appId,
      appName: appName,
      proSku: proSku,
      seedColor: seedColor,
      fontFamily: fontFamily,
      displayFontFamily: displayFontFamily,
      defaultBrightness: defaultBrightness,
      billingMode: mode,
      licenseBaseUrl: licenseUrlRaw.isEmpty ? null : Uri.tryParse(licenseUrlRaw),
      appSecret: secret,
    );
  }

  /// Identificatore interno, usato per i namespace di preferenze e cartelle.
  final String appId;

  /// Nome mostrato all'utente.
  final String appName;

  /// SKU del prodotto in-app su Google Play. Immutabile dopo la pubblicazione.
  final String proSku;

  final Color seedColor;
  final String fontFamily;
  final String? displayFontFamily;

  /// Il tema con cui l'app si presenta la prima volta, se l'utente non ha scelto.
  final Brightness defaultBrightness;

  final BillingMode billingMode;

  /// Base del License Server. `null` significa che l'app non parla con nessun server:
  /// funziona lo stesso, con il solo entitlement locale (ADR-007).
  final Uri? licenseBaseUrl;

  /// Segreto per la firma HMAC delle chiamate al server (ADR-014).
  ///
  /// Non e' un segreto vero: sta dentro l'APK e chi decompila lo trova. Serve a tenere
  /// fuori il traffico casuale, non a proteggere l'entitlement, che e' protetto dalla
  /// verifica dell'acquisto presso Google.
  final String appSecret;

  /// `true` se l'app puo' parlare con il License Server.
  bool get serverEnabled => licenseBaseUrl != null && appSecret.isNotEmpty;

  /// `true` se gli acquisti passano da Google Play.
  bool get usesRealBilling => billingMode == BillingMode.play;

  /// Fa fallire il programma se una build di release usa il gateway finto.
  ///
  /// Si chiama in `main()`, prima di `runApp`. Un crash all'avvio in fase di verifica
  /// e' incomparabilmente meno grave di una release che regala il Pro.
  void assertUsableInRelease() {
    if (kReleaseMode && billingMode == BillingMode.fake) {
      throw StateError(
        'Build di release con BILLING=fake: il paywall sbloccherebbe il Pro a chiunque. '
        'Ricompilare con --dart-define=BILLING=play.',
      );
    }
  }

  @override
  String toString() =>
      'MicroAppConfig($appId, billing: ${billingMode.name}, server: ${serverEnabled ? licenseBaseUrl : "nessuno"})';
}

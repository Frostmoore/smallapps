import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../util/micro_log.dart';
import '../util/result.dart';
import 'entitlement.dart';

/// La risposta del License Server.
@immutable
class ServerEntitlement {
  const ServerEntitlement({
    required this.status,
    required this.serverTime,
    this.productId,
    this.purchasedAt,
    this.revokedAt,
  });

  factory ServerEntitlement.fromJson(Map<String, Object?> json) => ServerEntitlement(
    status: switch (json['status']) {
      'pro' => ProStatus.pro,
      'pending' => ProStatus.pending,
      'revoked' => ProStatus.revoked,
      _ => ProStatus.free,
    },
    productId: json['sku'] as String?,
    purchasedAt: _time(json['purchasedAt']),
    revokedAt: _time(json['revokedAt']),
    serverTime: _time(json['serverTime']) ?? DateTime.now().toUtc(),
  );

  final ProStatus status;
  final String? productId;
  final DateTime? purchasedAt;
  final DateTime? revokedAt;
  final DateTime serverTime;

  static DateTime? _time(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
}

/// Un codice di ripristino, per riportare l'acquisto su un altro dispositivo.
@immutable
class RestoreCode {
  const RestoreCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Il contratto verso il License Server.
///
/// ⚑ Esiste separato dall'implementazione HTTP perché `EntitlementService` non ha alcun
/// bisogno di sapere che dall'altra parte c'è `package:http`. Il beneficio si vede nei
/// test: un doppio si scrive implementando quattro metodi, senza `noSuchMethod` e senza
/// dover fingere `baseUri`, `appSecret` e gli altri campi di configurazione che non
/// c'entrano niente con il comportamento sotto esame.
abstract interface class LicenseApi {
  Future<Result<ServerEntitlement>> verifyPurchase({
    required String sku,
    required String purchaseToken,
    String? orderId,
  });

  Future<Result<ServerEntitlement>> fetchEntitlement();

  Future<Result<RestoreCode>> createRestoreCode();

  Future<Result<ServerEntitlement>> claimRestoreCode(String code);

  void close();
}

/// Il client HTTP del License Server.
///
/// ⚑ Nessun retry qui dentro. Il ritentativo è responsabilità di chi chiama, che è
/// l'unico a sapere se l'operazione è critica (la verifica dopo un acquisto: sì, con
/// backoff) oppure opportunistica (la sincronizzazione periodica: no, si riproverà
/// domani). Un retry nascosto nel client trasforma un timeout di 8 secondi in uno di 24
/// senza che nessuno lo abbia deciso.
class LicenseApiClient implements LicenseApi {
  LicenseApiClient({
    required this.baseUri,
    required this.appId,
    required this.appSecret,
    required this.installId,
    required this.appVersion,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 8),
  }) : _http = httpClient ?? http.Client();

  final Uri baseUri;
  final String appId;
  final String appSecret;
  final String installId;
  final String appVersion;
  final Duration timeout;
  final http.Client _http;

  @override
  Future<Result<ServerEntitlement>> verifyPurchase({
    required String sku,
    required String purchaseToken,
    String? orderId,
  }) => _post('/v1/purchases/verify', <String, Object?>{
    'sku': sku,
    'purchaseToken': purchaseToken,
    'orderId': orderId,
    'appVersion': appVersion,
  }, ServerEntitlement.fromJson);

  @override
  Future<Result<ServerEntitlement>> fetchEntitlement() =>
      _get('/v1/entitlements/$installId', ServerEntitlement.fromJson);

  @override
  Future<Result<RestoreCode>> createRestoreCode() => _post(
    '/v1/restore/code',
    const <String, Object?>{},
    (json) => RestoreCode(
      code: json['code']! as String,
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(days: 7)),
    ),
  );

  @override
  Future<Result<ServerEntitlement>> claimRestoreCode(String code) => _post(
    '/v1/restore/claim',
    <String, Object?>{'code': code},
    ServerEntitlement.fromJson,
  );

  @override
  void close() => _http.close();

  /// Firma HMAC della richiesta (ADR-014).
  ///
  /// ☠ Non è sicurezza forte e non va spacciata per tale: `appSecret` sta dentro l'APK e
  /// chi decompila lo trova. Serve a tenere fuori il traffico casuale e a rendere non
  /// banale il replay. La sicurezza vera è che il server, prima di concedere qualcosa,
  /// verifica il `purchaseToken` presso Google.
  Map<String, String> _headers(String method, String path, String body) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final payload = '$method\n$path\n$timestamp\n$bodyHash';
    final signature = Hmac(sha256, utf8.encode(appSecret)).convert(utf8.encode(payload));
    return <String, String>{
      'content-type': 'application/json',
      'x-ma-app': appId,
      'x-ma-install': installId,
      'x-ma-timestamp': '$timestamp',
      'x-ma-signature': signature.toString(),
    };
  }

  Future<Result<T>> _post<T>(
    String path,
    Map<String, Object?> body,
    T Function(Map<String, Object?>) parse,
  ) async {
    final encoded = jsonEncode(body);
    return _send(
      () => _http
          .post(baseUri.resolve(path), headers: _headers('POST', path, encoded), body: encoded)
          .timeout(timeout),
      parse,
      path,
    );
  }

  Future<Result<T>> _get<T>(String path, T Function(Map<String, Object?>) parse) async =>
      _send(
        () => _http.get(baseUri.resolve(path), headers: _headers('GET', path, '')).timeout(timeout),
        parse,
        path,
      );

  Future<Result<T>> _send<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, Object?>) parse,
    String path,
  ) async {
    try {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, Object?>) {
          return const Err(
            MicroError(code: MicroErrorCodes.badResponse, message: 'Risposta non è un oggetto'),
          );
        }
        return Ok(parse(decoded));
      }
      return Err(_errorFor(response, path));
    } on Exception catch (error, stack) {
      MicroLog.w('chiamata a $path fallita', error: error);
      MicroLog.d('stack', data: stack);
      return Err(
        MicroError(
          code: MicroErrorCodes.network,
          message: 'Server non raggiungibile',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  MicroError _errorFor(http.Response response, String path) {
    String code;
    try {
      final decoded = jsonDecode(response.body);
      code = (decoded is Map && decoded['error'] is Map)
          ? ((decoded['error'] as Map)['code']?.toString() ?? 'http_${response.statusCode}')
          : 'http_${response.statusCode}';
    } on FormatException {
      code = 'http_${response.statusCode}';
    }
    MicroLog.w('$path ha risposto ${response.statusCode} ($code)');
    return MicroError(code: code, message: 'HTTP ${response.statusCode} da $path');
  }
}

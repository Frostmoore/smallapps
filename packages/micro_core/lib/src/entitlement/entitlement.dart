import 'package:meta/meta.dart';

/// Lo stato dell'acquisto Pro.
enum ProStatus {
  free,
  pro,

  /// Pagamento avviato e non ancora concluso (conferma bancaria, pagamento in contanti).
  pending,

  /// Rimborsato o annullato. È l'unico stato che può togliere il Pro.
  revoked,
}

/// Da dove viene l'informazione, in ordine di fiducia crescente.
enum EntitlementSource {
  none(0),
  local(1),
  play(2),
  server(3);

  const EntitlementSource(this.trust);
  final int trust;
}

/// Il diritto di questa installazione a usare le funzioni Pro.
///
/// Implementa ADR-007: la verità vive in un file locale, e il server può **promuovere**
/// ma non declassare per silenzio.
@immutable
class Entitlement {
  const Entitlement({
    required this.appId,
    required this.status,
    required this.source,
    this.productId,
    this.purchaseToken,
    this.purchasedAt,
    this.verifiedAt,
    this.revokedAt,
  });

  factory Entitlement.free(String appId) =>
      Entitlement(appId: appId, status: ProStatus.free, source: EntitlementSource.none);

  factory Entitlement.fromJson(Map<String, Object?> json) => Entitlement(
    appId: json['appId']! as String,
    status: ProStatus.values.byName(json['status']! as String),
    source: EntitlementSource.values.byName(json['source']! as String),
    productId: json['productId'] as String?,
    purchaseToken: json['purchaseToken'] as String?,
    purchasedAt: _readTime(json['purchasedAt']),
    verifiedAt: _readTime(json['verifiedAt']),
    revokedAt: _readTime(json['revokedAt']),
  );

  final String appId;
  final ProStatus status;
  final EntitlementSource source;
  final String? productId;
  final String? purchaseToken;
  final DateTime? purchasedAt;
  final DateTime? verifiedAt;
  final DateTime? revokedAt;

  bool get isPro => status == ProStatus.pro;
  bool get isPending => status == ProStatus.pending;
  bool get isRevoked => status == ProStatus.revoked;

  Map<String, Object?> toJson() => <String, Object?>{
    'appId': appId,
    'status': status.name,
    'source': source.name,
    'productId': productId,
    'purchaseToken': purchaseToken,
    'purchasedAt': purchasedAt?.toUtc().toIso8601String(),
    'verifiedAt': verifiedAt?.toUtc().toIso8601String(),
    'revokedAt': revokedAt?.toUtc().toIso8601String(),
  };

  Entitlement copyWith({
    ProStatus? status,
    EntitlementSource? source,
    String? productId,
    String? purchaseToken,
    DateTime? purchasedAt,
    DateTime? verifiedAt,
    DateTime? revokedAt,
  }) => Entitlement(
    appId: appId,
    status: status ?? this.status,
    source: source ?? this.source,
    productId: productId ?? this.productId,
    purchaseToken: purchaseToken ?? this.purchaseToken,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    revokedAt: revokedAt ?? this.revokedAt,
  );

  /// `true` se **questo** deve sostituire [other].
  ///
  /// È il cuore di ADR-007. Le regole, in ordine di applicazione:
  ///
  /// 1. Una **revoca dal server** vince sempre: è l'unico modo di togliere il Pro, e
  ///    corrisponde a un rimborso o a un chargeback reali.
  /// 2. Un Pro non viene **mai** sostituito da un free proveniente da una fonte di
  ///    fiducia uguale o inferiore. È la regola che impedisce a una risposta vuota, a un
  ///    timeout o a un errore di rete di declassare chi ha pagato.
  /// 3. A parità di stato, vince la fonte più affidabile.
  /// 4. A parità di stato e fonte, vince la verifica più recente.
  bool supersedes(Entitlement other) {
    // 1. Il nulla non sostituisce un'informazione.
    if (source == EntitlementSource.none && other.source != EntitlementSource.none) {
      return false;
    }

    // 2. **Un `free` non toglie mai il Pro, da nessuna fonte.** Nemmeno dal server: se il
    //    server volesse togliere il Pro dovrebbe dirlo con `revoked`, che è un fatto
    //    (rimborso, chargeback), non con l'assenza di un fatto. È questa riga che rende
    //    impossibile declassare chi ha pagato per una risposta vuota o un errore di rete.
    if (other.isPro && status == ProStatus.free) return false;

    // 3. Una revoca resta finché non arriva un acquisto **successivo** alla revoca.
    //    Senza questa regola un utente rimborsato non potrebbe più ricomprare l'app: la
    //    revoca vincerebbe per sempre su qualsiasi acquisto futuro.
    if (other.isRevoked && other.source == EntitlementSource.server && isPro) {
      if (source == EntitlementSource.server) return true;
      final revokedAt = other.revokedAt;
      final boughtAt = purchasedAt;
      if (revokedAt == null || boughtAt == null) return false;
      return boughtAt.isAfter(revokedAt);
    }

    // 4. A stati diversi, vince la fonte più affidabile.
    if (source.trust != other.source.trust) return source.trust > other.source.trust;

    // 5. Stessa fonte, stato diverso: è informazione nuova e si applica. È il caso di un
    //    pagamento che passa da `free` a `pending`, o da `pending` ad annullato.
    if (status != other.status) return true;

    // 6. Stesso stato e stessa fonte: vince la verifica più recente.
    final mine = verifiedAt;
    final theirs = other.verifiedAt;
    if (mine == null) return false;
    if (theirs == null) return true;
    return mine.isAfter(theirs);
  }

  static DateTime? _readTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.appId == appId &&
      other.status == status &&
      other.source == source &&
      other.productId == productId &&
      other.purchaseToken == purchaseToken;

  @override
  int get hashCode => Object.hash(appId, status, source, productId, purchaseToken);

  @override
  String toString() => 'Entitlement($appId, ${status.name}, da ${source.name})';
}

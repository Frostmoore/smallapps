import 'package:meta/meta.dart';

/// Esito di un'operazione che puo' fallire per cause **attese**.
///
/// Le eccezioni restano riservate ai bug. Rete assente, file corrotto, acquisto
/// annullato dall'utente non sono bug: sono esiti previsti, e vanno maneggiati dal
/// chiamante come valori. Questo evita il `try/catch` decorativo intorno a ogni
/// chiamata e rende impossibile dimenticare il ramo d'errore, perche' [fold] lo
/// richiede.
@immutable
sealed class Result<T> {
  const Result();

  /// `true` se l'operazione e' andata a buon fine.
  bool get isOk => this is Ok<T>;

  /// `true` se l'operazione e' fallita.
  bool get isErr => this is Err<T>;

  /// Il valore, oppure `null` se l'esito e' un errore.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// L'errore, oppure `null` se l'esito e' positivo.
  MicroError? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };

  /// Il valore, oppure [fallback] se l'esito e' un errore.
  T orElse(T fallback) => valueOrNull ?? fallback;

  /// Riduce i due rami a un unico valore. Entrambi i rami sono obbligatori.
  R fold<R>({required R Function(T value) ok, required R Function(MicroError error) err}) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final error) => err(error),
      };

  /// Trasforma il valore, propagando l'errore invariato.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final error) => Err<R>(error),
  };

  /// Concatena un'altra operazione fallibile, propagando l'errore invariato.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => transform(value),
    Err<T>(:final error) => Err<R>(error),
  };
}

/// Esito positivo.
@immutable
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

/// Esito negativo.
@immutable
final class Err<T> extends Result<T> {
  const Err(this.error);

  final MicroError error;

  @override
  bool operator ==(Object other) => other is Err<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Err<T>, error);

  @override
  String toString() => 'Err($error)';
}

/// Errore atteso, con un codice stabile su cui il chiamante puo' ramificare.
///
/// Il [code] non e' un messaggio: e' un identificatore che non cambia quando si
/// riscrive il testo per l'utente o lo si traduce. Il [message] e' per i log, non
/// per la UI: le stringhe mostrate all'utente vivono negli ARB.
@immutable
class MicroError {
  const MicroError({required this.code, required this.message, this.cause, this.stackTrace});

  /// Errore generico da un'eccezione non prevista.
  factory MicroError.unexpected(Object cause, [StackTrace? stackTrace]) => MicroError(
    code: 'unexpected',
    message: cause.toString(),
    cause: cause,
    stackTrace: stackTrace,
  );

  final String code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      other is MicroError && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'MicroError($code): $message';
}

/// Codici d'errore condivisi da piu' moduli di `micro_core`.
///
/// I moduli possono definirne altri, purche' documentati nel proprio atlante.
abstract final class MicroErrorCodes {
  static const String network = 'network';
  static const String timeout = 'timeout';
  static const String unauthorized = 'unauthorized';
  static const String notFound = 'not_found';
  static const String rateLimited = 'rate_limited';
  static const String badResponse = 'bad_response';
  static const String io = 'io';
  static const String corruptedFile = 'corrupted_file';
  static const String unsupportedVersion = 'unsupported_version';
  static const String billingUnavailable = 'billing_unavailable';
  static const String purchaseCanceled = 'purchase_canceled';
  static const String purchaseFailed = 'purchase_failed';
  static const String permissionDenied = 'permission_denied';
  static const String unexpected = 'unexpected';
}

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../util/civil_date.dart';

/// Preferenze dell'app, tipizzate e con namespace.
///
/// ⚑ Perché il namespace: le quattro app hanno preferenze omonime (`onboarding_done`).
/// In produzione i processi sono separati e non collidono, ma in test e in eventuali
/// build multi-flavor sì. Il prefisso costa nulla e toglie una classe di bug.
///
/// ⚑ Perché ogni getter richiede un `orElse` invece di restituire `null`: una preferenza
/// mancante ha sempre un significato ("non ancora impostata" = un valore preciso), e
/// obbligare a dichiararlo sul posto evita i `?? false` sparsi che nascondono la
/// differenza fra "spento" e "mai deciso".
class SettingsStore {
  SettingsStore._(this._prefs, this.namespace);

  static Future<SettingsStore> create({required String namespace}) async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStore._(prefs, namespace);
  }

  /// Costruttore per i test, con un'istanza già pronta.
  factory SettingsStore.withPreferences(SharedPreferences prefs, {required String namespace}) =>
      SettingsStore._(prefs, namespace);

  final SharedPreferences _prefs;
  final String namespace;

  final StreamController<String> _changes = StreamController<String>.broadcast();

  /// Emette la chiave modificata, senza prefisso.
  Stream<String> get changes => _changes.stream;

  String _k(String key) => '$namespace.$key';

  void _notify(String key) {
    if (!_changes.isClosed) _changes.add(key);
  }

  bool getBool(String key, {required bool orElse}) => _prefs.getBool(_k(key)) ?? orElse;

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(_k(key), value);
    _notify(key);
  }

  int getInt(String key, {required int orElse}) => _prefs.getInt(_k(key)) ?? orElse;

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(_k(key), value);
    _notify(key);
  }

  double getDouble(String key, {required double orElse}) => _prefs.getDouble(_k(key)) ?? orElse;

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(_k(key), value);
    _notify(key);
  }

  String? getString(String key) => _prefs.getString(_k(key));

  Future<void> setString(String key, String value) async {
    await _prefs.setString(_k(key), value);
    _notify(key);
  }

  List<String> getStringList(String key) => _prefs.getStringList(_k(key)) ?? const <String>[];

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(_k(key), value);
    _notify(key);
  }

  /// Le date civili si salvano come `YYYY-MM-DD` anche qui, coerentemente con ADR-008.
  CivilDate? getDate(String key) => CivilDate.tryParse(_prefs.getString(_k(key)));

  Future<void> setDate(String key, CivilDate value) async {
    await _prefs.setString(_k(key), value.toIso());
    _notify(key);
  }

  /// Gli istanti veri si salvano in millisecondi UTC.
  DateTime? getInstant(String key) {
    final ms = _prefs.getInt(_k(key));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> setInstant(String key, DateTime value) async {
    await _prefs.setInt(_k(key), value.toUtc().millisecondsSinceEpoch);
    _notify(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(_k(key));
    _notify(key);
  }

  /// Cancella solo le chiavi di questo namespace, non quelle delle altre app.
  Future<void> clearNamespace() async {
    final prefix = '$namespace.';
    for (final key in _prefs.getKeys().where((k) => k.startsWith(prefix)).toList()) {
      await _prefs.remove(key);
    }
    _notify('*');
  }

  Future<void> dispose() => _changes.close();
}

/// Chiavi condivise da tutte le app. Le chiavi specifiche stanno nell'app che le usa.
abstract final class SettingKeys {
  static const String onboardingDone = 'onboarding_done';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String lastRescheduleAt = 'last_reschedule_at';
  static const String lastServerSyncAt = 'last_server_sync_at';
  static const String paywallShownCount = 'paywall_shown_count';
  static const String reviewPromptShownAt = 'review_prompt_shown_at';
  static const String launchCount = 'launch_count';
  static const String firstLaunchAt = 'first_launch_at';
}

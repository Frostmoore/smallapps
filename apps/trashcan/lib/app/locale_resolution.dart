import 'package:flutter/widgets.dart';

/// Le lingue supportate, **con l'inglese per primo**.
///
/// L'ordine non e' estetico: quando il dispositivo non corrisponde a nessuna lingua
/// supportata, Flutter ripiega sul primo elemento della lista. Mettere l'italiano per
/// primo darebbe l'italiano a un utente tedesco.
const List<Locale> kSupportedLocales = <Locale>[Locale('en'), Locale('it')];

/// Italiano sui dispositivi italiani, inglese su tutti gli altri (ADR-011).
///
/// Si controlla il solo `languageCode`, cosi' che `it`, `it_IT` e `it_CH` ricevano tutti
/// l'italiano.
///
/// Non si segue l'intera lista di preferenze del dispositivo cercando la prima lingua
/// supportata: un utente con preferenze `[de, it, en]` riceverebbe l'italiano perche'
/// viene prima dell'inglese. E' difendibile in astratto, ma sorprende: chi ha il
/// telefono in tedesco si aspetta l'inglese come ripiego. Si guarda solo se l'italiano
/// compare tra le preferenze, e in caso contrario si va in inglese.
Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'it') return const Locale('it');
  }
  return const Locale('en');
}

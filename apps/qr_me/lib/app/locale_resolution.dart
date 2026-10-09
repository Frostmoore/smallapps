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
/// ⚑ Si guarda **tutta** la lista delle preferenze, e basta che l'italiano ci compaia in
/// qualunque posizione: `[de, it, en]` da' l'italiano, `[de, en]` l'inglese. Chi ha messo
/// l'italiano fra le sue lingue lo legge; l'inglese e' il ripiego solo per chi non l'ha.
/// E' il codice dell'ADR-011 (develop_microapps.md), identico in tutte le app.
///
/// ☠ Fino al 2026-10-09 questo commento diceva il contrario (che `[de, it, en]` dovesse dare
/// l'inglese): era sbagliato il commento, non il codice. Le copie nelle altre app hanno ancora
/// il testo vecchio.
Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'it') return const Locale('it');
  }
  return const Locale('en');
}

import 'dart:async';

import '../../app/routes.dart';
import '../../data/film_repository.dart';

/// I link del QR del rullino (F6.12): `filmtracker://roll/<sequenceNumber>`.
///
/// ⚑ Il QR porta il **numero del rullino** ("#17") e non l'id del database: il numero e' quello
/// scritto in chiaro sotto il codice e sul contenitore, e' UNIQUE (`FilmRolls.sequenceNumber`)
/// e resta lo stesso dopo un ripristino del backup, mentre l'id puo' cambiare.

/// Il testo da mettere nel QR del rullino numero [sequenceNumber].
String rollQrData(int sequenceNumber) => '${Routes.scheme}://roll/$sequenceNumber';

/// Il numero del rullino letto da un link del QR; null se il link non e' nostro o e' storto.
///
/// Accetta `filmtracker://roll/17` (la forma che scriviamo), con o senza barra finale, e
/// `filmtracker:///roll/17` (host vuoto: alcuni lettori di QR riscrivono cosi' gli schemi che
/// non conoscono). Rifiuta numeri non positivi, segni, spazi, altri percorsi e altri schemi.
///
/// ⚑ Funzione pura: e' l'unico punto in cui un testo arrivato da fuori (un QR stampato da
/// chiunque) entra nell'app, quindi si prova da sola (`test/features/qr/qr_links_test.dart`).
int? sequenceFromUri(Uri uri) {
  if (uri.scheme.toLowerCase() != Routes.scheme) return null;
  final parts = [
    if (uri.host.isNotEmpty) uri.host.toLowerCase(),
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  if (parts.length != 2 || parts[0] != 'roll') return null;
  final digits = parts[1];
  // Solo cifre, e al massimo nove: niente "+17", "1e3", "0x11" o numeri fuori da un int SQLite
  // ragionevole.
  if (!RegExp(r'^[0-9]{1,9}$').hasMatch(digits)) return null;
  final n = int.parse(digits);
  return n > 0 ? n : null;
}

/// Dove portare l'utente per il link [uri]: il dettaglio del rullino (`Routes.rollOf(id)`),
/// oppure null se il link non e' nostro o quel rullino su questo telefono non c'e'.
Future<String?> locationForRollLink(Uri uri, FilmRepository repository) async {
  final n = sequenceFromUri(uri);
  if (n == null) return null;
  final roll = await repository.rollBySequence(n);
  return roll == null ? null : Routes.rollOf(roll.id);
}

/// Ascolta i link in ingresso e apre il rullino con [open] (in app: `router.push`).
///
/// [links] e' `AppLinks().uriLinkStream`, che da app_links 6 consegna **anche** il link con cui
/// l'app e' stata aperta da chiusa: basta ascoltare lui, senza `getInitialLink` (che lo
/// consegnerebbe due volte). I link non nostri o di rullini che non ci sono si ignorano: la
/// home resta dov'e', che e' il comportamento meno sorprendente.
///
/// Restituisce l'abbonamento, da cancellare in `dispose`.
StreamSubscription<Uri> listenRollLinks({
  required Stream<Uri> links,
  required FilmRepository Function() repository,
  required void Function(String location) open,
}) => links.listen((uri) async {
  final location = await locationForRollLink(uri, repository());
  if (location != null) open(location);
});

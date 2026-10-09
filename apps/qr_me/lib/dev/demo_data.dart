import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/qr_repository.dart';
import '../domain/qr_content.dart';
import '../domain/qr_encoder.dart';
import '../domain/qr_style.dart';

/// Dati di esempio per provare l'app e per gli screenshot e il video degli store.
///
/// `flutter run --dart-define=QM_DEMO=true`
///
/// ⚑ Perche' esistono: la home con preferiti e recenti, il Wi-Fi di casa con lo stile e il logo
/// si vedono solo dopo giorni d'uso, e da fuori (test d'integrazione) non si scrivono date nel
/// passato. Stesso principio dei dati di esempio di Film Tracker (`FT_DEMO`).
///
/// ⚑ Il Pro **non** si attiva qui: come in Film Tracker lo compra il test d'integrazione con il
/// gateway finto (che in debug c'e' gia'), cosi' lo stesso giro fotografa anche il paywall per la
/// revisione di Apple. I preferiti sono tre anche senza Pro: il limite di 1 lo controlla chi salva
/// (`saveAsFavorite` in qr_actions.dart), non il repository.
///
/// ☠ Mai in release: anche compilato con il define, in release non fa niente.
const bool demoRequested = bool.fromEnvironment('QM_DEMO');

bool get demoEnabled => demoRequested && !kReleaseMode;

/// Lo stile «Neon» del Wi-Fi di casa: verde scuro su bianco, moduli e occhi rotondi, l'icona del
/// Wi-Fi al centro. ⚑ Verde `#2E7D32` (uno dei tondini della pagina Stile) e non il `#3BD13B`
/// dell'interfaccia: il verde acceso su bianco ha un contrasto sotto 3 e la pagina Stile
/// mostrerebbe l'avviso rosso proprio nello screenshot.
const QrStyle kDemoNeonStyle = QrStyle(
  foreground: 0xFF2E7D32,
  background: 0xFFFFFFFF,
  moduleShape: QrModuleShape.circle,
  eyeShape: QrEyeShape.circle,
  logo: IconLogo('wifi'),
);

/// Un QR d'esempio: contenuto, da dove, giorni fa (e minuti, per l'ordine), preferito con nome.
typedef _Demo = ({
  QrContent content,
  String source,
  int days,
  int minutes,
  String? favorite,
  QrStyle style,
});

/// Riempie il database se e' vuoto. Restituisce l'id del Wi-Fi di casa (o null se non ha scritto).
///
/// Due preferiti (il Wi-Fi di casa con lo stile Neon, il proprio contatto) e quattro recenti negli
/// ultimi giorni: un sito, un testo, un contatto letto, un'email precompilata. ⚑ Due preferiti e
/// non tre: con tre, nello screenshot della home i recenti finivano sotto il bordo dello schermo.
/// ⚑ Niente telefono ne' SMS: dopo F17.10 non hanno piu' un modulo, e uno scatto che li mostra
/// prometterebbe una funzione che non c'e'.
Future<int?> seedDemoData(QrDatabase db, {bool english = false}) async {
  if (!demoEnabled) return null;
  if ((await db.select(db.qrCodes).get()).isNotEmpty) return null;
  final now = DateTime.now();

  final demo = <_Demo>[
    (
      content: WifiContent(ssid: english ? 'Home' : 'Casa Rossi', password: 'girasole-2024'),
      source: QrSource.form,
      days: 20,
      minutes: 0,
      favorite: english ? 'Home Wi-Fi' : 'Wi-Fi di casa',
      style: kDemoNeonStyle,
    ),
    (
      content: ContactContent(
        name: 'Giulia Rossi',
        phone: '+39 347 123 4567',
        email: 'giulia.rossi@example.com',
        organization: english ? 'Rossi Design Studio' : 'Studio Rossi Design',
      ),
      source: QrSource.form,
      days: 18,
      minutes: 0,
      favorite: english ? 'My contact' : 'Il mio contatto',
      style: QrStyle.plain,
    ),
    (
      content: EmailContent(
        to: 'info@smpmicroapps.it',
        subject: english ? 'Booking request' : 'Richiesta di prenotazione',
        body: english
            ? 'Hello, I would like to book for two people on Saturday.'
            : 'Buongiorno, vorrei prenotare per due persone sabato.',
      ),
      source: QrSource.form,
      days: 4,
      minutes: 0,
      favorite: null,
      style: QrStyle.plain,
    ),
    (
      content: ContactContent(
        name: 'Marco Bianchi',
        phone: '+39 333 765 4321',
        organization: english ? 'Bianchi Plumbing' : 'Idraulica Bianchi',
      ),
      source: QrSource.scanned,
      days: 3,
      minutes: 0,
      favorite: null,
      style: QrStyle.plain,
    ),
    (
      content: TextContent(
        english
            ? 'Gate code 4512 - second floor, buzzer "Rossi"'
            : 'Codice del cancello 4512 - secondo piano, citofono «Rossi»',
      ),
      source: QrSource.typed,
      days: 1,
      minutes: 0,
      favorite: null,
      style: QrStyle.plain,
    ),
    (
      content: UrlContent(Uri.parse('https://smpmicroapps.it')),
      source: QrSource.shared,
      days: 0,
      minutes: 30,
      favorite: null,
      style: QrStyle.plain,
    ),
  ];

  int? wifi;
  for (final d in demo) {
    final at = now.subtract(Duration(days: d.days, minutes: d.minutes));
    final repo = QrRepository(db, clock: () => at);
    final id = await repo.recordShown(
      content: d.content,
      payload: QrEncoder.encode(d.content),
      source: d.source,
      style: d.style,
    );
    if (d.favorite case final title?) await repo.saveAsFavorite(id, title: title);
    wifi ??= id;
  }
  return wifi;
}

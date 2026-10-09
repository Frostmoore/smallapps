import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_share/micro_share.dart';

import '../app/routes.dart';
import '../data/database.dart' show QrSource;
import '../domain/qr_decoder.dart';
import '../domain/qr_encoder.dart';
import 'readability_check.dart';

/// Com'e' andata una condivisione: la pagina che ascolta mostra un messaggio per gli esiti che
/// non aprono niente.
enum ShareOutcome {
  /// Un testo o un link: aperto `/show`.
  shownText,

  /// Un'immagine con un QR: aperto `/scan/result`.
  scannedImage,

  /// Un'immagine senza QR: «Nessun QR in questa immagine».
  noQrInImage,

  /// Il lettore di QR (ZXing) non c'e' su questo dispositivo: «Non riesco a leggere le immagini qui».
  readerUnavailable,

  /// Lo stesso elemento arrivato di nuovo entro [ShareRouter.duplicateWindow]: ignorato.
  duplicate,

  /// Niente di utilizzabile (lista vuota).
  nothing,
}

/// Da cio' che un'altra app ha condiviso alla rotta giusta (develop_microapps.md F17.1.7).
///
/// - [SharedText] → `QrDecoder.decodeTyped` (un link senza schema diventa un link) → `/show` con
///   `source: shared`. ⚑ `decodeTyped` e non `decode`: chi condivide «esempio.it» intende il sito.
/// - [SharedImage] → il lettore ZXing sul file → `/scan/result` con `source: image`, o
///   [ShareOutcome.noQrInImage].
/// - Piu' elementi: il primo testo, altrimenti la prima immagine.
///
/// ☠ **Doppioni** (F17.1.11 punto 5): con l'app aperta `incoming` e `initial` possono consegnare
/// lo stesso elemento. Un payload identico entro [duplicateWindow] dal precedente si ignora:
/// altrimenti si aprirebbero due pagine del QR una sopra l'altra.
class ShareRouter {
  ShareRouter({required this._reader, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final QrImageReader _reader;
  final DateTime Function() _clock;

  static const Duration duplicateWindow = Duration(seconds: 2);

  SharedPayload? _last;
  DateTime? _lastAt;

  /// Instrada una consegna intera (la lista che arriva da `ShareInbox`).
  Future<ShareOutcome> handleAll(List<SharedPayload> payloads, GoRouter router) async {
    final pick =
        payloads.whereType<SharedText>().firstOrNull ??
        payloads.whereType<SharedImage>().firstOrNull;
    if (pick == null) return ShareOutcome.nothing;
    return handle(pick, router);
  }

  /// Instrada un elemento.
  Future<ShareOutcome> handle(SharedPayload payload, GoRouter router) async {
    final now = _clock();
    final last = _lastAt;
    if (payload == _last && last != null && now.difference(last) < duplicateWindow) {
      MicroLog.i('condivisione doppia ignorata');
      return ShareOutcome.duplicate;
    }
    _last = payload;
    _lastAt = now;

    switch (payload) {
      case SharedText(:final text):
        final content = QrDecoder.decodeTyped(text);
        unawaited(
          router.push(
            Routes.show,
            extra: QrDisplayArgs(
              content: content,
              payload: QrEncoder.encode(content),
              source: QrSource.shared,
            ),
          ),
        );
        return ShareOutcome.shownText;
      case SharedImage(:final path):
        final List<String> values;
        try {
          values = await _reader.read(path);
        } on QrReaderUnavailable {
          return ShareOutcome.readerUnavailable;
        }
        if (values.isEmpty) return ShareOutcome.noQrInImage;
        unawaited(
          router.push(
            Routes.scanResult,
            extra: ScanResultArgs(raw: values.first, source: QrSource.image),
          ),
        );
        return ShareOutcome.scannedImage;
    }
  }
}

/// Il collegamento fra la cassetta delle condivisioni e il router dell'app (F17.1.8).
///
/// All'avvio: [ShareInbox.initial] **una volta**, subito [ShareInbox.reset] (☠ senza, la stessa
/// condivisione torna a galla anche su `incoming`), poi l'ascolto di [ShareInbox.incoming].
///
/// ⚑ Separato dal widget dell'app perche' si testi con `FakeShareInbox` e un router vero, senza
/// montare l'app intera (database, entitlement...).
///
/// ☠ Funziona solo con il **deep link di Flutter spento** (F17.1.11 punto 6): acceso, lo schema
/// `ShareMedia-…` di iOS (o l'intent di Android) arriverebbe anche a go_router, che cercherebbe
/// una rotta e mostrerebbe «Non trovato».
class ShareIntake {
  ShareIntake({required this.inbox, required this.router, required this.goRouter, this.onOutcome});

  final ShareInbox inbox;
  final ShareRouter router;
  final GoRouter goRouter;

  /// Per i messaggi (immagine senza QR, lettore assente).
  final void Function(ShareOutcome outcome)? onOutcome;

  StreamSubscription<List<SharedPayload>>? _sub;

  Future<void> start() async {
    _sub = inbox.incoming.listen(
      (payloads) => unawaited(_route(payloads)),
      onError: (Object error, StackTrace stack) =>
          MicroLog.e('condivisione in arrivo', error: error, stackTrace: stack),
    );
    try {
      final first = await inbox.initial();
      await inbox.reset();
      if (first.isNotEmpty) await _route(first);
    } on Object catch (error, stack) {
      // Un plugin che fallisce all'avvio non deve impedire all'app di aprirsi.
      MicroLog.e('condivisione iniziale', error: error, stackTrace: stack);
    }
  }

  Future<void> _route(List<SharedPayload> payloads) async {
    final outcome = await router.handleAll(payloads, goRouter);
    onOutcome?.call(outcome);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

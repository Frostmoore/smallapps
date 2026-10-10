import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/lettura/cartellino_parser.dart';
import '../../domain/quantita.dart';
import '../../domain/riga_spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/lettura_service.dart';
import '../cartellino/conferma_bilancia_sheet.dart';
import '../cartellino/conferma_cartellino_sheet.dart';
import '../cartellino/peso_sheet.dart';

/// Le scritture sulla spesa in corso fatte dall'interfaccia, in un posto solo: il tastierino, i
/// fogli del cartellino e della bilancia, il foglio della riga.
///
/// ⚑ Perche' passano tutte da qui: la spesa si crea **pigramente** al primo articolo (F12.1.11) e
/// deve nascere col **budget abituale** (`budgetPredefinitoProvider`); e ogni riga aggiunta deve
/// dare la stessa vibrazione. Tre strade diverse che lo fanno ognuna a modo suo finiscono per
/// dimenticarlo in una.
class AzioniSpesa {
  AzioniSpesa(this._ref);

  final WidgetRef _ref;

  /// La spesa in corso, creata se serve con il budget abituale. Ritorna l'id.
  Future<int> assicura() => _ref
      .read(spesaRepositoryProvider)
      .assicuraInCorso(budgetPredefinito: _ref.read(budgetPredefinitoProvider));

  /// Aggiunge una riga contata (e vibra).
  Future<void> aggiungi(RigaSpesa riga) async {
    await assicura();
    await _ref.read(spesaRepositoryProvider).aggiungiRiga(riga);
    _ref.read(apticaProvider).aggiunto();
  }

  /// +[pezzi] a una riga a pezzi gia' nella spesa («Aggiungi (ora 2)»).
  Future<void> incrementa(RigaSpesa riga, int pezzi) async {
    final n = riga.pezzi;
    if (n == null) return;
    final nuovi = (n + pezzi).clamp(1, Pezzi.massimo);
    await _ref.read(spesaRepositoryProvider).aggiornaRiga(riga.copyWith(quantita: Pezzi(nuovi)));
    _ref.read(apticaProvider).aggiunto();
  }
}

/// Il giro completo del cartellino (F12.1.12): mirino → risultato → foglio giusto → riga.
///
/// - `LettoCartellino`: con piu' cartellini prima «quale?»; con il solo prezzo al kg il foglio del
///   **peso**; altrimenti il foglio di conferma. ☠ Mai una riga senza un tocco su Aggiungi.
/// - `LettaBilancia`: il foglio della bilancia.
/// - `NienteLetto` / `OcrAssente`: un messaggio che manda al tastierino, mai un crash.
/// «Riprova» riapre il mirino; «Leggi l'etichetta della bilancia» lo riapre in modo bilancia.
Future<void> flussoCartellino(BuildContext context, WidgetRef ref, {bool bilancia = false}) async {
  final r = await context.push<RisultatoCartellino>(bilancia ? Routes.cartellinoBilancia : Routes.cartellino);
  if (r == null || !context.mounted) return;
  await gestisciRisultatoCartellino(context, ref, r);
}

/// La seconda meta' di [flussoCartellino], separata per i test (il risultato senza la fotocamera).
Future<void> gestisciRisultatoCartellino(BuildContext context, WidgetRef ref, RisultatoCartellino r) async {
  final l = L.of(context);
  final azioni = AzioniSpesa(ref);
  switch (r) {
    case OcrAssente():
      MicroSnack.show(context, l.cartellino_ocrAssente, icon: Icons.dialpad);
    case NienteLetto(:final forseAMano):
      MicroSnack.show(context, forseAMano ? l.cartellino_forseAMano : l.cartellino_nienteLetto, icon: Icons.dialpad);
    case LettaBilancia(:final lettura):
      final esito = await ConfermaBilanciaSheet.show(context, lettura);
      if (!context.mounted) return;
      switch (esito) {
        case BilanciaAggiungi(:final riga):
          await azioni.aggiungi(riga);
        case BilanciaRiprova():
          await flussoCartellino(context, ref, bilancia: true);
        case null:
          break;
      }
    case LettoCartellino(:final lettura):
      if (lettura.vuota) return;
      final PropostaCartellino? proposta = lettura.proposte.length > 1
          ? await SceltaCartellinoSheet.show(context, lettura.proposte)
          : lettura.proposte.first;
      if (proposta == null || !context.mounted) return;
      final unitario = proposta.unitario;
      if (proposta.aMisura && unitario != null) {
        await _flussoPeso(context, ref, nome: proposta.nome, alKg: unitario.valore, unita: unitario.unita);
        return;
      }
      final esistenti = ref.read(spesaInCorsoProvider).value?.righe ?? const <RigaSpesa>[];
      final esito = await ConfermaCartellinoSheet.show(context, proposta: proposta, esistenti: esistenti);
      if (!context.mounted) return;
      switch (esito) {
        case CartellinoAggiungi(:final riga):
          await azioni.aggiungi(riga);
        case CartellinoIncrementa(:final esistente, :final pezzi):
          await azioni.incrementa(esistente, pezzi);
        case CartellinoRiprova():
          await flussoCartellino(context, ref);
        case CartellinoBattiAMano(:final prezzo):
          if (prezzo != null) ref.read(tastierinoProvider.notifier).precompila(prezzo);
        case null:
          break;
      }
  }
}

/// Il peso a mano dopo un cartellino al kg: riga `AMisura`, o il mirino in modo bilancia.
Future<void> _flussoPeso(
  BuildContext context,
  WidgetRef ref, {
  required String nome,
  required Money alKg,
  required UnitaMisura unita,
}) async {
  final esito = await PesoSheet.show(context, alKg: alKg, unita: unita, nome: nome);
  if (!context.mounted) return;
  switch (esito) {
    case PesoScelto(:final quantita):
      await AzioniSpesa(ref).aggiungi(
        RigaSpesa(nome: nome.trim(), quantita: quantita, prezzoUnitario: alKg, origine: OrigineRiga.cartellino),
      );
    case PesoLeggiBilancia():
      await flussoCartellino(context, ref, bilancia: true);
    case null:
      break;
  }
}

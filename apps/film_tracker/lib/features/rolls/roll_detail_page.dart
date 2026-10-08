import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../data/film_repository.dart';
import '../../domain/roll_status.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/film_strip.dart';
import '../photos/image_store_provider.dart';
import '../photos/roll_photos_section.dart';

/// Il dettaglio di un rullino (F6.6): intestazione, azione del momento, **timeline verticale**
/// (caricato → terminato → consegnato → sviluppato → stampato), foto, poi QR, modifica ed
/// eliminazione.
///
/// ⚑ **Timeline e non una scheda a campi**: "ogni rullino diventa una scheda cronologica"
/// (spec). La cronologia e' la struttura del dato; una griglia di campi la nasconderebbe.
///
/// ⚑ **Il suggerimento dello stato si calcola qui, dagli stream**, con
/// `RollStatusMachine.suggestFrom` (la stessa regola di `FilmRepository.suggestedStatus`):
/// cosi' compare appena si torna dal modulo dello sviluppo o della stampa, senza che quelle
/// pagine debbano avvisare il dettaglio.
class RollDetailPage extends ConsumerWidget {
  const RollDetailPage({required this.rollId, super.key});

  final int rollId;

  static const RollStatusMachine _machine = RollStatusMachine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final rollAsync = ref.watch(rollProvider(rollId));
    final roll = rollAsync.value;

    if (roll == null) {
      return Scaffold(
        appBar: AppBar(),
        body: rollAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : MicroEmptyState(icon: Icons.search_off, title: l.roll_notFound, message: ''),
      );
    }

    final devAsync = ref.watch(developmentProvider(rollId));
    final printsAsync = ref.watch(printsProvider(rollId));
    final dev = devAsync.value;
    final prints = printsAsync.value ?? const <PrintOrder>[];
    final cameras = ref.watch(camerasProvider).value ?? const <Camera>[];
    Camera? camera;
    for (final c in cameras) {
      if (c.id == roll.cameraId) camera = c;
    }

    final status = roll.statusEnum;
    // Solo con sviluppo e stampe arrivati: prima, il suggerimento sarebbe sbagliato per un
    // istante e lampeggerebbe.
    final suggested = devAsync.hasValue && printsAsync.hasValue
        ? _machine.suggestFrom(
            current: status,
            finishedAt: roll.finishedDate,
            development: dev?.toLabEvent(),
            prints: [for (final p in prints) p.toLabEvent()],
          )
        : status;

    return Scaffold(
      appBar: AppBar(title: Text(l.roll_detailTitle(roll.sequenceNumber))),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          _Header(roll: roll, camera: camera),
          if (suggested != status) ...[
            MicroSpacing.gapL,
            _SuggestionCard(roll: roll, suggested: suggested),
          ],
          MicroSpacing.gapL,
          _StatusActions(roll: roll),
          MicroSpacing.gapXL,
          SectionLabel(l.roll_timeline),
          _Timeline(roll: roll, camera: camera, development: dev, prints: prints),
          if (roll.note != null) ...[
            MicroSpacing.gapL,
            Text(roll.note!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          MicroSpacing.gapXL,
          RollPhotosSection(rollId: rollId),
          MicroSpacing.gapXL,
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.qr_code_2),
            title: Text(l.roll_qr),
            onTap: () => context.push(Routes.qrOf(rollId)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.swap_vert),
            title: Text(l.roll_changeStatus),
            onTap: () => unawaited(_changeStatus(context, ref, roll)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.roll_editTitle),
            onTap: () => context.push(Routes.rollEditOf(rollId)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(
              l.roll_delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => unawaited(_delete(context, ref, roll)),
          ),
        ],
      ),
    );
  }

  /// Il cambio di stato a mano: solo le transizioni ammesse da `RollStatusMachine` (F6.3).
  ///
  /// ⚑ Niente "forza" da qui: le transizioni ammesse coprono gia' le correzioni sensate
  /// (annullare una consegna, ristampare, togliere dall'archivio). Lo stato fuori sequenza
  /// arriva solo dal suggerimento, che ha dietro un dato registrato.
  Future<void> _changeStatus(BuildContext context, WidgetRef ref, FilmRoll roll) async {
    final l = L.of(context);
    final from = roll.statusEnum;
    final targets = RollStatusMachine.allowedTransitions[from] ?? const <RollStatus>{};
    final to = await showModalBottomSheet<RollStatus>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: MicroSpacing.pageH,
              child: Text(l.roll_changeStatusHelp(statusName(l, from))),
            ),
            MicroSpacing.gapS,
            for (final s in RollStatus.values)
              if (targets.contains(s))
                ListTile(
                  key: ValueKey('status-${s.key}'),
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(statusName(l, s)),
                  onTap: () => Navigator.of(sheet).pop(s),
                ),
            MicroSpacing.gapS,
          ],
        ),
      ),
    );
    if (to == null || !context.mounted) return;
    await _setStatus(context, ref, roll.id, to);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FilmRoll roll) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.roll_deleteTitle(roll.sequenceNumber),
      message: l.roll_deleteBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(repositoryProvider);
    final store = ref.read(imageStoreProvider);
    // ☠ Il database non cancella i file (F6.2): i percorsi tornano dal repository e si
    // cancellano qui, altrimenti le foto restano sul telefono per sempre.
    final paths = await repo.deleteRollAndCollectImagePaths(rollId);
    for (final relative in paths) {
      try {
        final file = store.resolve(relative);
        if (file.existsSync()) await file.delete();
      } on Object catch (e, st) {
        // Un file che non si cancella resta orfano: lo toglie `pruneOrphans`, non e' un
        // motivo per fermare l'eliminazione.
        MicroLog.e('file del rullino $rollId', error: e, stackTrace: st);
      }
    }
    if (!context.mounted) return;
    MicroSnack.success(context, l.roll_deleted);
    context.pop();
  }

  /// Porta il rullino allo stato [to] e lo dice; [force] solo per il suggerimento.
  static Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    int id,
    RollStatus to, {
    bool force = false,
  }) async {
    final l = L.of(context);
    try {
      await ref.read(repositoryProvider).setRollStatus(id, to, force: force);
      if (context.mounted) MicroSnack.success(context, l.roll_statusChanged(statusName(l, to)));
    } on RollTransitionException catch (e, st) {
      MicroLog.e('transizione rifiutata', error: e, stackTrace: st);
    }
  }
}

/// Pellicola, titolo, stato, formato, ISO, fotogrammi, macchina.
class _Header extends StatelessWidget {
  const _Header({required this.roll, required this.camera});

  final FilmRoll roll;
  final Camera? camera;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iso = roll.isPushPull
        ? 'ISO ${roll.nominalIso} · ${l.roll_exposedAt(roll.exposedIso)}'
        : 'ISO ${roll.nominalIso}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(roll.title ?? roll.filmName, style: theme.textTheme.headlineSmall),
        if (roll.title != null) Text(roll.filmName, style: theme.textTheme.titleMedium),
        MicroSpacing.gapS,
        Wrap(
          spacing: MicroSpacing.s,
          runSpacing: MicroSpacing.s,
          children: [
            Chip(
              key: const ValueKey('roll-status'),
              avatar: Icon(Icons.circle, size: 10, color: scheme.primary),
              label: Text(statusName(l, roll.statusEnum)),
            ),
            Chip(label: Text(formatName(l, roll.formatEnum))),
            Chip(
              label: Text(iso),
              backgroundColor: roll.isPushPull ? scheme.tertiaryContainer : null,
            ),
            Chip(label: Text(l.roll_framesCount(roll.frames))),
            if (camera != null)
              Chip(
                avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                label: Text(camera!.displayName),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Sviluppo e stampe dicono «Sviluppato»" con "Applica".
class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.roll, required this.suggested});

  final FilmRoll roll;
  final RollStatus suggested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('roll-suggestion'),
      color: scheme.secondaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: MicroSpacing.cardTight,
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: scheme.onSecondaryContainer),
            MicroSpacing.hGapM,
            Expanded(
              child: Text(
                l.roll_suggestion(statusName(l, suggested)),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              // ⚑ `force` se la macchina a stati non lo ammette: il suggerimento nasce da
              // uno sviluppo o una stampa registrati, quindi dice la verita' anche quando il
              // rullino ha saltato un passo (sviluppo registrato su un rullino ancora "in
              // macchina").
              onPressed: () => unawaited(
                RollDetailPage._setStatus(
                  context,
                  ref,
                  roll.id,
                  suggested,
                  force: !RollDetailPage._machine.canTransition(roll.statusEnum, suggested),
                ),
              ),
              child: Text(l.roll_suggestionApply),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'azione del momento, secondo lo stato (F6.6):
/// - `loaded`: "Rullino terminato", un tocco (`markFinished` con la data di oggi);
/// - `exposed`: "Consegna al laboratorio" (modulo dello sviluppo);
/// - `sentForDevelopment`: "Registra sviluppo" (lo stesso modulo, per il ritorno);
/// - `developed`/`printed`: "Aggiungi stampa" e "Archivia";
/// - `archived`: "Aggiungi stampa" (una ristampa mesi dopo, F6.3).
class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.roll});

  final FilmRoll roll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final id = roll.id;

    Widget primary(String key, IconData icon, String label, VoidCallback onTap) =>
        FilledButton.icon(
          key: ValueKey(key),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        );

    final addPrint = primary(
      'action-print',
      Icons.photo_library_outlined,
      l.roll_actionAddPrint,
      () => context.push(Routes.printNewOf(id)),
    );

    final children = switch (roll.statusEnum) {
      RollStatus.loaded => [
        primary('action-finished', Icons.flag_outlined, l.roll_actionFinished, () async {
          await ref.read(repositoryProvider).markFinished(id, ref.read(todayProvider));
          if (context.mounted) MicroSnack.success(context, l.roll_finishedDone);
        }),
      ],
      RollStatus.exposed => [
        primary(
          'action-deliver',
          Icons.local_shipping_outlined,
          l.roll_actionDeliver,
          () => context.push(Routes.developmentOf(id)),
        ),
      ],
      RollStatus.sentForDevelopment => [
        primary(
          'action-development',
          Icons.science_outlined,
          l.roll_actionDevelopment,
          () => context.push(Routes.developmentOf(id)),
        ),
      ],
      RollStatus.developed || RollStatus.printed => [
        addPrint,
        OutlinedButton.icon(
          key: const ValueKey('action-archive'),
          onPressed: () =>
              unawaited(RollDetailPage._setStatus(context, ref, id, RollStatus.archived)),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l.roll_actionArchive),
        ),
      ],
      RollStatus.archived => [addPrint],
    };

    return Wrap(spacing: MicroSpacing.s, runSpacing: MicroSpacing.s, children: children);
  }
}

/// Un evento della timeline.
class _Event {
  const _Event({
    required this.icon,
    required this.title,
    required this.done,
    this.date,
    this.details = const [],
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool done;
  final CivilDate? date;
  final List<String> details;
  final VoidCallback? onTap;
}

/// La timeline verticale: caricato → terminato → consegnato → sviluppato → stampato, con date
/// e costi accanto a ogni evento, e la spesa totale in fondo.
///
/// Un evento e' "fatto" se c'e' il dato **oppure** se lo stato dice che e' passato (uno stato
/// messo a mano senza registrare lo sviluppo): la timeline non deve contraddire lo stato.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.roll,
    required this.camera,
    required this.development,
    required this.prints,
  });

  final FilmRoll roll;
  final Camera? camera;
  final Development? development;
  final List<PrintOrder> prints;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = roll.statusEnum;
    final dev = development;
    // L'ordine degli stati lungo la vita del rullino; `archived` non dice che cosa e' successo
    // (si archivia anche un rullino mai sviluppato), quindi non segna nulla come fatto.
    bool reached(RollStatus s) => status != RollStatus.archived && status.index >= s.index;
    String money(int? cents) => cents == null ? '' : formatCents(l, cents);
    void openDev() => context.push(Routes.developmentOf(roll.id));

    final events = <_Event>[
      _Event(
        icon: Icons.camera_roll_outlined,
        title: l.roll_eventLoaded,
        done: true,
        date: roll.loadedDate,
        details: [?camera?.displayName, if (roll.costCents != null) money(roll.costCents)],
      ),
      _Event(
        icon: Icons.flag_outlined,
        title: l.roll_eventFinished,
        done: roll.finishedAt != null || reached(RollStatus.exposed),
        date: roll.finishedDate,
      ),
      if (dev == null || !dev.selfDeveloped)
        _Event(
          icon: Icons.local_shipping_outlined,
          title: l.roll_eventDelivered,
          done: dev != null || reached(RollStatus.sentForDevelopment),
          date: dev?.submittedDate,
          details: [
            if (dev?.laboratory != null && dev!.laboratory!.trim().isNotEmpty) dev.laboratory!,
          ],
          onTap: openDev,
        ),
      _Event(
        icon: Icons.science_outlined,
        title: dev != null && dev.selfDeveloped ? l.roll_eventSelfDeveloped : l.roll_eventDeveloped,
        done: (dev?.toLabEvent().isReturned ?? false) || reached(RollStatus.developed),
        date: dev?.returnedDate,
        details: [
          if (dev?.processEnum != null) processName(l, dev!.processEnum!),
          if (dev?.developmentCostCents != null)
            l.roll_costDevelopment(money(dev!.developmentCostCents)),
          if (dev?.scanCostCents != null) l.roll_costScan(money(dev!.scanCostCents)),
        ],
        onTap: openDev,
      ),
      if (prints.isEmpty)
        _Event(
          icon: Icons.photo_library_outlined,
          title: l.roll_eventPrinted,
          done: reached(RollStatus.printed),
          onTap: () => context.push(Routes.printNewOf(roll.id)),
        )
      else
        for (final p in prints)
          _Event(
            icon: Icons.photo_library_outlined,
            title: p.returnedAt != null ? l.roll_eventPrintBack : l.roll_eventPrintOrdered,
            done: true,
            date: p.returnedDate ?? p.submittedDate,
            details: [
              if (p.laboratory != null && p.laboratory!.trim().isNotEmpty) p.laboratory!,
              ?p.format,
              if (p.numberOfPrints != null) l.roll_printsCount(p.numberOfPrints!),
              if (p.costCents != null) money(p.costCents),
            ],
            onTap: () => context.push(Routes.printEditOf(roll.id, p.id)),
          ),
    ];

    final total = [
      roll.costCents,
      dev?.developmentCostCents,
      dev?.scanCostCents,
      for (final p in prints) p.costCents,
    ].whereType<int>().fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < events.length; i++)
          _EventRow(event: events[i], isLast: i == events.length - 1),
        if (total > 0) ...[
          MicroSpacing.gapS,
          Text(
            l.roll_totalCost(formatCents(l, total)),
            key: const ValueKey('roll-total'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ],
    );
  }
}

/// Una riga della timeline: il pallino (pieno se fatto, vuoto se no) con la linea verso il
/// prossimo evento, e a destra titolo, data e dettagli.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.isLast});

  final _Event event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final e = event;
    final color = e.done ? scheme.primary : scheme.outline;
    final when = e.date != null
        ? formatDay(l, e.date!)
        : (e.done ? l.roll_noDate : l.roll_eventNotYet);
    final details = [
      for (final d in e.details)
        if (d.isNotEmpty) d,
    ].join(' · ');

    return InkWell(
      onTap: e.onTap,
      borderRadius: const BorderRadius.all(MicroRadius.small),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.done ? color : null,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(e.icon, size: 15, color: e.done ? scheme.onPrimary : color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: scheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            MicroSpacing.hGapM,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: MicroSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: e.done ? null : scheme.mutedText,
                      ),
                    ),
                    Text(when, style: theme.textTheme.bodySmall?.copyWith(color: scheme.mutedText)),
                    if (details.isNotEmpty) Text(details, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

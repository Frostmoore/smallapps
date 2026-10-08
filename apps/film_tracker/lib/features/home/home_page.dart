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
import '../rolls/roll_cover.dart';

/// La home a tre sezioni (F6.8): In macchina, In laboratorio, Archivio.
///
/// Interfaccia essenziale (F6.0 punto 6): Material 3 pulito, la grafica definitiva arriva con
/// le proposte. Le tre sezioni stanno in **una sola pagina che scorre** e non in tre schede:
/// i rullini in macchina e in laboratorio sono pochi (uno, due, tre), e l'archivio sotto,
/// con le copertine, e' quello che si vuole vedere appena si apre l'app.
///
/// ⚑ Ogni sezione ha il suo stream (`rollItemsProvider(section)`): un rullino che cambia stato
/// passa da una sezione all'altra da solo, senza che la pagina sappia perche'.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final inCamera = ref.watch(rollItemsProvider(RollSection.inCamera));
    final atLab = ref.watch(rollItemsProvider(RollSection.atLab));
    final archive = ref.watch(rollItemsProvider(RollSection.archive));

    final sections = [inCamera, atLab, archive];
    final Widget body;
    if (sections.any((s) => s.hasError && !s.hasValue)) {
      body = MicroEmptyState(
        icon: Icons.error_outline,
        title: l.home_loadError,
        message: l.home_loadErrorBody,
        actionLabel: l.common_retry,
        onAction: () => ref.invalidate(rollItemsProvider),
      );
    } else if (sections.any((s) => !s.hasValue)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (sections.every((s) => s.value!.isEmpty)) {
      // ⚑ Tutto vuoto: un invito solo, non tre sezioni vuote che sembrano un'app rotta.
      body = MicroEmptyState(
        icon: Icons.camera_roll_outlined,
        title: l.home_emptyTitle,
        message: l.home_emptyBody,
        actionLabel: l.home_emptyAction,
        onAction: () => context.push(Routes.rollNew),
      );
    } else {
      body = _Sections(inCamera: inCamera.value!, atLab: atLab.value!, archive: archive.value!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.home_menuMore,
            icon: const Icon(Icons.more_vert),
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: Routes.cameras,
                child: ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l.home_menuCameras),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: Routes.stocks,
                child: ListTile(
                  leading: const Icon(Icons.camera_roll_outlined),
                  title: Text(l.home_menuStocks),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // Pro (F6.10): senza il Pro la pagina mostra il lucchetto (ProGate).
              PopupMenuItem(
                value: Routes.stats,
                child: ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(l.stats_title),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: l.settings_title,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.rollNew),
        icon: const Icon(Icons.add),
        label: Text(l.home_newRoll),
      ),
    );
  }
}

/// Le tre sezioni, quando c'e' almeno un rullino.
class _Sections extends ConsumerWidget {
  const _Sections({required this.inCamera, required this.atLab, required this.archive});

  final List<RollListItem> inCamera;
  final List<RollListItem> atLab;
  final List<RollListItem> archive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final today = ref.watch(todayProvider);
    final muted = Theme.of(context).colorScheme.mutedText;
    final hint = Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted);

    // In laboratorio: chi aspetta da piu' tempo in cima (F6.8). Senza data di consegna in
    // fondo: non si sa da quanto aspetta.
    final lab = [...atLab]
      ..sort((a, b) {
        final da = waitingDays(a, today);
        final db = waitingDays(b, today);
        if (da == null && db == null) {
          return b.roll.sequenceNumber.compareTo(a.roll.sequenceNumber);
        }
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    Widget header(String title, int count) => Padding(
      padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.xl, MicroSpacing.l, 0),
      child: MicroSectionHeader(title: title, count: count == 0 ? null : '$count'),
    );

    Widget emptyLine(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l),
      child: Text(text, style: hint),
    );

    return CustomScrollView(
      slivers: [
        // ── In macchina ──
        SliverToBoxAdapter(child: header(l.home_inCamera, inCamera.length)),
        if (inCamera.isEmpty)
          SliverToBoxAdapter(child: emptyLine(l.home_inCameraEmpty))
        else
          SliverList.list(
            children: [for (final i in inCamera) _InCameraCard(item: i, today: today)],
          ),

        // ── In laboratorio ──
        SliverToBoxAdapter(child: header(l.home_atLab, lab.length)),
        if (lab.isEmpty)
          SliverToBoxAdapter(child: emptyLine(l.home_atLabEmpty))
        else
          SliverList.list(
            children: [
              for (final i in lab) _AtLabCard(item: i, waitingDays: waitingDays(i, today)),
            ],
          ),

        // ── Archivio ──
        SliverToBoxAdapter(child: header(l.home_archive, archive.length)),
        if (archive.isEmpty) ...[
          SliverToBoxAdapter(child: emptyLine(l.home_archiveEmpty)),
          const SliverToBoxAdapter(child: MicroSpacing.gapM),
          // ⚑ Archivio vuoto: due segnaposti con la striscia di pellicola, per far vedere
          // cosa ci sara' (F6.8), non un buco.
          SliverPadding(
            padding: MicroSpacing.pageH,
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: MicroSpacing.m,
              crossAxisSpacing: MicroSpacing.m,
              childAspectRatio: 1.5,
              children: const [
                _PlaceholderTile(key: ValueKey('archive-placeholder-0')),
                _PlaceholderTile(key: ValueKey('archive-placeholder-1')),
              ],
            ),
          ),
        ] else
          SliverPadding(
            padding: MicroSpacing.pageH,
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: MicroSpacing.m,
                crossAxisSpacing: MicroSpacing.m,
                childAspectRatio: 0.82,
              ),
              itemCount: archive.length,
              itemBuilder: (_, i) => _ArchiveCard(item: archive[i]),
            ),
          ),
        // Spazio per il FAB: l'ultima riga non deve finirci sotto.
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

/// Da quanti giorni il rullino e' in laboratorio: dalla consegna dello sviluppo
/// (`submittedAt`). Null se la consegna non ha data (stato messo a mano, o sviluppo registrato
/// senza data): quei rullini vanno in fondo alla sezione.
@visibleForTesting
int? waitingDays(RollListItem item, CivilDate today) {
  final since = item.development?.submittedDate;
  if (since == null) return null;
  final days = since.daysUntil(today);
  return days < 0 ? 0 : days;
}

/// Il numero del rullino, "#17", nel colore d'accento: il riferimento con cui l'utente lo
/// ritrova sul contenitore (QR, F6.12).
class _SeqBadge extends StatelessWidget {
  const _SeqBadge({required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 22,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text('#$n', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

/// Una card della sezione In macchina: pellicola, macchina, giorni dal caricamento.
class _InCameraCard extends StatelessWidget {
  const _InCameraCard({required this.item, required this.today});

  final RollListItem item;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final roll = item.roll;
    final loaded = roll.loadedDate;
    final days = loaded?.daysUntil(today).clamp(0, 100000);
    final when = item.status == RollStatus.exposed
        ? l.home_finishedToDeliver
        : (days == null ? l.home_notLoadedYet : l.home_loadedDaysAgo(days));
    final details = [
      if (roll.title != null) roll.filmName,
      ?item.camera?.displayName,
      if (roll.isPushPull) 'ISO ${roll.exposedIso}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l, vertical: 4),
        leading: _SeqBadge(n: roll.sequenceNumber),
        title: Text(roll.title ?? roll.filmName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [if (details.isNotEmpty) details, when].join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: details.isNotEmpty,
        trailing: item.status == RollStatus.exposed
            ? Icon(Icons.local_shipping_outlined, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () => context.push(Routes.rollOf(roll.id)),
      ),
    );
  }
}

/// Una card della sezione In laboratorio: "Ilford HP5+ — consegnato 5 giorni fa".
class _AtLabCard extends StatelessWidget {
  const _AtLabCard({required this.item, required this.waitingDays});

  final RollListItem item;
  final int? waitingDays;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final roll = item.roll;
    final days = waitingDays;
    final delivered = days == null ? l.home_delivered : l.home_deliveredDaysAgo(days);
    final lab = item.development?.laboratory?.trim();
    final details = [?roll.title, if (lab != null && lab.isNotEmpty) lab].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l, vertical: 4),
        leading: _SeqBadge(n: roll.sequenceNumber),
        title: Text('${roll.filmName} — $delivered', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: details.isEmpty
            ? null
            : Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.hourglass_top_outlined),
        onTap: () => context.push(Routes.rollOf(roll.id)),
      ),
    );
  }
}

/// Una card dell'archivio: copertina (o striscia di pellicola), titolo e periodo.
class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.item});

  final RollListItem item;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.mutedText;
    final roll = item.roll;
    final period = formatPeriod(l, roll.loadedDate, roll.finishedDate);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(Routes.rollOf(roll.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: RollCover(
                cover: item.cover,
                edgeLabel: '${roll.filmName} · ${roll.sequenceNumber}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MicroSpacing.m, MicroSpacing.s, MicroSpacing.m, 0),
              child: Text(
                roll.title ?? roll.filmName,
                style: text.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MicroSpacing.m, 2, MicroSpacing.m, MicroSpacing.s),
              child: Text(
                ['#${roll.sequenceNumber}', ?period].join(' · '),
                style: text.bodySmall?.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un segnaposto dell'archivio vuoto: solo la striscia, senza testo.
class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({super.key});

  @override
  Widget build(BuildContext context) => const ClipRRect(
    borderRadius: BorderRadius.all(MicroRadius.medium),
    child: Opacity(opacity: 0.7, child: FilmStripPlaceholder()),
  );
}

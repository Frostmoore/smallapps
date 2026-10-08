import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/film_palette.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../data/film_repository.dart';
import '../../domain/roll_status.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/film_strip.dart';
import '../rolls/roll_cover.dart';

/// La home a tre sezioni (F6.8): In macchina, In laboratorio, Archivio, vestita da
/// **"C · Provino"** (scelta del proprietario, 2026-10-08; F6.0 punto 6).
///
/// - In macchina: ogni rullino e' una striscia di pellicola con le perforazioni e la scritta a
///   bordo ("ILFORD HP5+ 800 ▸ 12"), i giorni in macchina in arancio monospaziato.
/// - In laboratorio: righe compatte con i giorni d'attesa.
/// - Archivio: un foglio provini a tre colonne, ogni fotogramma con il suo numero.
///
/// Le tre sezioni stanno in **una sola pagina che scorre** e non in tre schede: i rullini in
/// macchina e in laboratorio sono pochi, e l'archivio sotto e' quello che si vuole vedere.
///
/// ⚑ Ogni sezione ha il suo stream (`rollItemsProvider(section)`): un rullino che cambia stato
/// passa da una sezione all'altra da solo, senza che la pagina sappia perche'.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FilmPalette.of(context);
    final inCamera = ref.watch(rollItemsProvider(RollSection.inCamera));
    final atLab = ref.watch(rollItemsProvider(RollSection.atLab));
    final archive = ref.watch(rollItemsProvider(RollSection.archive));

    final sections = [inCamera, atLab, archive];
    final total = sections.fold<int>(0, (n, s) => n + (s.value?.length ?? 0));
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(total: total),
            Expanded(child: body),
          ],
        ),
      ),
      // Il pulsante principale largo in fondo, come nel disegno: il gesto piu' frequente.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () => context.push(Routes.rollNew),
            icon: const Icon(Icons.add),
            label: EdgeText(l.home_newRoll, size: 15, bold: true, color: p.onEdge),
          ),
        ),
      ),
    );
  }
}

/// La testata: la scritta a bordo, il titolo, il menu e le impostazioni.
class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FilmPalette.of(context);
    Widget quadrato(Widget child) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: p.strip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdgeText(l.home_overline(total)),
                const SizedBox(height: 4),
                Text(
                  l.home_title,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.ink),
                ),
              ],
            ),
          ),
          quadrato(
            PopupMenuButton<String>(
              tooltip: l.home_menuMore,
              icon: Icon(Icons.more_vert, color: p.ink),
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
          ),
          const SizedBox(width: 8),
          quadrato(
            IconButton(
              tooltip: l.settings_title,
              icon: Icon(Icons.settings_outlined, color: p.ink),
              onPressed: () => context.push(Routes.settings),
            ),
          ),
        ],
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
    final p = FilmPalette.of(context);
    final today = ref.watch(todayProvider);
    final hint = Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.inkMuted);

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

    Widget label(String title, int count) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: SectionLabel(title, count: count),
    );

    Widget emptyLine(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(text, style: hint),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── In macchina ──
        label(l.home_inCamera, inCamera.length),
        if (inCamera.isEmpty)
          emptyLine(l.home_inCameraEmpty)
        else
          for (final i in inCamera)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _InCameraStrip(item: i, today: today),
            ),

        // ── In laboratorio ──
        label(l.home_atLab, lab.length),
        if (lab.isEmpty)
          emptyLine(l.home_atLabEmpty)
        else
          for (final i in lab)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _AtLabRow(item: i, waitingDays: waitingDays(i, today)),
            ),

        // ── Archivio: il foglio provini ──
        label(l.home_contactSheet, archive.length),
        if (archive.isEmpty) ...[
          emptyLine(l.home_archiveEmpty),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ContactSheet(items: archive),
        ),
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

/// La scritta a bordo di un rullino: "ILFORD HP5+ 800 ▸ 12".
///
/// ⚑ L'ISO si aggiunge solo se non e' gia' nel nome ("Kodak Portra 400" restava
/// "PORTRA 400 400", visto sull'emulatore il 2026-10-08) o se il rullino e' stato tirato o
/// trattenuto: allora l'ISO di esposizione e' l'informazione che conta.
@visibleForTesting
String edgeLabelOf(FilmRoll roll) {
  final isoNelNome = RegExp(r'(^|\D)' '${roll.nominalIso}' r'(\D|$)').hasMatch(roll.filmName);
  final iso = roll.isPushPull || !isoNelNome ? ' ${roll.exposedIso}' : '';
  return '${roll.filmName}$iso ▸ ${roll.sequenceNumber}';
}

/// Un rullino in macchina: una striscia di pellicola.
class _InCameraStrip extends StatelessWidget {
  const _InCameraStrip({required this.item, required this.today});

  final RollListItem item;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FilmPalette.of(context);
    final roll = item.roll;
    final loaded = roll.loadedDate;
    final days = loaded?.daysUntil(today).clamp(0, 100000);
    final finished = item.status == RollStatus.exposed;
    final when = finished
        ? l.home_finishedToDeliver
        : (days == null ? l.home_notLoadedYet : l.home_loadedDaysAgo(days));
    final details = [?item.camera?.displayName, when].join(' · ');

    return FilmStrip(
      edgeText: edgeLabelOf(roll),
      onTap: () => context.push(Routes.rollOf(roll.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roll.title ?? roll.filmName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ⚑ Finito: il furgone dice "da portare in laboratorio" meglio di un numero.
          if (finished)
            Icon(Icons.local_shipping_outlined, color: p.edge)
          else if (days != null)
            EdgeText(l.home_daysShort(days), size: 20, bold: true),
        ],
      ),
    );
  }
}

/// Un rullino in laboratorio: "Ektar 100 · Fotoservice" e i giorni d'attesa.
class _AtLabRow extends StatelessWidget {
  const _AtLabRow({required this.item, required this.waitingDays});

  final RollListItem item;
  final int? waitingDays;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FilmPalette.of(context);
    final roll = item.roll;
    final days = waitingDays;
    final lab = item.development?.laboratory?.trim();
    final dettagli = [?roll.title, if (lab != null && lab.isNotEmpty) lab].join(' · ');
    // Il lettore di schermo legge la frase intera, non "38 GG".
    final frase = '${roll.filmName} — ${days == null ? l.home_delivered : l.home_deliveredDaysAgo(days)}';

    return Semantics(
      label: frase,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: p.strip,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.rollOf(roll.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: roll.filmName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (dettagli.isNotEmpty) TextSpan(text: ' · $dettagli', style: TextStyle(color: p.inkMuted)),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: p.ink),
                  ),
                ),
                const SizedBox(width: 12),
                EdgeText(days == null ? '—' : l.home_daysShort(days), size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'archivio come foglio provini: tre colonne, ogni fotogramma con il suo numero.
///
/// ⚑ Vuoto: due fotogrammi segnaposto con la striscia di pellicola, per far vedere cosa ci
/// sara' (F6.8), non un buco.
class _ContactSheet extends StatelessWidget {
  const _ContactSheet({required this.items});

  final List<RollListItem> items;

  @override
  Widget build(BuildContext context) {
    final p = FilmPalette.of(context);
    final celle = items.isEmpty
        ? const <Widget>[
            _PlaceholderFrame(key: ValueKey('archive-placeholder-0')),
            _PlaceholderFrame(key: ValueKey('archive-placeholder-1')),
          ]
        : [for (final i in items) _Frame(item: i)];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.strip, borderRadius: BorderRadius.circular(6)),
      child: LayoutBuilder(
        builder: (context, c) {
          const colonne = 3;
          const gap = 6.0;
          final w = (c.maxWidth - gap * (colonne - 1)) / colonne;
          return Wrap(
            spacing: gap,
            runSpacing: 10,
            children: [for (final cella in celle) SizedBox(width: w, child: cella)],
          );
        },
      ),
    );
  }
}

/// Un fotogramma del provino: la copertina (o la striscia) e "▸ 3 DOLOMITI".
class _Frame extends StatelessWidget {
  const _Frame({required this.item});

  final RollListItem item;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final roll = item.roll;
    final nome = roll.title ?? roll.filmName;
    final periodo = formatPeriod(l, roll.loadedDate, roll.finishedDate);
    return Semantics(
      button: true,
      label: ['#${roll.sequenceNumber}', nome, ?periodo].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(Routes.rollOf(roll.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: RollCover(cover: item.cover),
              ),
            ),
            const SizedBox(height: 4),
            EdgeText('▸ ${roll.sequenceNumber} $nome', size: 9),
          ],
        ),
      ),
    );
  }
}

/// Un fotogramma vuoto del provino: solo la striscia, senza testo.
class _PlaceholderFrame extends StatelessWidget {
  const _PlaceholderFrame({super.key});

  @override
  Widget build(BuildContext context) => const AspectRatio(
    aspectRatio: 4 / 3,
    child: ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      child: Opacity(opacity: 0.7, child: FilmStripPlaceholder()),
    ),
  );
}

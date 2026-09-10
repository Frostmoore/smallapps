import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/waste_presets.dart';
import '../../data/repository.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il wizard iniziale.
///
/// ⚑ È il punto in cui si perdono più utenti: chi non finisce il setup disinstalla. Per
/// questo il passo dei giorni è **una griglia tipo × giorno** e non un wizard per tipo:
/// l'utente ha in mano il volantino del Comune, che è una tabella, e riprodurre la
/// tabella è la traduzione più diretta del suo modello mentale. Riduce il setup da due
/// minuti a trenta secondi.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();

  int _step = 0;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  /// Indice del preset -> giorni scelti. Un preset senza giorni non viene creato.
  final Map<int, Set<int>> _selection = <int, Set<int>>{};

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  List<int> get _chosenPresets => _selection.keys.toList()..sort();

  void _goTo(int step) {
    setState(() => _step = step);
    _pages.animateToPage(step, duration: MicroDuration.normal, curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    final l = L.of(context);
    setState(() => _saving = true);

    final types = <WizardWasteType>[];
    for (final index in _chosenPresets) {
      final preset = kWastePresets[index];
      types.add(
        WizardWasteType(
          name: _presetName(l, preset.nameKey),
          iconKey: preset.iconKey,
          colorValue: preset.color.toARGB32(),
          weekdays: _selection[index] ?? <int>{},
        ),
      );
    }

    await ref
        .read(repositoryProvider)
        .createCalendarFromWizard(
          name: _name.text.trim().isEmpty ? l.onboarding_calendarNameHint : _name.text.trim(),
          notificationTime: _formatTime(_time),
          types: types,
        );
    await ref.read(settingsProvider).setBool(SettingKeys.onboardingDone, true);
    await ref.read(settingsProvider).setString('notification_time', _formatTime(_time));

    if (!mounted) return;
    // Si invalida il provider perché il redirect del router legge la preferenza: senza,
    // resteremmo bloccati sul wizard appena completato.
    ref.invalidate(onboardingDoneProvider);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    // ☠ Senza questo il tasto Back di sistema chiude l'app invece di tornare al passo
    // precedente: il wizard vive in una sola rotta, quindi per Navigator il primo pop e'
    // gia' l'uscita. Chi sbaglia a scegliere i tipi di rifiuto perde tutto quello che ha
    // inserito e riparte da capo.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _goTo(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MicroSpacing.l,
                  vertical: MicroSpacing.m,
                ),
                child: _StepDots(current: _step, total: 4),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(onNext: () => _goTo(1)),
                    _NameStep(controller: _name, onNext: () => _goTo(2)),
                    _TypesStep(
                      selection: _selection,
                      onToggle: (index) => setState(() {
                        if (_selection.containsKey(index)) {
                          _selection.remove(index);
                        } else {
                          _selection[index] = <int>{};
                        }
                      }),
                      onNext: _chosenPresets.isEmpty ? null : () => _goTo(3),
                    ),
                    _ScheduleStep(
                      chosen: _chosenPresets,
                      selection: _selection,
                      time: _time,
                      saving: _saving,
                      onToggleDay: (index, weekday) => setState(() {
                        final days = _selection[index] ?? <int>{};
                        if (!days.remove(weekday)) days.add(weekday);
                        _selection[index] = days;
                      }),
                      onPickTime: () async {
                        final picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                      onFinish: _finish,
                    ),
                  ],
                ),
              ),
              if (_step > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                  child: TextButton(
                    onPressed: _saving ? null : () => _goTo(_step - 1),
                    child: Text(l.common_back),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// Traduce la chiave ARB di un preset nel nome mostrato.
///
/// I preset portano una chiave, non un nome: il nome dipende dalla lingua del dispositivo
/// (ADR-011), e l'utente può comunque rinominarlo dopo.
String _presetName(L l, String key) => switch (key) {
  'waste_organic' => l.waste_organic,
  'waste_paper' => l.waste_paper,
  'waste_plastic' => l.waste_plastic,
  'waste_glass' => l.waste_glass,
  'waste_metal' => l.waste_metal,
  'waste_unsorted' => l.waste_unsorted,
  'waste_garden' => l.waste_garden,
  'waste_nappies' => l.waste_nappies,
  _ => l.waste_other,
};

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: MicroDuration.normal,
            margin: const EdgeInsets.symmetric(horizontal: MicroSpacing.xs),
            height: 6,
            width: i == current ? 26 : 6,
            decoration: BoxDecoration(
              color: i <= current ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, this.subtitle, required this.child, this.footer});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: MicroSpacing.pageH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroSpacing.gapL,
          Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null) ...[
            MicroSpacing.gapS,
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.mutedText),
            ),
          ],
          MicroSpacing.gapXL,
          Expanded(child: child),
          if (footer != null) ...[footer!, MicroSpacing.gapL],
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _StepScaffold(
      title: l.onboarding_welcomeTitle,
      subtitle: l.onboarding_welcomeBody,
      footer: MicroPrimaryButton(label: l.onboarding_start, onPressed: onNext),
      child: Center(
        child: Icon(
          Icons.recycling,
          size: 120,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _StepScaffold(
      title: l.onboarding_calendarNameTitle,
      subtitle: l.onboarding_calendarNameHelp,
      footer: MicroPrimaryButton(label: l.common_next, onPressed: onNext),
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l.onboarding_calendarNameHint),
        onSubmitted: (_) => onNext(),
      ),
    );
  }
}

class _TypesStep extends StatelessWidget {
  const _TypesStep({required this.selection, required this.onToggle, required this.onNext});

  final Map<int, Set<int>> selection;
  final void Function(int index) onToggle;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _StepScaffold(
      title: l.onboarding_wasteTypesTitle,
      subtitle: l.onboarding_wasteTypesHelp,
      footer: MicroPrimaryButton(label: l.common_next, onPressed: onNext),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: MicroSpacing.s,
          runSpacing: MicroSpacing.s,
          children: [
            for (var i = 0; i < kWastePresets.length; i++)
              MicroChip(
                label: _presetName(l, kWastePresets[i].nameKey),
                icon: WasteIcons.resolve(kWastePresets[i].iconKey),
                color: kWastePresets[i].color,
                selected: selection.containsKey(i),
                onTap: () => onToggle(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// La griglia tipo × giorno: il passo che ricalca il volantino del Comune.
class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    required this.chosen,
    required this.selection,
    required this.time,
    required this.saving,
    required this.onToggleDay,
    required this.onPickTime,
    required this.onFinish,
  });

  final List<int> chosen;
  final Map<int, Set<int>> selection;
  final TimeOfDay time;
  final bool saving;
  final void Function(int index, int weekday) onToggleDay;
  final VoidCallback onPickTime;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Le iniziali dei giorni nella lingua del dispositivo: in inglese lunedì e martedì
    // iniziano entrambi per M, quindi si usano due lettere.
    final labels = [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        DateFormat('EEEE', locale)
            .format(DateTime(2026, 9, 6 + weekday))
            .substring(0, locale.startsWith('it') ? 1 : 2)
            .toUpperCase(),
    ];

    return _StepScaffold(
      title: l.onboarding_scheduleTitle,
      subtitle: l.onboarding_scheduleHelp,
      footer: Column(
        children: [
          MicroCard(
            onTap: onPickTime,
            padding: MicroSpacing.cardTight,
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                MicroSpacing.hGapM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.onboarding_notificationTitle, style: theme.textTheme.cardTitle),
                      Text(
                        l.onboarding_notificationHelp,
                        style: theme.textTheme.cardMeta.copyWith(
                          color: theme.colorScheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                MicroSpacing.hGapS,
                Text(_formatTime(time), style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          MicroSpacing.gapM,
          MicroPrimaryButton(
            label: l.onboarding_finish,
            loading: saving,
            onPressed: () => onFinish(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final index in chosen)
              Padding(
                padding: const EdgeInsets.only(bottom: MicroSpacing.m),
                child: MicroCard(
                  padding: MicroSpacing.cardTight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            WasteIcons.resolve(kWastePresets[index].iconKey),
                            size: 18,
                            color: kWastePresets[index].color,
                          ),
                          MicroSpacing.hGapS,
                          Text(
                            _presetName(l, kWastePresets[index].nameKey),
                            style: theme.textTheme.cardTitle,
                          ),
                        ],
                      ),
                      MicroSpacing.gapS,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
                            _DayToggle(
                              label: labels[weekday - 1],
                              selected: selection[index]?.contains(weekday) ?? false,
                              color: kWastePresets[index].color,
                              onTap: () => onToggleDay(index, weekday),
                            ),
                        ],
                      ),
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

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: MicroDuration.quick,
        // 44 dp: sotto i 48 raccomandati ma con sette pulsanti in riga su schermi
        // piccoli è il compromesso necessario. L'area di tocco effettiva è più larga
        // grazie allo spazio fra i cerchi.
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? MicroCard.foregroundOn(color) : scheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

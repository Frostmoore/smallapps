import 'dart:async';

import 'package:flutter/material.dart';

import '../billing/purchase_gateway.dart';
import '../entitlement/entitlement_service.dart';
import '../theme/micro_tokens.dart';
import '../ui/micro_widgets.dart';
import 'feature_gate.dart';
import 'feature_key.dart';

/// Un beneficio elencato nel paywall.
@immutable
class PaywallBenefit {
  const PaywallBenefit({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final FeatureKey key;
  final IconData icon;
  final String title;
  final String description;
}

/// I testi e l'aspetto del paywall di un'app.
@immutable
class PaywallConfig {
  const PaywallConfig({
    required this.appName,
    required this.headline,
    required this.subhead,
    required this.benefits,
    required this.buyLabel,
    required this.restoreLabel,
    required this.pendingLabel,
    required this.thanksLabel,
    required this.nothingToRestoreLabel,
    required this.unavailableLabel,
    required this.productUnavailableLabel,
    required this.retryLabel,
    required this.oneTimeNotice,
    this.heroBuilder,
    this.footnote,
  });

  final String appName;
  final String headline;
  final String subhead;
  final List<PaywallBenefit> benefits;

  /// Etichetta del bottone. Riceve il prezzo già formattato dallo store.
  final String Function(String? price) buyLabel;

  final String restoreLabel;
  final String pendingLabel;
  final String thanksLabel;
  final String nothingToRestoreLabel;
  final String unavailableLabel;

  /// Lo store risponde ma il prezzo del Pro non arriva. Diverso da [unavailableLabel], che
  /// vuol dire "su questo dispositivo non c'e' nessuno store".
  final String productUnavailableLabel;

  /// Il pulsante che richiede il prezzo allo store.
  final String retryLabel;

  /// La frase che dice "pagamento unico, nessun abbonamento".
  ///
  /// ⚑ Non è un dettaglio legale: è il principale motivo per cui una persona compra
  /// questo tipo di app invece di un concorrente in abbonamento. Nasconderla è lasciare
  /// soldi sul tavolo.
  final String oneTimeNotice;

  final WidgetBuilder? heroBuilder;
  final String? footnote;
}

/// La pagina che vende il Pro.
class PaywallPage extends StatefulWidget {
  const PaywallPage({
    required this.config,
    required this.service,
    this.highlight,
    super.key,
  });

  final PaywallConfig config;
  final EntitlementService service;

  /// La funzione che ha innescato il paywall, evidenziata nell'elenco.
  final FeatureKey? highlight;

  /// Apre il paywall. Restituisce `true` se l'utente esce con il Pro attivo.
  static Future<bool> show(
    BuildContext context, {
    required PaywallConfig config,
    required EntitlementService service,
    FeatureKey? highlight,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PaywallPage(config: config, service: service, highlight: highlight),
      ),
    );
    return result ?? service.isPro;
  }

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _wasPro = false;

  @override
  void initState() {
    super.initState();
    _wasPro = widget.service.isPro;
    widget.service.addListener(_onServiceChanged);

    // ☠ Il prezzo si richiede a ogni apertura in cui manca. Il servizio lo chiedeva solo
    //   all'avvio dell'app, e se in quel momento non arrivava, il paywall restava ad
    //   aspettarlo per sempre: il difetto che su iPhone impediva di comprare il Pro.
    final service = widget.service;
    if (!service.storeAvailable) {
      unawaited(service.reconnectStore());
    } else if (service.proProduct == null) {
      unawaited(service.reloadProducts());
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    // Appena il Pro è attivo la pagina si chiude da sola: restare lì con un bottone
    // "acquista" già premuto è il modo migliore per far comprare due volte.
    if (!_wasPro && widget.service.isPro) {
      _wasPro = true;
      MicroSnack.success(context, widget.config.thanksLabel);
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = widget.config;
    final service = widget.service;
    final product = service.proProduct;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(service.isPro),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            if (config.heroBuilder != null) ...[
              config.heroBuilder!(context),
              MicroSpacing.gapXL,
            ],
            Text(config.headline, style: theme.textTheme.headlineMedium),
            MicroSpacing.gapS,
            Text(
              config.subhead,
              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.mutedText),
            ),
            MicroSpacing.gapXL,
            for (final benefit in config.benefits)
              _BenefitRow(benefit: benefit, highlighted: benefit.key == widget.highlight),
            MicroSpacing.gapXL,
            if (service.isPending)
              MicroCard(
                accent: scheme.warning,
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top),
                    MicroSpacing.hGapM,
                    Expanded(child: Text(config.pendingLabel)),
                  ],
                ),
              )
            else if (!service.storeAvailable)
              // ⚑ Anche qui si puo' riprovare: "nessuno store" all'avvio puo' voler dire
              //   soltanto che il Play Store si stava aggiornando.
              _PriceMissing(
                message: config.unavailableLabel,
                retryLabel: config.retryLabel,
                onRetry: service.reconnectStore,
              )
            else
              _BuyButton(config: config, service: service, product: product),
            MicroSpacing.gapM,
            Center(
              child: Text(
                config.oneTimeNotice,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.mutedText),
              ),
            ),
            MicroSpacing.gapS,
            // Sempre visibile, anche quando l'acquisto non è disponibile: chi ha
            // reinstallato l'app cerca esattamente questo, e non trovarlo produce
            // richieste di rimborso da parte di gente che aveva già pagato.
            TextButton(
              onPressed: service.isBusy ? null : () => _restore(service, config),
              child: Text(config.restoreLabel),
            ),
            if (config.footnote != null) ...[
              MicroSpacing.gapL,
              Text(
                config.footnote!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _restore(EntitlementService service, PaywallConfig config) async {
    await service.restorePurchases();
    if (!mounted) return;
    if (!service.isPro) MicroSnack.show(context, config.nothingToRestoreLabel);
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.config, required this.service, required this.product});

  final PaywallConfig config;
  final EntitlementService service;
  final MicroProduct? product;

  @override
  Widget build(BuildContext context) {
    // ☠ Finché il prezzo non è arrivato dallo store si mostra uno scheletro, non un
    // prezzo inventato: Google applica prezzi diversi per paese e promozione, e un
    // numero scritto nel codice sarebbe sbagliato per la maggioranza degli utenti.
    final available = product;
    if (available == null) {
      // ⚑ Rotellina solo mentre lo store sta rispondendo. Quando ha risposto senza il
      //   prodotto, o non ha risposto in tempo, si dice cosa succede e si offre di
      //   riprovare: una rotellina eterna non dice niente e non lascia fare niente.
      return switch (service.catalogState) {
        CatalogState.idle || CatalogState.loading => const _PriceSkeleton(),
        CatalogState.ready || CatalogState.missing || CatalogState.failed => _PriceMissing(
          message: config.productUnavailableLabel,
          retryLabel: config.retryLabel,
          onRetry: service.reloadProducts,
        ),
      };
    }
    return MicroPrimaryButton(
      label: config.buyLabel(available.formattedPrice),
      loading: service.isBusy,
      onPressed: service.buyPro,
    );
  }
}

class _PriceMissing extends StatelessWidget {
  const _PriceMissing({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MicroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: scheme.mutedText),
              MicroSpacing.hGapM,
              Expanded(child: Text(message)),
            ],
          ),
          MicroSpacing.gapM,
          MicroPrimaryButton(label: retryLabel, onPressed: () => unawaited(onRetry())),
        ],
      ),
    );
  }
}

class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: MicroRadius.card,
    ),
    alignment: Alignment.center,
    child: const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit, required this.highlighted});

  final PaywallBenefit benefit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: MicroSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(MicroSpacing.s),
            decoration: BoxDecoration(
              color: highlighted ? scheme.primaryContainer : scheme.surfaceContainerHigh,
              borderRadius: MicroRadius.chip,
            ),
            child: Icon(
              benefit.icon,
              size: 20,
              color: highlighted ? scheme.onPrimaryContainer : scheme.primary,
            ),
          ),
          MicroSpacing.hGapL,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: theme.textTheme.cardTitle.copyWith(
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                Text(
                  benefit.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Il badge "PRO" da mettere accanto a una funzione a pagamento.
class ProBadge extends StatelessWidget {
  const ProBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? MicroSpacing.xs : MicroSpacing.s,
        vertical: MicroSpacing.xxs,
      ),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: MicroRadius.chip),
      child: Text(
        'PRO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Come si comporta [ProLock] quando la funzione non è disponibile.
enum ProLockMode {
  /// Mostra il contenuto attenuato, con il badge sopra.
  overlay,

  /// Nasconde del tutto il contenuto.
  hide,

  /// Mostra il contenuto normalmente, con solo il badge accanto.
  badgeOnly,
}

/// Avvolge una funzione a pagamento.
///
/// Non decide nulla da sé: interroga [FeatureGate], che legge la mappa dei limiti
/// dell'app (ADR-017). Toccando un contenuto bloccato chiama [onBlocked], che tipicamente
/// apre il paywall evidenziando proprio quella funzione.
class ProLock extends StatelessWidget {
  const ProLock({
    required this.feature,
    required this.gate,
    required this.child,
    this.currentCount = 0,
    this.mode = ProLockMode.overlay,
    this.onBlocked,
    super.key,
  });

  final FeatureKey feature;
  final FeatureGate gate;
  final Widget child;
  final int currentCount;
  final ProLockMode mode;
  final void Function(GateBlocked blocked)? onBlocked;

  @override
  Widget build(BuildContext context) {
    final verdict = gate.check(feature, currentCount: currentCount);
    if (verdict is GateAllowed) return child;
    final blocked = verdict as GateBlocked;

    switch (mode) {
      case ProLockMode.hide:
        return const SizedBox.shrink();

      case ProLockMode.badgeOnly:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [Flexible(child: child), MicroSpacing.hGapS, const ProBadge(compact: true)],
        );

      case ProLockMode.overlay:
        return Stack(
          children: [
            // `IgnorePointer` + opacità: il contenuto resta visibile, così l'utente vede
            // cosa otterrebbe. Nasconderlo del tutto renderebbe il paywall un salto nel
            // buio, e chi non sa cosa compra non compra.
            IgnorePointer(child: Opacity(opacity: 0.45, child: child)),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: MicroRadius.card,
                  onTap: onBlocked == null ? null : () => onBlocked!(blocked),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(padding: EdgeInsets.all(MicroSpacing.s), child: ProBadge()),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../prefs.dart';
import '../widgets/widgets.dart';
import 'platform_config.dart';

String _lang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// Stable across runs (unlike `String.hashCode`), for "dismissed" flags.
int textHash(String s) =>
    s.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x3fffffff);

/// Wraps the whole app (`MaterialApp.builder`): maintenance covers
/// everything but sign-out; an outdated app gets a dismissible prompt.
class PlatformGate extends ConsumerStatefulWidget {
  const PlatformGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlatformGate> createState() => _PlatformGateState();
}

class _PlatformGateState extends ConsumerState<PlatformGate> {
  /// Per launch: the prompt is soft, it comes back next time.
  var _updateDismissed = false;

  @override
  Widget build(BuildContext context) {
    final maintenance = ref.watch(
      platformConfigProvider.select((c) => c.maintenance),
    );
    final update = ref.watch(
      platformConfigProvider.select((c) => c.needsUpdate()),
    );
    return Stack(
      children: [
        widget.child,
        if (update && !_updateDismissed && !maintenance)
          UpdatePrompt(
            onDismiss: () => setState(() => _updateDismissed = true),
          ),
        if (maintenance) const Positioned.fill(child: MaintenancePage()),
      ],
    );
  }
}

/// Calm full-screen notice while the platform is in maintenance.
class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final message = ref.watch(
      platformConfigProvider.select(
        (c) => c.maintenanceMessage(_lang(context)),
      ),
    );
    final signedIn = ref.watch(authStateProvider).value != null;
    return Material(
      color: p.bg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.md,
              children: [
                const BrandMark(size: 64),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l.platformMaintenanceTitle,
                  style: text.displaySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  message.isEmpty ? l.platformMaintenanceBody : message,
                  style: text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.md),
                AppButton(
                  label: l.platformMaintenanceRetry,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => ref
                      .read(platformConfigProvider.notifier)
                      .refresh(force: true),
                ),
                if (signedIn)
                  AppButton(
                    label: l.platformSignOut,
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut().ignore(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft "please update" sheet pinned to the bottom; never blocks.
class UpdatePrompt extends ConsumerWidget {
  const UpdatePrompt({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final message = ref.watch(
      platformConfigProvider.select((c) => c.updateMessage(_lang(context))),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          boxShadow: AppElevation.raised(p),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.xl,
                AppSpace.gutter,
                AppSpace.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.sm,
                children: [
                  Row(
                    spacing: AppSpace.md,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: p.accentSoft,
                        child: Icon(
                          Icons.system_update_outlined,
                          size: 20,
                          color: p.ink,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.platformUpdateTitle,
                          style: text.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    message.isEmpty ? l.platformUpdateBody : message,
                    style: text.bodyMedium,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      label: l.platformUpdateLater,
                      variant: AppButtonVariant.text,
                      onPressed: onDismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The admin's announcement on Home; dismissed per banner text.
class PlatformBanner extends ConsumerWidget {
  const PlatformBanner({super.key});

  static const _flagScope = 'platform';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(platformConfigProvider);
    final message = config.bannerText(_lang(context));
    if (!config.bannerActive || message.isEmpty) {
      return const SizedBox.shrink();
    }
    final flag =
        'banner:${textHash('${config.bannerText('bn')}|${config.bannerText('en')}')}';
    final dismissed = ref.watch(messFlagsProvider(_flagScope)).value;
    // Wait for the flags so a dismissed banner never flashes.
    if (dismissed == null || dismissed.contains(flag)) {
      return const SizedBox.shrink();
    }
    final p = context.palette;
    final (color, icon) = switch (config.bannerLevel) {
      BannerLevel.info => (p.inkSecondary, Icons.info_outline),
      BannerLevel.warning => (p.warning, Icons.warning_amber_outlined),
      BannerLevel.critical => (p.due, Icons.error_outline),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: AppCard.raised(
        padding: const EdgeInsetsDirectional.only(start: AppSpace.md),
        child: Row(
          spacing: AppSpace.md,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 20, color: color),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: p.ink),
                ),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).platformBannerDismiss,
              icon: const Icon(Icons.close),
              onPressed: () => setMessFlag(ref, _flagScope, flag),
            ),
          ],
        ),
      ),
    );
  }
}

/// The admin's logo, else the bundled ম mark (also when the logo fails).
class BrandMark extends ConsumerWidget {
  const BrandMark({super.key, this.size = AppSize.touch});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(platformConfigProvider.select((c) => c.logoUrl));
    final fallback = ClipRRect(
      key: const Key('brand-fallback'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(
        'assets/icon/brand.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Meal Bazar',
      ),
    );
    return Center(
      child: url == null
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

/// Logo, app name and tagline from the branding config.
class BrandHeader extends ConsumerWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = _lang(context);
    final config = ref.watch(platformConfigProvider);
    final text = Theme.of(context).textTheme;
    return Row(
      spacing: AppSpace.md,
      children: [
        const BrandMark(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.appName(lang), style: text.titleMedium),
              Text(config.tagline(lang), style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

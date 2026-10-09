import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';

/// The link a QR / share message carries; [extractInviteCode] reads it back.
String inviteLink(String code) => 'https://mealbazar.app/join/$code';

final _codeInUrl = RegExp(r'/join/([A-Za-z0-9]{6})(?:[/?#]|$)');
final _rawCode = RegExp(r'^[A-Za-z0-9]{6}$');

/// The 6-character invite code inside a scanned `…/join/CODE` URL or a raw
/// code, uppercased; null for anything else.
String? extractInviteCode(String scanned) {
  final s = scanned.trim();
  final code =
      _codeInUrl.firstMatch(s)?.group(1) ?? (_rawCode.hasMatch(s) ? s : null);
  return code?.toUpperCase();
}

/// Letters/digits only, uppercased, at most 6.
final inviteCodeFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
  LengthLimitingTextInputFormatter(6),
  TextInputFormatter.withFunction(
    (_, v) => v.copyWith(text: v.text.toUpperCase()),
  ),
];

void showSnack(BuildContext context, String message) =>
    AppSnack.show(context, message);

void showFailure(BuildContext context, Object error) => AppSnack.show(
  context,
  failureText(context, error),
  icon: Icons.error_outline,
);

/// True when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Confirms, then signs out. The router takes the user to sign-in. Signing
/// out wipes the local DB, so unsent offline writes are called out.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final unsent = await ref.read(appDbProvider).unsentCount();
  if (!context.mounted) return;
  final ok = await confirmDialog(
    context,
    title: l.moreSignOutConfirmTitle,
    body: [
      l.moreSignOutConfirmBody,
      if (unsent > 0)
        l.moreSignOutUnsent(
          Fmt.digits(
            '$unsent',
            bangla: Localizations.localeOf(context).languageCode == 'bn',
          ),
        ),
    ].join('\n\n'),
    action: l.moreSignOut,
  );
  if (!ok) return;
  try {
    await ref.read(authRepositoryProvider).signOut();
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// Month start day, 1–28.
class MonthStartDayField extends StatelessWidget {
  const MonthStartDayField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l.messMonthStartLabel,
        helperText: l.messMonthStartHelp,
        helperMaxLines: 3,
      ),
      items: [
        for (var d = 1; d <= 28; d++)
          DropdownMenuItem(value: d, child: Text(l.messMonthStartDay('$d'))),
      ],
      onChanged: (d) => d == null ? null : onChanged(d),
    );
  }
}

/// A one-line field label above a group; 24 above, 12 below.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.gutter,
      AppSpace.xl,
      AppSpace.gutter,
      AppSpace.md,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// The screen's one primary action, pinned in thumb reach above the insets.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: children,
      ),
    ),
  );
}

/// A person's first letter in a muted circle (the list's visual anchor).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = name.trim().characters.firstOrNull ?? '?';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Text(
          first.toUpperCase(),
          textScaler: TextScaler.noScaling,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: p.inkSecondary,
            fontSize: size * 0.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// A leading icon on a rounded, muted square (settings-style rows).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: AppSize.spinner + 2, color: color ?? p.ink),
    );
  }
}

/// Rows grouped on one raised card, split by inset hairlines.
class RaisedGroup extends StatelessWidget {
  const RaisedGroup({super.key, required this.children, this.inset = 68});

  final List<Widget> children;

  /// Where the hairline starts (past a leading avatar / icon tile).
  final double inset;

  @override
  Widget build(BuildContext context) => AppCard.raised(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(indent: inset),
          children[i],
        ],
      ],
    ),
  );
}

/// A tappable settings-style row: icon tile, title, optional subtitle,
/// chevron. Presses scale.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge = 0,
    this.chevron = true,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final int badge;
  final bool chevron;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return PressableScale(
      scale: 0.98,
      child: ListTile(
        minTileHeight: AppSize.touch + AppSpace.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        // The same turmeric count as Home's message shortcut.
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            IconTile(icon, color: color),
            if (badge > 0)
              PositionedDirectional(
                top: -AppSpace.sm,
                end: -AppSpace.sm,
                child: CountBadge(badge),
              ),
          ],
        ),
        title: Text(
          title,
          style: text.titleSmall?.copyWith(color: color),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: chevron
            ? Icon(Icons.chevron_right, color: p.inkTertiary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// A small outlined tag (role, status, method). [strong] = ink fill.
class StatusTag extends StatelessWidget {
  const StatusTag(this.text, {super.key, this.color, this.strong = false});

  final String text;
  final Color? color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? (strong ? p.onInk : p.inkSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs / 2,
      ),
      decoration: BoxDecoration(
        color: strong ? p.ink : p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
      ),
    );
  }
}

/// A segmented control whose ink pill slides to the picked segment.
class InkSegmented<T> extends StatelessWidget {
  const InkSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = segments.length;
    final i = segments.indexWhere((s) => s.$1 == selected);
    final d = AppMotion.of(context, AppMotion.base);
    final label = Theme.of(context).textTheme.labelLarge!;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.touch),
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        children: [
          if (i >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(n == 1 ? 0 : -1 + 2 * i / (n - 1), 0),
                duration: d,
                curve: AppMotion.arrive,
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.ink,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final (v, text) in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: v == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (v != selected) HapticFeedback.selectionClick();
                        onChanged(v);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSize.touch - AppSpace.sm,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.xs,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: d,
                              curve: AppMotion.state,
                              style: label.copyWith(
                                color: v == selected ? p.onInk : p.inkSecondary,
                              ),
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showFailure(BuildContext context, Object error) =>
    showSnack(context, failureText(context, error));

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

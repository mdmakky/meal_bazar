import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';

/// Opened by a password-reset link. Once saved, the recovery flag clears and
/// the router moves on into the app.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() => _SetNewPasswordState();
}

class _SetNewPasswordState extends ConsumerState<SetNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final password = _password.text;
    setState(() {
      _passwordError = password.length >= 8 ? null : l.signInPasswordShort;
      _confirmError = _confirm.text == password ? null : l.resetMismatch;
    });
    if (_passwordError != null || _confirmError != null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      if (mounted) AppSnack.show(context, l.resetDone);
      ref.read(passwordRecoveryProvider.notifier).clear();
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        failureText(context, e),
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xxxl,
                    AppSpace.gutter,
                    AppSpace.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: p.accentSoft,
                          child: Icon(Icons.lock_reset, color: p.ink),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Text(l.resetTitle, style: text.displaySmall),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        l.resetHint,
                        style: text.bodyLarge?.copyWith(color: p.inkSecondary),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      AppCard.raised(
                        child: Column(
                          children: [
                            TextField(
                              key: const Key('newPassword'),
                              controller: _password,
                              autofocus: true,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l.resetNewPasswordLabel,
                                errorText: _passwordError,
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                            TextField(
                              key: const Key('confirmPassword'),
                              controller: _confirm,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l.resetConfirmLabel,
                                errorText: _confirmError,
                              ),
                              onSubmitted: (_) => _save(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.gutter),
                child: AppButton(
                  key: const Key('savePassword'),
                  expand: true,
                  loading: _saving,
                  label: l.resetSave,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

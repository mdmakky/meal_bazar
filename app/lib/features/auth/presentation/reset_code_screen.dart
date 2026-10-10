import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'code_widgets.dart';

/// Password reset by the code in the email: verify it, set the new password.
/// The router leaves this screen once the session starts.
class ResetCodeScreen extends ConsumerStatefulWidget {
  const ResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetCodeScreen> createState() => _ResetCodeState();
}

class _ResetCodeState extends ConsumerState<ResetCodeScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;
  Object? _failure;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final code = _code.text.trim();
    final password = _password.text;
    setState(() {
      _codeError = code.length >= 6 ? null : l.authCodeInvalid;
      _passwordError = password.length >= 8 ? null : l.signInPasswordShort;
      _confirmError = _confirm.text == password ? null : l.resetMismatch;
      _failure = null;
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(authRepositoryProvider);
    final recovery = ref.read(passwordRecoveryProvider.notifier);
    // Verifying signs in; keep the router off the link-based reset screen.
    recovery.codeFlow = true;
    try {
      await repo.verifyEmailOtp(widget.email, code, OtpType.recovery);
      await repo.updatePassword(password);
      if (mounted) AppSnack.show(context, l.resetDone);
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      recovery.codeFlow = false;
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
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Text(l.authCodeResetTitle, style: text.displaySmall),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        l.authCodeEmailSentTo(widget.email),
                        style: text.bodyLarge?.copyWith(color: p.inkSecondary),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      AppCard.raised(
                        child: Column(
                          children: [
                            EmailCodeField(
                              key: const Key('resetCode'),
                              controller: _code,
                              autofocus: true,
                              errorText: _codeError,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            TextField(
                              key: const Key('newPassword'),
                              controller: _password,
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
                            if (_failure != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpace.md,
                                ),
                                child: Text(
                                  failureText(context, _failure!),
                                  key: const Key('resetCodeFailure'),
                                  style: text.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(
                            key: const Key('changeEmail'),
                            variant: AppButtonVariant.text,
                            label: l.authCodeChangeEmail,
                            onPressed: _saving
                                ? null
                                : () => context.go('/auth/sign-in'),
                          ),
                          Flexible(
                            child: ResendCodeButton(
                              enabled: !_saving,
                              onResend: () => ref
                                  .read(authRepositoryProvider)
                                  .sendPasswordReset(widget.email),
                            ),
                          ),
                        ],
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
                  label: l.authCodeResetSubmit,
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

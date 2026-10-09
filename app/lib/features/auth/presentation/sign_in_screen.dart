import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/platform/platform_widgets.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum _Busy { google, email, reset }

/// Google or email/password. The router leaves this screen once the auth
/// state turns signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    this.googleEnabled = Env.googleWebClientId != '',
  });

  /// Hidden when no Google web client id is configured.
  final bool googleEnabled;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  _Busy? _busy;
  String? _emailError;
  String? _passwordError;
  Object? _failure;

  /// Set after a sign-up that needs the emailed link clicked.
  String? _confirmEmail;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Runs [action] with [busy] shown; any error lands in [_failure].
  Future<void> _run(_Busy busy, Future<void> Function() action) async {
    setState(() {
      _busy = busy;
      _failure = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  bool _validEmail() {
    final ok = _emailRe.hasMatch(_email.text.trim());
    setState(
      () => _emailError = ok
          ? null
          : AppLocalizations.of(context).signInEmailInvalid,
    );
    return ok;
  }

  void _submit() {
    final emailOk = _validEmail();
    final passOk = _password.text.length >= 8;
    setState(
      () => _passwordError = passOk
          ? null
          : AppLocalizations.of(context).signInPasswordShort,
    );
    if (!emailOk || !passOk) return;
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    _run(_Busy.email, () async {
      if (!_signUp) return repo.signInWithEmail(email, _password.text);
      final hasSession = await repo.signUpWithEmail(email, _password.text);
      if (!hasSession && mounted) setState(() => _confirmEmail = email);
    });
  }

  void _forgot() {
    if (!_validEmail()) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _run(_Busy.reset, () async {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      messenger.showSnackBar(SnackBar(content: Text(l.signInResetSent)));
    });
  }

  void _google() => _run(
    _Busy.google,
    // false = user cancelled: nothing to show.
    () => ref.read(authRepositoryProvider).signInWithGoogle(),
  );

  /// Other actions are disabled while one runs; the running one keeps its
  /// callback so its spinner is not dimmed.
  VoidCallback? _tap(_Busy kind, VoidCallback f) =>
      _busy == null || _busy == kind ? f : null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final busy = _busy != null;
    final confirm = _confirmEmail;
    final google = widget.googleEnabled && ref.featureOn('google_login');
    final email = ref.featureOn('email_login');

    final List<Widget> body;
    if (confirm != null) {
      body = [
        Text(l.signInConfirmTitle, style: text.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(l.signInConfirmBody(confirm), style: text.bodyLarge),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          expand: true,
          label: l.signInBackToLogin,
          onPressed: () => setState(() {
            _confirmEmail = null;
            _signUp = false;
            _password.clear();
          }),
        ),
      ];
    } else {
      body = [
        const BrandHeader(),
        const SizedBox(height: AppSpace.xl),
        Text(l.signInTitle, style: text.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(l.signInHint, style: text.bodyMedium),
        const SizedBox(height: AppSpace.xl),
        if (google) ...[
          AppButton(
            key: const Key('google'),
            expand: true,
            icon: Icons.login,
            label: l.signInGoogle,
            loading: _busy == _Busy.google,
            onPressed: _tap(_Busy.google, _google),
          ),
          if (email) ...[
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  child: Text(l.signInOrEmail, style: text.labelMedium),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
          ],
        ],
        if (email) ...[
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.signInModeLogin)),
                ButtonSegment(value: true, label: Text(l.signInModeSignUp)),
              ],
              selected: {_signUp},
              onSelectionChanged: busy
                  ? null
                  : (v) => setState(() {
                      _signUp = v.first;
                      _failure = null;
                    }),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.signInEmailLabel,
              errorText: _emailError,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: true,
            autofillHints: [
              _signUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l.signInPasswordLabel,
              errorText: _passwordError,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_failure != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              failureText(context, _failure!),
              style: text.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          AppButton(
            key: const Key('submit'),
            expand: true,
            // One primary action: the Google button when it is shown.
            variant: google
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            loading: _busy == _Busy.email,
            label: _signUp ? l.signInSubmitSignUp : l.signInSubmitLogin,
            onPressed: _tap(_Busy.email, _submit),
          ),
          if (!_signUp) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              child: AppButton(
                variant: AppButtonVariant.text,
                loading: _busy == _Busy.reset,
                label: l.signInForgot,
                onPressed: _tap(_Busy.reset, _forgot),
              ),
            ),
          ],
        ],
        // Google's error shows here when the email form is hidden.
        if (!email && _failure != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            failureText(context, _failure!),
            style: text.bodyMedium?.copyWith(color: scheme.error),
          ),
        ],
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xxxl,
              AppSpace.gutter,
              AppSpace.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: body,
            ),
          ),
        ),
      ),
    );
  }
}

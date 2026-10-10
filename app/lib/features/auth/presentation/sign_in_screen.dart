import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../core/env.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'code_widgets.dart';
import 'login_hero.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum _Busy { google, email, reset, verify }

/// Google or email/password. The router leaves this screen once the auth
/// state turns signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    this.googleEnabled = Env.googleWebClientId != '',
    this.inviteCode,
  });

  /// An invite being followed: shows a hint to create an account first.
  final String? inviteCode;

  /// Hidden when no Google web client id is configured.
  final bool googleEnabled;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _signUp = false;
  _Busy? _busy;
  String? _codeError;
  String? _emailError;
  String? _passwordError;
  Object? _failure;

  /// Set after a sign-up that needs the emailed link clicked.
  String? _confirmEmail;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
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
    _run(_Busy.reset, () async {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      AppSnack.show(
        context,
        l.signInResetSent,
        icon: Icons.mark_email_read_outlined,
      );
      context.go('/auth/reset-code', extra: _email.text.trim());
    });
  }

  /// Signup code: on success a session starts and the router moves on.
  void _confirm() {
    final code = _code.text.trim();
    final bad = code.length < 6;
    setState(
      () => _codeError = bad
          ? AppLocalizations.of(context).authCodeInvalid
          : null,
    );
    if (bad) return;
    _run(
      _Busy.verify,
      () => ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(_confirmEmail!, code, OtpType.signup),
    );
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
    final p = context.palette;
    final busy = _busy != null;
    final confirm = _confirmEmail;
    final google = widget.googleEnabled && ref.featureOn('google_login');
    final email = ref.featureOn('email_login');

    final lang = Localizations.localeOf(context).languageCode;
    final config = ref.watch(platformConfigProvider);

    Widget failureLine() => Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Text(
        failureText(context, _failure!),
        style: text.bodyMedium?.copyWith(color: scheme.error),
      ),
    );

    final List<Widget> body;
    if (confirm != null) {
      body = [
        CircleAvatar(
          radius: 28,
          backgroundColor: p.accentSoft,
          child: Icon(Icons.mark_email_unread_outlined, color: p.ink),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Text(l.signInConfirmTitle, style: text.headlineSmall),
            Text(l.signInConfirmBody(confirm), style: text.bodyLarge),
          ],
        ),
        AppCard.raised(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailCodeField(
                key: const Key('signupCode'),
                controller: _code,
                autofocus: true,
                errorText: _codeError,
              ),
              if (_failure != null) failureLine(),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                key: const Key('confirmCode'),
                expand: true,
                loading: _busy == _Busy.verify,
                label: l.authCodeConfirmSubmit,
                onPressed: _tap(_Busy.verify, _confirm),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Align(
                  child: ResendCodeButton(
                    enabled: !busy,
                    onResend: () => ref
                        .read(authRepositoryProvider)
                        .resendSignupCode(confirm),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppButton(
          expand: true,
          variant: AppButtonVariant.text,
          label: l.signInBackToLogin,
          onPressed: busy
              ? null
              : () => setState(() {
                  _confirmEmail = null;
                  _signUp = false;
                  _failure = null;
                  _code.clear();
                  _password.clear();
                }),
        ),
      ];
    } else {
      body = [
        Text(l.signInTitle, style: text.displaySmall),
        if (widget.inviteCode?.isNotEmpty ?? false)
          Container(
            key: const Key('inviteBanner'),
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(l.inviteSignInBanner, style: text.bodyMedium),
          ),
        if (google)
          AppButton(
            key: const Key('google'),
            expand: true,
            icon: Icons.login,
            variant: AppButtonVariant.secondary,
            label: l.signInGoogle,
            loading: _busy == _Busy.google,
            onPressed: _tap(_Busy.google, _google),
          ),
        if (google && email)
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
        if (email)
          AppCard.raised(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l.signInModeLogin),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l.signInModeSignUp),
                      ),
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
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  key: const Key('password'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: [
                    _signUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l.signInPasswordLabel,
                    errorText: _passwordError,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_failure != null) failureLine(),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  key: const Key('submit'),
                  expand: true,
                  loading: _busy == _Busy.email,
                  label: _signUp ? l.signInSubmitSignUp : l.signInSubmitLogin,
                  onPressed: _tap(_Busy.email, _submit),
                ),
                if (!_signUp)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Align(
                      child: AppButton(
                        variant: AppButtonVariant.text,
                        loading: _busy == _Busy.reset,
                        label: l.signInForgot,
                        onPressed: _tap(_Busy.reset, _forgot),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Google's error shows here when the email form is hidden.
        if (!email && _failure != null) failureLine(),
      ];
    }

    final content = StaggeredList(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.xl,
        children: StaggeredList.wrap(body),
      ),
    );
    if (confirm == null) {
      // The dark hero runs under the status bar; the form sits on a light
      // sheet whose rounded top overlaps it.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        // Light status-bar icons over the dark hero.
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          body: AutofillGroup(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      LoginHero(
                        name: config.appName(lang),
                        tagline: config.tagline(lang),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: AppRadius.xl + 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.xl + 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.sm,
                      AppSpace.gutter,
                      AppSpace.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: content,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xxxl,
              AppSpace.gutter,
              AppSpace.xl,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

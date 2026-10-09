import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/failure_text.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/application/auth_providers.dart';
import '../application/admin_providers.dart';
import 'admin_shell.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (c) => AppLocalizations.of(c).adminTitle,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    locale: ref.watch(adminLocaleProvider),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AdminGate(),
  );
}

/// Signed out → sign in. Signed in but not a platform admin → access
/// denied. Otherwise the panel. The RPCs re-check admin rights server-side.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(isPlatformAdminProvider);
    return admin.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        body: ErrorView(
          message: failureText(context, e),
          onRetry: () => ref.invalidate(isPlatformAdminProvider),
        ),
      ),
      data: (isAdmin) => switch (isAdmin) {
        null => const AdminSignInPage(),
        false => const AccessDeniedPage(),
        true => const AdminShell(),
      },
    );
  }
}

class AccessDeniedPage extends ConsumerWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.lg,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: AppSize.emptyIcon,
                  color: context.palette.inkTertiary,
                ),
                Text(
                  l.adminAccessDenied,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(l.adminAccessDeniedBody, textAlign: TextAlign.center),
                AppButton(
                  label: l.adminSignOut,
                  icon: Icons.logout,
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminSignInPage extends ConsumerStatefulWidget {
  const AdminSignInPage({super.key});

  @override
  ConsumerState<AdminSignInPage> createState() => _AdminSignInPageState();
}

class _AdminSignInPageState extends ConsumerState<AdminSignInPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  Object? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(_email.text, _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.lg,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l.adminTitle, style: text.headlineSmall),
                        ),
                        const LocaleToggle(),
                      ],
                    ),
                    Text(l.adminSignInHint),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l.signInEmailLabel,
                      ),
                      validator: (v) =>
                          RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch((v ?? '').trim())
                          ? null
                          : l.signInEmailInvalid,
                    ),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l.signInPasswordLabel,
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? l.adminErrRequired : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_failure != null)
                      Text(
                        failureText(context, _failure!),
                        style: text.bodyMedium?.copyWith(
                          color: context.palette.due,
                        ),
                      ),
                    AppButton(
                      label: l.adminSignIn,
                      loading: _busy,
                      onPressed: _busy ? null : _submit,
                      expand: true,
                    ),
                    if (Env.googleWebClientId.isNotEmpty)
                      AppButton(
                        label: l.adminSignInGoogle,
                        variant: AppButtonVariant.secondary,
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .signInWithGoogleWeb(),
                              ),
                        expand: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// বাংলা ⇄ English.
class LocaleToggle extends ConsumerWidget {
  const LocaleToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(adminLocaleProvider).languageCode == 'bn';
    return TextButton(
      onPressed: ref.read(adminLocaleProvider.notifier).toggle,
      child: Text(bn ? 'English' : 'বাংলা'),
    );
  }
}

/// Developer-facing: the build is missing its Supabase defines.
class AdminConfigMissing extends StatelessWidget {
  const AdminConfigMissing({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              Text(
                l.configMissingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.md),
              const SelectableText(
                'flutter build web -t lib/admin/admin_main.dart '
                '--dart-define-from-file=env.json',
              ),
            ],
          ),
        );
      },
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';

/// First-run: name and app language. The router moves on once it is saved.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends ConsumerState<ProfileSetupScreen> {
  late final _name = TextEditingController(
    text: ref.read(myProfileProvider).value?.fullName,
  );
  late String _locale = ref.read(myProfileProvider).value?.locale ?? 'bn';
  bool _saving = false;
  bool _nameMissing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    setState(() => _nameMissing = name.isEmpty);
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(fullName: name, locale: _locale);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureText(context, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.authProfileTitle, style: text.headlineSmall),
                    const SizedBox(height: AppSpace.sm),
                    Text(l.authProfileHint, style: text.bodyMedium),
                    const SizedBox(height: AppSpace.xl),
                    TextField(
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: l.authNameLabel,
                        errorText: _nameMissing ? l.authNameRequired : null,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(l.authLanguageLabel, style: text.titleSmall),
                    const SizedBox(height: AppSpace.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          // Each language names itself.
                          ButtonSegment(value: 'bn', label: Text('বাংলা')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {_locale},
                        onSelectionChanged: (v) =>
                            setState(() => _locale = v.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.gutter),
              child: AppButton(
                expand: true,
                loading: _saving,
                label: l.authProfileSave,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

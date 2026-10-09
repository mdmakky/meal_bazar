import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/platform/platform_widgets.dart';
import '../../../core/version.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../mess/presentation/common.dart';
import '../data/account_repository.dart';

/// Profile name, language and account deletion (Play Store requirement).
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController();
  String? _loadedFor;
  var _saving = false;
  var _deleting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save({String? fullName, String? locale}) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(fullName: fullName, locale: locale);
      if (mounted && fullName != null) showSnack(context, l.accountNameSaved);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmAccountDeletion(context) || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(accountRepositoryProvider).deleteMyAccount();
      // The router takes the signed-out user to sign-in.
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.value;

    if (profile != null && _loadedFor != profile.id) {
      _loadedFor = profile.id;
      _name.text = profile.fullName;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: switch (profileAsync) {
        AsyncError(:final error) when profile == null => ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        _ when profile == null => const LoadingView(),
        _ => StaggeredList(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.xxl),
            children: StaggeredList.wrap([
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.lg,
                  AppSpace.gutter,
                  0,
                ),
                child: AppCard.raised(
                  child: Row(
                    spacing: AppSpace.lg,
                    children: [
                      InitialsAvatar(profile.fullName, size: 56),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpace.xs,
                          children: [
                            Text(
                              profile.fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleLarge,
                            ),
                            if (profile.phone case final phone?
                                when phone.isNotEmpty)
                              Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium?.copyWith(
                                  color: p.inkSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SectionTitle(l.accountName),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.md,
                  children: [
                    TextField(
                      controller: _name,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l.accountName),
                    ),
                    AppButton(
                      label: l.accountNameSave,
                      variant: AppButtonVariant.secondary,
                      loading: _saving,
                      onPressed: () {
                        final name = _name.text.trim();
                        if (name.isNotEmpty) _save(fullName: name);
                      },
                    ),
                  ],
                ),
              ),
              SectionTitle(l.accountLanguage),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                child: InkSegmented<String>(
                  segments: [('bn', l.accountLangBn), ('en', l.accountLangEn)],
                  selected: profile.locale,
                  onChanged: (v) {
                    if (!_saving && v != profile.locale) _save(locale: v);
                  },
                ),
              ),
              const SupportSection(),
              SectionTitle(l.platformAboutTitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                child: AppCard.raised(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpace.md,
                    children: [
                      const BrandHeader(),
                      Text(
                        l.platformVersion(appVersion),
                        style: text.labelSmall?.copyWith(color: p.inkTertiary),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xxl,
                  AppSpace.gutter,
                  0,
                ),
                child: RaisedGroup(
                  children: [
                    ListTile(
                      key: const Key('deleteAccount'),
                      minTileHeight: AppSize.touch + AppSpace.md,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                      ),
                      leading: IconTile(
                        Icons.delete_forever_outlined,
                        color: p.due,
                      ),
                      title: Text(
                        l.accountDelete,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(color: p.due),
                      ),
                      trailing: _deleting
                          ? const SizedBox.square(
                              dimension: AppSize.spinner,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _deleting ? null : _delete,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      },
    );
  }
}

/// Explains what is removed vs kept, then asks the user to type the confirm
/// word. True only when they did.
Future<bool> confirmAccountDeletion(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final ok = await AppSheet.show<bool>(
    context,
    title: l.accountDeleteTitle,
    child: const _DeleteConfirm(),
  );
  return ok ?? false;
}

class _DeleteConfirm extends StatefulWidget {
  const _DeleteConfirm();

  @override
  State<_DeleteConfirm> createState() => _DeleteConfirmState();
}

class _DeleteConfirmState extends State<_DeleteConfirm> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final confirmed =
        _typed.text.trim().toLowerCase() == l.accountDeleteWord.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        Text(l.accountDeleteRemoved, style: text.bodyLarge),
        Text(l.accountDeleteKept, style: text.bodyLarge),
        Text(
          l.accountDeleteManager,
          style: text.bodyMedium?.copyWith(color: p.inkSecondary),
        ),
        TextField(
          key: const Key('deleteConfirmField'),
          controller: _typed,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.accountDeleteTypeHint(l.accountDeleteWord),
          ),
        ),
        FilledButton(
          key: const Key('deleteConfirmButton'),
          style: FilledButton.styleFrom(
            backgroundColor: p.due,
            foregroundColor: p.onInk,
          ),
          onPressed: confirmed ? () => Navigator.pop(context, true) : null,
          child: Text(l.accountDeleteConfirm),
        ),
        AppButton(
          label: l.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// Support email / WhatsApp and the privacy policy from the platform config.
/// Each is selectable with a copy button; hidden when the admin left it blank.
class SupportSection extends ConsumerWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = ref.watch(platformConfigProvider);
    final rows = [
      (Icons.mail_outline, l.platformSupportEmail, c.supportEmail),
      (Icons.chat_outlined, l.platformSupportWhatsapp, c.supportWhatsapp),
      (Icons.privacy_tip_outlined, l.platformPrivacy, c.privacyUrl),
    ].where((r) => r.$3.isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.platformSupportTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: RaisedGroup(
            children: [
              for (final (icon, label, value) in rows)
                ListTile(
                  contentPadding: const EdgeInsets.only(
                    left: AppSpace.lg,
                    right: AppSpace.sm,
                  ),
                  leading: IconTile(icon),
                  title: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: SelectableText(value, maxLines: 2),
                  trailing: IconButton(
                    tooltip: l.platformCopy,
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (context.mounted) {
                        showSnack(context, l.platformCopied);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

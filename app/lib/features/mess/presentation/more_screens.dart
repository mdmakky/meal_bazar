import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/mess_providers.dart';
import '../domain/member.dart';
import 'common.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final membership = ref.watch(currentMembershipProvider);
    final isManager = ref.watch(amIManagerProvider);
    final usable = (ref.watch(myMembershipsProvider).value ?? const [])
        .where((m) => m.mess != null)
        .toList();

    Widget tile(
      IconData icon,
      String title,
      VoidCallback onTap, [
      String? sub,
    ]) => ListTile(
      minTileHeight: AppSize.touch + AppSpace.md,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      leading: Icon(icon),
      title: Text(title, style: text.titleSmall),
      subtitle: sub == null ? null : Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    final tiles = [
      tile(
        Icons.group_outlined,
        l.moreMembers,
        () => context.push('/more/members'),
      ),
      if (isManager) ...[
        tile(
          Icons.person_add_alt,
          l.moreInvite,
          () => context.push('/more/invite'),
        ),
        tile(
          Icons.settings_outlined,
          l.moreSettings,
          () => context.push('/more/settings'),
        ),
        tile(
          Icons.restaurant_menu,
          l.mealTypesTitle,
          () => context.push('/more/meal-types'),
        ),
      ],
      tile(
        Icons.shopping_basket_outlined,
        l.dutyTitle,
        () => context.push('/more/duty'),
      ),
      tile(Icons.history, l.auditTitle, () => context.push('/more/audit')),
      tile(
        Icons.person_outline,
        l.accountTitle,
        () => context.push('/more/account'),
      ),
      if (usable.length > 1)
        tile(
          Icons.swap_horiz,
          l.moreSwitchMess,
          () => _switchMess(context, ref, usable),
          membership?.mess?.name,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ListView(
        children: [
          if (membership?.mess != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xs,
                children: [
                  Text(membership!.mess!.name, style: text.headlineSmall),
                  Text(
                    '${membership.member.displayName} · '
                    '${isManager ? l.moreRoleManager : l.moreRoleMember}',
                    style: text.bodyMedium?.copyWith(
                      color: context.palette.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          for (final t in tiles) ...[t, const Divider()],
          const SizedBox(height: AppSpace.xl),
          const Divider(),
          ListTile(
            minTileHeight: AppSize.touch + AppSpace.md,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.gutter,
            ),
            leading: const Icon(Icons.logout),
            title: Text(l.moreSignOut, style: text.titleSmall),
            onTap: () => confirmSignOut(context, ref),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _switchMess(
    BuildContext context,
    WidgetRef ref,
    List<Membership> usable,
  ) async {
    final l = AppLocalizations.of(context);
    final current = ref.read(currentMessIdProvider);
    final id = await AppSheet.show<String>(
      context,
      title: l.moreSwitchMess,
      child: Column(
        children: [
          for (final m in usable)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.mess!.name),
              subtitle: m.member.status == MemberStatus.pending
                  ? Text(l.messPendingTitle)
                  : null,
              trailing: m.messId == current ? const Icon(Icons.check) : null,
              selected: m.messId == current,
              onTap: () => Navigator.pop(context, m.messId),
            ),
        ],
      ),
    );
    if (id != null) ref.read(currentMessIdProvider.notifier).select(id);
  }
}

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  String? _code;
  Object? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    // Memberships may still be loading on a cold start; generate once known.
    ref.listenManual(currentMessIdProvider, (_, id) {
      if (id != null && _code == null && !_loading) _generate();
    }, fireImmediately: true);
  }

  Future<void> _generate() async {
    final messId = ref.read(currentMessIdProvider);
    if (messId == null || !ref.read(amIManagerProvider)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await ref.read(messControllerProvider).createInvite(messId);
      if (mounted) setState(() => _code = code);
    } catch (e) {
      if (!mounted) return;
      // Keep showing the old code if there is one; tell why it didn't change.
      if (_code == null) {
        setState(() => _error = e);
      } else {
        showFailure(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String code) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showSnack(context, l.inviteCopied);
  }

  void _share(String code) {
    final l = AppLocalizations.of(context);
    final mess = ref.read(currentMessProvider)?.name ?? '';
    SharePlus.instance.share(
      ShareParams(text: l.inviteShareMessage(mess, code, inviteLink(code))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final code = _code;

    final Widget body;
    if (!ref.watch(amIManagerProvider)) {
      body = EmptyView(message: l.inviteManagerOnly, icon: Icons.lock_outline);
    } else if (_error != null) {
      body = ErrorView(
        message: failureText(context, _error!),
        onRetry: _generate,
      );
    } else if (code == null) {
      body = const LoadingView();
    } else {
      body = ListView(
        padding: const EdgeInsets.all(AppSpace.gutter),
        children: [
          Text(
            l.inviteBody,
            style: text.bodyLarge?.copyWith(color: p.inkSecondary),
          ),
          const SizedBox(height: AppSpace.xl),
          Center(
            child: SelectableText(
              code,
              key: const Key('inviteCode'),
              style: text.displaySmall?.copyWith(
                letterSpacing: AppSpace.md,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Center(
            child: Text(
              l.inviteValidity,
              style: text.bodyMedium?.copyWith(color: p.inkTertiary),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Center(
            // Always dark on light: scanners misread inverted codes.
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppPalette.light.surface,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Semantics(
                label: l.inviteQrLabel,
                child: QrImageView(
                  data: inviteLink(code),
                  size: AppSpace.xxxl * 4,
                  padding: EdgeInsets.zero,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppPalette.light.ink,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppPalette.light.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.inviteTitle)),
      body: body,
      bottomNavigationBar: code == null
          ? null
          : BottomAction(
              children: [
                AppButton(
                  label: l.inviteShare,
                  icon: Icons.share_outlined,
                  onPressed: () => _share(code),
                ),
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l.inviteCopy,
                        icon: Icons.copy,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _copy(code),
                      ),
                    ),
                    Expanded(
                      child: AppButton(
                        label: l.inviteRegenerate,
                        icon: Icons.refresh,
                        variant: AppButtonVariant.text,
                        loading: _loading,
                        onPressed: _generate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class MessSettingsScreen extends ConsumerStatefulWidget {
  const MessSettingsScreen({super.key});

  @override
  ConsumerState<MessSettingsScreen> createState() => _MessSettingsScreenState();
}

class _MessSettingsScreenState extends ConsumerState<MessSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  String? _loadedFor;
  var _startDay = 1;
  var _cutoff = const TimeOfDay(hour: 22, minute: 0);
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickCutoff() async {
    final t = await showTimePicker(context: context, initialTime: _cutoff);
    if (t != null) setState(() => _cutoff = t);
  }

  Future<void> _save(String messId) async {
    final l = AppLocalizations.of(context);
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    String two(int n) => n.toString().padLeft(2, '0');
    try {
      await ref
          .read(messControllerProvider)
          .updateMess(
            messId,
            name: _name.text,
            address: _address.text,
            monthStartDay: _startDay,
            mealOffCutoff: '${two(_cutoff.hour)}:${two(_cutoff.minute)}:00',
          );
      if (mounted) showSnack(context, l.settingsSaved);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mess = ref.watch(currentMessProvider);
    final isManager = ref.watch(amIManagerProvider);

    // Fill the fields once per mess; later rebuilds keep the user's edits.
    if (mess != null && _loadedFor != mess.id) {
      _loadedFor = mess.id;
      _name.text = mess.name;
      _address.text = mess.address ?? '';
      _startDay = mess.monthStartDay;
      final [h, m, ...] = mess.mealOffCutoff.split(':');
      _cutoff = TimeOfDay(hour: int.parse(h), minute: int.parse(m));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: switch ((mess, isManager)) {
        (null, _) => EmptyView(message: l.emptyGeneric),
        (_, false) => EmptyView(
          message: l.settingsManagerOnly,
          icon: Icons.lock_outline,
        ),
        _ => Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l.messNameLabel),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.messNameRequired : null,
              ),
              const SizedBox(height: AppSpace.lg),
              TextFormField(
                controller: _address,
                maxLines: null,
                decoration: InputDecoration(labelText: l.settingsAddress),
              ),
              const SizedBox(height: AppSpace.lg),
              MonthStartDayField(
                key: ValueKey(_loadedFor),
                value: _startDay,
                onChanged: (d) => setState(() => _startDay = d),
              ),
              const SizedBox(height: AppSpace.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSize.touch,
                leading: const Icon(Icons.schedule),
                title: Text(l.settingsCutoff),
                subtitle: Text(l.settingsCutoffHelp),
                trailing: Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(_cutoff),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                onTap: _pickCutoff,
              ),
            ],
          ),
        ),
      },
      bottomNavigationBar: mess == null || !isManager
          ? null
          : BottomAction(
              children: [
                AppButton(
                  label: l.settingsSave,
                  loading: _saving,
                  onPressed: () => _save(mess.id),
                ),
              ],
            ),
    );
  }
}

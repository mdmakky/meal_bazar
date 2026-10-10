import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/presentation/meal_grid.dart'
    show clockText, mealOf, relativeDay;
import '../../meals/presentation/meal_widgets.dart' show bnDigits;
import '../../money/domain/money.dart' show parseAmount;
import '../../messages/application/unread_provider.dart';
import '../../notices/application/notice_providers.dart';
import '../../push/application/inbox_providers.dart';
import '../application/mess_providers.dart';
import '../domain/member.dart';
import '../domain/mess.dart';
import 'common.dart';
import 'leave_delete.dart';

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

    final unread = ref.watch(unreadNoticeCountProvider);
    final on = ref.featureOn;
    final messId = membership?.messId;
    final unreadMessages = messId == null || !on('messages')
        ? 0
        : ref.watch(unreadMessagesCountProvider(messId)).value ?? 0;

    NavRow tile(
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? sub,
      int badge = 0,
    }) => NavRow(
      icon: icon,
      title: title,
      subtitle: sub,
      badge: badge,
      onTap: onTap,
    );

    final mess = [
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
        if (on('meal_defaults'))
          tile(
            Icons.tune,
            l.mealDefaultTitle,
            () => context.push('/more/meal-defaults'),
          ),
        if (on('recurring'))
          tile(
            Icons.event_repeat,
            l.recurringTitle,
            () => context.push('/more/recurring'),
          ),
        if (on('due_reminders') && on('messages'))
          tile(
            Icons.notifications_active_outlined,
            l.dueRemTitle,
            () => context.push('/more/due-reminders'),
            sub: l.dueRemMoreSub,
          ),
      ],
    ];
    final tools = [
      if (on('messages') && messId != null)
        tile(
          Icons.forum_outlined,
          l.msgTitle,
          () => context.push('/more/messages'),
          sub: l.msgMoreSub,
          badge: unreadMessages,
        ),
      if (on('notices'))
        tile(
          Icons.campaign_outlined,
          l.noticeTitle,
          () => context.push('/more/notices'),
          badge: unread,
        ),
      if (on('duty'))
        tile(
          Icons.shopping_basket_outlined,
          l.dutyTitle,
          () => context.push('/more/duty'),
        ),
      // The whole mess log is the manager's; members see what concerns them.
      if (isManager && on('audit_log'))
        tile(Icons.history, l.auditTitle, () => context.push('/more/audit')),
      if (!isManager && messId != null)
        tile(
          Icons.history,
          l.activityMoreTile,
          () => context.push('/more/activity'),
        ),
      if (on('export'))
        tile(
          Icons.file_download_outlined,
          l.exportTitle,
          () => context.push('/more/export'),
        ),
      tile(
        Icons.notifications_none_outlined,
        l.inboxTitle,
        () => context.push('/more/notifications/inbox'),
        sub: l.inboxMoreSub,
        badge: ref.watch(inboxUnreadCountProvider).value ?? 0,
      ),
      if (on('reminders'))
        tile(
          Icons.notifications_outlined,
          l.remindTitle,
          () => context.push('/more/reminders'),
        ),
    ];
    final account = [
      tile(
        Icons.person_outline,
        l.accountTitle,
        () => context.push('/more/account'),
      ),
      if (membership?.mess != null)
        tile(Icons.logout, l.leaveTile, () => showLeaveMessSheet(context)),
      if (usable.length > 1)
        tile(
          Icons.swap_horiz,
          l.moreSwitchMess,
          () => _switchMess(context, ref, usable),
          sub: membership?.mess?.name,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: StaggeredList(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.gutter,
            AppSpace.xxxl,
          ),
          children: StaggeredList.wrap([
            if (membership?.mess != null)
              AppCard.raised(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  spacing: AppSpace.md,
                  children: [
                    InitialsAvatar(membership!.mess!.name, size: 52),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.xs,
                        children: [
                          Text(
                            membership.mess!.name,
                            style: text.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                membership.member.displayName,
                                style: text.bodyMedium?.copyWith(
                                  color: context.palette.inkSecondary,
                                ),
                              ),
                              StatusTag(
                                isManager
                                    ? l.moreRoleManager
                                    : l.moreRoleMember,
                                strong: isManager,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            for (final group in [mess, tools, account])
              if (group.isNotEmpty) RaisedGroup(children: group),
            RaisedGroup(
              children: [
                NavRow(
                  icon: Icons.logout,
                  title: l.moreSignOut,
                  color: context.palette.due,
                  chevron: false,
                  onTap: () => confirmSignOut(context, ref),
                ),
              ],
            ),
          ]).expand((w) => [w, const SizedBox(height: AppSpace.lg)]).toList(),
        ),
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
          AppButton(
            key: const Key('inviteByLink'),
            expand: true,
            icon: Icons.link,
            label: l.inviteByLink,
            onPressed: () => AppSheet.show<void>(
              context,
              title: l.inviteLinkSheetTitle,
              child: const _InviteLinkSheet(),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(l.inviteSharedCodeTitle, style: text.titleMedium),
          const SizedBox(height: AppSpace.xs),
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
          if (ref.featureOn('invite_qr')) ...[
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

/// Makes a single-use invite link for one person, then offers copy / share.
class _InviteLinkSheet extends ConsumerStatefulWidget {
  const _InviteLinkSheet();

  @override
  ConsumerState<_InviteLinkSheet> createState() => _InviteLinkSheetState();
}

class _InviteLinkSheetState extends ConsumerState<_InviteLinkSheet> {
  final _name = TextEditingController();
  String? _link;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final messId = ref.read(currentMessIdProvider);
    if (_busy || messId == null) return;
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(messControllerProvider)
          .createInviteLink(messId, inviteeName: _name.text);
      if (mounted) setState(() => _link = inviteLink(code));
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String link) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) showSnack(context, l.inviteLinkCopied);
  }

  void _share(String link) {
    final l = AppLocalizations.of(context);
    final manager = ref.read(currentMembershipProvider)?.member.displayName;
    final mess = ref.read(currentMessProvider)?.name ?? '';
    SharePlus.instance.share(
      ShareParams(text: l.inviteLinkShareMessage(manager ?? '', mess, link)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final link = _link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        if (link == null) ...[
          TextField(
            key: const Key('inviteeName'),
            controller: _name,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l.inviteeNameLabel),
            onSubmitted: (_) => _create(),
          ),
          AppButton(
            key: const Key('createLink'),
            expand: true,
            label: l.inviteCreateLink,
            loading: _busy,
            onPressed: _create,
          ),
        ] else ...[
          SelectableText(link, key: const Key('inviteLinkText')),
          AppButton(
            expand: true,
            icon: Icons.share_outlined,
            label: l.inviteShare,
            onPressed: () => _share(link),
          ),
          AppButton(
            expand: true,
            icon: Icons.copy,
            variant: AppButtonVariant.secondary,
            label: l.inviteCopyLink,
            onPressed: () => _copy(link),
          ),
        ],
        Text(
          l.inviteLinkNote,
          style: text.bodyMedium?.copyWith(color: p.inkTertiary),
        ),
      ],
    );
  }
}

const _prevDay = -1;
const _custom = -2;
const _leadPresets = [60, 120, 240];

class MessSettingsScreen extends ConsumerStatefulWidget {
  const MessSettingsScreen({super.key});

  @override
  ConsumerState<MessSettingsScreen> createState() => _MessSettingsScreenState();
}

class _MessSettingsScreenState extends ConsumerState<MessSettingsScreen> {
  /// Only whoever opened the mess may delete it (a manager of an ownerless
  /// mess too).
  bool _isOwner(Mess mess) {
    final me = ref.read(currentMembershipProvider)?.member;
    return me != null &&
        me.role == MemberRole.manager &&
        (mess.createdBy == null || mess.createdBy == me.userId);
  }

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _rate = TextEditingController();
  String? _loadedFor;
  var _fixedRate = false;
  var _startDay = 1;
  var _cutoff = const TimeOfDay(hour: 22, minute: 0);

  /// Meal-off lead in minutes; [_prevDay] = the previous-day cutoff rule,
  /// [_custom] = the hours field.
  var _lead = _prevDay;
  final _hours = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _rate.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _pickCutoff() async {
    final t = await showTimePicker(context: context, initialTime: _cutoff);
    if (t != null && mounted) setState(() => _cutoff = t);
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
            mealOffLead: (minutes: _leadMinutes),
            fixedRate: _fixedRate,
            fixedMealRate: _fixedRate ? parseAmount(_rate.text) : null,
          );
      if (mounted) showSnack(context, l.settingsSaved);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "মিল বন্ধের সময়সীমা": presets, the previous-day time or custom hours,
  /// and a live example on the last meal of the day.
  Widget _deadlineSection(BuildContext context, String messId) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final cutoffText = clockText(context, _cutoff.hour, _cutoff.minute);
    final choices = [
      for (final m in _leadPresets)
        (m, l.settingsLeadHours(Fmt.digits('${m ~/ 60}', bangla: bn))),
      (_prevDay, l.settingsLeadPrevDay(cutoffText)),
      (_custom, l.settingsLeadCustom),
    ];
    final types = ref.watch(mealTypesProvider(messId)).value ?? const [];
    final last = types.where((t) => t.enabled).lastOrNull;
    String? example;
    final lead = _leadMinutes;
    if (last != null && (lead == null || lead <= 2880)) {
      final now = DateTime.now();
      final day = DateTime.utc(now.year, now.month, now.day);
      final [h, m, ...] = last.serveTime.split(':').map(int.parse).toList();
      final at = lead == null
          ? day
                .subtract(const Duration(days: 1))
                .add(Duration(hours: _cutoff.hour, minutes: _cutoff.minute))
          : day.add(Duration(hours: h, minutes: m - lead));
      final when = relativeDay(context, at, day);
      final clock = clockText(context, at.hour, at.minute);
      example = l.settingsLeadExample(
        mealOf(context, last.name),
        when.isEmpty ? clock : '$when $clock',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.settingsLeadTitle, style: text.titleSmall),
        const SizedBox(height: AppSpace.xs),
        Text(l.settingsLeadHelp, style: text.bodySmall),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xs,
          children: [
            for (final (v, label) in choices)
              ChoiceChip(
                key: ValueKey('lead-$v'),
                label: Text(label),
                selected: _lead == v,
                onSelected: (_) => setState(() => _lead = v),
              ),
          ],
        ),
        if (_lead == _prevDay)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSize.touch,
            leading: const IconTile(Icons.schedule),
            title: Text(l.settingsCutoff),
            trailing: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(_cutoff),
              style: text.titleSmall,
            ),
            onTap: _pickCutoff,
          ),
        if (_lead == _custom) ...[
          const SizedBox(height: AppSpace.md),
          TextFormField(
            key: const ValueKey('lead-hours'),
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.settingsLeadCustomLabel),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final h = parseAmount(v ?? '');
              return h == null || h < 0 || h > 48
                  ? l.settingsLeadCustomInvalid
                  : null;
            },
          ),
        ],
        if (example != null) ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.sm,
            children: [
              Icon(Icons.info_outline, size: AppSpace.lg, color: p.inkTertiary),
              Expanded(
                child: Text(
                  example,
                  style: text.bodySmall?.copyWith(color: p.inkSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// The lead to save; null = previous-day cutoff.
  int? get _leadMinutes => switch (_lead) {
    _prevDay => null,
    _custom => ((parseAmount(_hours.text) ?? 0) * 60).round(),
    final m => m,
  };

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
      final lead = mess.mealOffLeadMinutes;
      _lead = lead == null
          ? _prevDay
          : _leadPresets.contains(lead)
          ? lead
          : _custom;
      _hours.text = lead == null || _lead != _custom
          ? ''
          : (lead % 60 == 0 ? '${lead ~/ 60}' : '${lead / 60}');
      _fixedRate = mess.fixedRate;
      _rate.text = switch (mess.fixedMealRate) {
        null => '',
        final r => r == r.roundToDouble() ? '${r.toInt()}' : '$r',
      };
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
              _deadlineSection(context, mess!.id),
              SwitchListTile(
                key: const ValueKey('fund-mode'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.fundModeTitle),
                subtitle: Text(l.fundModeHelp),
                value: mess.fundMode,
                onChanged: (on) async {
                  try {
                    await ref
                        .read(messControllerProvider)
                        .setFundMode(mess.id, on);
                  } catch (e) {
                    if (context.mounted) showFailure(context, e);
                  }
                },
              ),
              // Kept while the mess already uses a fixed rate.
              if (ref.featureOn('fixed_rate') || _fixedRate) ...[
                const SizedBox(height: AppSpace.lg),
                Text(
                  l.rateSection,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(l.rateHelp, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpace.sm),
                InkSegmented<bool>(
                  segments: [(false, l.rateCalculated), (true, l.rateFixed)],
                  selected: _fixedRate,
                  onChanged: (v) => setState(() => _fixedRate = v),
                ),
                if (_fixedRate) ...[
                  const SizedBox(height: AppSpace.md),
                  TextFormField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l.rateAmountLabel),
                    validator: (v) => (parseAmount(v ?? '') ?? 0) > 0
                        ? null
                        : l.rateAmountRequired,
                  ),
                ],
              ],
              // The last thing on the page, in red: it cannot be missed and
              // cannot be tapped by accident while saving.
              if (_isOwner(mess)) ...[
                const SizedBox(height: AppSpace.xxxl),
                OutlinedButton.icon(
                  key: const Key('delete-mess'),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.deleteMessTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.palette.due,
                    side: BorderSide(
                      color: context.palette.due.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: () => showDeleteMessSheet(context),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
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

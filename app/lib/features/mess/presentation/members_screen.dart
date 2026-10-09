import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/mess_providers.dart';
import '../domain/member.dart';
import 'common.dart';

enum _Action { makeManager, makeMember, markInactive, markActive, markLeft }

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.membersTitle)),
      floatingActionButton: isManager && messId != null
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.membersAdd),
              onPressed: () => _addMember(context, messId),
            )
          : null,
      body: messId == null
          ? EmptyView(message: l.emptyGeneric, icon: Icons.group_outlined)
          : ref
                .watch(membersProvider(messId))
                .when(
                  skipLoadingOnRefresh: true,
                  loading: () => const LoadingView(rows: 5),
                  error: (e, _) => ErrorView(
                    message: failureText(context, e),
                    onRetry: () => ref.invalidate(membersProvider(messId)),
                  ),
                  data: (members) => RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(membersProvider(messId).future),
                    child: _MemberList(members: members, isManager: isManager),
                  ),
                ),
    );
  }

  Future<void> _addMember(BuildContext context, String messId) async {
    final l = AppLocalizations.of(context);
    final name = await AppSheet.show<String>(
      context,
      title: l.membersAdd,
      child: _AddMemberForm(messId: messId),
    );
    if (name != null && context.mounted) {
      showSnack(context, l.membersAdded(name));
    }
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList({required this.members, required this.isManager});

  final List<Member> members;
  final bool isManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final meId = ref.watch(currentMembershipProvider)?.member.id;
    List<Member> by(MemberStatus s) =>
        members.where((m) => m.status == s).toList();
    final pending = isManager ? by(MemberStatus.pending) : const <Member>[];
    final active = by(MemberStatus.active);
    final inactive = by(MemberStatus.inactive);
    final left = by(MemberStatus.left);

    if (pending.isEmpty && active.isEmpty && inactive.isEmpty && left.isEmpty) {
      return ListView(
        children: [
          EmptyView(
            message: l.membersEmpty,
            icon: Icons.group_outlined,
            actionLabel: isManager ? l.moreInvite : null,
            onAction: isManager ? () => context.push('/more/invite') : null,
          ),
        ],
      );
    }

    final bn = Localizations.localeOf(context).languageCode == 'bn';
    String count(List<Member> list) => Fmt.digits('${list.length}', bangla: bn);
    Widget row(Member m) =>
        _MemberRow(member: m, isMe: m.id == meId, canManage: isManager);
    Widget group(List<Widget> rows) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: RaisedGroup(children: rows),
    );
    var i = 0; // stagger across sections
    Widget stagger(Widget w) => Stagger(index: i++, child: w);
    Iterable<Widget> section(String title, List<Member> list) => [
      if (list.isNotEmpty) ...[
        SectionTitle('$title · ${count(list)}'),
        group([for (final m in list) stagger(row(m))]),
      ],
    ];

    return StaggeredList(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xxxl * 2),
        children: [
          if (pending.isNotEmpty) ...[
            SectionTitle('${l.membersPending} · ${count(pending)}'),
            group([for (final m in pending) stagger(_PendingRow(member: m))]),
          ],
          ...section(l.membersActive, active),
          ...section(l.membersInactive, inactive),
          if (left.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.gutter,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                '${l.membersLeft} · ${count(left)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.only(bottom: AppSpace.lg),
              children: [
                group([for (final m in left) row(m)]),
              ],
            ),
        ],
      ),
    );
  }
}

String _subtitle(BuildContext context, Member m) {
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  return [
    if (m.room != null && m.room!.isNotEmpty) l.membersRoom(m.room!),
    if (!m.hasAccount) l.membersNoApp,
    if (m.leftOn != null)
      l.membersLeftOn(Fmt.dateLong(m.leftOn!, locale: locale)),
  ].join(' · ');
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canManage,
  });

  final Member member;
  final bool isMe;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sub = _subtitle(context, member);
    final p = context.palette;
    return ListTile(
      minTileHeight: AppSize.touch + AppSpace.lg,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      leading: InitialsAvatar(member.displayName),
      title: Text(
        isMe ? '${member.displayName} ${l.membersYou}' : member.displayName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: member.status == MemberStatus.left ? p.inkTertiary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: sub.isEmpty
          ? null
          : Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: member.role == MemberRole.manager
          ? StatusTag(l.membersRoleManager, strong: true)
          : null,
      onTap: canManage ? () => _manage(context, ref) : null,
    );
  }

  Future<void> _manage(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final m = member;
    ListTile option(_Action a, IconData icon, String label, [String? help]) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconTile(icon),
          title: Text(label),
          subtitle: help == null ? null : Text(help),
          onTap: () => Navigator.pop(context, a),
        );
    final action = await AppSheet.show<_Action>(
      context,
      title: m.displayName,
      child: Column(
        children: [
          if (m.status != MemberStatus.left)
            m.role == MemberRole.manager
                ? option(
                    _Action.makeMember,
                    Icons.person_outline,
                    l.membersMakeMember,
                  )
                : option(
                    _Action.makeManager,
                    Icons.admin_panel_settings_outlined,
                    l.membersMakeManager,
                  ),
          if (m.status == MemberStatus.active)
            option(
              _Action.markInactive,
              Icons.pause_circle_outline,
              l.membersMarkInactive,
              l.membersInactiveHelp,
            )
          else
            option(
              _Action.markActive,
              Icons.play_circle_outline,
              l.membersMarkActive,
            ),
          if (m.status != MemberStatus.left)
            option(_Action.markLeft, Icons.logout, l.membersMarkLeft),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == _Action.markLeft &&
        !await confirmDialog(
          context,
          title: l.membersLeftConfirmTitle(m.displayName),
          body: l.membersLeftConfirmBody,
          action: l.membersLeftConfirmAction,
        )) {
      return;
    }
    final c = ref.read(messControllerProvider);
    try {
      await switch (action) {
        _Action.makeManager => c.setRole(m, MemberRole.manager),
        _Action.makeMember => c.setRole(m, MemberRole.member),
        _Action.markInactive => c.setStatus(m, MemberStatus.inactive),
        _Action.markActive => c.setStatus(m, MemberStatus.active),
        _Action.markLeft => c.setStatus(m, MemberStatus.left),
      };
      if (context.mounted) showSnack(context, l.membersSaved);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

class _PendingRow extends ConsumerStatefulWidget {
  const _PendingRow({required this.member});

  final Member member;

  @override
  ConsumerState<_PendingRow> createState() => _PendingRowState();
}

class _PendingRowState extends ConsumerState<_PendingRow> {
  var _busy = false;

  Future<void> _run(Future<void> Function() change, String done) async {
    setState(() => _busy = true);
    try {
      await change();
      if (mounted) showSnack(context, done);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final l = AppLocalizations.of(context);
    final m = widget.member;
    final ok = await confirmDialog(
      context,
      title: l.membersRejectConfirmTitle(m.displayName),
      body: l.membersRejectConfirmBody,
      action: l.membersReject,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(messControllerProvider).rejectMember(m),
      l.membersRejected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.member;
    final sub = _subtitle(context, m);
    // Name on top, actions under it: fits 360 dp at large text.
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Row(
            spacing: AppSpace.md,
            children: [
              InitialsAvatar(m.displayName),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.isNotEmpty)
                      Text(sub, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: AppSpace.sm,
            children: [
              Expanded(
                child: AppButton(
                  label: l.membersReject,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _reject,
                ),
              ),
              Expanded(
                child: AppButton(
                  label: l.membersApprove,
                  loading: _busy,
                  onPressed: () => _run(
                    () => ref.read(messControllerProvider).approveMember(m),
                    l.membersApproved(m.displayName),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddMemberForm extends ConsumerStatefulWidget {
  const _AddMemberForm({required this.messId});

  final String messId;

  @override
  ConsumerState<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<_AddMemberForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _room = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final m = await ref
          .read(messControllerProvider)
          .addOfflineMember(
            messId: widget.messId,
            displayName: _name.text,
            room: _room.text,
          );
      if (mounted) Navigator.pop(context, m.displayName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.lg,
        children: [
          Text(
            l.membersAddHelp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.palette.inkSecondary,
            ),
          ),
          TextFormField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.membersAddName),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l.messNameRequired : null,
          ),
          TextFormField(
            controller: _room,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l.membersAddRoom),
            onFieldSubmitted: (_) => _submit(),
          ),
          AppButton(
            label: l.membersAddSubmit,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

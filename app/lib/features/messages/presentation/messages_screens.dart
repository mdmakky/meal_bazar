import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_grid.dart' show mealOf;
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/application/money_providers.dart'
    show moneyRepositoryProvider;
import '../../money/domain/money.dart';
import '../../money/presentation/money_sheets.dart'
    show showBazarForm, showDepositForm, showExpenseForm;
import '../../push/application/push_service.dart';
import '../application/message_providers.dart';
import '../domain/message.dart';
import '../domain/message_draft.dart';

// ── shared bits ─────────────────────────────────────────────────────────────

(IconData, String) refCopy(AppLocalizations l, String? type) => switch (type) {
  'deposit' => (Icons.account_balance_wallet_outlined, l.msgRefDeposit),
  'bazar' => (Icons.shopping_basket_outlined, l.msgRefBazar),
  'expense' => (Icons.receipt_long_outlined, l.msgRefExpense),
  'meal' => (Icons.restaurant_outlined, l.msgRefMeal),
  _ => (Icons.info_outline, l.msgRefOther),
};

/// Where an entry of [type] lives in the app, or null.
String? refRoute(String? type) => switch (type) {
  'deposit' || 'expense' => '/money',
  'bazar' => '/bazar',
  'meal' => '/meals',
  _ => null,
};

/// "14:05" today, else "৮ অক্টোবর, 14:05".
String messageTime(BuildContext context, DateTime at, {DateTime? now}) {
  final l = AppLocalizations.of(context);
  final bn = l.localeName == 'bn';
  final local = at.toLocal();
  final time = Fmt.digits(
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(local)),
    bangla: bn,
  );
  if (DateUtils.isSameDay(local, now ?? DateTime.now())) return time;
  final date = Fmt.dateLong(local, locale: l.localeName, banglaDigits: bn);
  return '${date.substring(0, date.lastIndexOf(' '))}, $time';
}

/// "সমস্যা জানান": opens a new message about this entry. Pops a sheet first
/// when [popFirst].
class ReportProblemButton extends StatelessWidget {
  const ReportProblemButton({
    super.key,
    required this.draft,
    this.popFirst = false,
  });

  final MessageDraft draft;
  final bool popFirst;

  @override
  Widget build(BuildContext context) => AppButton(
    label: AppLocalizations.of(context).msgReport,
    icon: Icons.report_outlined,
    variant: AppButtonVariant.secondary,
    onPressed: () {
      final router = GoRouter.of(context);
      if (popFirst) Navigator.pop(context);
      router.push('/more/messages/new', extra: draft);
    },
  );
}

/// The entry a thread is about: type icon + label; taps open its screen.
class RefCard extends ConsumerWidget {
  const RefCard({
    super.key,
    required this.type,
    required this.label,
    this.refId,
  });

  final String? type;
  final String label;

  /// The referenced row; with it a manager opens the entry's edit form.
  final String? refId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final (icon, kind) = refCopy(l, type);
    final route = refRoute(type);
    return AppCard.raised(
      padding: const EdgeInsets.all(AppSpace.md),
      onTap: route == null ? null : () => _open(context, ref, route),
      child: Row(
        spacing: AppSpace.md,
        children: [
          IconTile(icon, color: p.accent),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  '${l.msgAbout} · $kind',
                  style: text.labelSmall?.copyWith(color: p.inkTertiary),
                ),
                Text(
                  label,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (route != null)
            Icon(
              _canEdit(ref) ? Icons.edit_outlined : Icons.chevron_right,
              color: _canEdit(ref) ? p.ink : p.inkTertiary,
            ),
        ],
      ),
    );
  }

  bool _canEdit(WidgetRef ref) =>
      refId != null &&
      const {'deposit', 'bazar', 'expense'}.contains(type) &&
      ref.read(amIManagerProvider);

  /// A manager lands in the entry's edit form; everyone else on its list.
  Future<void> _open(BuildContext context, WidgetRef ref, String route) async {
    if (!_canEdit(ref)) return context.go(route);
    try {
      final e = await ref.read(moneyRepositoryProvider).entry(type!, refId!);
      if (!context.mounted) return;
      switch (e) {
        case Deposit d:
          await showDepositForm(context, existing: d);
        case Bazar b:
          await showBazarForm(context, existing: b);
        case Expense x:
          await showExpenseForm(context, existing: x);
        default:
          context.go(route);
      }
    } catch (err) {
      if (context.mounted) showFailure(context, err);
    }
  }
}

// ── inbox ───────────────────────────────────────────────────────────────────

/// Threads: a member sees their own, managers every member's (open /
/// resolved filter).
class MessagesInboxScreen extends ConsumerStatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  ConsumerState<MessagesInboxScreen> createState() => _InboxState();
}

class _InboxState extends ConsumerState<MessagesInboxScreen> {
  var _resolved = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    ref.listen(pushArrivalProvider, (_, next) {
      if (messId != null && (next.value ?? '').startsWith('/more/messages/')) {
        ref.invalidate(threadsProvider(messId));
      }
    });
    void compose() => context.push('/more/messages/new');

    return Scaffold(
      appBar: AppBar(title: Text(l.msgTitle)),
      floatingActionButton: messId == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.msgNew),
              onPressed: compose,
            ),
      body: messId == null
          ? EmptyView(message: l.emptyGeneric)
          : switch (ref.watch(threadsProvider(messId))) {
              AsyncValue(:final value?) => _list(
                context,
                messId,
                value,
                isManager: isManager,
                onCompose: compose,
              ),
              AsyncValue(:final error?) => ErrorView(
                message: failureText(context, error),
                onRetry: () => ref.invalidate(threadsProvider(messId)),
              ),
              _ => const LoadingView(),
            },
    );
  }

  Widget _list(
    BuildContext context,
    String messId,
    List<MessageThread> all, {
    required bool isManager,
    required VoidCallback onCompose,
  }) {
    final l = AppLocalizations.of(context);
    final group = ref.featureOn('mess_group')
        ? all.where((t) => t.isGroup).firstOrNull
        : null;
    final threads = [
      for (final t in all)
        if (!t.isGroup && (!isManager || t.resolved == _resolved)) t,
    ];
    final filter = isManager
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              AppSpace.sm,
            ),
            child: InkSegmented<bool>(
              segments: [(false, l.msgFilterOpen), (true, l.msgResolved)],
              selected: _resolved,
              onChanged: (v) => setState(() => _resolved = v),
            ),
          )
        : null;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(threadsProvider(messId).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (group != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                AppSpace.sm,
              ),
              sliver: SliverToBoxAdapter(child: GroupThreadTile(thread: group)),
            ),
          if (filter != null) SliverToBoxAdapter(child: filter),
          if (threads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                message: !isManager
                    ? l.msgEmpty
                    : _resolved
                    ? l.msgEmptyResolved
                    : l.msgEmptyManager,
                icon: Icons.forum_outlined,
                actionLabel: isManager ? null : l.msgNew,
                onAction: isManager ? null : onCompose,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.xxxl * 2,
              ),
              sliver: SliverList.separated(
                itemCount: threads.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                itemBuilder: (_, i) => Stagger(
                  index: i,
                  child: ThreadTile(thread: threads[i], showMember: isManager),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `user id → display name` for a mess (left members included).
Map<String, String> memberNames(WidgetRef ref, String messId) => {
  for (final m in ref.watch(membersProvider(messId)).value ?? const <Member>[])
    if (m.userId != null) m.userId!: m.displayName,
};

/// Members who can read the group (active and inactive).
int groupMemberCount(WidgetRef ref, String messId) =>
    (ref.watch(membersProvider(messId)).value ?? const <Member>[])
        .where(
          (m) =>
              m.status == MemberStatus.active ||
              m.status == MemberStatus.inactive,
        )
        .length;

/// "Mirpur Mess গ্রুপ", or the generic name before the mess has loaded.
String groupTitle(AppLocalizations l, WidgetRef ref) {
  final name = ref.watch(currentMessProvider)?.name;
  return name == null ? l.msgGroupShort : l.msgGroupTitle(name);
}

/// The mess group, pinned above the inbox: an ink roundel (the group is the
/// mess itself), member count, the last line with its author.
class GroupThreadTile extends ConsumerWidget {
  const GroupThreadTile({super.key, required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = thread;
    final bn = l.localeName == 'bn';
    final me = ref.watch(messageControllerProvider).myUserId;
    final count = Fmt.digits('${groupMemberCount(ref, t.messId)}', bangla: bn);
    final String? preview;
    if (t.lastSenderId == null && t.lastBody == null) {
      preview = null;
    } else if (t.lastHidden) {
      preview = l.msgHidden;
    } else if (t.lastSenderId != null && t.lastSenderId == me) {
      preview = l.msgYou(t.lastBody ?? '');
    } else {
      final who =
          memberNames(ref, t.messId)[t.lastSenderId] ?? l.msgDeletedUser;
      preview = '$who: ${t.lastBody ?? ''}';
    }

    return AppCard.raised(
      key: const Key('msgGroupTile'),
      onTap: () => context.push('/more/messages/${t.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.md,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: p.ink,
              child: Icon(Icons.groups_rounded, size: 22, color: p.onInk),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Expanded(
                      child: Text(
                        groupTitle(l, ref),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: t.isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (t.isUnread) const UnreadDot(),
                  ],
                ),
                // The mess name gets the whole first line; time sits here.
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Expanded(
                      child: Text(
                        l.msgGroupMembers(count),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(color: p.inkTertiary),
                      ),
                    ),
                    if (preview != null)
                      Text(
                        messageTime(context, t.lastMessageAt),
                        style: text.labelSmall?.copyWith(
                          color: t.isUnread ? p.ink : p.inkTertiary,
                        ),
                      ),
                  ],
                ),
                if (preview != null)
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: p.inkSecondary,
                      fontStyle: t.lastHidden ? FontStyle.italic : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The turmeric "unread" dot.
class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).msgUnread,
    child: Container(
      key: const Key('msgUnreadDot'),
      width: AppSize.dot + 2,
      height: AppSize.dot + 2,
      decoration: BoxDecoration(
        color: context.palette.accent,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class ThreadTile extends ConsumerWidget {
  const ThreadTile({super.key, required this.thread, this.showMember = false});

  final MessageThread thread;

  /// Managers see whose thread it is.
  final bool showMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = thread;
    final mine =
        t.lastSenderId != null &&
        t.lastSenderId == ref.watch(messageControllerProvider).myUserId;
    final (refIcon, refKind) = refCopy(l, t.refType);

    return AppCard.raised(
      onTap: () => context.push('/more/messages/${t.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.md,
        children: [
          if (showMember)
            InitialsAvatar(t.memberName, size: 40)
          else
            IconTile(t.refType == null ? Icons.forum_outlined : refIcon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Expanded(
                      child: Text(
                        showMember ? t.memberName : t.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: t.isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      messageTime(context, t.lastMessageAt),
                      style: text.labelSmall?.copyWith(
                        color: t.isUnread ? p.ink : p.inkTertiary,
                      ),
                    ),
                    if (t.isUnread) const UnreadDot(),
                  ],
                ),
                if (showMember)
                  Text(
                    t.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                if (t.lastBody != null)
                  Text(
                    mine ? l.msgYou(t.lastBody!) : t.lastBody!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                  ),
                if (t.refLabel != null || t.resolved)
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    children: [
                      if (t.refLabel != null) StatusTag(t.refLabel!),
                      if (t.resolved) StatusTag(l.msgResolved, strong: true),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── thread ──────────────────────────────────────────────────────────────────

/// `/more/messages/group`: finds (or creates) the mess group, then shows it.
class GroupThreadScreen extends ConsumerWidget {
  const GroupThreadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.msgGroupShort)),
        body: const LoadingView(),
      );
    }
    return switch (ref.watch(groupThreadIdProvider(messId))) {
      AsyncValue(:final value?) => ThreadScreen(id: value),
      AsyncValue(:final error?) => Scaffold(
        appBar: AppBar(title: Text(l.msgGroupShort)),
        body: ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(groupThreadIdProvider(messId)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(l.msgGroupShort)),
        body: const LoadingView(),
      ),
    };
  }
}

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadState();
}

class _ThreadState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// My optimistic messages not yet seen in the server list, oldest first.
  final _outbox = <ChatMessage>[];
  var _statusBusy = false;
  String? _readUpTo;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    // Fresh on every open, even when a cached copy exists.
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    ref
      ..invalidate(threadMessagesProvider(widget.id))
      ..invalidate(threadProvider(widget.id));
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  });

  Future<void> _send(MessageThread t, [ChatMessage? retry]) async {
    final body = retry?.body ?? _input.text.trim();
    if (body.isEmpty) return;
    final pending = ChatMessage(
      id: retry?.id ?? uuidV4(),
      threadId: t.id,
      senderId: ref.read(messageControllerProvider).myUserId,
      body: body,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() {
      _outbox
        ..removeWhere((m) => m.id == pending.id)
        ..add(pending);
      if (retry == null) _input.clear();
    });
    _toBottom();
    try {
      await ref.read(messageControllerProvider).post(t, pending.id, body);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _outbox.indexWhere((m) => m.id == pending.id);
        if (i >= 0) {
          _outbox[i] = ChatMessage(
            id: pending.id,
            threadId: t.id,
            senderId: pending.senderId,
            body: body,
            createdAt: pending.createdAt,
            failed: true,
          );
        }
      });
      showFailure(context, e);
    }
  }

  Future<void> _setResolved(MessageThread t, bool resolved) async {
    setState(() => _statusBusy = true);
    try {
      await ref.read(messageControllerProvider).setResolved(t, resolved);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  /// Long-press on a group message: copy, and remove for whoever may.
  Future<void> _actions(MessageThread t, ChatMessage m, bool canHide) async {
    final l = AppLocalizations.of(context);
    final action = await AppSheet.show<String>(
      context,
      title: l.msgTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(l.platformCopy),
            onTap: () => Navigator.pop(context, 'copy'),
          ),
          if (canHide)
            ListTile(
              key: const Key('msgHide'),
              leading: Icon(Icons.delete_outline, color: context.palette.due),
              title: Text(
                l.msgHide,
                style: TextStyle(color: context.palette.due),
              ),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.body));
      if (mounted) showSnack(context, l.platformCopied);
    } else if (action == 'hide') {
      final ok = await confirmDialog(
        context,
        title: l.msgHide,
        body: l.msgHideBody,
        action: l.msgHideAction,
      );
      if (!ok || !mounted) return;
      try {
        await ref.read(messageControllerProvider).hide(t, m.id);
      } catch (e) {
        if (mounted) showFailure(context, e);
      }
    }
  }

  /// Marks read once per newest message seen.
  void _markRead(MessageThread t, List<ChatMessage> server) {
    final last = server.lastOrNull?.id;
    if (last == null || last == _readUpTo) return;
    _readUpTo = last;
    unawaited(ref.read(messageControllerProvider).markRead(t));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final isManager = ref.watch(amIManagerProvider);
    final threadAsync = ref.watch(threadProvider(widget.id));
    final msgsAsync = ref.watch(threadMessagesProvider(widget.id));
    final t = threadAsync.value;
    final group = t?.isGroup ?? false;
    ref.listen(pushArrivalProvider, (_, next) {
      if (next.value == '/more/messages/${widget.id}') _refresh();
    });
    ref.listen(threadMessagesProvider(widget.id), (_, next) {
      if (next.hasValue) _toBottom();
    });

    final server = msgsAsync.value;
    if (server != null) {
      final ids = {for (final m in server) m.id};
      _outbox.removeWhere((m) => ids.contains(m.id));
      if (t != null) _markRead(t, server);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group ? groupTitle(l, ref) : t?.subject ?? l.msgTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (t != null && (group || isManager))
              Text(
                group
                    ? l.msgGroupMembers(
                        Fmt.digits(
                          '${groupMemberCount(ref, t.messId)}',
                          bangla: l.localeName == 'bn',
                        ),
                      )
                    : t.memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: context.palette.inkSecondary,
                ),
              ),
          ],
        ),
      ),
      body: t != null && server != null
          ? Column(
              children: [
                if (!group)
                  _StatusBar(
                    thread: t,
                    isManager: isManager,
                    busy: _statusBusy,
                    onSet: (r) => _setResolved(t, r),
                  ),
                Expanded(child: _messages(context, t, [...server, ..._outbox])),
                _Composer(controller: _input, onSend: () => _send(t)),
              ],
            )
          : switch (threadAsync.error ?? msgsAsync.error) {
              final error? => ErrorView(
                message: failureText(context, error),
                onRetry: _refresh,
              ),
              _ when threadAsync.hasValue => EmptyView(
                message: l.msgGone,
                icon: Icons.forum_outlined,
              ),
              _ => const LoadingView(),
            },
    );
  }

  Widget _messages(
    BuildContext context,
    MessageThread t,
    List<ChatMessage> all,
  ) {
    final isManager = ref.watch(amIManagerProvider);
    final me = ref.watch(messageControllerProvider).myUserId;
    final names = memberNames(ref, t.messId);
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final children = <Widget>[];
    for (var i = 0; i < all.length; i++) {
      final m = all[i];
      final prev = i == 0 ? null : all[i - 1];
      final mine = m.senderId != null && m.senderId == me;
      if (prev == null ||
          !DateUtils.isSameDay(
            prev.createdAt.toLocal(),
            m.createdAt.toLocal(),
          )) {
        children.add(_DaySeparator(day: m.createdAt));
      }
      if (m.meta != null && !m.hidden) {
        children.add(_SystemPill(message: m));
        continue;
      }
      final actionable = t.isGroup && !m.hidden && !m.pending && !m.failed;
      children.add(
        _Bubble(
          message: m,
          mine: mine,
          // The group names every incoming message; in a direct thread
          // managers see who wrote, consecutive ones sharing the name.
          name: t.isGroup || (isManager && prev?.senderId != m.senderId)
              ? (names[m.senderId] ?? l.msgDeletedUser)
              : null,
          avatar: t.isGroup,
          onRetry: m.failed ? () => _send(t, m) : null,
          onLongPress: actionable
              ? () => _actions(t, m, isManager || mine)
              : null,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await ref.read(threadMessagesProvider(widget.id).future);
      },
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.md,
          AppSpace.gutter,
          AppSpace.lg,
        ),
        children: [
          if (t.refLabel != null) ...[
            RefCard(type: t.refType, label: t.refLabel!, refId: t.refId),
            const SizedBox(height: AppSpace.lg),
          ],
          if (t.isGroup && all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
              child: EmptyView(
                message: l.msgGroupEmpty,
                icon: Icons.groups_outlined,
              ),
            ),
          ...children,
          if (t.resolved && !t.isGroup)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(
                l.msgResolvedNote,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: p.inkTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// "আজ" / "গতকাল" / "৮ অক্টোবর ২০২৬" between messages of different days.
class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = l.localeName == 'bn';
    final local = DateUtils.dateOnly(day.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());
    final label = local == today
        ? l.msgDayToday
        : local == DateUtils.addDaysToDate(today, -1)
        ? l.msgDayYesterday
        : Fmt.dateLong(local, locale: l.localeName, banglaDigits: bn);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.lg),
      child: Row(
        spacing: AppSpace.md,
        children: [
          Expanded(child: Divider(color: p.border, height: 1)),
          Semantics(
            header: true,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: p.inkTertiary),
            ),
          ),
          Expanded(child: Divider(color: p.border, height: 1)),
        ],
      ),
    );
  }
}

/// A system notice ("তানভীর আজ রাতের মিল বন্ধ করেছেন") as a centred pill,
/// worded in my language from its payload; the stored text otherwise.
class _SystemPill extends StatelessWidget {
  const _SystemPill({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            child: Text(
              systemNoticeText(context, message),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: p.inkSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The words of a system notice for this viewer (day relative to today).
String systemNoticeText(BuildContext context, ChatMessage m) {
  final l = AppLocalizations.of(context);
  final j = m.meta!;
  final date = DateTime.tryParse('${j['date']}');
  if (j['t'] != 'meal_off' || date == null) return m.body;
  final today = DateUtils.dateOnly(DateTime.now());
  final day = switch (date.difference(today).inDays) {
    0 => l.msgDayToday,
    1 => l.dayTomorrow,
    -1 => l.msgDayYesterday,
    _ => Fmt.dateLong(
      date,
      locale: l.localeName,
      banglaDigits: l.localeName == 'bn',
    ),
  };
  final name = '${j['name'] ?? ''}';
  final meal = mealOf(context, '${j['meal_name'] ?? ''}');
  return j['off'] == true
      ? l.msgMealOff(name, day, meal)
      : l.msgMealOn(name, day, meal);
}

/// Status tag, plus resolve / reopen for whoever may.
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.thread,
    required this.isManager,
    required this.busy,
    required this.onSet,
  });

  final MessageThread thread;
  final bool isManager;
  final bool busy;
  final ValueChanged<bool> onSet;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final resolved = thread.resolved;
    // Managers resolve or reopen; the member may only reopen.
    final canAct = isManager || resolved;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.gutter,
          vertical: AppSpace.xs,
        ),
        child: Row(
          spacing: AppSpace.sm,
          children: [
            StatusTag(
              resolved ? l.msgResolved : l.msgFilterOpen,
              strong: resolved,
            ),
            const Spacer(),
            if (canAct)
              TextButton.icon(
                key: const Key('msgStatusButton'),
                onPressed: busy ? null : () => onSet(!resolved),
                icon: Icon(
                  resolved ? Icons.replay : Icons.check_circle_outline,
                  size: AppSize.spinner,
                ),
                label: Text(resolved ? l.msgReopen : l.msgResolve),
              ),
            if (!canAct) const SizedBox(height: AppSize.touch),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.name,
    this.avatar = false,
    this.onRetry,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool mine;
  final String? name;

  /// The sender's initial beside incoming bubbles (the group).
  final bool avatar;
  final VoidCallback? onRetry;

  /// Copy / remove sheet; the text is then not selectable in place.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final m = message;
    const r = Radius.circular(AppRadius.lg);
    const tail = Radius.circular(AppSpace.xs);
    final meta = m.failed
        ? l.msgNotSent
        : m.pending
        ? l.msgSending
        : messageTime(context, m.createdAt);

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md + 2,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: m.hidden
            ? Colors.transparent
            : mine
            ? p.ink
            : p.surfaceRaised,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: mine ? r : tail,
          bottomRight: mine ? tail : r,
        ),
        border: m.failed
            ? Border.all(color: p.due, width: 1.5)
            : mine && !m.hidden
            ? null
            : Border.all(color: p.border),
        boxShadow: mine || m.hidden ? null : AppElevation.raised(p),
      ),
      child: m.hidden
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.xs,
              children: [
                Icon(Icons.block, size: 16, color: p.inkTertiary),
                Flexible(
                  child: Text(
                    l.msgHidden,
                    style: text.bodyMedium?.copyWith(
                      color: p.inkTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            )
          : onLongPress != null
          ? Text(
              m.body,
              style: text.bodyLarge?.copyWith(color: mine ? p.onInk : p.ink),
            )
          : SelectableText(
              m.body,
              style: text.bodyLarge?.copyWith(color: mine ? p.onInk : p.ink),
            ),
    );
    if (m.pending) bubble = Opacity(opacity: 0.6, child: bubble);
    if (onLongPress != null) {
      bubble = GestureDetector(
        key: Key('msgBubble-${m.id}'),
        onLongPress: onLongPress,
        child: bubble,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: _withAvatar(
            avatar && !mine ? name : null,
            Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                if (name != null && !mine)
                  Text(
                    name!,
                    style: text.labelMedium?.copyWith(color: p.inkSecondary),
                  ),
                bubble,
                InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: onRetry == null ? 0 : AppSpace.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpace.xs,
                      children: [
                        if (m.failed)
                          Icon(Icons.error_outline, size: 16, color: p.due),
                        Text(
                          meta,
                          style: text.labelSmall?.copyWith(
                            color: m.failed ? p.due : p.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Puts the sender's initial at the bubble's top start.
  static Widget _withAvatar(String? name, Widget column) => name == null
      ? column
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.sm,
          children: [
            InitialsAvatar(name, size: 32),
            Flexible(child: column),
          ],
        );
}

/// Text field + send. Send is off while the field is empty.
class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final empty = controller.text.trim().isEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.sm,
            AppSpace.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSpace.sm,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('msgComposer'),
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: messageBodyMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l.msgComposeHint,
                    counterText: '',
                  ),
                ),
              ),
              IconButton.filled(
                key: const Key('msgSend'),
                tooltip: l.msgSend,
                constraints: const BoxConstraints(
                  minWidth: AppSize.touch,
                  minHeight: AppSize.touch,
                ),
                onPressed: empty ? null : onSend,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

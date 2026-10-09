import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
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
class RefCard extends StatelessWidget {
  const RefCard({super.key, required this.type, required this.label});

  final String? type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final (icon, kind) = refCopy(l, type);
    final route = refRoute(type);
    return AppCard.raised(
      padding: const EdgeInsets.all(AppSpace.md),
      onTap: route == null ? null : () => context.go(route),
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
          if (route != null) Icon(Icons.chevron_right, color: p.inkTertiary),
        ],
      ),
    );
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
                isManager
                    ? value.where((t) => t.resolved == _resolved).toList()
                    : value,
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
    List<MessageThread> threads, {
    required bool isManager,
    required VoidCallback onCompose,
  }) {
    final l = AppLocalizations.of(context);
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
                    if (t.isUnread)
                      Semantics(
                        label: l.msgUnread,
                        child: Container(
                          key: const Key('msgUnreadDot'),
                          width: AppSize.dot + 2,
                          height: AppSize.dot + 2,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
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
              t?.subject ?? l.msgTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isManager && t != null)
              Text(
                t.memberName,
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
    final names = <String, String>{
      for (final m
          in ref.watch(membersProvider(t.messId)).value ?? const <Member>[])
        if (m.userId != null) m.userId!: m.displayName,
    };
    final l = AppLocalizations.of(context);
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
            RefCard(type: t.refType, label: t.refLabel!),
            const SizedBox(height: AppSpace.lg),
          ],
          for (var i = 0; i < all.length; i++)
            _Bubble(
              message: all[i],
              mine: all[i].senderId != null && all[i].senderId == me,
              // Managers see who wrote; consecutive ones share the name.
              name:
                  isManager &&
                      (i == 0 || all[i - 1].senderId != all[i].senderId)
                  ? (names[all[i].senderId] ?? l.msgDeletedUser)
                  : null,
              onRetry: all[i].failed ? () => _send(t, all[i]) : null,
            ),
          if (t.resolved)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(
                l.msgResolvedNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.palette.inkTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
    this.onRetry,
  });

  final ChatMessage message;
  final bool mine;
  final String? name;
  final VoidCallback? onRetry;

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
        color: mine ? p.ink : p.surfaceRaised,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: mine ? r : tail,
          bottomRight: mine ? tail : r,
        ),
        border: m.failed
            ? Border.all(color: p.due, width: 1.5)
            : mine
            ? null
            : Border.all(color: p.border),
        boxShadow: mine ? null : AppElevation.raised(p),
      ),
      child: SelectableText(
        m.body,
        style: text.bodyLarge?.copyWith(color: mine ? p.onInk : p.ink),
      ),
    );
    if (m.pending) bubble = Opacity(opacity: 0.6, child: bubble);

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
          child: Column(
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
    );
  }
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

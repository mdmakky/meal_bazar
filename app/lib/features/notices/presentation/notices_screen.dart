import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../application/notice_providers.dart';
import '../domain/notice.dart';

String noticeDate(BuildContext context, DateTime d) {
  final l = AppLocalizations.of(context);
  return Fmt.dateLong(
    d.toLocal(),
    locale: l.localeName,
    banglaDigits: l.localeName == 'bn',
  );
}

/// The notice board: pinned first, unread marked, expired hidden.
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.noticeTitle)),
      floatingActionButton: isManager && messId != null
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.noticeAdd),
              onPressed: () => showNoticeForm(context, messId: messId),
            )
          : null,
      body: messId == null
          ? EmptyView(message: l.emptyGeneric)
          : switch (ref.watch(noticesProvider(messId))) {
              AsyncValue(:final value?) when value.isEmpty => EmptyView(
                message: l.noticeEmpty,
                icon: Icons.campaign_outlined,
                actionLabel: isManager ? l.noticeAdd : null,
                onAction: isManager
                    ? () => showNoticeForm(context, messId: messId)
                    : null,
              ),
              AsyncValue(:final value?) => RefreshIndicator(
                onRefresh: () => ref.refresh(noticesProvider(messId).future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpace.xxxl * 2),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: AppSize.hairline),
                  itemBuilder: (_, i) => NoticeTile(notice: value[i]),
                ),
              ),
              AsyncValue(:final error?) => ErrorView(
                message: failureText(context, error),
                onRetry: () => ref.invalidate(noticesProvider(messId)),
              ),
              _ => const LoadingView(),
            },
    );
  }
}

class NoticeTile extends StatelessWidget {
  const NoticeTile({super.key, required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final n = notice;

    return ListTile(
      minTileHeight: AppSize.touch + AppSpace.md,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      leading: SizedBox(
        width: AppSpace.sm,
        child: n.isRead
            ? null
            : Semantics(
                label: l.noticeUnread,
                child: Container(
                  key: const Key('noticeUnreadDot'),
                  width: AppSpace.sm,
                  height: AppSpace.sm,
                  decoration: BoxDecoration(
                    color: p.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
      ),
      title: Text(
        n.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.titleSmall?.copyWith(
          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          if (n.body.isNotEmpty)
            Text(
              n.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
          Text(
            noticeDate(context, n.createdAt),
            style: text.labelSmall?.copyWith(color: p.inkTertiary),
          ),
        ],
      ),
      trailing: n.pinned
          ? Icon(Icons.push_pin_outlined, semanticLabel: l.noticePinned)
          : null,
      onTap: () => context.push('/more/notices/${n.id}'),
    );
  }
}

/// One notice in full. Opening it marks it read; managers can edit/delete.
class NoticeDetailScreen extends ConsumerStatefulWidget {
  const NoticeDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailState();
}

class _NoticeDetailState extends ConsumerState<NoticeDetailScreen> {
  var _marked = false;

  void _markRead(Notice n) {
    if (_marked || n.isRead) return;
    _marked = true;
    // Best effort: a failed read receipt just leaves the dot on.
    unawaited(
      ref.read(noticeControllerProvider).markRead(n).catchError((Object _) {}),
    );
  }

  Future<void> _delete(Notice n) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.noticeDeleteConfirmTitle,
      body: l.noticeDeleteConfirmBody,
      action: l.delete,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(noticeControllerProvider).delete(n);
      if (!mounted) return;
      showSnack(context, l.noticeDeleted);
      context.pop();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    final async = messId == null
        ? const AsyncValue<List<Notice>>.data([])
        : ref.watch(noticesProvider(messId));
    final n = async.value?.where((n) => n.id == widget.id).firstOrNull;
    if (n != null) _markRead(n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.noticeTitle),
        actions: [
          if (isManager && n != null) ...[
            IconButton(
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showNoticeForm(context, messId: n.messId, existing: n),
            ),
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(n),
            ),
          ],
        ],
      ),
      body: switch (async) {
        AsyncValue(hasValue: true) when n == null => EmptyView(
          message: l.noticeGone,
          icon: Icons.campaign_outlined,
        ),
        AsyncValue(hasValue: true) => ListView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: [
            Text(n!.title, style: text.headlineSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  noticeDate(context, n.createdAt),
                  style: text.labelSmall?.copyWith(color: p.inkTertiary),
                ),
                if (n.pinned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpace.xs,
                    children: [
                      Icon(
                        Icons.push_pin_outlined,
                        size: AppSpace.lg,
                        color: p.inkTertiary,
                      ),
                      Text(
                        l.noticePinned,
                        style: text.labelSmall?.copyWith(color: p.inkTertiary),
                      ),
                    ],
                  ),
                if (n.expiresAt != null)
                  Text(
                    l.noticeUntil(
                      noticeDate(
                        context,
                        n.expiresAt!.subtract(const Duration(minutes: 1)),
                      ),
                    ),
                    style: text.labelSmall?.copyWith(color: p.inkTertiary),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            SelectableText(n.body, style: text.bodyLarge),
          ],
        ),
        AsyncValue(:final error?) => ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(noticesProvider(messId!)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

/// Manager compose / edit sheet. Snackbars "saved" when it closes saved.
Future<void> showNoticeForm(
  BuildContext context, {
  required String messId,
  Notice? existing,
}) async {
  final l = AppLocalizations.of(context);
  final saved = await AppSheet.show<bool>(
    context,
    title: existing == null ? l.noticeAdd : l.noticeEdit,
    child: NoticeForm(messId: messId, existing: existing),
  );
  if (saved == true && context.mounted) showSnack(context, l.noticeSaved);
}

class NoticeForm extends ConsumerStatefulWidget {
  const NoticeForm({super.key, required this.messId, this.existing});

  final String messId;
  final Notice? existing;

  @override
  ConsumerState<NoticeForm> createState() => _NoticeFormState();
}

class _NoticeFormState extends ConsumerState<NoticeForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);
  late var _pinned = widget.existing?.pinned ?? false;

  /// The last day the notice shows; it expires at the end of that day.
  late DateTime? _lastDay = switch (widget.existing?.expiresAt) {
    final e? => DateUtils.dateOnly(
      e.toLocal().subtract(const Duration(minutes: 1)),
    ),
    null => null,
  };
  var _saving = false;
  Object? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _lastDay ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _lastDay = d);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final day = _lastDay;
    try {
      await ref
          .read(noticeControllerProvider)
          .save(
            id: widget.existing?.id,
            messId: widget.messId,
            title: _title.text,
            body: _body.text,
            pinned: _pinned,
            expiresAt: day == null
                ? null
                : DateTime(day.year, day.month, day.day + 1),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final day = _lastDay;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.lg,
        children: [
          TextFormField(
            key: const Key('noticeTitleField'),
            controller: _title,
            maxLength: noticeTitleMax,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.noticeTitleLabel),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l.noticeTitleRequired : null,
          ),
          TextFormField(
            key: const Key('noticeBodyField'),
            controller: _body,
            maxLength: noticeBodyMax,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(labelText: l.noticeBodyLabel),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.noticePin),
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSize.touch,
            leading: const Icon(Icons.event_outlined),
            title: Text(l.noticeExpiry),
            subtitle: Text(
              day == null
                  ? l.noticeNoExpiry
                  : l.noticeUntil(noticeDate(context, day)),
            ),
            trailing: day == null
                ? null
                : IconButton(
                    tooltip: l.noticeClearExpiry,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lastDay = null),
                  ),
            onTap: _pickDay,
          ),
          if (_error != null)
            Text(
              failureText(context, _error!),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.palette.due),
            ),
          AppButton(label: l.noticeSave, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

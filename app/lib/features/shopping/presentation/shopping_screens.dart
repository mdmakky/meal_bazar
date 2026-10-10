import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_widgets.dart' show pickOne;
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/domain/bazar_catalogue.dart' show bazarUnits;
import '../../money/domain/money.dart' show parseAmount;
import '../../money/presentation/money_sheets.dart' show money, shortDate;
import '../application/shopping_providers.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

Map<String, String> _names(WidgetRef ref, String messId) => {
  for (final m in ref.watch(membersProvider(messId)).value ?? const <Member>[])
    m.id: m.displayName,
};

// ── Bazar tab: the lists I may see ─────────────────────────────────────────

/// "বাজারের তালিকা" on the Bazar tab: open and waiting lists, and a way to
/// start one.
class ShoppingSection extends ConsumerWidget {
  const ShoppingSection({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = l.localeName == 'bn';
    final lists = ref.watch(shoppingListsProvider(messId)).value ?? const [];
    final names = _names(ref, messId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.shopTitle, style: text.titleSmall)),
              TextButton.icon(
                key: const Key('shop-new'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.shopNew),
                onPressed: () => AppSheet.show<void>(
                  context,
                  title: l.shopSheetTitle,
                  child: NewShoppingListForm(messId: messId),
                ),
              ),
            ],
          ),
          if (lists.isEmpty)
            Text(
              l.shopEmpty,
              style: text.bodySmall?.copyWith(color: p.inkTertiary),
            )
          else
            RaisedGroup(
              children: [
                for (final s in lists)
                  ListTile(
                    key: Key('shop-${s.id}'),
                    minTileHeight: AppSize.touch + AppSpace.md,
                    leading: const IconTile(Icons.checklist_rtl_outlined),
                    title: Text(
                      s.title ?? shortDate(context, s.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    subtitle: Text(
                      [
                        l.shopProgress(
                          Fmt.digits('${s.boughtCount}', bangla: bn),
                          Fmt.digits('${s.items.length}', bangla: bn),
                        ),
                        if (s.assigneeId != null)
                          l.shopAssignedTo(names[s.assigneeId] ?? ''),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: StatusTag(
                      s.isOpen ? l.shopStatusOpen : l.shopStatusWaiting,
                    ),
                    onTap: () => context.push('/bazar/list/${s.id}'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Day, who goes (a manager may send someone), a note; then the list opens
/// to fill in.
class NewShoppingListForm extends ConsumerStatefulWidget {
  const NewShoppingListForm({super.key, required this.messId});

  final String messId;

  @override
  ConsumerState<NewShoppingListForm> createState() =>
      _NewShoppingListFormState();
}

class _NewShoppingListFormState extends ConsumerState<NewShoppingListForm> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  var _date = today();
  String? _assignee;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = uuidV4();
    setState(() => _busy = true);
    try {
      await ref
          .read(shoppingControllerProvider)
          .saveList(
            id: id,
            messId: widget.messId,
            date: _date,
            title: _title.text.trim().isEmpty ? null : _title.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            assigneeId: _assignee,
          );
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push('/bazar/list/$id');
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final manager = ref.watch(amIManagerProvider);
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final members = [
      for (final m
          in ref.watch(membersProvider(widget.messId)).value ??
              const <Member>[])
        if (m.status == MemberStatus.active && m.id != me) m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        TextField(
          key: const Key('shop-title'),
          controller: _title,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: l.shopFieldTitle,
            counterText: '',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: AppSize.touch,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(l.shopFieldDate),
          trailing: Text(
            shortDate(context, _date),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: today().subtract(const Duration(days: 30)),
              lastDate: today().add(const Duration(days: 60)),
            );
            if (d != null && mounted) setState(() => _date = dayOnly(d));
          },
        ),
        if (manager && members.isNotEmpty)
          DropdownButtonFormField<String?>(
            key: const Key('shop-assign'),
            initialValue: _assignee,
            decoration: InputDecoration(labelText: l.shopFieldAssign),
            items: [
              DropdownMenuItem(value: null, child: Text(l.shopMe)),
              for (final m in members)
                DropdownMenuItem(value: m.id, child: Text(m.displayName)),
            ],
            onChanged: (v) => setState(() => _assignee = v),
          ),
        TextField(
          controller: _note,
          maxLength: 300,
          decoration: InputDecoration(labelText: l.shopFieldNote),
        ),
        AppButton(
          key: const Key('shop-create'),
          label: l.shopCreate,
          loading: _busy,
          onPressed: _create,
        ),
      ],
    );
  }
}

/// The Bazar tab's way in: one clear card to the lists (and to start one).
class ShoppingEntryCard extends ConsumerWidget {
  const ShoppingEntryCard({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final n =
        (ref.watch(shoppingListsProvider(messId)).value ?? const []).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: AppCard.raised(
        key: const Key('shop-entry'),
        onTap: () => context.push('/bazar/lists'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          spacing: AppSpace.md,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.checklist_rtl_outlined, color: p.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.shopTitle, style: text.titleSmall),
                  Text(
                    n == 0
                        ? l.shopEntryNone
                        : l.shopEntryCount(
                            Fmt.digits('$n', bangla: l.localeName == 'bn'),
                          ),
                    style: text.bodySmall?.copyWith(color: p.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.inkTertiary),
          ],
        ),
      ),
    );
  }
}

/// All the lists, and a way to start one.
class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.shopTitle)),
      body: messId == null
          ? EmptyView(message: l.shopEmpty)
          : RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(shoppingListsProvider(messId).future),
              child: ListView(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                children: [ShoppingSection(messId: messId)],
              ),
            ),
    );
  }
}

// ── Home: a list waiting for me ────────────────────────────────────────────

/// Home, for the member a manager sent shopping: one tap to the list.
class ShoppingHomeCard extends ConsumerWidget {
  const ShoppingHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    final me = ref.watch(currentMembershipProvider)?.member.id;
    if (messId == null || me == null) return const SizedBox.shrink();
    final mine = [
      for (final s
          in ref.watch(shoppingListsProvider(messId)).value ??
              const <ShoppingList>[])
        if (s.isOpen && s.assigneeId == me) s,
    ];
    if (mine.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final first = mine.first;
    final left = first.items.where((i) => !i.bought).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: AppCard.raised(
        key: const Key('shop-home'),
        onTap: () => context.push('/bazar/list/${first.id}'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          spacing: AppSpace.md,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.checklist_rtl_outlined, color: p.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.shopHomeTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    l.shopHomeSub(
                      Fmt.digits('$left', bangla: l.localeName == 'bn'),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.inkTertiary),
          ],
        ),
      ),
    );
  }
}

// ── The list itself ────────────────────────────────────────────────────────

/// Plan, then shop: tick what is bought and write its price; the total is
/// the ticked prices. Edits save as you go (the list keeps its own copy, so
/// nothing reloads under your thumb); "send as bazar" hands it in.
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  ShoppingList? _list;
  Object? _error;
  var _loading = true;
  var _busy = false;
  final _timers = <String, Timer>{};
  final _pending = <String, ShoppingItem>{};

  late final ShoppingRepository _repo = ref.read(shoppingRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Whatever was typed a moment ago still reaches the server.
    for (final t in _timers.values) {
      t.cancel();
    }
    for (final i in _pending.values) {
      unawaited(
        _repo.upsertItem(_list?.messId ?? '', i).catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await _repo.list(ref.read(currentMessIdProvider)!, widget.id);
      if (mounted) {
        setState(() {
          _list = l;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  /// Shows [l] and keeps the phone's copy in step, so the list survives a
  /// restart or a lost signal.
  void _setList(ShoppingList l) {
    setState(() => _list = l);
    unawaited(ref.read(shoppingControllerProvider).remember(l));
  }

  void _replace(ShoppingItem item) {
    final l = _list!;
    _setList(
      l.copyWith(items: [for (final i in l.items) i.id == item.id ? item : i]),
    );
  }

  /// Saves an item a moment after the last change.
  void _change(ShoppingItem item, {bool now = false}) {
    _replace(item);
    _pending[item.id] = item;
    _timers[item.id]?.cancel();
    Future<void> send() async {
      _timers.remove(item.id);
      final latest = _pending.remove(item.id);
      if (latest == null) return;
      try {
        await ref
            .read(shoppingControllerProvider)
            .upsertItem(_list!.messId, latest);
      } catch (e) {
        if (mounted) showFailure(context, e);
      }
    }

    if (now) {
      unawaited(send());
    } else {
      _timers[item.id] = Timer(const Duration(milliseconds: 700), send);
    }
  }

  Future<void> _flush() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    final items = _pending.values.toList();
    _pending.clear();
    for (final i in items) {
      await _repo.upsertItem(_list!.messId, i);
    }
  }

  Future<void> _add({required bool planner}) async {
    final l = AppLocalizations.of(context);
    final r = await AppSheet.show<_ItemDraft>(
      context,
      title: planner ? l.shopAddItem : l.shopAddExtra,
      child: const _ItemForm(),
    );
    if (r == null || !mounted) return;
    final list = _list!;
    final item = ShoppingItem(
      id: uuidV4(),
      listId: list.id,
      name: r.name,
      qty: r.qty,
      unit: r.unit,
      extra: !planner,
      sort: list.items.isEmpty ? 0 : list.items.last.sort + 1,
    );
    _setList(list.copyWith(items: [...list.items, item]));
    try {
      await ref.read(shoppingControllerProvider).upsertItem(list.messId, item);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _edit(ShoppingItem item) async {
    final r = await AppSheet.show<_ItemDraft>(
      context,
      title: item.name,
      child: _ItemForm(initial: item),
    );
    if (r == null || !mounted) return;
    _change(item.copyWith(name: r.name, qty: r.qty, unit: r.unit), now: true);
  }

  Future<void> _remove(ShoppingItem item) async {
    final list = _list!;
    setState(
      () => _list = list.copyWith(
        items: [
          for (final i in list.items)
            if (i.id != item.id) i,
        ],
      ),
    );
    _pending.remove(item.id);
    _timers.remove(item.id)?.cancel();
    try {
      await ref
          .read(shoppingControllerProvider)
          .deleteItem(list.messId, item.id);
    } catch (e) {
      if (mounted) {
        showFailure(context, e);
        unawaited(_load());
      }
    }
  }

  Future<void> _submit(bool manager) async {
    final l = AppLocalizations.of(context);
    final list = _list!;
    if (list.total <= 0) {
      showSnack(context, l.shopNothing);
      return;
    }
    final ownPocket = await pickOne<bool>(
      context,
      title: l.shopSubmitSheet,
      options: [(true, l.shopOwnPocket), (false, l.shopFromFund)],
    );
    if (ownPocket == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _flush();
      await ref
          .read(shoppingControllerProvider)
          .submit(list, ownPocket: ownPocket);
      if (!mounted) return;
      showSnack(context, manager ? l.shopSentDone : l.shopSent);
      await _load();
      if (mounted && _list?.status == 'done') context.pop();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A manager sent it to the wrong person (or wants it back): pick again.
  /// The person it is taken from is told.
  Future<void> _reassign() async {
    final l = AppLocalizations.of(context);
    final list = _list!;
    final me = ref.read(currentMembershipProvider)?.member.id;
    final members = [
      for (final m
          in ref.read(membersProvider(list.messId)).value ?? const <Member>[])
        if (m.status == MemberStatus.active) m,
    ];
    final pick = await pickOne<String>(
      context,
      title: l.shopChangeWho,
      options: [
        if (me != null) (me, l.shopMe),
        for (final m in members)
          if (m.id != me) (m.id, m.displayName),
      ],
    );
    if (pick == null || !mounted) return;
    try {
      await ref
          .read(shoppingControllerProvider)
          .saveList(
            id: list.id,
            messId: list.messId,
            date: list.date,
            title: list.title,
            note: list.note,
            assigneeId: pick,
          );
      await _load();
      if (mounted) showSnack(context, l.shopWhoChanged);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.shopCancelAsk,
      body: _list!.title ?? shortDate(context, _list!.date),
      action: l.delete,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(shoppingControllerProvider).cancel(_list!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final list = _list;
    final manager = ref.watch(amIManagerProvider);
    final me = ref.watch(currentMembershipProvider)?.member.id;

    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.shopTitle)),
        body: _loading
            ? const LoadingView()
            : _error != null
            ? ErrorView(
                message: failureText(context, _error!),
                onRetry: () {
                  setState(() => _loading = true);
                  _load();
                },
              )
            : EmptyView(message: l.shopNotFound),
      );
    }
    final names = _names(ref, list.messId);
    final planner = manager || list.createdBy == me;
    final canWork = manager || list.createdBy == me || list.assigneeId == me;
    final editable = list.isOpen && canWork;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          list.title ?? shortDate(context, list.date),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (list.isOpen && planner)
            PopupMenuButton<int>(
              key: const Key('shop-menu'),
              onSelected: (v) => v == 1 ? _reassign() : _cancel(),
              itemBuilder: (_) => [
                if (manager)
                  PopupMenuItem(value: 1, child: Text(l.shopChangeWho)),
                PopupMenuItem(value: 0, child: Text(l.shopCancel)),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxxl * 2,
        ),
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              StatusTag(shortDate(context, list.date)),
              if (list.assigneeId != null)
                StatusTag(l.shopAssignedTo(names[list.assigneeId] ?? '')),
              StatusTag(list.isOpen ? l.shopStatusOpen : l.shopStatusWaiting),
            ],
          ),
          if (list.note != null && list.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Text(list.note!, style: text.bodyMedium),
            ),
          if (list.isOpen && list.rejectReason != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(
                l.shopRejected(list.rejectReason!),
                key: const Key('shop-rejected'),
                style: text.bodyMedium?.copyWith(color: p.due),
              ),
            ),
          if (!list.isOpen)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(
                l.shopSubmitted,
                key: const Key('shop-submitted'),
                style: text.bodyMedium?.copyWith(color: p.inkSecondary),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          if (list.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Center(child: Text(l.shopAddItem, style: text.bodyMedium)),
            )
          else
            RaisedGroup(
              children: [
                for (final i in list.items)
                  _ItemRow(
                    key: ValueKey(i.id),
                    item: i,
                    editable: editable,
                    removable: editable && (planner || i.extra),
                    onChanged: _change,
                    onEdit: () => _edit(i),
                    onRemove: () => _remove(i),
                  ),
              ],
            ),
          if (editable)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: AppButton(
                key: const Key('shop-add-item'),
                label: planner ? l.shopAddItem : l.shopAddExtra,
                icon: Icons.add,
                variant: AppButtonVariant.secondary,
                onPressed: () => _add(planner: planner),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !editable
          ? null
          : BottomAction(
              children: [
                Row(
                  spacing: AppSpace.lg,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.shopTotal, style: text.labelSmall),
                        Text(
                          money(context, list.total),
                          key: const Key('shop-total'),
                          style: text.titleLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: AppButton(
                        key: const Key('shop-submit'),
                        label: l.shopSubmit,
                        loading: _busy,
                        onPressed: () => _submit(manager),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.editable,
    required this.removable,
    required this.onChanged,
    required this.onEdit,
    required this.onRemove,
  });

  final ShoppingItem item;
  final bool editable;
  final bool removable;
  final void Function(ShoppingItem item, {bool now}) onChanged;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final _price = TextEditingController(
    text: widget.item.price == null ? '' : _num(widget.item.price!),
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final item = widget.item;
    final bn = l.localeName == 'bn';
    final qty = [
      if (item.qty != null) Fmt.digits(_num(item.qty!), bangla: bn),
      ?item.unit,
    ].join(' ');
    final row = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.sm,
        end: AppSpace.md,
        top: AppSpace.xs,
        bottom: AppSpace.xs,
      ),
      child: Row(
        children: [
          Checkbox(
            key: Key('shop-tick-${item.id}'),
            value: item.bought,
            onChanged: widget.editable
                ? (v) => widget.onChanged(
                    item.copyWith(bought: v ?? false),
                    now: true,
                  )
                : null,
          ),
          Expanded(
            child: InkWell(
              onTap: widget.editable ? widget.onEdit : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: text.bodyLarge?.copyWith(
                        decoration: item.bought
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.bought ? p.inkSecondary : p.ink,
                      ),
                    ),
                    if (qty.isNotEmpty || item.extra)
                      Text(
                        [
                          if (qty.isNotEmpty) qty,
                          if (item.extra) l.shopExtra,
                        ].join(' · '),
                        style: text.bodySmall?.copyWith(color: p.inkTertiary),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: TextField(
              key: Key('shop-price-${item.id}'),
              controller: _price,
              enabled: widget.editable,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]')),
              ],
              onChanged: (v) => widget.onChanged(
                item.copyWith(
                  price: v.trim().isEmpty ? null : parseAmount(v),
                  // Writing a price means it was bought.
                  bought: v.trim().isNotEmpty ? true : item.bought,
                ),
              ),
              style: text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: l.shopPrice,
                prefixText: '৳',
                isDense: true,
                filled: true,
                fillColor: p.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.sm + 2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (!widget.removable) return row;
    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove(),
      background: ColoredBox(
        color: p.due,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Icon(Icons.delete_outline, color: p.onInk),
          ),
        ),
      ),
      child: ColoredBox(color: p.surface, child: row),
    );
  }
}

typedef _ItemDraft = ({String name, double? qty, String? unit});

/// Name, quantity and unit of one item.
class _ItemForm extends StatefulWidget {
  const _ItemForm({this.initial});

  final ShoppingItem? initial;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _qty = TextEditingController(
    text: widget.initial?.qty == null ? '' : _num(widget.initial!.qty!),
  );
  late String? _unit = widget.initial?.unit;
  var _bad = false;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _done() {
    final name = _name.text.trim();
    final qtyText = _qty.text.trim();
    final qty = qtyText.isEmpty ? null : parseAmount(qtyText);
    if (name.isEmpty || (qtyText.isNotEmpty && (qty == null || qty <= 0))) {
      setState(() => _bad = true);
      return;
    }
    Navigator.pop<_ItemDraft>(context, (name: name, qty: qty, unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        TextField(
          key: const Key('shop-item-name'),
          controller: _name,
          autofocus: widget.initial == null,
          maxLength: 60,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l.shopItemName,
            counterText: '',
            errorText: _bad && _name.text.trim().isEmpty
                ? l.bazarItemInvalid
                : null,
          ),
        ),
        Row(
          spacing: AppSpace.md,
          children: [
            Expanded(
              child: TextField(
                key: const Key('shop-item-qty'),
                controller: _qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]')),
                ],
                decoration: InputDecoration(labelText: l.shopItemQty),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                key: const Key('shop-item-unit'),
                onPressed: () async {
                  final u = await pickOne<String>(
                    context,
                    title: l.bazarItemUnit,
                    options: [
                      for (final x in {?_unit, ...bazarUnits}) (x, x),
                      ('', l.bazarUnitNone),
                    ],
                  );
                  if (u != null && mounted) {
                    setState(() => _unit = u.isEmpty ? null : u);
                  }
                },
                child: Text(_unit ?? l.bazarItemUnit),
              ),
            ),
          ],
        ),
        AppButton(
          key: const Key('shop-item-save'),
          label: l.save,
          onPressed: _done,
        ),
      ],
    );
  }
}

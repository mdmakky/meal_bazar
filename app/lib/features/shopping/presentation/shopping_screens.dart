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
import '../../../core/platform/platform_config.dart';
import '../../money/domain/bazar_catalogue.dart' show bazarUnits, catalogueUnit;
import '../../money/domain/money.dart' show parseAmount;
import '../../money/presentation/money_sheets.dart'
    show BazarItemPicker, money, shortDate;
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
          _WhoField(
            key: const Key('shop-assign'),
            name: _assignee == null
                ? l.shopMe
                : members.firstWhere((m) => m.id == _assignee).displayName,
            sub: _assignee == null ? l.shopMeSub : l.shopNotifies,
            onTap: () async {
              final pick = await pickShopper(
                context,
                members: members,
                meId: me,
                selectedId: _assignee ?? me,
              );
              if (pick != null && mounted) {
                setState(() => _assignee = pick == me ? null : pick);
              }
            },
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
  final _picked = ValueNotifier<Set<String>>({});
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
    _picked.dispose();
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
        _picked.value = {
          for (final i in l?.items ?? const <ShoppingItem>[]) i.name,
        };
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
    _picked.value = {for (final i in l.items) i.name};
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

  /// A catalogue chip: on adds the item (quantity 1, its usual unit), off
  /// takes it off the list again (the shopper only their own extras).
  Future<void> _toggle(String name, {required bool planner}) async {
    final list = _list!;
    final existing = list.items.where((i) => i.name == name).firstOrNull;
    if (existing != null) {
      if (planner || existing.extra) await _remove(existing);
      return;
    }
    final item = ShoppingItem(
      id: uuidV4(),
      listId: list.id,
      name: name,
      qty: 1,
      unit: catalogueUnit(name, ref.read(platformConfigProvider).catalogue),
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
    final pick = await pickShopper(
      context,
      members: [
        for (final m in members)
          if (m.id != me) m,
      ],
      meId: me,
      selectedId: list.assigneeId ?? list.createdBy,
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
          // Pick from the catalogue, like on the Add bazar form.
          if (editable)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: BazarItemPicker(
                key: const Key('shop-picker'),
                selected: _picked,
                onToggle: (n) => _toggle(n, planner: planner),
                open: list.items.isEmpty,
              ),
            ),
          if (list.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Center(
                child: Text(
                  editable ? l.shopPickHint : l.shopEmptyList,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: p.inkTertiary),
                ),
              ),
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
                label: l.shopAddCustom,
                icon: Icons.add,
                variant: AppButtonVariant.secondary,
                onPressed: () => _add(planner: planner),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !editable
          ? null
          : _SendBar(list: list, busy: _busy, onSend: () => _submit(manager)),
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
  late final _qty = TextEditingController(
    text: widget.item.qty == null ? '' : _num(widget.item.qty!),
  );

  @override
  void dispose() {
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _pickUnit() async {
    final l = AppLocalizations.of(context);
    final item = widget.item;
    final u = await pickOne<String>(
      context,
      title: l.bazarItemUnit,
      options: [
        for (final x in {?item.unit, ...bazarUnits}) (x, x),
      ],
    );
    if (u != null && mounted) {
      widget.onChanged(item.copyWith(unit: u), now: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final item = widget.item;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.editable ? widget.onEdit : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    child: Text(
                      item.name,
                      style: text.bodyLarge?.copyWith(
                        decoration: item.bought
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.bought ? p.inkSecondary : p.ink,
                      ),
                    ),
                  ),
                ),
                // Quantity is typed right here (decimals ok) with its unit,
                // as on the Add bazar form: no extra tap to change it.
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 44,
                            child: TextField(
                              key: Key('shop-qty-${item.id}'),
                              controller: _qty,
                              enabled: widget.editable,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[0-9০-৯.]'),
                                ),
                              ],
                              onChanged: (v) {
                                final q = parseAmount(v);
                                if (q != null && q > 0) {
                                  widget.onChanged(item.copyWith(qty: q));
                                }
                              },
                              style: text.titleSmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              decoration: InputDecoration(
                                hintText: l.shopItemQty,
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.sm,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            key: Key('shop-unit-${item.id}'),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            onTap: widget.editable ? _pickUnit : null,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpace.xs,
                                end: AppSpace.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.unit ?? l.bazarItemUnit,
                                    style: text.labelLarge?.copyWith(
                                      color: item.unit == null
                                          ? p.inkTertiary
                                          : p.ink,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                    color: p.inkTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.extra)
                      Text(
                        l.shopExtra,
                        style: text.bodySmall?.copyWith(color: p.inkTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
              ],
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

/// The "who goes shopping" field: avatar, name, a line on what happens, a
/// chevron. Tapping opens [pickShopper].
class _WhoField extends StatelessWidget {
  const _WhoField({
    super.key,
    required this.name,
    required this.sub,
    required this.onTap,
  });

  final String name;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${l.shopFieldAssign}: $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l.shopFieldAssign,
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpace.sm,
              AppSpace.sm + 2,
              AppSpace.md,
              AppSpace.sm + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: p.border, width: 1.5),
            ),
          ),
          child: Row(
            spacing: AppSpace.md,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first,
                  style: text.labelLarge,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleSmall),
                    Text(
                      sub,
                      style: text.bodySmall?.copyWith(color: p.inkTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.expand_more, size: 18, color: p.inkSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list sheet to pick who goes: me first (set apart), then the members,
/// the chosen one tinted amber with a tick; a search box once there are many.
/// Returns the chosen member id ([meId] for "me"), or null if dismissed.
Future<String?> pickShopper(
  BuildContext context, {
  required List<Member> members,
  required String? meId,
  required String? selectedId,
}) => AppSheet.show<String>(
  context,
  title: AppLocalizations.of(context).shopFieldAssign,
  child: _ShopperList(members: members, meId: meId, selectedId: selectedId),
);

class _ShopperList extends StatefulWidget {
  const _ShopperList({
    required this.members,
    required this.meId,
    required this.selectedId,
  });

  final List<Member> members;
  final String? meId;
  final String? selectedId;

  @override
  State<_ShopperList> createState() => _ShopperListState();
}

class _ShopperListState extends State<_ShopperList> {
  var _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final shown = [
      for (final m in widget.members)
        if (m.id != widget.meId &&
            m.displayName.toLowerCase().contains(_q.trim().toLowerCase()))
          m,
    ];
    Widget row(String id, String name, String sub, {Key? key}) {
      final on = id == widget.selectedId;
      return Material(
        key: key,
        color: on ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Navigator.pop(context, id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.sm,
            ),
            child: Row(
              spacing: AppSpace.md,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? p.surface : p.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first,
                    style: text.labelLarge,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: text.titleSmall),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          style: text.bodySmall?.copyWith(color: p.inkTertiary),
                        ),
                    ],
                  ),
                ),
                if (on) Icon(Icons.check, color: p.accent),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.members.length > 6)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: TextField(
              key: const Key('shop-who-search'),
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: l.shopSearchMember,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: p.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        if (widget.meId != null && _q.trim().isEmpty) ...[
          row(widget.meId!, l.shopMe, l.shopMeSub, key: const Key('who-me')),
          Divider(height: AppSpace.lg, color: p.border),
        ],
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in shown)
                row(
                  m.id,
                  m.displayName,
                  l.shopNotifies,
                  key: Key('who-${m.id}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The list's bottom bar: how far along, the running total, and the one
/// action. A white surface with a hairline and a soft lift, so it reads as
/// part of the app and not as a button floating on the page.
class _SendBar extends StatelessWidget {
  const _SendBar({
    required this.list,
    required this.busy,
    required this.onSend,
  });

  final ShoppingList list;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = l.localeName == 'bn';
    final total = list.items.length;
    final done = list.boughtCount;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: p.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.md,
            AppSpace.gutter,
            AppSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    key: const Key('shop-progress'),
                    value: done / total,
                    minHeight: 4,
                    color: p.accent,
                    backgroundColor: p.surfaceMuted,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          money(context, list.total),
                          key: const Key('shop-total'),
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          total == 0
                              ? l.shopTotal
                              : l.shopProgress(
                                  Fmt.digits('$done', bangla: bn),
                                  Fmt.digits('$total', bangla: bn),
                                ),
                          style: text.bodySmall?.copyWith(color: p.inkTertiary),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 168),
                    child: AppButton(
                      key: const Key('shop-submit'),
                      label: l.shopSubmit,
                      icon: Icons.send_outlined,
                      loading: busy,
                      onPressed: onSend,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

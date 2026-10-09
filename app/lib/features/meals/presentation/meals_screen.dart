import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../export/presentation/export_actions.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart' show SectionTitle;
import '../../money/application/money_providers.dart'
    show firstOpenDateProvider;
import '../../money/presentation/money_sheets.dart';
import '../../recurring/application/recurring_providers.dart';
import '../../recurring/domain/recurring.dart';
import '../../today/application/day_grid.dart';
import '../application/meal_providers.dart';
import '../domain/meal.dart';
import 'meal_grid.dart';
import 'meal_widgets.dart';

/// মিল: the daily entry screen. Mess and manager, a month pill and a day
/// switcher, the member × meal stepper grid with column totals, the day's
/// total; then the month's per-member meals (SQL).
class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key, this.initialDate});

  /// Opens on this day (`/meals?date=YYYY-MM-DD`); default today.
  final DateTime? initialDate;

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  late DateTime _day = widget.initialDate ?? today();

  @override
  void didUpdateWidget(MealsScreen old) {
    super.didUpdateWidget(old);
    // The tab keeps its state, so a new deep link moves the day.
    final d = widget.initialDate;
    if (d != null && d != old.initialDate) _go(d);
  }

  /// Direction of the last day/month change: the date text slides with it.
  bool _forward = true;
  double _dragDx = 0;

  void _go(DateTime day) => setState(() {
    _forward = !day.isBefore(_day);
    _day = day;
  });

  void _shift(int days) =>
      _go(dayOnly(_day.add(Duration(days: days, hours: 2))));

  /// Planning ahead stops at tomorrow.
  bool get _canNext => !_day.isAfter(today());

  /// Previous/next calendar month: its first day, or today in this month.
  void _shiftMonth(int delta) {
    final now = today();
    final first = DateTime(_day.year, _day.month + delta);
    _go(first.year == now.year && first.month == now.month ? now : first);
  }

  /// Swipe on the grid: left = next day, right = previous day.
  void _onSwipeEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    if (dx.abs() < 64 && v.abs() < 700) return;
    final next = (dx.abs() >= 64 ? dx : v) < 0;
    if (next && !_canNext) return;
    HapticFeedback.selectionClick();
    _shift(next ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const Scaffold(body: LoadingView());

    final key = (messId: messId, day: _day);
    // A day inside a closed month is view-only: no steppers, no "+".
    final firstOpen = ref.watch(firstOpenDateProvider(messId)).value;
    final closed = firstOpen != null && _day.isBefore(firstOpen);
    final manager = ref.watch(amIManagerProvider);
    final edit = manager && !closed;
    final mess = ref.watch(currentMessProvider);
    final myId = plainMemberId(ref);
    final ownOff = closed ? null : ownOffId(ref);
    final membersAsync = ref.watch(membersProvider(messId));
    final typesAsync = ref.watch(mealTypesProvider(messId));
    final gridAsync = ref.watch(dayGridProvider(key));

    void retry() {
      ref.invalidate(membersProvider(messId));
      ref.invalidate(mealTypesProvider(messId));
      ref.invalidate(dayEntriesProvider(key));
      monthProviders(messId).forEach(ref.invalidate);
    }

    final error = [
      if (!membersAsync.hasValue) membersAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
      if (!gridAsync.hasValue) gridAsync.error,
    ].nonNulls.firstOrNull;

    final List<Widget> grid;
    var rows = const <Member>[];
    var types = const <MealType>[];
    if (error != null) {
      grid = [ErrorView(message: failureText(context, error), onRetry: retry)];
    } else if (!membersAsync.hasValue ||
        !typesAsync.hasValue ||
        !gridAsync.hasValue) {
      grid = [const LoadingView(rows: 5)];
    } else {
      final members = membersAsync.value!;
      (:rows, :types) = gridShape(
        members,
        typesAsync.value!,
        gridAsync.value!.values,
        _day,
      );
      final hasMembers = members.any((m) => m.status != MemberStatus.pending);
      grid = [
        if (!hasMembers)
          EmptyView(
            icon: Icons.group_outlined,
            message: l.todayNoMembers,
            actionLabel: manager ? l.membersAdd : null,
            onAction: () => context.push('/more/members'),
          )
        else if (rows.isEmpty)
          // The mess has members, just none present on this day.
          EmptyView(
            icon: Icons.event_busy_outlined,
            message: l.dashNobodyThatDay,
            actionLabel: _day == today() ? null : l.todayBackToToday,
            onAction: () => _go(today()),
          )
        else if (types.isEmpty)
          EmptyView(
            icon: Icons.restaurant_outlined,
            message: l.todayNoMealTypes,
            actionLabel: manager ? l.todayNoMealTypesAction : null,
            onAction: () => context.push('/more/meal-types'),
          )
        else ...[
          if (closed) const _ClosedDayNote(),
          if (edit)
            _BulkActions(
              dayKey: key,
              members: [
                for (final m in rows)
                  if (presentOn(m, _day)) m,
              ],
              types: [
                for (final t in types)
                  if (t.enabled) t,
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: AppCard.raised(
              padding: EdgeInsets.zero,
              child: MealStepperGrid(
                dayKey: key,
                rows: rows,
                types: types,
                editable: edit,
                ownOffId: ownOff,
              ),
            ),
          ),
          if (edit)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                0,
              ),
              child: Text(
                l.mealGridHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.palette.inkTertiary,
                ),
              ),
            ),
          _DayTotal(dayKey: key, types: types),
          if (!closed &&
              myId != null &&
              mess != null &&
              ref.featureOn('member_meal_off'))
            MealOffHint(mess: mess),
        ],
      ];
    }

    return Scaffold(
      floatingActionButton: edit && rows.isNotEmpty && types.isNotEmpty
          ? PressableScale(
              haptic: true,
              child: FloatingActionButton(
                tooltip: l.mealGridAdd,
                onPressed: () => showAddChooser(context, ref, key, rows, types),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            retry();
            await ref
                .read(dayEntriesProvider(key).future)
                .catchError((_) => const <MealEntry>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpace.xxxl * 2),
            children: [
              _Header(
                messId: messId,
                day: _day,
                forward: _forward,
                onShiftMonth: _shiftMonth,
              ),
              _DaySwitcher(
                day: _day,
                forward: _forward,
                canNext: _canNext,
                onShift: _shift,
                onToday: () => _go(today()),
              ),
              SyncLine(messId: messId),
              const SizedBox(height: AppSpace.sm),
              // Swipe the grid sideways to change the day.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) => _dragDx = 0,
                onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
                onHorizontalDragEnd: _onSwipeEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: grid,
                ),
              ),
              if (mess != null)
                _MonthSummary(
                  messId: messId,
                  start: periodStartFor(_day, mess.monthStartDay),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Above a closed month's grid: a lock and "view only".
class _ClosedDayNote extends StatelessWidget {
  const _ClosedDayNote();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.sm,
      ),
      child: Row(
        spacing: AppSpace.xs,
        children: [
          Icon(Icons.lock_outline, size: 16, color: p.inkTertiary),
          Expanded(
            child: Text(
              AppLocalizations.of(context).closeMonthDayLocked,
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

/// The "+" chooser (মিল and হোম FABs): AI, bazar, expense, deposit, guest,
/// meal off. Runs the picked action for [key]'s day.
Future<void> showAddChooser(
  BuildContext context,
  WidgetRef ref,
  MessDay key,
  List<Member> rows,
  List<MealType> types,
) async {
  final l = AppLocalizations.of(context);
  final config = ref.read(platformConfigProvider);
  final action = await pickTile<VoidCallback>(
    context,
    title: l.mealGridAddTitle,
    options: [
      if (config.aiMealDraft)
        (
          () => showMealDraftSheet(context, day: key.day),
          l.mealGridAi,
          Icons.auto_awesome_outlined,
        ),
      (
        () => showAddBazarSheet(context),
        l.todayActionBazar,
        Icons.shopping_basket_outlined,
      ),
      (
        () => showAddExpenseSheet(context),
        l.todayActionExpense,
        Icons.receipt_long_outlined,
      ),
      (
        () => showAddDepositSheet(context),
        l.todayActionDeposit,
        Icons.savings_outlined,
      ),
      if (config.feature('guest_meals'))
        (
          () => addGuest(context, ref, key, rows, types),
          l.todayActionGuest,
          Icons.person_add_alt_outlined,
        ),
      (
        () => markMealOff(context, ref, key, rows, types),
        l.todayActionMealOff,
        Icons.no_meals_outlined,
      ),
    ],
  );
  if (context.mounted) action?.call();
}

/// [text] that slides sideways when it changes (shared axis X): the new value
/// comes in from the side we are moving towards, the old one leaves the
/// other way. An instant swap with "Remove animations".
class _SlideText extends StatelessWidget {
  const _SlideText(
    this.text, {
    required this.forward,
    this.style,
    this.textAlign,
  });

  final String text;
  final bool forward;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(text);
    // Scales down rather than cutting off at 360 dp / 1.3× text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.page),
          switchInCurve: AppMotion.arrive,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, a) {
            final dir =
                (child.key == current ? 1.0 : -1.0) * (forward ? 1 : -1);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(0.35 * dir, 0),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            );
          },
          child: Text(
            text,
            key: current,
            textAlign: textAlign,
            maxLines: 1,
            style: style,
          ),
        ),
      ),
    );
  }
}

/// Mess name, its manager, and the month pill.
class _Header extends ConsumerWidget {
  const _Header({
    required this.messId,
    required this.day,
    required this.forward,
    required this.onShiftMonth,
  });

  final String messId;
  final DateTime day;
  final bool forward;
  final ValueChanged<int> onShiftMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final mess = ref.watch(currentMessProvider);
    final manager = (ref.watch(membersProvider(messId)).value ?? const [])
        .where((m) => m.isActiveManager)
        .firstOrNull;
    final long = Fmt.dateLong(
      day,
      locale: Localizations.localeOf(context).languageCode,
      banglaDigits: bnDigits(context),
    );
    final month = long.substring(long.indexOf(' ') + 1);
    final now = today();
    final isThisMonth = day.year == now.year && day.month == now.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        0,
      ),
      // Name and pill share a line when they fit; at large text the pill
      // drops below instead of squeezing the name.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpace.md,
        runSpacing: AppSpace.md,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                mess?.name ?? l.mealsTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
              if (manager != null)
                Text(
                  l.mealGridManager(manager.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.overline(context),
                ),
            ],
          ),
          ConstrainedBox(
            // Leaves the mess name room; a long month scales down instead.
            constraints: const BoxConstraints(maxWidth: 232),
            child: PressableScale(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppSize.touch),
                  boxShadow: AppElevation.button(p),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l.mealGridPrevMonth,
                      onPressed: () => onShiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Flexible(
                      child: _SlideText(
                        month,
                        forward: forward,
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.mealGridNextMonth,
                      onPressed: isThisMonth ? null : () => onShiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ‹  date (আজ)  ›; tomorrow at most, for planning ahead.
class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.day,
    required this.forward,
    required this.canNext,
    required this.onShift,
    required this.onToday,
  });

  final DateTime day;
  final bool forward;
  final bool canNext;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isToday = day == today();
    final pill = BorderRadius.circular(AppSize.touch);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.xs,
      ),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          _RoundNav(
            icon: Icons.chevron_left,
            tooltip: l.todayPrevDay,
            onPressed: () => onShift(-1),
          ),
          Expanded(
            child: Column(
              spacing: AppSpace.xs,
              children: [
                _SlideText(
                  Fmt.dateLong(
                    day,
                    locale: Localizations.localeOf(context).languageCode,
                    banglaDigits: bnDigits(context),
                  ),
                  forward: forward,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.chip),
                  child: isToday
                      ? DecoratedBox(
                          key: const ValueKey('today'),
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            border: Border.all(color: p.accent),
                            borderRadius: pill,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: AppSpace.xs + 2,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.accent,
                                  ),
                                ),
                                Text(
                                  l.todayIsToday,
                                  style: text.labelMedium?.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : PressableScale(
                          key: const ValueKey('back'),
                          child: Material(
                            color: p.surfaceMuted,
                            borderRadius: pill,
                            child: InkWell(
                              borderRadius: pill,
                              onTap: onToday,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.md,
                                  vertical: 2,
                                ),
                                child: Text(
                                  l.todayBackToToday,
                                  style: text.labelMedium?.copyWith(
                                    color: p.inkSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          _RoundNav(
            icon: Icons.chevron_right,
            tooltip: l.todayNextDay,
            onPressed: canNext ? () => onShift(1) : null,
          ),
        ],
      ),
    );
  }
}

/// A large raised round chevron (52 dp) that scales and clicks on press.
class _RoundNav extends StatelessWidget {
  const _RoundNav({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = onPressed != null;
    return PressableScale(
      enabled: on,
      haptic: on,
      scale: 0.9,
      child: AnimatedOpacity(
        opacity: on ? 1 : 0.38,
        duration: AppMotion.of(context, AppMotion.fast),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.surfaceRaised,
            boxShadow: on ? AppElevation.button(p) : null,
            border: on ? null : Border.all(color: p.border),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            iconSize: 28,
            constraints: const BoxConstraints.tightFor(width: 52, height: 52),
            icon: Icon(icon, color: p.ink),
          ),
        ),
      ),
    );
  }
}

/// "সবাই ১" and "গতকালের মতো", each one batched write, and the cook share
/// (managers).
class _BulkActions extends ConsumerStatefulWidget {
  const _BulkActions({
    required this.dayKey,
    required this.members,
    required this.types,
  });

  final MessDay dayKey;

  /// Present members and enabled types only.
  final List<Member> members;
  final List<MealType> types;

  @override
  ConsumerState<_BulkActions> createState() => _BulkActionsState();
}

class _BulkActionsState extends ConsumerState<_BulkActions> {
  String? _busy;

  Future<void> _run(String which) async {
    final l = AppLocalizations.of(context);
    final key = widget.dayKey;
    setState(() => _busy = which);
    try {
      final Map<String, MealEntry>? yesterday = which == 'yesterday'
          ? await ref.read(
              dayGridProvider((
                messId: key.messId,
                day: dayOnly(key.day.subtract(const Duration(hours: 22))),
              )).future,
            )
          : null;
      // Offline (or failing) defaults fall back to 1, like a mess with none.
      final defaults = yesterday == null
          ? const <MealDefaultKey, double>{}
          : await ref
                .read(mealDefaultsProvider(key.messId).future)
                .catchError((Object _) => <MealDefaultKey, double>{});
      final now = ref.read(dayGridProvider(key)).value;
      final changes = [
        for (final m in widget.members)
          for (final t in widget.types)
            ?_change(entryOrZero(now, key, m.id, t.id), yesterday, defaults),
      ];
      if (changes.isEmpty) {
        if (mounted) {
          AppSnack.show(
            context,
            l.mealGridNothingToChange,
            icon: Icons.info_outline,
          );
        }
        return;
      }
      markBulkApply();
      await ref.read(dayGridProvider(key).notifier).putAll(changes);
    } catch (e) {
      if (mounted) snackFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// The new value of [e], or null when it would not change. "Like
  /// yesterday" with no row yesterday uses the member's default, else 1
  /// (PRODUCT_RULES §1).
  MealEntry? _change(
    MealEntry e,
    Map<String, MealEntry>? yesterday,
    Map<MealDefaultKey, double> defaults,
  ) {
    final y = yesterday?[cellKey(e.memberId, e.mealTypeId)];
    final next = yesterday == null
        ? e.copyWith(count: 1, isOff: false)
        : y == null
        ? e.copyWith(
            count:
                defaults[(memberId: e.memberId, mealTypeId: e.mealTypeId)] ?? 1,
            guestCount: 0,
            isOff: false,
          )
        : e.copyWith(count: y.count, guestCount: y.guestCount, isOff: y.isOff);
    final same =
        next.count == e.count &&
        next.guestCount == e.guestCount &&
        next.isOff == e.isOff;
    return same ? null : next;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget action(String which, String label, IconData icon) => _BulkChip(
      label: label,
      icon: icon,
      loading: _busy == which,
      onPressed: _busy == null ? () => _run(which) : null,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.md,
      ),
      // Wraps rather than truncating at 360 dp / 1.3× text.
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          action('one', l.mealGridAllOne, Icons.done_all),
          action('yesterday', l.mealGridLikeYesterday, Icons.history),
          CookShareButton(messId: widget.dayKey.messId),
        ],
      ),
    );
  }
}

/// A raised pressable chip (48 dp): icon + label; a spinner while running.
class _BulkChip extends StatelessWidget {
  const _BulkChip({
    required this.label,
    required this.icon,
    required this.loading,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pill = BorderRadius.circular(AppSize.touch);
    final on = onPressed != null;
    return PressableScale(
      enabled: on,
      haptic: on,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: pill,
          boxShadow: AppElevation.button(p),
        ),
        child: Material(
          color: p.surfaceRaised,
          borderRadius: pill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.touch),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.md,
                  AppSpace.xs,
                  AppSpace.lg,
                  AppSpace.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.sm,
                  children: [
                    SizedBox.square(
                      dimension: AppSize.spinner,
                      child: loading
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.ink,
                            )
                          : Icon(icon, size: AppSize.spinner, color: p.ink),
                    ),
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: on || loading ? p.ink : p.inkTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The statement: the day's headcount, rolling, with its proof per meal type.
class _DayTotal extends ConsumerWidget {
  const _DayTotal({required this.dayKey, required this.types});

  final MessDay dayKey;
  final List<MealType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final entries =
        ref.watch(dayGridProvider(dayKey)).value?.values ?? const [];
    final total = dayPeople(entries, types);
    final proof = [
      for (final t in types)
        '${t.name} ${Fmt.meals(dayPeople(entries, [t]), banglaDigits: bn)}',
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        0,
      ),
      child: AppCard.ink(
        child: Builder(
          // Reads the statement theme the card installs.
          builder: (context) {
            final text = Theme.of(context).textTheme;
            final p = context.palette;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(l.mealGridDayTotal, style: AppType.overline(context)),
                RollingNumber.meals(
                  total,
                  key: const Key('day-total'),
                  banglaDigits: bn,
                  style: text.displayLarge,
                ),
                Text(
                  proof,
                  style: text.bodyMedium?.copyWith(
                    color: p.inkSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The selected month: total meals and rate (SQL), then meals per member.
class _MonthSummary extends ConsumerWidget {
  const _MonthSummary({required this.messId, required this.start});

  final String messId;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final key = (messId: messId, start: start);
    final bn = bnDigits(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final current = ref.watch(currentPeriodProvider(messId)).value;
    final summary = ref.watch(periodSummaryProvider(key));
    final title = SectionTitle(l.mealsByMember);
    if (summary.hasError && !summary.hasValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          ErrorView(
            message: failureText(context, summary.error!),
            onRetry: () => ref.invalidate(periodSummaryProvider(key)),
          ),
        ],
      );
    }
    final value = summary.value;
    if (value == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const LoadingView(rows: 3)],
      );
    }
    final (period, t, balances) = value;
    final isCurrent = current != null && current.start == period.start;
    final guests = isCurrent
        ? ref.watch(guestMealsProvider(messId)).value ?? const {}
        : const <String, double>{};
    final rows = balances.where((b) => b.meals > 0).toList()
      ..sort((a, b) => b.meals.compareTo(a.meals));
    final locale = Localizations.localeOf(context).languageCode;
    String date(DateTime d) =>
        Fmt.dateLong(d, locale: locale, banglaDigits: bn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.lg,
            children: [
              Expanded(
                child: Figure(
                  label: l.mealsTotalLabel,
                  value: Fmt.meals(t.totalMeals, banglaDigits: bn),
                  proof: l.mealsPeriod(
                    date(period.start),
                    // The period end is exclusive.
                    date(period.end.subtract(const Duration(hours: 12))),
                  ),
                  initiallyExpanded: true,
                ),
              ),
              Expanded(
                child: t.unallocatedFood
                    ? Text(
                        l.todayRateUnallocated(
                          Fmt.money(t.foodTotal, banglaDigits: bn),
                        ),
                        style: text.bodyMedium?.copyWith(color: p.warning),
                      )
                    : Figure(
                        label: l.todayRateLabel,
                        value: Fmt.money(t.mealRate, banglaDigits: bn),
                        proof: t.fixedRate
                            ? l.rateFixed
                            : l.todayRateProof(
                                Fmt.money(t.foodTotal, banglaDigits: bn),
                                Fmt.meals(t.totalMeals, banglaDigits: bn),
                              ),
                        initiallyExpanded: true,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (rows.isEmpty)
          EmptyView(icon: Icons.restaurant_outlined, message: l.mealsEmpty)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: AppCard.raised(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: StaggeredList(
                child: Column(
                  children: StaggeredList.wrap([
                    for (final (i, b) in rows.indexed)
                      Column(
                        children: [
                          if (i > 0)
                            const Divider(
                              height: 1,
                              indent: AppSpace.gutter + 36 + AppSpace.md,
                            ),
                          ListTile(
                            minTileHeight: AppSize.touch + AppSpace.md,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.gutter,
                            ),
                            horizontalTitleGap: AppSpace.md,
                            leading: InitialsAvatar(b.displayName, size: 36),
                            title: Text(b.displayName, style: text.titleSmall),
                            subtitle: (guests[b.memberId] ?? 0) > 0
                                ? Text(
                                    l.mealsGuestNote(
                                      Fmt.meals(
                                        guests[b.memberId]!,
                                        banglaDigits: bn,
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: AppSpace.xs,
                              children: [
                                Text(
                                  Fmt.meals(b.meals, banglaDigits: bn),
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: AppSize.spinner,
                                  color: p.inkTertiary,
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MemberMealsScreen(
                                  messId: messId,
                                  memberId: b.memberId,
                                  name: b.displayName,
                                  meals: b.meals,
                                  period: period,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One member's period, day by day, newest first. Read-only.
class MemberMealsScreen extends ConsumerWidget {
  const MemberMealsScreen({
    super.key,
    required this.messId,
    required this.memberId,
    required this.name,
    required this.meals,
    required this.period,
  });

  final String messId;
  final String memberId;
  final String name;

  /// Billable, from SQL `member_balances`.
  final double meals;
  final MonthPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = (
      messId: messId,
      from: period.start,
      to: period.end,
      memberId: memberId,
    );
    final entriesAsync = ref.watch(rangeEntriesProvider(range));
    final typesAsync = ref.watch(mealTypesProvider(messId));

    final error = [
      if (!entriesAsync.hasValue) entriesAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
    ].nonNulls.firstOrNull;

    final Widget body;
    if (error != null) {
      body = ErrorView(
        message: failureText(context, error),
        onRetry: () {
          ref.invalidate(rangeEntriesProvider(range));
          ref.invalidate(mealTypesProvider(messId));
        },
      );
    } else if (!entriesAsync.hasValue || !typesAsync.hasValue) {
      body = const LoadingView(rows: 6);
    } else {
      body = _DayList(
        name: name,
        meals: meals,
        entries: entriesAsync.value!,
        types: typesAsync.value!,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: body,
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.name,
    required this.meals,
    required this.entries,
    required this.types,
  });

  final String name;
  final double meals;
  final List<MealEntry> entries;
  final List<MealType> types;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final locale = Localizations.localeOf(context).languageCode;
    if (entries.isEmpty) {
      return EmptyView(
        icon: Icons.restaurant_outlined,
        message: l.mealsMemberEmpty(name),
      );
    }
    final byDay = <DateTime, Map<String, MealEntry>>{};
    for (final e in entries) {
      (byDay[dayOnly(e.date)] ??= {})[e.mealTypeId] = e;
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = types
        .where((t) => t.enabled || entries.any((e) => e.mealTypeId == t.id))
        .toList();
    final now = today();
    return StaggeredList(
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        itemCount: days.length + 1,
        separatorBuilder: (_, i) => i == 0
            ? const SizedBox.shrink()
            : const Divider(height: 1, indent: AppSpace.gutter),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.lg,
                AppSpace.gutter,
                AppSpace.md,
              ),
              child: Row(
                spacing: AppSpace.xs,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      spacing: AppSpace.md,
                      children: [
                        InitialsAvatar(name, size: 40),
                        Expanded(
                          child: Text(
                            l.mealsMemberTotal(
                              Fmt.meals(meals, banglaDigits: bn),
                            ),
                            style: text.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final t in shown)
                    SizedBox(
                      width: AppSize.mealCellWidth,
                      child: Text(
                        t.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.overline(context),
                      ),
                    ),
                ],
              ),
            );
          }
          final d = days[i - 1];
          final row = byDay[d]!;
          final total = row.values.fold(0.0, (s, e) => s + e.people);
          final date = Fmt.dateLong(d, locale: locale, banglaDigits: bn);
          final item = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.gutter,
              vertical: AppSpace.xs,
            ),
            child: Row(
              spacing: AppSpace.xs,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: text.titleSmall),
                      Text(
                        Fmt.meals(total, banglaDigits: bn),
                        style: text.labelSmall?.copyWith(
                          color: p.inkTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final t in shown)
                  MealCell(
                    label: '$date ${t.name}',
                    count: row[t.id]?.count ?? 0,
                    guests: row[t.id]?.guestCount ?? 0,
                    off: row[t.id]?.isOff ?? false,
                    today: d == now,
                    banglaDigits: bn,
                  ),
              ],
            ),
          );
          return i - 1 < AppMotion.staggerMax
              ? Stagger(index: i - 1, child: item)
              : item;
        },
      ),
    );
  }
}

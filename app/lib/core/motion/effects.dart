import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Shrinks its child to [scale] while a finger is down. Listens to raw
/// pointers, so the child's own InkWell / button still gets the tap.
/// A drag past touch slop releases (scrolling a list never leaves a card
/// pressed). [haptic] adds a selection click on press.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.96,
    this.haptic = false,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  Offset _origin = Offset.zero;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !AppMotion.reduced(context);
    return Listener(
      onPointerDown: widget.enabled
          ? (e) {
              _origin = e.position;
              if (widget.haptic) HapticFeedback.selectionClick();
              if (on) _set(true);
            }
          : null,
      onPointerMove: (e) {
        if ((e.position - _origin).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: on && _down ? widget.scale : 1,
        duration: _down ? AppMotion.fast : AppMotion.base,
        curve: _down ? AppMotion.state : AppMotion.arrive,
        child: widget.child,
      ),
    );
  }
}

/// Pops its child 1.0 → [peak] → 1.0 over 120 ms whenever [value] changes,
/// e.g. a stepper's meal count.
class PopOnChange extends StatefulWidget {
  const PopOnChange({
    super.key,
    required this.value,
    required this.child,
    this.peak = 1.12,
  });

  final Object? value;
  final Widget child;
  final double peak;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.pop);
  late final _scale = _c.drive(
    TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: widget.peak), weight: 1),
      TweenSequenceItem(tween: Tween(begin: widget.peak, end: 1.0), weight: 1),
    ]),
  );

  @override
  void didUpdateWidget(PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !AppMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Scope for a list's entrance. Rows wrapped in [Stagger] fade and rise in
/// one after another, but only during the list's first build: rows that
/// mount later (scrolled into view, pulled in by a refresh) appear as-is.
///
/// ```dart
/// StaggeredList(child: ListView(children: StaggeredList.wrap(rows)))
/// ```
class StaggeredList extends StatefulWidget {
  const StaggeredList({super.key, required this.child});

  final Widget child;

  /// Wraps the first [AppMotion.staggerMax] children in [Stagger].
  static List<Widget> wrap(List<Widget> children) => [
    for (var i = 0; i < children.length; i++)
      i < AppMotion.staggerMax
          ? Stagger(index: i, child: children[i])
          : children[i],
  ];

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList> {
  // Frame clock, not wall clock: it follows fake time in tests.
  final _born = SchedulerBinding.instance.currentSystemFrameTimeStamp;

  @override
  Widget build(BuildContext context) =>
      _StaggerScope(born: _born, child: widget.child);
}

class _StaggerScope extends InheritedWidget {
  const _StaggerScope({required this.born, required super.child});

  final Duration born;

  /// The entrance window: long enough for the first frame's rows to mount.
  bool get fresh =>
      SchedulerBinding.instance.currentSystemFrameTimeStamp - born <
      const Duration(milliseconds: 500);

  @override
  bool updateShouldNotify(_StaggerScope old) => false;
}

/// One row of a [StaggeredList]: waits `index × 30 ms`, then fades in while
/// rising 8 dp. Index ≥ 8 (or outside a fresh scope) shows immediately.
class Stagger extends StatefulWidget {
  const Stagger({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final scope = context
        .getInheritedWidgetOfExactType<_StaggerScope>(); // no rebuild dep
    final play =
        widget.index < AppMotion.staggerMax &&
        (scope?.fresh ?? true) &&
        !AppMotion.reduced(context);
    if (!play) return;
    final delay = AppMotion.staggerStep * widget.index;
    _c = AnimationController(vsync: this, duration: delay + AppMotion.base)
      ..forward();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    final delay = AppMotion.staggerStep * widget.index;
    final t = c.drive(
      CurveTween(
        curve: Interval(
          delay.inMicroseconds / c.duration!.inMicroseconds,
          1,
          curve: AppMotion.arrive,
        ),
      ),
    );
    return FadeTransition(
      opacity: t,
      child: AnimatedBuilder(
        animation: t,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, AppMotion.rise * (1 - t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// The brand moment for "settled" and "closed": an outlined stamp, rotated
/// −8°, that lands (scale 1.4 → 1.0 with a slight overshoot, 260 ms) and
/// thumps (medium haptic). e.g. `StampMark('পরিশোধিত')`, `StampMark('বন্ধ')`.
///
/// Lands once, on first mount, when [animate] is true; otherwise (and with
/// "Remove animations" on) it is simply there.
class StampMark extends StatefulWidget {
  const StampMark(
    this.text, {
    super.key,
    this.accent = false,
    this.animate = true,
  });

  final String text;

  /// Turmeric instead of ink: for "live" stamps (e.g. today's settle).
  final bool accent;
  final bool animate;

  static const angle = -8 * 3.1415926535 / 180;

  @override
  State<StampMark> createState() => _StampMarkState();
}

class _StampMarkState extends State<StampMark>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.stamp,
    value: 1,
  );
  late final _scale = _c.drive(
    Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
  );
  late final _fade = _c.drive(CurveTween(curve: const Interval(0, 0.4)));

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppMotion.reduced(context)) return;
      _c.forward(from: 0).then((_) => HapticFeedback.mediumImpact());
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.accent ? p.accent : p.ink;
    final stamp = Transform.rotate(
      angle: StampMark.angle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          widget.text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color, height: 1.2),
        ),
      ),
    );
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(scale: _scale, child: stamp),
        ),
      ),
    );
  }
}

/// The sync dot. Breathes (opacity .35 ↔ 1, 900 ms) only while [active];
/// the one continuous animation in the app. Static with "Remove animations".
class AnimatedSyncDot extends StatefulWidget {
  const AnimatedSyncDot({super.key, required this.color, this.active = true});

  final Color color;
  final bool active;

  @override
  State<AnimatedSyncDot> createState() => _AnimatedSyncDotState();
}

class _AnimatedSyncDotState extends State<AnimatedSyncDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
    value: 1,
  );
  late final _opacity = _c.drive(Tween(begin: 0.35, end: 1.0));

  void _sync() {
    if (widget.active && !AppMotion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AnimatedSyncDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(
      opacity: _opacity,
      child: Container(
        width: AppSize.dot,
        height: AppSize.dot,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    ),
  );
}

/// Calm skeleton pulse: opacity .55 ↔ 1 over 1200 ms on the whole subtree
/// (one layer, however many blocks). Stops after ~20 s: a load that slow is
/// an error state, and a finite pulse lets `pumpAndSettle` settle.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.skeleton,
    value: 1,
  );
  late final _opacity = _c.drive(
    Tween(begin: 0.55, end: 1.0).chain(CurveTween(curve: AppMotion.state)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context) || _c.isAnimating) return;
    // ponytail: finite repeat (8 round trips ≈ 19 s), loop forever only if
    // real loads ever outlast it.
    _c.repeat(reverse: true, count: 16);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(opacity: _opacity, child: widget.child),
  );
}

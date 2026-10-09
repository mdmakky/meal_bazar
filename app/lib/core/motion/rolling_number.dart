import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

/// The signature: a number that rolls like an odometer when it changes.
///
/// The formatted text is diffed character by character, right-aligned so
/// units stay in their columns. Every changed digit slides in its own clipped
/// slot: up when the value grows, down when it shrinks, the rightmost digit
/// first. Signs, ৳, separators and Bangla digits (০-৯) roll with the rest.
///
/// At rest it is one plain [Text] (kerning intact, `find.text` works); the
/// per-character row exists only while rolling. Transform + clip only, inside
/// a [RepaintBoundary]. With "Remove animations" on it simply swaps the text.
class RollingNumber extends StatefulWidget {
  /// A plain number, trimmed to at most [decimals] fraction digits:
  /// `RollingNumber(20.5, banglaDigits: true)` → ২০.৫.
  const RollingNumber(
    this.value, {
    super.key,
    this.decimals = 2,
    this.prefix = '',
    this.banglaDigits = false,
    this.style,
    this.color,
  }) : signed = false,
       _money = false,
       _meals = false;

  /// ৳ with South Asian grouping via `Fmt.money` (-৳1,23,456.50).
  /// [signed] colours < 0 `due` and > 0 `advance`.
  const RollingNumber.money(
    this.value, {
    super.key,
    this.signed = false,
    this.banglaDigits = false,
    this.style,
    this.color,
  }) : decimals = 2,
       prefix = '',
       _money = true,
       _meals = false;

  /// A meal count via `Fmt.meals` (১৬¼, ১৯½): the one meal format.
  const RollingNumber.meals(
    this.value, {
    super.key,
    this.banglaDigits = false,
    this.style,
    this.color,
  }) : decimals = 2,
       prefix = '',
       signed = false,
       _money = false,
       _meals = true;

  final num value;
  final int decimals;
  final String prefix;
  final bool banglaDigits;
  final bool signed;
  final TextStyle? style;

  /// Overrides the sign colour. Animates when it changes.
  final Color? color;
  final bool _money;
  final bool _meals;

  String get text {
    if (_money) return Fmt.money(value, banglaDigits: banglaDigits);
    if (_meals) return Fmt.meals(value, banglaDigits: banglaDigits);
    var s = value.toStringAsFixed(decimals);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    if (s == '-0') s = '0';
    return Fmt.digits('$prefix$s', bangla: banglaDigits);
  }

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _from = null);
      });
  }

  /// Text we roll away from; null at rest.
  String? _from;
  bool _up = true;

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    final from = old.text, to = widget.text;
    if (from == to || AppMotion.reduced(context)) {
      _from = null;
      _c.stop();
      return;
    }
    _from = from;
    _up = widget.value >= old.value;
    final slots = to.length > from.length ? to.length : from.length;
    _c.duration =
        AppMotion.slow + AppMotion.staggerStep * (slots.clamp(1, 6) - 1);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color? _color(AppPalette p) {
    if (widget.color != null) return widget.color;
    if (!widget.signed || widget.value == 0) return null;
    return widget.value < 0 ? p.due : p.advance;
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.text;
    final base = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      // Latin digits may be set tight; Bangla digits keep their own spacing.
      letterSpacing: widget.banglaDigits ? 0 : null,
    );
    final target = _color(context.palette) ?? base.color;
    final from = _from;

    return Semantics(
      label: to,
      excludeSemantics: true,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: target),
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.state,
        builder: (context, color, _) {
          final style = base.copyWith(color: color);
          if (from == null) return Text(to, style: style, maxLines: 1);
          return RepaintBoundary(child: _rolling(from, to, style));
        },
      ),
    );
  }

  Widget _rolling(String from, String to, TextStyle style) {
    final n = to.length > from.length ? to.length : from.length;
    final a = from.padLeft(n, '\u0000'), b = to.padLeft(n, '\u0000');
    final total = _c.duration!.inMicroseconds;
    final step = AppMotion.staggerStep.inMicroseconds;
    final slots = <Widget>[];
    for (var i = 0; i < n; i++) {
      final oldCh = a[i] == '\u0000' ? '' : a[i];
      final newCh = b[i] == '\u0000' ? '' : b[i];
      if (oldCh == newCh) {
        slots.add(Text(newCh, style: style));
        continue;
      }
      // Rightmost slot starts first; each step left starts 30 ms later.
      final fromRight = (n - 1 - i).clamp(0, 5);
      final start = fromRight * step / total;
      final t = _c.drive(
        CurveTween(curve: Interval(start, 1, curve: AppMotion.arrive)),
      );
      slots.add(_Slot(t: t, oldCh: oldCh, newCh: newCh, up: _up, style: style));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: slots);
  }
}

/// One clipped character cell: the old glyph leaves, the new one arrives.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.t,
    required this.oldCh,
    required this.newCh,
    required this.up,
    required this.style,
  });

  final Animation<double> t;
  final String oldCh, newCh;
  final bool up;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final sign = up ? -1.0 : 1.0;
    return ClipRect(
      child: AnimatedBuilder(
        animation: t,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            FractionalTranslation(
              translation: Offset(0, sign * t.value),
              child: Text(oldCh, style: style),
            ),
            FractionalTranslation(
              translation: Offset(0, -sign * (1 - t.value)),
              child: Text(newCh, style: style),
            ),
          ],
        ),
      ),
    );
  }
}

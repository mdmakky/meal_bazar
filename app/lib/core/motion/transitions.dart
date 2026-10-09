import 'package:flutter/material.dart';

import 'tokens.dart';

/// Shared-axis (X) for pushed routes, 280 ms: the new page slides in 30 dp
/// from the trailing edge and fades in over the old one, which drifts 30 dp
/// the other way. The incoming page is opaque, so its fade is a cross-fade
/// with no gap to the window background. Installed for Android in the theme.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  static const shift = 30.0;

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final dir = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final enter = animation.drive(CurveTween(curve: AppMotion.arrive));
    final behind = secondaryAnimation.drive(
      CurveTween(curve: AppMotion.arrive),
    );
    return FadeTransition(
      opacity: animation.drive(
        CurveTween(curve: const Interval(0, 0.7, curve: AppMotion.state)),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(dir * shift * ((1 - enter.value) - behind.value), 0),
          child: child,
        ),
      ),
    );
  }
}

/// Fade-through between the shell's tabs (210 ms): the old tab fades out in
/// the first 35%, the new one fades in and settles from 92% scale. Branch
/// navigators stay mounted (state is kept, inactive tickers are paused),
/// exactly like `StatefulShellRoute.indexedStack`.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: AppMotion.tab, value: 1)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) setState(() => _from = null);
        });
  late final _in = _c.drive(
    CurveTween(curve: const Interval(0.35, 1, curve: AppMotion.arrive)),
  );
  late final _scale = _in.drive(Tween(begin: 0.92, end: 1.0));
  late final _out = _c.drive(
    Tween(
      begin: 1.0,
      end: 0.0,
    ).chain(CurveTween(curve: const Interval(0, 0.35, curve: AppMotion.exit))),
  );
  int? _from;

  @override
  void didUpdateWidget(FadeThroughBranches old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    if (AppMotion.reduced(context)) {
      _from = null;
      _c.value = 1;
      return;
    }
    _from = old.index;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _branch(i, widget.children[i]),
      ],
    );
  }

  Widget _branch(int i, Widget child) {
    final active = i == widget.index;
    final leaving = i == _from;
    // Same widget shape in every state so branch navigators never remount.
    return Offstage(
      offstage: !active && !leaving,
      child: TickerMode(
        enabled: active,
        child: IgnorePointer(
          ignoring: !active,
          child: FadeTransition(
            opacity: active ? _in : (leaving ? _out : kAlwaysCompleteAnimation),
            child: ScaleTransition(
              scale: active ? _scale : kAlwaysCompleteAnimation,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

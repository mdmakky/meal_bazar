import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../l10n/gen/app_localizations.dart';
import '../motion/tokens.dart';

/// The cold start as one continuous motion. The native splash is only the
/// background colour, so the first thing anyone sees is this: the dark tile
/// settles in, the bowl is served into it, steam rises, the name arrives,
/// and the whole mark lifts away into the app, which has been loading
/// underneath the whole time.
///
/// It leaves once [isReady] holds (checked whenever [ready] notifies) and the
/// entrance has played, or after [maxWait] whatever happens. With "Remove
/// animations" on, it cuts straight to the app as soon as it is ready.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({
    super.key,
    required this.ready,
    required this.isReady,
    required this.child,
    this.maxWait = const Duration(seconds: 5),
  });

  /// Notifies when [isReady] may have changed.
  final Listenable ready;

  /// True once the first real screen is routed (not the boot splash).
  final bool Function() isReady;
  final Widget child;
  final Duration maxWait;

  static const logoSize = 128.0;

  /// Same as the native splash (flutter_native_splash.yaml), so the handover
  /// is invisible.
  static const background = Color(0xFFFAFAF9);

  static const layers = [
    'assets/icon/intro_tile.png',
    'assets/icon/intro_glyph.png',
    'assets/icon/intro_steam.png',
  ];

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Timer? _timeout;
  bool _started = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    widget.ready.addListener(_maybeLeave);
    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed) _maybeLeave();
    });
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _gone = true);
    });
    _timeout = Timer(widget.maxWait, _leave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Decode the layers first so no piece pops in late; the native splash
    // (same colour) covers the wait.
    Future.wait([
      for (final a in LaunchIntro.layers) precacheImage(AssetImage(a), context),
    ]).whenComplete(() async {
      await WidgetsBinding.instance.endOfFrame;
      FlutterNativeSplash.remove();
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _intro.value = 1;
        _maybeLeave();
      } else {
        _intro.forward();
      }
    });
  }

  void _maybeLeave() {
    if (_intro.isCompleted && widget.isReady()) _leave();
  }

  void _leave() {
    if (_exit.isAnimating || _exit.isCompleted || !mounted) return;
    _timeout?.cancel();
    widget.ready.removeListener(_maybeLeave);
    FlutterNativeSplash.remove();
    if (AppMotion.reduced(context)) {
      setState(() => _gone = true);
    } else {
      _exit.forward();
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    widget.ready.removeListener(_maybeLeave);
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // The app underneath may not be ready for touch yet.
        AbsorbPointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _exit]),
            builder: (context, _) {
              final out = AppMotion.exit.transform(_exit.value);
              return Opacity(
                opacity: 1 - out,
                child: ColoredBox(
                  color: LaunchIntro.background,
                  child: Transform.scale(
                    // Lifts toward the viewer as it clears.
                    scale: 1 + 0.06 * out,
                    child: _Mark(t: _intro.value),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The mark, centred; [t] is the entrance progress (0–1).
class _Mark extends StatelessWidget {
  const _Mark({required this.t});

  final double t;

  static double _at(double t, double begin, double end, [Curve? curve]) =>
      Interval(begin, end, curve: curve ?? AppMotion.arrive).transform(t);

  @override
  Widget build(BuildContext context) {
    const size = LaunchIntro.logoSize;
    // 1. The tile settles in.
    final tile = _at(t, 0, 0.42);
    final tileFade = _at(t, 0, 0.22, Curves.easeOut);
    // 2. The bowl and wallet are served into it.
    final glyph = _at(t, 0.16, 0.52);
    // 3. Steam rises, wisp by wisp (below). 4. The name arrives.
    final name = _at(t, 0.50, 0.92);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: tileFade,
            child: Transform.scale(
              scale: 0.78 + 0.22 * tile,
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(LaunchIntro.layers[0]),
                    Opacity(
                      opacity: glyph,
                      child: Transform.translate(
                        offset: Offset(0, 6 * (1 - glyph)),
                        child: Image.asset(LaunchIntro.layers[1]),
                      ),
                    ),
                    for (final (i, (from, to)) in const [
                      (0.0, 0.403),
                      (0.403, 0.492),
                      (0.492, 1.0),
                    ].indexed)
                      _Wisp(
                        p: _at(t, 0.36 + i * 0.07, 0.72 + i * 0.07),
                        from: from,
                        to: to,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Opacity(
            opacity: name,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - name)),
              child: Text(
                AppLocalizations.of(context).appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF141416),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One steam wisp rising out of the bowl into place ([p]: 0–1).
class _Wisp extends StatelessWidget {
  const _Wisp({required this.p, required this.from, required this.to});

  final double p;
  final double from;
  final double to;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: _Columns(from, to),
      child: Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - p)),
          child: Image.asset(LaunchIntro.layers[2]),
        ),
      ),
    );
  }
}

/// A vertical slice of the steam layer, so each wisp moves on its own.
class _Columns extends CustomClipper<Rect> {
  const _Columns(this.from, this.to);

  final double from;
  final double to;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * from, 0, size.width * to, size.height);

  @override
  bool shouldReclip(_Columns old) => old.from != from || old.to != to;
}

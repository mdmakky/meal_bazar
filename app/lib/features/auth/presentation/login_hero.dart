import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// The dark top of the login page: the logo with steam rising off the bowl,
/// and Bangla numerals (১ ½ ২ ৳ …) drifting up like steam behind it, the way
/// a mess's accounts feel. Plays an entrance once, then loops softly. With
/// "Remove animations" it is a still picture.
class LoginHero extends StatefulWidget {
  const LoginHero({super.key, required this.name, required this.tagline});

  final String name;
  final String tagline;

  static const _gold = Color(0xFFF6E3B3);

  @override
  State<LoginHero> createState() => _LoginHeroState();
}

/// char, x (0–1), size, rise seconds, start offset seconds, tilt degrees.
const _numerals = <(String, double, double, double, double, double)>[
  ('১', .08, 22, 7.5, 0.0, -14),
  ('৳', .22, 17, 6.2, 1.6, 10),
  ('½', .36, 24, 8.8, 3.1, -8),
  ('২', .52, 15, 5.8, 4.4, 14),
  ('৫০', .66, 20, 7.1, 0.9, -12),
  ('মিল', .80, 16, 8.2, 2.4, 8),
  ('১.৫', .92, 18, 6.6, 5.2, -6),
  ('৳১০০', .14, 14, 9.0, 6.0, 12),
  ('৩', .44, 26, 7.9, 5.6, -18),
  ('বাজার', .74, 14, 8.6, 3.8, 6),
  ('১', .58, 19, 6.9, 0.3, 16),
  ('২', .30, 21, 7.4, 4.9, -10),
];

class _LoginHeroState extends State<LoginHero> with TickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 45),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _enter.value = 1;
      _loop.stop();
    } else if (!_enter.isAnimating && !_enter.isCompleted) {
      _enter.forward();
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    super.dispose();
  }

  static double _at(double t, double a, double b) =>
      Interval(a, b, curve: AppMotion.arrive).transform(t);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final still = AppMotion.reduced(context);
    return Container(
      height: top + 300,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.3,
          colors: [const Color(0xFF2B2620), p.surfaceInk],
          stops: const [0, .65],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _loop]),
        builder: (context, _) {
          final secs = _loop.value * 45;
          final e = _enter.value;
          return Stack(
            children: [
              // Soft golden light behind the bowl.
              Positioned(
                left: 0,
                right: 0,
                top: top + 8,
                child: Center(
                  child: Opacity(
                    opacity: _at(e, 0, .6),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            LoginHero._gold.withValues(alpha: .20),
                            LoginHero._gold.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!still)
                for (final (ch, x, size, dur, start, tilt) in _numerals)
                  _Numeral(
                    ch: ch,
                    x: x,
                    size: size,
                    tilt: tilt,
                    phase: (((secs + start) % dur) / dur),
                    appear: _at(e, .3, .9),
                  ),
              Positioned(
                left: 0,
                right: 0,
                top: top + 24,
                child: Column(
                  children: [
                    Opacity(
                      opacity: _at(e, 0, .5),
                      child: Transform.scale(
                        scale: .84 + .16 * _at(e, 0, .7),
                        child: _Mark(secs: secs, steamIn: _at(e, .35, .8)),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Opacity(
                      opacity: _at(e, .45, .85),
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _at(e, .45, .85))),
                        child: Text(
                          widget.name,
                          style: text.headlineSmall?.copyWith(
                            color: p.onInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Opacity(
                      opacity: _at(e, .55, 1),
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _at(e, .55, 1))),
                        child: Text(
                          widget.tagline,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: p.onInk.withValues(alpha: .7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Numeral extends StatelessWidget {
  const _Numeral({
    required this.ch,
    required this.x,
    required this.size,
    required this.tilt,
    required this.phase,
    required this.appear,
  });

  final String ch;
  final double x;
  final double size;
  final double tilt;

  /// 0 at the bottom of its rise, 1 at the top.
  final double phase;
  final double appear;

  @override
  Widget build(BuildContext context) {
    // In over the first sixth of the rise, out over the rest.
    final o = phase < .16 ? phase / .16 : (1 - phase) / .84;
    return Positioned(
      left: x * (MediaQuery.sizeOf(context).width - 40),
      bottom: 12 + phase * 250,
      child: Opacity(
        opacity: (o * .5 * appear).clamp(0, 1),
        child: Transform.rotate(
          angle: tilt * 3.14159 / 180 * phase,
          child: Text(
            ch,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: LoginHero._gold,
            ),
          ),
        ),
      ),
    );
  }
}

/// The app mark: dark tile, white bowl and wallet, three steam wisps that
/// each rise and fade on their own beat.
class _Mark extends StatelessWidget {
  const _Mark({required this.secs, required this.steamIn});

  final double secs;
  final double steamIn;

  static const _size = 112.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC98A0B).withValues(alpha: .45),
              blurRadius: 40,
              offset: const Offset(0, 18),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/icon/intro_tile.png'),
            Image.asset('assets/icon/intro_glyph.png'),
            for (final (i, (from, to)) in const [
              (0.0, .403),
              (.403, .492),
              (.492, 1.0),
            ].indexed)
              _Wisp(
                phase: ((secs - i * .45) % 2.6) / 2.6,
                appear: steamIn,
                from: from,
                to: to,
              ),
          ],
        ),
      ),
    );
  }
}

class _Wisp extends StatelessWidget {
  const _Wisp({
    required this.phase,
    required this.appear,
    required this.from,
    required this.to,
  });

  final double phase;
  final double appear;
  final double from;
  final double to;

  @override
  Widget build(BuildContext context) {
    final p = phase < 0 ? phase + 1 : phase;
    final o = p < .25 ? p / .25 : 1 - (p - .25) / .75;
    return Opacity(
      opacity: (o * appear).clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 8 - 26 * p),
        child: ClipRect(
          clipper: _Columns(from, to),
          child: Image.asset('assets/icon/intro_steam.png'),
        ),
      ),
    );
  }
}

class _Columns extends CustomClipper<Rect> {
  const _Columns(this.from, this.to);

  final double from;
  final double to;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * from, -40, size.width * to, size.height);

  @override
  bool shouldReclip(_Columns old) => old.from != from || old.to != to;
}

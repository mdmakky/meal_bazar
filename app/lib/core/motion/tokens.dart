import 'package:flutter/material.dart' show Easing;
import 'package:flutter/widgets.dart';

/// Motion tokens (DESIGN_SYSTEM.md, "Premium v2 · Motion").
///
/// Three durations, three curves. Arrivals decelerate (emphasized), state
/// changes use the standard curve, exits run at 70% of their entrance and
/// accelerate away. Every authored animation goes through [of] so the system
/// "Remove animations" setting turns it into an instant cut.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);

  /// Entrances: sheets, staggered rows, the proof line, the nav dot.
  static const Curve arrive = Easing.emphasizedDecelerate;

  /// State changes in place: colours, selected chips, cross-fades.
  static const Curve state = Easing.standard;

  /// Exits: leave faster than you came.
  static const Curve exit = Easing.emphasizedAccelerate;

  /// [d] shortened to an exit (70%).
  static Duration exitOf(Duration d) => d * 0.7;

  /// [d], or zero when the system asks for no animations.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  // Named moments.
  static const page = Duration(milliseconds: 280); // shared-axis push
  static const tab = Duration(milliseconds: 210); // fade-through tabs
  static const chip = Duration(milliseconds: 180);
  static const stamp = Duration(milliseconds: 260);
  static const pop = fast; // stepper value pop
  static const staggerStep = Duration(milliseconds: 30);
  static const staggerMax = 8;
  static const rise = 8.0; // dp, staggered rows + proof line
  static const skeleton = Duration(milliseconds: 1200);

  // v1 names, kept for existing call sites.
  static const proofReveal = base;
  static const proofRise = rise;
  static const valueFade = fast;
  static const pulse = Duration(milliseconds: 900); // sync dot
}

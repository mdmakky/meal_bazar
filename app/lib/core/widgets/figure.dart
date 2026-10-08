import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Headline number with its label and an optional proof line.
/// Tap toggles the proof (8 dp rise + fade, 220 ms emphasized-decelerate).
class Figure extends StatefulWidget {
  const Figure({
    super.key,
    required this.value,
    required this.label,
    this.proof,
    this.valueColor,
    this.initiallyExpanded = false,
    this.compact = false,
  });

  /// Already formatted, e.g. `Fmt.money(...)`.
  final String value;
  final String label;
  final String? proof;

  /// Only for due/advance: pass `context.palette.due` / `.advance`.
  final Color? valueColor;
  final bool initiallyExpanded;

  /// Smaller value (headlineSmall), for figures in a stat grid.
  final bool compact;

  @override
  State<Figure> createState() => _FigureState();
}

class _FigureState extends State<Figure> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final proof = widget.proof;
    final showProof = proof != null && _expanded;

    Widget? proofLine;
    if (showProof) {
      proofLine = Padding(
        padding: const EdgeInsets.only(top: AppSpace.xs),
        child: Text(
          proof,
          style: text.bodyMedium?.copyWith(
            color: palette.inkTertiary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
      if (!MediaQuery.disableAnimationsOf(context)) {
        proofLine = TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.proofReveal,
          curve: Easing.emphasizedDecelerate,
          child: proofLine,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, AppMotion.proofRise * (1 - t)),
              child: child,
            ),
          ),
        );
      }
    }

    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: text.bodyMedium),
          Text(
            widget.value,
            style: (widget.compact ? text.headlineSmall : text.displaySmall)
                ?.copyWith(
                  color: widget.valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          ?proofLine,
        ],
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: proof != null,
        expanded: proof == null ? null : _expanded,
        child: proof == null
            ? body
            : InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => setState(() => _expanded = !_expanded),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSize.touch),
                  child: body,
                ),
              ),
      ),
    );
  }
}

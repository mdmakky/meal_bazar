import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The bottom navigation bar: M3 anatomy (pill indicator over the icon,
/// label below, 80 dp, equal-width ≥ 48 dp targets) in the brand's terms.
/// The active pill fills with ink (180 ms) and a single turmeric dot slides
/// beneath it to the new tab (360 ms, emphasized decelerate): "you are here".
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const height = 80.0;
  static const _pill = Size(56, 32);
  static const _top = 12.0;
  static const _dot = 4.0;

  /// Dot centre sits in the 8 dp gap between pill and label.
  static const dotTop = _top + 32 + 2;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final n = items.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / n;
              return Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(child: _item(context, i, p, text)),
                    ],
                  ),
                  AnimatedPositioned(
                    key: const Key('nav-dot'),
                    duration: AppMotion.of(context, AppMotion.slow),
                    curve: AppMotion.arrive,
                    top: dotTop,
                    left: slot * selectedIndex + (slot - _dot) / 2,
                    child: IgnorePointer(
                      child: Container(
                        width: _dot,
                        height: _dot,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, AppPalette p, TextTheme text) {
    final item = items[i];
    final selected = i == selectedIndex;
    final d = AppMotion.of(context, AppMotion.chip);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onSelected(i),
        containedInkWell: false,
        radius: _pill.width / 2 + AppSpace.sm,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: _top, bottom: AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: d,
                curve: AppMotion.state,
                width: _pill.width,
                height: _pill.height,
                decoration: BoxDecoration(
                  color: selected ? p.ink : p.ink.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(_pill.height / 2),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: selected ? p.onInk : p.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              AnimatedDefaultTextStyle(
                duration: d,
                curve: AppMotion.state,
                style: text.labelMedium!.copyWith(
                  color: selected ? p.ink : p.inkSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

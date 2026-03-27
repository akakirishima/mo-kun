import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:nes_ui/nes_ui.dart';

class GlassBottomDock extends StatelessWidget {
  const GlassBottomDock({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.selectionProgress,
    required this.onSelectTab,
  });

  static const reservedBottomSpacing = 112.0;
  static double reservedBottomSpacingFor(BuildContext context) {
    return reservedBottomSpacing + MediaQuery.paddingOf(context).bottom;
  }

  final List<AppTab> tabs;
  final AppTab selectedTab;
  final double selectionProgress;
  final ValueChanged<AppTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: NesContainer(
          key: const ValueKey<String>('app-navigation-dock'),
          backgroundColor: const Color(0xFFE0A56D).withValues(alpha: 0.92),
          painterBuilder: NesContainerSquareCornerPainter.new,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Row(
            key: const ValueKey<String>('app-navigation-bar'),
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                Expanded(
                  child: _DockItem(
                    tab: tabs[i],
                    selected: tabs[i] == selectedTab,
                    onTap: () => onSelectTab(tabs[i]),
                  ),
                ),
                if (i != tabs.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? tab.accentColor : const Color(0xFFB8703C);
    final iconColor = selected
        ? const Color(0xFF4D2C1A)
        : const Color(0xFFFFF3D3);
    final labelColor = selected
        ? const Color(0xFF4D2C1A)
        : const Color(0xFFFFF6DF);
    final borderColor = selected
        ? const Color(0xFF2F1A0F)
        : const Color(0xFF6D3C1D);
    final shadowColor = selected
        ? const Color(0xFF8C5833)
        : const Color(0xFF7A451F);

    return Semantics(
      key: ValueKey<String>('nav-semantics-${tab.name}'),
      selected: selected,
      button: true,
      label: tab.semanticLabel,
      child: NesPressable(
        key: ValueKey<String>('nav-${tab.name}'),
        onPress: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 76,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? tab.selectedIcon : tab.icon,
                key: ValueKey<String>('nav-slot-icon-${tab.name}'),
                size: 24,
                color: iconColor,
              ),
              const SizedBox(height: 6),
              Text(
                tab.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

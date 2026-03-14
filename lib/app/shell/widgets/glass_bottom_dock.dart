import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';

class GlassBottomDock extends StatefulWidget {
  const GlassBottomDock({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.selectionProgress,
    required this.onSelectTab,
  });

  static const reservedBottomSpacing = 92.0;
  static const _dockRadius = 32.0;
  static const _pillRadius = 22.0;
  static const _dockHorizontalPadding = 8.0;
  static const _dockVerticalPadding = 8.0;
  static const _slotGap = 4.0;
  static const _slotHeight = 40.0;
  static const _compactPillMinWidth = 44.0;
  static const _compactPillMaxWidth = 58.0;
  static const _inactiveIconSize = 20.0;
  static const _dragLiftOffset = 5.0;
  static const _dragLiftAllowance = 8.0;

  final List<AppTab> tabs;
  final AppTab selectedTab;
  final double selectionProgress;
  final ValueChanged<AppTab> onSelectTab;

  @override
  State<GlassBottomDock> createState() => _GlassBottomDockState();
}

class _GlassBottomDockState extends State<GlassBottomDock> {
  double? _dragProgress;
  bool _isDragging = false;

  double get _effectiveProgress =>
      _normalizeProgress(_dragProgress ?? widget.selectionProgress);

  double _normalizeProgress(double progress) {
    if (!progress.isFinite) {
      return widget.selectedTab.index.toDouble();
    }

    return progress.clamp(0.0, widget.tabs.length - 1.0).toDouble();
  }

  int _nearestIndexForProgress(double progress) {
    return progress.round().clamp(0, widget.tabs.length - 1).toInt();
  }

  @override
  void didUpdateWidget(covariant GlassBottomDock oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isDragging || _dragProgress == null) {
      return;
    }

    final override = _dragProgress!;
    if (widget.selectedTab.index.toDouble() != override) {
      _dragProgress = null;
      return;
    }

    final externalProgress = _normalizeProgress(widget.selectionProgress);
    if ((externalProgress - override).abs() < 0.02) {
      _dragProgress = null;
    }
  }

  void _startDrag(double currentProgress) {
    if (_isDragging) {
      return;
    }

    setState(() {
      _isDragging = true;
      _dragProgress = currentProgress;
    });
  }

  void _updateDrag({
    required double deltaX,
    required _DockLayoutMetrics metrics,
  }) {
    if (!_isDragging) {
      return;
    }

    final current = _dragProgress ?? _effectiveProgress;
    final deltaProgress = deltaX / metrics.slotSpan;
    final next = (current + deltaProgress)
        .clamp(0.0, widget.tabs.length - 1.0)
        .toDouble();

    if ((next - current).abs() < 0.0001) {
      return;
    }

    setState(() {
      _dragProgress = next;
    });
  }

  void _endDrag() {
    if (!_isDragging) {
      return;
    }

    final settledProgress = _dragProgress ?? _effectiveProgress;
    final targetIndex = _nearestIndexForProgress(settledProgress);
    final targetTab = widget.tabs[targetIndex];

    setState(() {
      _isDragging = false;
      _dragProgress = targetIndex.toDouble();
    });

    widget.onSelectTab(targetTab);
  }

  void _cancelDrag() {
    if (!_isDragging) {
      return;
    }

    setState(() {
      _isDragging = false;
      _dragProgress = null;
    });
  }

  void _handleActivePillTap() {
    final targetIndex = _nearestIndexForProgress(_effectiveProgress);
    widget.onSelectTab(widget.tabs[targetIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = _effectiveProgress;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dockWidth = constraints.maxWidth;
            final metrics = _DockLayoutMetrics.fromTabs(
              tabs: widget.tabs,
              selectionProgress: safeProgress,
              availableWidth: dockWidth,
            );
            final nearestIndex = _nearestIndexForProgress(safeProgress);
            final dockBodyHeight =
                GlassBottomDock._slotHeight +
                (GlassBottomDock._dockVerticalPadding * 2);

            return SizedBox(
              width: dockWidth,
              height: dockBodyHeight + GlassBottomDock._dragLiftAllowance,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: GlassBottomDock._dragLiftAllowance,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        GlassBottomDock._dockRadius,
                      ),
                      child: BackdropFilter(
                        key: const ValueKey<String>('glass-dock-blur'),
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              GlassBottomDock._dockRadius,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.48),
                                Colors.white.withValues(alpha: 0.22),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.52),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0x400F172A,
                                ).withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.16),
                                blurRadius: 12,
                                offset: const Offset(0, -3),
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                GlassBottomDock._dockRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    GlassBottomDock._dockHorizontalPadding,
                                vertical: GlassBottomDock._dockVerticalPadding,
                              ),
                              child: SizedBox(
                                width: metrics.rowWidth,
                                height: GlassBottomDock._slotHeight,
                                child: Row(
                                  key: const ValueKey<String>(
                                    'app-navigation-bar',
                                  ),
                                  children: [
                                    for (
                                      var i = 0;
                                      i < widget.tabs.length;
                                      i++
                                    ) ...[
                                      _GlassDockSlot(
                                        tab: widget.tabs[i],
                                        width: metrics.slotWidths[i],
                                        iconOpacity: _iconOpacityForProgress(
                                          progress: safeProgress,
                                          index: i,
                                        ),
                                        iconColor: _iconColorForProgress(
                                          progress: safeProgress,
                                          index: i,
                                        ),
                                        isSelected: i == nearestIndex,
                                        isSemanticsSelected: i == nearestIndex,
                                        onTap: () =>
                                            widget.onSelectTab(widget.tabs[i]),
                                      ),
                                      if (i != widget.tabs.length - 1)
                                        const SizedBox(
                                          width: GlassBottomDock._slotGap,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left:
                        GlassBottomDock._dockHorizontalPadding +
                        metrics.activeLeft,
                    top:
                        GlassBottomDock._dragLiftAllowance +
                        GlassBottomDock._dockVerticalPadding -
                        (_isDragging ? GlassBottomDock._dragLiftOffset : 0),
                    width: metrics.activeWidth,
                    height: GlassBottomDock._slotHeight,
                    child: GestureDetector(
                      key: const ValueKey<String>(
                        'glass-dock-active-pill-gesture',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleActivePillTap,
                      onPanStart: (_) => _startDrag(safeProgress),
                      onPanUpdate: (details) => _updateDrag(
                        deltaX: details.delta.dx,
                        metrics: metrics,
                      ),
                      onPanEnd: (_) => _endDrag(),
                      onPanCancel: _cancelDrag,
                      child: IgnorePointer(
                        child: _ActiveGlassPill(
                          accentColor: metrics.activeTint,
                          isDragging: _isDragging,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _iconOpacityForProgress({
    required double progress,
    required int index,
  }) {
    final distance = (progress - index).abs();
    final emphasis = (1 - distance).clamp(0.0, 1.0);
    return lerpDouble(0.72, 1, emphasis) ?? 1;
  }

  Color _iconColorForProgress({required double progress, required int index}) {
    final distance = (progress - index).abs();
    final emphasis = (1 - distance).clamp(0.0, 1.0);
    return Color.lerp(
          _GlassDockSlot.inactiveContentColor,
          _GlassDockSlot.activeContentColor,
          emphasis,
        ) ??
        _GlassDockSlot.inactiveContentColor;
  }
}

class _ActiveGlassPill extends StatelessWidget {
  const _ActiveGlassPill({required this.accentColor, required this.isDragging});

  final Color accentColor;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final selectedFill = Color.alphaBlend(
      accentColor.withValues(alpha: isDragging ? 0.52 : 0.38),
      Colors.white.withValues(alpha: 0.34),
    );
    final edgeHighlight = Colors.white.withValues(
      alpha: isDragging ? 0.9 : 0.72,
    );
    final innerGlow = Colors.white.withValues(alpha: isDragging ? 0.34 : 0.22);
    final scaleX = isDragging ? 1.12 : 1.0;
    final scaleY = isDragging ? 1.08 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
      child: DecoratedBox(
        key: const ValueKey<String>('glass-dock-active-pill'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GlassBottomDock._pillRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isDragging ? 0.72 : 0.58),
              selectedFill.withValues(alpha: isDragging ? 0.96 : 0.92),
            ],
          ),
          color: selectedFill,
          border: Border.all(color: edgeHighlight, width: isDragging ? 1.2 : 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDragging ? 0.28 : 0.16),
              blurRadius: isDragging ? 30 : 20,
              spreadRadius: isDragging ? 2 : 0,
              offset: Offset(0, isDragging ? 10 : 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: isDragging ? 0.24 : 0.14),
              blurRadius: isDragging ? 24 : 14,
              offset: const Offset(0, -2),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GlassBottomDock._pillRadius),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.24),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  heightFactor: 0.46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        GlassBottomDock._pillRadius,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(
                            alpha: isDragging ? 0.48 : 0.34,
                          ),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(-0.72, -0.7),
                child: FractionallySizedBox(
                  widthFactor: 0.54,
                  heightFactor: 0.56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(
                            alpha: isDragging ? 0.42 : 0.3,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    GlassBottomDock._pillRadius,
                  ),
                  border: Border.all(color: innerGlow, width: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassDockSlot extends StatelessWidget {
  const _GlassDockSlot({
    required this.tab,
    required this.width,
    required this.iconOpacity,
    required this.iconColor,
    required this.isSelected,
    required this.isSemanticsSelected,
    required this.onTap,
  });

  static const activeContentColor = Color(0xFF17202C);
  static const inactiveContentColor = Color(0xFF6E7683);

  final AppTab tab;
  final double width;
  final double iconOpacity;
  final Color iconColor;
  final bool isSelected;
  final bool isSemanticsSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: GlassBottomDock._slotHeight,
      child: Semantics(
        key: ValueKey<String>('nav-semantics-${tab.name}'),
        selected: isSemanticsSelected,
        button: true,
        label: tab.semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('nav-${tab.name}'),
            borderRadius: BorderRadius.circular(GlassBottomDock._pillRadius),
            onTap: onTap,
            child: Center(
              child: Opacity(
                opacity: iconOpacity,
                child: Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  key: ValueKey<String>('nav-slot-icon-${tab.name}'),
                  size: GlassBottomDock._inactiveIconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockLayoutMetrics {
  const _DockLayoutMetrics({
    required this.slotWidths,
    required this.rowWidth,
    required this.slotSpan,
    required this.activeLeft,
    required this.activeWidth,
    required this.activeTint,
  });

  final List<double> slotWidths;
  final double rowWidth;
  final double slotSpan;
  final double activeLeft;
  final double activeWidth;
  final Color activeTint;

  factory _DockLayoutMetrics.fromTabs({
    required List<AppTab> tabs,
    required double selectionProgress,
    required double availableWidth,
  }) {
    final rowWidth =
        availableWidth - (GlassBottomDock._dockHorizontalPadding * 2);
    final totalGap = GlassBottomDock._slotGap * (tabs.length - 1);
    final slotWidth = (rowWidth - totalGap) / tabs.length;
    final slotSpan = slotWidth + GlassBottomDock._slotGap;
    final slotWidths = [for (final _ in tabs) slotWidth];
    final compactPillWidth = (slotWidth - 14)
        .clamp(
          GlassBottomDock._compactPillMinWidth,
          GlassBottomDock._compactPillMaxWidth,
        )
        .toDouble();

    final clampedProgress = selectionProgress.clamp(0.0, tabs.length - 1.0);
    final leadingIndex = clampedProgress.floor();
    final trailingIndex = clampedProgress.ceil();
    final transition = clampedProgress - leadingIndex;

    final leadingLeft =
        _slotLeftForIndex(slotWidths, leadingIndex) +
        ((slotWidths[leadingIndex] - compactPillWidth) / 2);
    final trailingLeft =
        _slotLeftForIndex(slotWidths, trailingIndex) +
        ((slotWidths[trailingIndex] - compactPillWidth) / 2);
    final activeLeft =
        lerpDouble(leadingLeft, trailingLeft, transition) ?? leadingLeft;

    return _DockLayoutMetrics(
      slotWidths: slotWidths,
      rowWidth: rowWidth,
      slotSpan: slotSpan,
      activeLeft: activeLeft,
      activeWidth: compactPillWidth,
      activeTint:
          Color.lerp(
            tabs[leadingIndex].accentColor,
            tabs[trailingIndex].accentColor,
            transition,
          ) ??
          tabs[leadingIndex].accentColor,
    );
  }

  static double _slotLeftForIndex(List<double> slotWidths, int index) {
    var left = 0.0;
    for (var i = 0; i < index; i++) {
      left += slotWidths[i] + GlassBottomDock._slotGap;
    }
    return left;
  }
}

import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class DiaryOuterFramePanel extends StatelessWidget {
  const DiaryOuterFramePanel({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.innerBackgroundColor,
    required this.borderColor,
    required this.innerBorderColor,
    required this.shadowColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color backgroundColor;
  final Color innerBackgroundColor;
  final Color borderColor;
  final Color innerBorderColor;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(color: shadowColor, offset: const Offset(0, 6)),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: innerBorderColor, width: 2),
          color: innerBackgroundColor,
        ),
        child: child,
      ),
    );
  }
}

class DiaryRetroPanel extends StatelessWidget {
  const DiaryRetroPanel({
    super.key,
    required this.child,
    required this.fillColor,
    required this.borderColor,
    required this.innerBorderColor,
    required this.shadowColor,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.innerRadius = 18,
    this.accentColor,
    this.textureOpacity = 0.0,
  });

  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final Color innerBorderColor;
  final Color shadowColor;
  final EdgeInsets padding;
  final double radius;
  final double innerRadius;
  final Color? accentColor;
  final double textureOpacity;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = accentColor == null
        ? fillColor
        : Color.lerp(fillColor, accentColor, 0.08)!;

    return NesContainer(
      backgroundColor: fillColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(4),
      painterBuilder: NesContainerSquareCornerPainter.new,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 5))],
      ),
      child: NesContainer(
        backgroundColor: surfaceColor,
        borderColor: innerBorderColor,
        padding: padding,
        painterBuilder: NesContainerSquareCornerPainter.new,
        child: textureOpacity > 0
            ? CustomPaint(
                painter: _DiaryPixelTexturePainter(
                  lightColor: Colors.white.withValues(
                    alpha: textureOpacity * 0.9,
                  ),
                  darkColor: borderColor.withValues(
                    alpha: textureOpacity * 0.4,
                  ),
                ),
                child: child,
              )
            : child,
      ),
    );
  }
}

class DiaryRetroBadge extends StatelessWidget {
  const DiaryRetroBadge({
    super.key,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.shadowColor,
  });

  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final EdgeInsets padding;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = shadowColor ?? borderColor.withValues(alpha: 0.22);

    return NesContainer(
      backgroundColor: fillColor,
      borderColor: borderColor,
      padding: padding,
      painterBuilder: NesContainerSquareCornerPainter.new,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: effectiveShadow, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.12,
        ),
      ),
    );
  }
}

class DiaryRetroPressable extends StatelessWidget {
  const DiaryRetroPressable({
    super.key,
    required this.child,
    required this.fillColor,
    required this.borderColor,
    required this.onPress,
    this.disabled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.shadowColor,
    this.width,
    this.height,
  });

  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final VoidCallback? onPress;
  final bool disabled;
  final EdgeInsets padding;
  final Color? shadowColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = shadowColor ?? borderColor.withValues(alpha: 0.2);

    return Opacity(
      opacity: disabled ? 0.58 : 1,
      child: Semantics(
        button: true,
        child: NesPressable(
          disabled: disabled,
          onPress: disabled ? null : onPress,
          child: SizedBox(
            width: width,
            height: height,
            child: NesContainer(
              backgroundColor: fillColor,
              borderColor: borderColor,
              padding: padding,
              painterBuilder: NesContainerSquareCornerPainter.new,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: effectiveShadow, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryPixelTexturePainter extends CustomPainter {
  const _DiaryPixelTexturePainter({
    required this.lightColor,
    required this.darkColor,
  });

  final Color lightColor;
  final Color darkColor;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 8.0;
    const pixelSize = 2.0;
    final lightPaint = Paint()..color = lightColor;
    final darkPaint = Paint()..color = darkColor;

    for (var row = 0; row * cellSize < size.height; row++) {
      for (var column = 0; column * cellSize < size.width; column++) {
        final left = column * cellSize;
        final top = row * cellSize;
        final useLight = (row + column).isEven;
        canvas.drawRect(
          Rect.fromLTWH(left + 1, top + 1, pixelSize, pixelSize),
          useLight ? lightPaint : darkPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(left + 4, top + 4, pixelSize, pixelSize),
          useLight ? darkPaint : lightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryPixelTexturePainter oldDelegate) {
    return oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor;
  }
}

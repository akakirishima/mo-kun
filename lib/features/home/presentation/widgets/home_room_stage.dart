import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeRoomStage extends StatelessWidget {
  const HomeRoomStage({
    super.key,
    this.characterImageUrl,
    this.isResolvingImage = false,
  });

  static const _frameFill = Color(0xFFFFEAF2);
  static const _frameBorder = Color(0xFFD2F4FF);
  static const _frameOutline = Color(0xFFE8A0C4);

  final String? characterImageUrl;
  final bool isResolvingImage;

  @override
  Widget build(BuildContext context) {
    final hasGeneratedImage = characterImageUrl != null && characterImageUrl!.isNotEmpty;

    return Container(
      key: const ValueKey<String>('home-room-stage'),
      decoration: BoxDecoration(
        color: _frameFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _frameOutline, width: 2),
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _frameBorder, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7FB), Color(0xFFFFE5F1)],
          ),
        ),
        child: AspectRatio(
          aspectRatio: 0.96,
          child: Stack(
            children: [
              if (!hasGeneratedImage)
                const Positioned.fill(
                  child: CustomPaint(painter: _RoomPainter()),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: const Alignment(0, 0.02),
                  child: Transform.translate(
                    offset: const Offset(0, -2),
                    child: _StageCharacter(
                      imageUrl: characterImageUrl,
                      isResolvingImage: isResolvingImage,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageCharacter extends StatelessWidget {
  const _StageCharacter({required this.imageUrl, required this.isResolvingImage});

  final String? imageUrl;
  final bool isResolvingImage;

  @override
  Widget build(BuildContext context) {
    if (isResolvingImage) {
      return const SizedBox(
        width: 96,
        height: 132,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              key: ValueKey<String>('home-room-stage-loading'),
              strokeWidth: 2.4,
            ),
          ),
        ),
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return const _MoriSprite(key: ValueKey<String>('home-room-stage-fallback'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 320,
        height: 320,
        child: Image.network(
          imageUrl!,
          key: const ValueKey<String>('home-room-stage-image'),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return const _MoriSprite(
              key: ValueKey<String>('home-room-stage-fallback'),
            );
          },
        ),
      ),
    );
  }
}

class _MoriSprite extends StatelessWidget {
  const _MoriSprite({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned(top: 0, child: _MoriHead()),
          Positioned(
            top: 55,
            child: Container(
              width: 60,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF77B796),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF5A8D75), width: 2),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F2D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'M',
                  style: TextStyle(
                    color: Color(0xFF62826B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 98, left: 20, child: _foot()),
          Positioned(top: 98, right: 20, child: _foot()),
          Positioned(
            top: 66,
            left: 4,
            child: Transform.rotate(angle: -0.3, child: _arm()),
          ),
          Positioned(
            top: 66,
            right: 4,
            child: Transform.rotate(angle: 0.3, child: _arm()),
          ),
        ],
      ),
    );
  }

  Widget _arm() {
    return Container(
      width: 12,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF77B796),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5A8D75), width: 1.5),
      ),
    );
  }

  Widget _foot() {
    return Container(
      width: 14,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFF4D5C2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1B49D), width: 1.2),
      ),
    );
  }
}

class _MoriHead extends StatelessWidget {
  const _MoriHead();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -6,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 12,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF94D1B3),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF70A686),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 6, top: 6, child: _ear()),
          Positioned(right: 6, top: 6, child: _ear()),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF7DCCB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4B79E), width: 2),
            ),
            child: Stack(
              children: const [
                Positioned(left: 16, top: 22, child: _FaceDot()),
                Positioned(right: 16, top: 22, child: _FaceDot()),
                Positioned(left: 25, top: 28, child: _SmileMark()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ear() {
    return Container(
      width: 14,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFFF7DCCB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4B79E), width: 1.5),
      ),
    );
  }
}

class _FaceDot extends StatelessWidget {
  const _FaceDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFF8A5E52),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SmileMark extends StatelessWidget {
  const _SmileMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 4,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF8A5E52), width: 1.2),
        ),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  static const _outline = Color(0xFFC88EAA);
  static const _glow = Color(0xFFD7F6FF);
  static const _leftWall = Color(0xFFFFEFF5);
  static const _rightWall = Color(0xFFFCE4F0);
  static const _floor = Color(0xFFF8D9E7);
  static const _window = Color(0xFFCCE9FF);
  static const _windowFrame = Color(0xFF92BED8);
  static const _desk = Color(0xFFF7E6AF);
  static const _deskOutline = Color(0xFFC8B16E);
  static const _shelf = Color(0xFFE3BAD3);
  static const _shelfOutline = Color(0xFFBF8BAB);
  static const _rug = Color(0xFFDDF7FF);
  static const _tvStand = Color(0xFFF4D9A9);
  static const _plant = Color(0xFF8AC7A2);

  @override
  void paint(Canvas canvas, Size size) {
    final ridge = Offset(size.width * 0.5, size.height * 0.16);
    final leftTop = Offset(size.width * 0.19, size.height * 0.34);
    final rightTop = Offset(size.width * 0.81, size.height * 0.34);
    final floorBack = Offset(size.width * 0.5, size.height * 0.53);
    final leftFront = Offset(size.width * 0.13, size.height * 0.78);
    final rightFront = Offset(size.width * 0.87, size.height * 0.78);
    final bottom = Offset(size.width * 0.5, size.height * 0.97);

    final fill = Paint()..style = PaintingStyle.fill;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _outline;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _glow;

    final leftWall = Path()
      ..moveTo(ridge.dx, ridge.dy)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..lineTo(leftFront.dx, leftFront.dy)
      ..lineTo(floorBack.dx, floorBack.dy)
      ..close();
    fill.color = _leftWall;
    canvas.drawPath(leftWall, fill);
    canvas.drawPath(leftWall, outline);
    canvas.drawPath(leftWall, glow);

    final rightWall = Path()
      ..moveTo(ridge.dx, ridge.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightFront.dx, rightFront.dy)
      ..lineTo(floorBack.dx, floorBack.dy)
      ..close();
    fill.color = _rightWall;
    canvas.drawPath(rightWall, fill);
    canvas.drawPath(rightWall, outline);
    canvas.drawPath(rightWall, glow);

    final floor = Path()
      ..moveTo(floorBack.dx, floorBack.dy)
      ..lineTo(rightFront.dx, rightFront.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(leftFront.dx, leftFront.dy)
      ..close();
    fill.color = _floor;
    canvas.drawPath(floor, fill);
    canvas.drawPath(floor, outline);
    canvas.drawPath(floor, glow);

    _drawWindow(canvas, size);
    _drawPictureFrames(canvas, size);
    _drawDesk(canvas, size);
    _drawShelf(canvas, size);
    _drawTvStand(canvas, size);
    _drawLamp(canvas, size);
    _drawRug(canvas, size);
    _drawPlant(canvas, size);
    _drawSparkles(canvas, size);
  }

  void _drawWindow(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.63,
        size.height * 0.39,
        size.width * 0.16,
        size.height * 0.14,
      ),
      const Radius.circular(16),
    );
    final paint = Paint()..color = _window;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _windowFrame;

    canvas.drawRRect(frame, paint);
    canvas.drawRRect(frame, stroke);
    canvas.drawLine(
      Offset(size.width * 0.71, size.height * 0.39),
      Offset(size.width * 0.71, size.height * 0.53),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.63, size.height * 0.46),
      Offset(size.width * 0.79, size.height * 0.46),
      stroke,
    );

    final light = Paint()..color = Colors.white.withValues(alpha: 0.34);
    final beam = Path()
      ..moveTo(size.width * 0.71, size.height * 0.53)
      ..lineTo(size.width * 0.8, size.height * 0.62)
      ..lineTo(size.width * 0.71, size.height * 0.7)
      ..lineTo(size.width * 0.61, size.height * 0.61)
      ..close();
    canvas.drawPath(beam, light);
  }

  void _drawPictureFrames(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _outline;
    final pastel = Paint()..color = const Color(0xFFE7CCFA);
    final warm = Paint()..color = const Color(0xFFFFD59F);
    final cool = Paint()..color = const Color(0xFFAADDF5);

    final wideFrame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.39,
        size.width * 0.2,
        size.height * 0.06,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(wideFrame, Paint()..color = const Color(0xFFFFF7FB));
    canvas.drawRRect(wideFrame, stroke);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.405,
        size.width * 0.06,
        size.height * 0.025,
      ),
      pastel,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.405,
        size.width * 0.08,
        size.height * 0.025,
      ),
      warm,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.29,
        size.height * 0.415,
        size.width * 0.09,
        size.height * 0.015,
      ),
      cool,
    );

    final tallFrame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.36,
        size.width * 0.06,
        size.height * 0.11,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(tallFrame, Paint()..color = const Color(0xFFFFF7FB));
    canvas.drawRRect(tallFrame, stroke);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.415), 5, cool);
  }

  void _drawDesk(Canvas canvas, Size size) {
    final fill = Paint()..color = _desk;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _deskOutline;

    final deskTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.57,
        size.width * 0.18,
        size.height * 0.08,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(deskTop, fill);
    canvas.drawRRect(deskTop, stroke);

    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.65),
      Offset(size.width * 0.23, size.height * 0.75),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.35, size.height * 0.75),
      stroke,
    );

    final chair = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.67,
        size.width * 0.07,
        size.height * 0.08,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(chair, fill);
    canvas.drawRRect(chair, stroke);

    final monitor = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.51,
        size.width * 0.09,
        size.height * 0.06,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(monitor, Paint()..color = const Color(0xFFC0E8F8));
    canvas.drawRRect(monitor, stroke);
    canvas.drawLine(
      Offset(size.width * 0.275, size.height * 0.57),
      Offset(size.width * 0.275, size.height * 0.6),
      stroke,
    );
  }

  void _drawShelf(Canvas canvas, Size size) {
    final fill = Paint()..color = _shelf;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _shelfOutline;

    final shelf = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.62,
        size.width * 0.15,
        size.height * 0.17,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(shelf, fill);
    canvas.drawRRect(shelf, stroke);
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.69),
      Offset(size.width * 0.85, size.height * 0.69),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.775, size.height * 0.62),
      Offset(size.width * 0.775, size.height * 0.79),
      stroke,
    );

    canvas.drawCircle(
      Offset(size.width * 0.735, size.height * 0.655),
      6,
      Paint()..color = const Color(0xFFFFB1C7),
    );
    canvas.drawCircle(
      Offset(size.width * 0.812, size.height * 0.73),
      7,
      Paint()..color = const Color(0xFFCDEEFF),
    );
  }

  void _drawTvStand(Canvas canvas, Size size) {
    final fill = Paint()..color = _tvStand;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _deskOutline;

    final tvBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.54,
        size.height * 0.74,
        size.width * 0.14,
        size.height * 0.1,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(tvBase, fill);
    canvas.drawRRect(tvBase, stroke);

    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.66,
        size.width * 0.1,
        size.height * 0.08,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(screen, Paint()..color = const Color(0xFFE6B0C8));
    canvas.drawRRect(screen, stroke);
  }

  void _drawLamp(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _outline;
    final fill = Paint()..color = const Color(0xFFFFF3B1);

    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.6),
      Offset(size.width * 0.16, size.height * 0.75),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.13, size.height * 0.75),
      Offset(size.width * 0.19, size.height * 0.75),
      stroke,
    );
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.54), 18, fill);
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.54),
      18,
      stroke,
    );
  }

  void _drawRug(Canvas canvas, Size size) {
    final rug = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.76,
        size.width * 0.26,
        size.height * 0.08,
      ),
      const Radius.circular(30),
    );
    canvas.drawRRect(rug, Paint()..color = _rug);
    canvas.drawRRect(
      rug,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF9FD3E8),
    );
  }

  void _drawPlant(Canvas canvas, Size size) {
    final pot = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.58,
        size.width * 0.04,
        size.height * 0.04,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(pot, Paint()..color = const Color(0xFFF8C8AE));
    canvas.drawRRect(
      pot,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _outline,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.56),
      7,
      Paint()..color = _plant,
    );
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.6);
    final centers = [
      Offset(size.width * 0.69, size.height * 0.27),
      Offset(size.width * 0.78, size.height * 0.48),
      Offset(size.width * 0.26, size.height * 0.48),
    ];

    for (final center in centers) {
      final radius = size.width * 0.012;
      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        paint,
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), paint);
      canvas.drawLine(Offset(0, -radius), Offset(0, radius), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => false;
}

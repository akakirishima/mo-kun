import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HomeRoomStageState { ready, loading, empty, error }

class HomeRoomStage extends StatelessWidget {
  const HomeRoomStage({
    super.key,
    this.imageUrl,
    required this.state,
    required this.message,
  });

  final String? imageUrl;
  final HomeRoomStageState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-room-stage'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6FB), Color(0xFFFFE4F0)],
        ),
        border: Border.all(color: const Color(0xFF5F4A57), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335F4A57),
            offset: Offset(0, 10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
            Positioned(
              left: 2,
              top: 2,
              child: _PixelSticker(
                color: const Color(0xFFF7B3CF),
                borderColor: const Color(0xFF8D5975),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: _PixelSticker(
                color: const Color(0xFFFFE08D),
                borderColor: const Color(0xFF8E7454),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.997,
                heightFactor: 0.997,
                child: CustomPaint(
                  painter: const _PixelFramePainter(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBFD),
                        border: Border.all(
                          color: const Color(0xFF5F4A57),
                          width: 2,
                        ),
                      ),
                      child: _StageContent(
                        imageUrl: imageUrl,
                        state: state,
                        message: message,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageContent extends StatelessWidget {
  const _StageContent({
    required this.imageUrl,
    required this.state,
    required this.message,
  });

  final String? imageUrl;
  final HomeRoomStageState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      HomeRoomStageState.loading => const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              key: ValueKey<String>('home-room-stage-loading'),
              strokeWidth: 2.6,
            ),
          ),
        ),
      HomeRoomStageState.ready => ColoredBox(
          color: const Color(0xFFFFF2F8),
          child: Image.network(
            imageUrl!,
            key: const ValueKey<String>('home-room-stage-image'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) {
              return const _StageMessage(
                key: ValueKey<String>('home-room-stage-error'),
                title: '通信に失敗しました',
                subtitle: '時間をおいてもう一度お試しください',
              );
            },
          ),
        ),
      HomeRoomStageState.empty => _StageMessage(
          key: const ValueKey<String>('home-room-stage-empty'),
          title: message,
          subtitle: 'HOME から再生成するとここに表示されます',
        ),
      HomeRoomStageState.error => _StageMessage(
          key: const ValueKey<String>('home-room-stage-error'),
          title: message,
          subtitle: '時間をおいてもう一度お試しください',
        ),
    };
  }
}

class _StageMessage extends StatelessWidget {
  const _StageMessage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8FB),
              border: Border.all(color: const Color(0xFF5F4A57), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7B3CF),
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFF5F4A57), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4D3845),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7A6170),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelSticker extends StatelessWidget {
  const _PixelSticker({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}

class _PixelFramePainter extends CustomPainter {
  const _PixelFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const outerDark = Color(0xFF5F4A57);
    const midTone = Color(0xFFD99AB8);
    const lightTone = Color(0xFFFFD9EA);
    final outer = Paint()..color = outerDark;
    final mid = Paint()..color = midTone;
    final light = Paint()..color = lightTone;

    canvas.drawRect(Offset.zero & size, outer);
    canvas.drawRect(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      mid,
    );
    canvas.drawRect(
      Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
      light,
    );

    const block = 14.0;
    final corners = <Rect>[
      const Rect.fromLTWH(0, 0, block * 2, block * 2),
      Rect.fromLTWH(size.width - block * 2, 0, block * 2, block * 2),
      Rect.fromLTWH(0, size.height - block * 2, block * 2, block * 2),
      Rect.fromLTWH(
        size.width - block * 2,
        size.height - block * 2,
        block * 2,
        block * 2,
      ),
    ];
    for (final corner in corners) {
      canvas.drawRect(corner, outer);
      canvas.drawRect(corner.deflate(4), mid);
      canvas.drawRect(corner.deflate(8), light);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFFFFEEF6);
    final floor = Paint()..color = const Color(0xFFF4D4E4);
    final stripe = Paint()..color = const Color(0xFFF9E2EE);
    final accent = Paint()..color = const Color(0xFFE7BDD1);
    final outline = Paint()
      ..color = const Color(0xFFB787A3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.7),
      wall,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      floor,
    );

    final stripeHeight = math.max(size.height * 0.08, 18);
    for (double y = 12; y < size.height * 0.55; y += stripeHeight) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripeHeight * 0.36),
        stripe,
      );
    }

    final window = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.16,
      size.width * 0.16,
      size.height * 0.16,
    );
    canvas.drawRect(window, Paint()..color = const Color(0xFFDFF4FF));
    canvas.drawRect(window, outline);

    final shelf = Rect.fromLTWH(
      size.width * 0.74,
      size.height * 0.16,
      size.width * 0.14,
      size.height * 0.06,
    );
    canvas.drawRect(shelf, Paint()..color = const Color(0xFFFFE4A5));
    canvas.drawRect(shelf, outline);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.78,
        size.height * 0.12,
        size.width * 0.04,
        size.height * 0.04,
      ),
      accent,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.83,
        size.height * 0.12,
        size.width * 0.03,
        size.height * 0.03,
      ),
      Paint()..color = const Color(0xFFB8E2C1),
    );

    final rug = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.76,
      size.width * 0.44,
      size.height * 0.1,
    );
    canvas.drawRect(rug, Paint()..color = const Color(0xFFDDF4FF));
    canvas.drawRect(rug, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

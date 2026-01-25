import 'package:flutter/material.dart';
import 'dart:math' as math;

class VerificationBadge extends StatelessWidget {
  final bool isDC;
  final bool isAdmin;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isDC,
    required this.isAdmin,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (isDC) {
      return CustomPaint(
        size: Size(size, size),
        painter: _SmoothStarBadgePainter(
          color: Colors.blue.shade600,
          iconColor: Colors.white,
        ),
      );
    } else if (isAdmin) {
      return CustomPaint(
        size: Size(size, size),
        painter: _SmoothStarBadgePainter(
          color: Colors.black87,
          iconColor: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SmoothStarBadgePainter extends CustomPainter {
  final Color color;
  final Color iconColor;

  _SmoothStarBadgePainter({required this.color, required this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.75;
    final points = 12;

    // Create the star path with smoother transitions
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerRadius : innerRadius;
      final x = centerX + r * math.cos(angle);
      final y = centerY + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw shadow
    canvas.drawPath(path.shift(const Offset(0, 0.5)), shadowPaint);
    
    // Draw main badge
    canvas.drawPath(path, paint);

    // Draw check mark - SMALLER SIZE
    final checkPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10 // Thinner stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final checkPath = Path();
    final checkScale = 0.35; // Reduced from 0.45 - makes check smaller
    final checkLeft = centerX - size.width * checkScale * 0.5;
    final checkTop = centerY - size.width * checkScale * 0.2;

    // Better proportioned check mark
    checkPath.moveTo(checkLeft, checkTop);
    checkPath.lineTo(
      checkLeft + size.width * checkScale * 0.35,
      checkTop + size.width * checkScale * 0.4,
    );
    checkPath.lineTo(
      checkLeft + size.width * checkScale * 0.85,
      checkTop - size.width * checkScale * 0.3,
    );

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
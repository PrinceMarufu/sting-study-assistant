import 'package:flutter/material.dart';

class SSALogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool animate;

  const SSALogo({
    super.key,
    this.size = 100,
    this.color,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SSALogoPainter(color: themeColor),
      ),
    );
  }
}

class SSALogoPainter extends CustomPainter {
  final Color color;

  SSALogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw Book Wings (Open Book)
    final bookPath = Path();
    
    // Left Page
    bookPath.moveTo(size.width * 0.1, size.height * 0.7);
    bookPath.cubicTo(
      size.width * 0.25, size.height * 0.5,
      size.width * 0.35, size.height * 0.5,
      size.width * 0.48, size.height * 0.7,
    );
    bookPath.lineTo(size.width * 0.48, size.height * 0.9);
    bookPath.cubicTo(
      size.width * 0.35, size.height * 0.7,
      size.width * 0.25, size.height * 0.7,
      size.width * 0.1, size.height * 0.9,
    );
    bookPath.close();

    // Right Page
    bookPath.moveTo(size.width * 0.9, size.height * 0.7);
    bookPath.cubicTo(
      size.width * 0.75, size.height * 0.5,
      size.width * 0.65, size.height * 0.5,
      size.width * 0.52, size.height * 0.7,
    );
    bookPath.lineTo(size.width * 0.52, size.height * 0.9);
    bookPath.cubicTo(
      size.width * 0.65, size.height * 0.7,
      size.width * 0.75, size.height * 0.7,
      size.width * 0.9, size.height * 0.9,
    );
    bookPath.close();

    canvas.drawPath(bookPath, fillPaint);
    canvas.drawPath(bookPath, paint);

    // Draw Glow / Lightbulb in the center rising out of the book
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final bulbRadius = size.width * 0.16;

    // Glow Effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08);
    canvas.drawCircle(center, bulbRadius * 1.5, glowPaint);

    // Bulb Outline
    final bulbPath = Path();
    bulbPath.addArc(
      Rect.fromCircle(center: center, radius: bulbRadius),
      -0.6 * 3.1415,
      4.34 * 3.1415,
    );
    
    // Bulb Base
    final baseWidth = bulbRadius * 0.9;
    final baseTop = center.dy + bulbRadius;
    bulbPath.lineTo(center.dx + baseWidth * 0.5, baseTop);
    bulbPath.lineTo(center.dx + baseWidth * 0.3, baseTop + bulbRadius * 0.3);
    bulbPath.lineTo(center.dx - baseWidth * 0.3, baseTop + bulbRadius * 0.3);
    bulbPath.lineTo(center.dx - baseWidth * 0.5, baseTop);
    bulbPath.close();

    canvas.drawPath(bulbPath, paint);

    // Bulb Filament
    final filamentPath = Path();
    filamentPath.moveTo(center.dx - bulbRadius * 0.3, center.dy + bulbRadius * 0.4);
    filamentPath.lineTo(center.dx - bulbRadius * 0.2, center.dy - bulbRadius * 0.2);
    filamentPath.quadraticBezierTo(
      center.dx, center.dy - bulbRadius * 0.5,
      center.dx + bulbRadius * 0.2, center.dy - bulbRadius * 0.2,
    );
    filamentPath.lineTo(center.dx + bulbRadius * 0.3, center.dy + bulbRadius * 0.4);
    canvas.drawPath(filamentPath, paint);

    // Draw Rays of Light
    final rayPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final rayLength = size.width * 0.1;
    final raySpacing = size.width * 0.08;

    // Top Ray
    canvas.drawLine(
      Offset(center.dx, center.dy - bulbRadius - raySpacing),
      Offset(center.dx, center.dy - bulbRadius - raySpacing - rayLength),
      rayPaint,
    );

    // Left Ray
    canvas.drawLine(
      Offset(center.dx - bulbRadius - raySpacing, center.dy),
      Offset(center.dx - bulbRadius - raySpacing - rayLength, center.dy),
      rayPaint,
    );

    // Right Ray
    canvas.drawLine(
      Offset(center.dx + bulbRadius + raySpacing, center.dy),
      Offset(center.dx + bulbRadius + raySpacing + rayLength, center.dy),
      rayPaint,
    );

    // Top-Left Ray
    canvas.drawLine(
      Offset(center.dx - (bulbRadius + raySpacing) * 0.707, center.dy - (bulbRadius + raySpacing) * 0.707),
      Offset(center.dx - (bulbRadius + raySpacing + rayLength) * 0.707, center.dy - (bulbRadius + raySpacing + rayLength) * 0.707),
      rayPaint,
    );

    // Top-Right Ray
    canvas.drawLine(
      Offset(center.dx + (bulbRadius + raySpacing) * 0.707, center.dy - (bulbRadius + raySpacing) * 0.707),
      Offset(center.dx + (bulbRadius + raySpacing + rayLength) * 0.707, center.dy - (bulbRadius + raySpacing + rayLength) * 0.707),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

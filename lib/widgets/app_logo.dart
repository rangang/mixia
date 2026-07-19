import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isHero;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final base = isDark ? AppColors.bg2 : AppColors.lightSurface;
    final lower = isDark ? AppColors.bg : AppColors.lightElevated;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [base, lower],
            ),
            shape: BoxShape.circle,
            boxShadow: isHero
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.25),
                      blurRadius: size / 2,
                      spreadRadius: size / 20,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: size / 6,
                      offset: Offset(0, size / 20),
                    ),
                  ],
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: size / 50,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(size / 12),
            child: CustomPaint(
              size: Size(size * 0.65, size * 0.65),
              painter: _LockBoxPainter(
                color: AppColors.accent,
                goldColor: AppColors.accent2,
                darkColor: isDark ? AppColors.bg3 : AppColors.lightRule,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size / 5),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                colorScheme.onSurface,
                colorScheme.onSurface.withOpacity(0.78),
              ],
            ).createShader(bounds),
            child: Text(
              '密匣',
              style: TextStyle(
                color: Colors.white,
                fontSize: size / 3,
                fontWeight: FontWeight.w700,
                letterSpacing: size / 15,
              ),
            ),
          ),
          SizedBox(height: size / 16),
          Text(
            'MiXia',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: size / 8,
              fontWeight: FontWeight.w500,
              letterSpacing: size / 40,
            ),
          ),
        ],
      ],
    );
  }
}

class _LockBoxPainter extends CustomPainter {
  final Color color;
  final Color goldColor;
  final Color darkColor;

  _LockBoxPainter({
    required this.color,
    required this.goldColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()..style = PaintingStyle.fill;

    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, h * 0.30, w, h * 0.54),
          Radius.circular(w * 0.10),
        ),
      );
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawPath(shadowPath, paint);

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.52),
      Radius.circular(w * 0.10),
    );
    paint.color = Color.lerp(color, darkColor, 0.4)!;
    canvas.drawRRect(boxRect, paint);

    final boxHighlightPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(3, h * 0.28 + 3, w - 6, h * 0.20),
          topLeft: Radius.circular(w * 0.09),
          topRight: Radius.circular(w * 0.09),
        ),
      );
    paint.color = color.withOpacity(0.5);
    canvas.drawPath(boxHighlightPath, paint);

    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.04, h * 0.02, w * 1.08, h * 0.34),
      Radius.circular(w * 0.10),
    );
    paint.color = Color.lerp(color, darkColor, 0.15)!;
    canvas.drawRRect(lidRect, paint);

    paint.color = Colors.white.withOpacity(0.12);
    final lidHighlightPath = Path()
      ..moveTo(w * 0.02, h * 0.08)
      ..lineTo(w * 0.98, h * 0.08)
      ..lineTo(w * 0.96, h * 0.20)
      ..lineTo(w * 0.04, h * 0.20)
      ..close();
    canvas.drawPath(lidHighlightPath, paint);

    final goldLinePaint = Paint()
      ..color = goldColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final goldLinePath = Path()
      ..moveTo(w * 0.10, h * 0.34)
      ..lineTo(w * 0.90, h * 0.34);
    canvas.drawPath(goldLinePath, goldLinePaint);

    final lockW = w * 0.28;
    final lockH = h * 0.28;
    final lockX = w / 2 - lockW / 2;
    final lockY = h * 0.12;

    final shacklePaint = Paint()
      ..color = goldColor
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shacklePath = Path()
      ..moveTo(lockX + lockW * 0.15, lockY + lockH * 0.25)
      ..quadraticBezierTo(
        lockX + lockW / 2,
        lockY - lockH * 0.25,
        lockX + lockW * 0.85,
        lockY + lockH * 0.25,
      );
    canvas.drawPath(shacklePath, shacklePaint);

    final shackleInnerPaint = Paint()
      ..color = Color.lerp(goldColor, Colors.orange, 0.3)!
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shackleInnerPath = Path()
      ..moveTo(lockX + lockW * 0.22, lockY + lockH * 0.25)
      ..quadraticBezierTo(
        lockX + lockW / 2,
        lockY - lockH * 0.12,
        lockX + lockW * 0.78,
        lockY + lockH * 0.25,
      );
    canvas.drawPath(shackleInnerPath, shackleInnerPaint);

    paint.style = PaintingStyle.fill;
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(lockX, lockY + lockH * 0.15, lockW, lockH * 0.65),
      Radius.circular(w * 0.05),
    );
    paint.color = goldColor;
    canvas.drawRRect(lockBody, paint);

    paint.color = Colors.white.withOpacity(0.25);
    final lockHighlight = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        lockX + 3,
        lockY + lockH * 0.15 + 3,
        lockW - 6,
        lockH * 0.18,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(lockHighlight, paint);

    paint.color = Color.lerp(goldColor, Colors.brown, 0.5)!;
    canvas.drawCircle(
      Offset(lockX + lockW / 2, lockY + lockH * 0.50),
      w * 0.035,
      paint,
    );

    final keySlotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lockX + lockW / 2, lockY + lockH * 0.60),
        width: w * 0.025,
        height: h * 0.08,
      ),
      Radius.circular(w * 0.01),
    );
    canvas.drawRRect(keySlotRect, paint);

    paint.color = goldColor.withOpacity(0.8);
    for (final dotX in [w * 0.18, w * 0.82]) {
      for (final dotY in [h * 0.50, h * 0.66]) {
        canvas.drawCircle(Offset(dotX, dotY), w * 0.025, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

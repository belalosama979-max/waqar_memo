import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's mark (icon-only logo).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Image.asset(
        onDark ? 'assets/brand/logo_mark_on_dark.png' : 'assets/brand/logo_mark.png',
        width: size,
        height: size,
        semanticLabel: 'شعار الوقار',
      );
}

/// Arabic wordmark "الوقار" with the tagline.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.color, this.size = 44, this.showTagline = true});
  final Color? color;
  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.emerald;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'الوقار',
          style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: size, fontWeight: FontWeight.w700, color: c, height: 1.3),
        ),
        if (showTagline)
          Text(
            'وقارُ الحفظ وإتقانُ التسميع',
            style: TextStyle(fontSize: size * 0.34, color: AppColors.gold, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}

/// Subtle eight-point-star lattice used behind brand surfaces.
class GeometricPattern extends StatelessWidget {
  const GeometricPattern({super.key, this.color = AppColors.gold, this.opacity = 0.08, this.cell = 56});
  final Color color;
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _StarLatticePainter(color.withValues(alpha: opacity), cell),
          size: Size.infinite,
        ),
      );
}

class _StarLatticePainter extends CustomPainter {
  _StarLatticePainter(this.color, this.cell);
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double y = cell / 2; y < size.height + cell; y += cell) {
      for (double x = cell / 2; x < size.width + cell; x += cell) {
        canvas.drawPath(starPath(Offset(x, y), cell * 0.36), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarLatticePainter old) => old.color != color || old.cell != cell;
}

/// Eight-point star (two overlapping squares) path.
Path starPath(Offset c, double r) {
  final inner = r * 0.7654;
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final ang = (math.pi / 8) * i - math.pi / 2;
    final rad = i.isEven ? r : inner;
    final p = Offset(c.dx + rad * math.cos(ang), c.dy + rad * math.sin(ang));
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

/// Emerald gradient header surface with pattern, used on dashboards.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: GeometricPattern(opacity: 0.10)),
            Padding(padding: padding, child: child),
          ],
        ),
      );
}

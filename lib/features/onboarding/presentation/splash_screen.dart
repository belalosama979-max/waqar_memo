import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../router/app_router.dart';

/// Animated splash shown right after the native splash.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final Animation<double> _logoScale = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Curves.easeOutBack));
  late final Animation<double> _logoFade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeOut));
  late final Animation<double> _textFade = CurvedAnimation(parent: _c, curve: const Interval(0.4, 0.8, curve: Curves.easeOut));
  late final Animation<double> _ring = CurvedAnimation(parent: _c, curve: const Interval(0.1, 1, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(_continue);
  }

  Future<void> _continue() async {
    // Wait for the auth session to resolve (bounded), then let the router decide.
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (mounted && !ref.read(sessionResolvedProvider) && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!mounted) return;
    ref.read(splashDoneProvider.notifier).finish();
    context.go(ref.read(initialLocationProvider));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradient)),
          FadeTransition(opacity: _logoFade, child: const GeometricPattern(opacity: 0.12)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ring,
                        builder: (_, _) => Transform.rotate(
                          angle: _ring.value * 0.8,
                          child: CustomPaint(
                            size: const Size(220, 220),
                            painter: _RingPainter(progress: _ring.value),
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(scale: _logoScale, child: const BrandMark(size: 150, onDark: true)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(_textFade),
                    child: const BrandWordmark(color: AppColors.ivory, size: 52),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: const Center(
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.gold,
                    backgroundColor: Color(0x33FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(starPath(c, size.width / 2 - 4), paint);
    canvas.drawCircle(c, size.width / 2 - 24, paint..color = AppColors.gold.withValues(alpha: 0.18 * progress));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

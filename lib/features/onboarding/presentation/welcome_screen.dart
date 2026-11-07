import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../router/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradient)),
          const GeometricPattern(opacity: 0.10),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const BrandMark(size: 150, onDark: true),
                            const SizedBox(height: 12),
                            const BrandWordmark(color: AppColors.ivory, size: 56),
                            const SizedBox(height: 22),
                            Text(
                              'منصة متكاملة لإدارة حلقات تحفيظ القرآن الكريم: تسجيل التسميع، ومتابعة الطلاب، واحتساب النقاط، ولوحات الصدارة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.ivory.withValues(alpha: 0.85), fontSize: 16, height: 1.8),
                            ),
                            const SizedBox(height: 36),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const Key('welcome_login'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.emeraldDeep),
                                onPressed: () => context.go(Routes.login),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('تسجيل الدخول'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '﴿وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا﴾',
                              style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: AppColors.goldLight.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ),
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

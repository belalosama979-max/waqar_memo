import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';

/// Shown when the build was made without Firebase configuration.
class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 110),
                  const SizedBox(height: 16),
                  Text('التطبيق غير مهيأ بعد', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  const Text(
                    'لم يتم ربط هذه النسخة بخادم الوقار. يرجى التواصل مع مسؤول النظام للحصول على النسخة الصحيحة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.7, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

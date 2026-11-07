import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../router/routes.dart';
import '../data/onboarding_repository.dart';

class _Page {
  const _Page(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    'assets/images/onboarding_1.png',
    'نظامٌ متكامل لإدارة التسميع',
    'الوقار يجمع حلقات التحفيظ في مكان واحد: معلمون، وطلاب، وسجل تسميع منظم يحفظ كل جهد.',
  ),
  _Page(
    'assets/images/onboarding_2.png',
    'متابعة دقيقة وتقييم عادل',
    'سجّل تسميع كل طالب بالجزء أو السورة، واختر التقييم، وأضف الكمية الإضافية لتُحسب النقاط تلقائياً.',
  ),
  _Page(
    'assets/images/onboarding_3.png',
    'لوحات صدارة وإنجازات',
    'تابع ترتيب الطلاب وإحصاءات الأداء الأسبوعية والشهرية، وحفّزهم بلوحات الصدارة والإنجازات.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingDoneProvider.notifier).complete();
    if (mounted) context.go(Routes.welcome);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GeometricPattern(opacity: 0.06, color: AppColors.emerald)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const BrandMark(size: 40),
                      const SizedBox(width: 8),
                      const Text('الوقار', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(onPressed: isLast ? null : _finish, child: const Text('تخطي')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _OnboardingPage(page: _pages[i], landscape: landscape),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsetsDirectional.only(end: 6),
                              width: i == _index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _index ? AppColors.gold : AppColors.emerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('onboarding_next'),
                        onPressed: _next,
                        icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
                        label: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page, required this.landscape});
  final _Page page;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(page.image, fit: BoxFit.contain);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(page.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.emeraldDeep, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          page.body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppColors.inkSoft),
        ),
      ],
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: landscape
              ? Row(children: [Expanded(child: image), const SizedBox(width: 24), Expanded(child: text)])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Flexible(child: image), const SizedBox(height: 24), text],
                ),
        ),
      ),
    );
  }
}

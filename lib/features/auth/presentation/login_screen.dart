import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../teachers/domain/teacher.dart';
import '../data/auth_repository.dart';
import '../domain/enums.dart';

final _loginDirectoryProvider = StreamProvider.family<List<LoginDirectoryEntry>, Department>(
  (ref, dep) => ref.watch(authRepositoryProvider).watchLoginDirectory(dep),
);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            Container(height: 260, decoration: const BoxDecoration(gradient: AppColors.brandGradient)),
            const SizedBox(height: 260, child: GeometricPattern(opacity: 0.1)),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: 'رجوع',
                      color: Colors.white,
                      onPressed: () => context.go(Routes.welcome),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const BrandMark(size: 84, onDark: true),
                  const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: MaxWidth(
                      maxWidth: 520,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const TabBar(
                              labelStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 15),
                              tabs: [
                                Tab(icon: Icon(Icons.menu_book_rounded), text: 'المعلمون'),
                                Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'الإدارة'),
                              ],
                            ),
                            const Expanded(child: TabBarView(children: [_TeacherLoginForm(), _AdminLoginForm()])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherLoginForm extends ConsumerStatefulWidget {
  const _TeacherLoginForm();

  @override
  ConsumerState<_TeacherLoginForm> createState() => _TeacherLoginFormState();
}

class _TeacherLoginFormState extends ConsumerState<_TeacherLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  Department _department = Department.male;
  LoginDirectoryEntry? _teacher;
  String? _rememberedId;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    ref.read(authRepositoryProvider).lastTeacherLogin().then((last) {
      if (!mounted) return;
      setState(() {
        _department = last.department ?? _department;
        _rememberedId = last.teacherId;
      });
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_teacher == null) {
      showAppSnack(context, 'يرجى اختيار اسم المعلم', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInTeacher(teacher: _teacher!, password: _password.text);
      // Router redirect takes over (first-login password change or home).
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(_loginDirectoryProvider(_department));
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<Department>(
            segments: [
              for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {_department},
            onSelectionChanged: (s) => setState(() {
              _department = s.first;
              _teacher = null;
            }),
          ),
          const SizedBox(height: 16),
          directory.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(AppFailure.from(e).message, style: const TextStyle(color: AppColors.danger)),
            data: (list) {
              if (_teacher == null && _rememberedId != null) {
                _teacher = list.where((t) => t.id == _rememberedId).firstOrNull;
              }
              if (list.isEmpty) {
                return const Text('لا يوجد معلمون مسجلون في هذا القسم بعد', textAlign: TextAlign.center);
              }
              return DropdownButtonFormField<String>(
                key: const Key('login_teacher_dropdown'),
                initialValue: list.any((t) => t.id == _teacher?.id) ? _teacher!.id : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _department == Department.male ? 'اسم المعلم' : 'اسم المعلمة',
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                items: [for (final t in list) DropdownMenuItem(value: t.id, child: Text(t.displayName))],
                onChanged: (id) => setState(() => _teacher = list.firstWhere((t) => t.id == id)),
                validator: (v) => v == null ? 'يرجى اختيار الاسم' : null,
              );
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('login_teacher_password'),
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: Validators.loginPassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'إظهار' : 'إخفاء',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عند الدخول لأول مرة استخدم كلمة المرور المؤقتة التي سلمتك إياها الإدارة، وسيُطلب منك تغييرها.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('login_teacher_submit'),
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)) : const Text('دخول'),
          ),
          const SizedBox(height: 8),
          Text(
            'نسيت كلمة المرور؟ تواصل مع الإدارة لإعادة تعيينها.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AdminLoginForm extends ConsumerStatefulWidget {
  const _AdminLoginForm();

  @override
  ConsumerState<_AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends ConsumerState<_AdminLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInAdmin(email: _email.text, password: _password.text);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            key: const Key('login_admin_email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email_rounded)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('login_admin_password'),
            controller: _password,
            obscureText: _obscure,
            onFieldSubmitted: (_) => _submit(),
            validator: Validators.loginPassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'إظهار' : 'إخفاء',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => context.push(Routes.forgotPassword), child: const Text('نسيت كلمة المرور؟')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('login_admin_submit'),
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)) : const Text('دخول الإدارة'),
          ),
        ],
      ),
    );
  }
}

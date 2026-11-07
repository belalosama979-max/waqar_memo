import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../application/session_providers.dart';
import '../data/auth_repository.dart';

/// Change password. When [forced] (first login) the user cannot skip it.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});
  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(currentPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      showAppSnack(context, 'تم تغيير كلمة المرور بنجاح', success: true);
      if (!widget.forced) context.pop();
      // When forced, the router redirect moves on once the profile flag updates.
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تغيير كلمة المرور'),
          automaticallyImplyLeading: !widget.forced,
          actions: [
            if (widget.forced)
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go(Routes.welcome);
                },
                child: const Text('خروج'),
              ),
          ],
        ),
        body: SafeArea(
          child: MaxWidth(
            maxWidth: 520,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.forced) ...[
                    const Center(child: BrandMark(size: 80)),
                    const SizedBox(height: 12),
                    Card(
                      color: AppColors.goldSoft,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'مرحباً ${user?.displayName ?? ''}، هذه أول مرة تدخل فيها. لحماية حسابك يرجى تعيين كلمة مرور جديدة خاصة بك.',
                          style: const TextStyle(height: 1.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('cp_current'),
                    controller: _current,
                    obscureText: true,
                    validator: Validators.loginPassword,
                    decoration: InputDecoration(
                      labelText: widget.forced ? 'كلمة المرور المؤقتة' : 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock_clock_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('cp_new'),
                    controller: _new,
                    obscureText: true,
                    validator: Validators.newPassword,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      helperText: '٨ أحرف على الأقل وتتضمن حروفاً وأرقاماً',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('cp_confirm'),
                    controller: _confirm,
                    obscureText: true,
                    validator: (v) => Validators.confirmPassword(v, _new.text),
                    decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('cp_submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Text('حفظ كلمة المرور'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Admin password reset by e-mail.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: MaxWidth(
        maxWidth: 520,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.mark_email_read_rounded, size: 72, color: AppColors.gold),
              const SizedBox(height: 12),
              Text(
                _sent
                    ? 'إذا كان البريد مسجلاً لدينا فستصلك رسالة تحتوي على رابط لإعادة تعيين كلمة المرور.'
                    : 'أدخل بريد حساب الإدارة وسنرسل لك رابطاً لإعادة تعيين كلمة المرور. أما المعلمون فتعيد الإدارة تعيين كلماتهم من لوحة التحكم.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.7),
              ),
              const SizedBox(height: 20),
              if (!_sent) ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: Validators.email,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email_rounded)),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                      : const Text('إرسال الرابط'),
                ),
              ] else
                OutlinedButton(onPressed: () => context.pop(), child: const Text('العودة لتسجيل الدخول')),
            ],
          ),
        ),
      ),
    );
  }
}

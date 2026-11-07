import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../auth/domain/enums.dart';
import '../../teachers/data/teacher_repository.dart';
import '../../teachers/domain/teacher.dart';
import 'admin_dashboard_screen.dart';

class AdminTeachersScreen extends ConsumerStatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  ConsumerState<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends ConsumerState<AdminTeachersScreen> {
  Department? _dep;
  String _q = '';

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) showAppSnack(context, success, success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _showPassword(String title, String name, String password) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سلّم كلمة المرور المؤقتة إلى $name. سيُطلب منه تغييرها عند أول دخول.'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: SelectableText(password, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    IconButton(
                      tooltip: 'نسخ',
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => Clipboard.setData(ClipboardData(text: password)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('تم'))],
        ),
      );

  Future<void> _openForm({Teacher? teacher}) async {
    final result = await showModalBottomSheet<_TeacherFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TeacherForm(teacher: teacher),
    );
    if (result == null || !mounted) return;
    final repo = ref.read(teacherRepositoryProvider);
    try {
      if (teacher == null) {
        final created = await repo.createTeacher(fullName: result.name, department: result.department, phone: result.phone);
        if (mounted) await _showPassword('تمت إضافة الحساب', result.name, created.temporaryPassword);
      } else {
        await repo.updateTeacher(teacherId: teacher.id, fullName: result.name, department: result.department, phone: result.phone);
        if (mounted) showAppSnack(context, 'تم حفظ التعديلات', success: true);
      }
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _action(Teacher t, String action) async {
    final repo = ref.read(teacherRepositoryProvider);
    switch (action) {
      case 'edit':
        await _openForm(teacher: t);
      case 'reset':
        final ok = await confirmDialog(
          context,
          title: 'إعادة تعيين الدخول',
          message: 'سيتم تعيين كلمة مرور مؤقتة جديدة لـ ${t.displayName} وتسجيل خروجه من جميع الأجهزة.',
        );
        if (!ok) return;
        try {
          final pwd = await repo.resetPassword(t.id);
          if (mounted) await _showPassword('تمت إعادة التعيين', t.displayName, pwd);
        } on AppFailure catch (e) {
          if (mounted) showAppSnack(context, e.message, error: true);
        }
      case 'toggle':
        await _run(
          () => repo.setActive(teacherId: t.id, active: !t.active),
          t.active ? 'تم إيقاف الحساب' : 'تم تفعيل الحساب',
        );
      case 'delete':
        if (t.studentCount > 0) {
          showAppSnack(context, 'انقل طلاب هذا المعلم أولاً قبل حذف حسابه', error: true);
          return;
        }
        final ok = await confirmDialog(
          context,
          title: 'حذف المعلم',
          message: 'سيتم حذف حساب ${t.displayName} نهائياً. يبقى سجل التسميع السابق محفوظاً.',
          confirmLabel: 'حذف',
          destructive: true,
        );
        if (ok) await _run(() => repo.deleteTeacher(t.id), 'تم حذف الحساب');
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(adminTeachersProvider(_dep));
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المعلمين')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_teacher'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة معلم'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: MaxWidth(
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _q = v),
                    decoration: const InputDecoration(hintText: 'ابحث بالاسم...', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Department?>(
                    segments: [
                      const ButtonSegment(value: null, label: Text('الكل')),
                      for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label)),
                    ],
                    selected: {_dep},
                    onSelectionChanged: (s) => setState(() => _dep = s.first),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<Teacher>>(
              value: teachers,
              data: (list) {
                final q = Fmt.searchKey(_q);
                final filtered = list.where((t) => q.isEmpty || Fmt.searchKey(t.displayName).contains(q)).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.badge_rounded,
                    title: list.isEmpty ? 'لا يوجد معلمون بعد' : 'لا توجد نتائج',
                    message: list.isEmpty ? 'أضف أول معلم من زر «إضافة معلم».' : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t = filtered[i];
                    return MaxWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            leading: NameAvatar(t.displayName, color: t.active ? AppColors.emerald : AppColors.inkSoft),
                            title: Text(t.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              '${t.departmentId.label} • ${Fmt.digits(t.studentCount)} طالب${t.active ? '' : ' • موقوف'}',
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'خيارات',
                              onSelected: (a) => _action(t, a),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                                const PopupMenuItem(value: 'reset', child: Text('إعادة تعيين كلمة المرور')),
                                PopupMenuItem(value: 'toggle', child: Text(t.active ? 'إيقاف الحساب' : 'تفعيل الحساب')),
                                const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: AppColors.danger))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherFormResult {
  const _TeacherFormResult(this.name, this.department, this.phone);
  final String name;
  final Department department;
  final String? phone;
}

class _TeacherForm extends StatefulWidget {
  const _TeacherForm({this.teacher});
  final Teacher? teacher;

  @override
  State<_TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<_TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.teacher?.displayName);
  late final _phone = TextEditingController(text: widget.teacher?.phone);
  late Department _dep = widget.teacher?.departmentId ?? Department.male;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.teacher != null;
    final firstName = _name.text.trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(editing ? 'تعديل بيانات المعلم' : 'إضافة معلم جديد', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('teacher_name'),
                controller: _name,
                validator: Validators.personName,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_rounded)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رقم الجوال (اختياري)', prefixIcon: Icon(Icons.phone_rounded)),
              ),
              const SizedBox(height: 12),
              const Text('القسم', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SegmentedButton<Department>(
                segments: [for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label))],
                selected: {_dep},
                onSelectionChanged: (s) => setState(() => _dep = s.first),
              ),
              if (editing && widget.teacher!.departmentId != _dep && widget.teacher!.studentCount > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('لا يمكن تغيير القسم لمعلم لديه طلاب؛ انقل طلابه أولاً.', style: TextStyle(color: AppColors.danger)),
                ),
              if (!editing && firstName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'كلمة المرور المؤقتة ستكون: $firstName١٢٣ (بالأرقام الإنجليزية: ${firstName}123) ويُلزم بتغييرها عند أول دخول.',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('teacher_save'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, _TeacherFormResult(_name.text.trim(), _dep, _phone.text.trim().isEmpty ? null : _phone.text.trim()));
                },
                child: Text(editing ? 'حفظ' : 'إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

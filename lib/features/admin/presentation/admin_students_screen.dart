import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../auth/domain/enums.dart';
import '../../students/application/student_providers.dart';
import '../../students/data/student_repository.dart';
import '../../students/domain/student.dart';
import '../../teachers/domain/teacher.dart';
import 'admin_dashboard_screen.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  Department? _dep;
  String _q = '';
  String? _teacherId;
  StudentSort _sort = StudentSort.name;
  int _visible = 30;

  Future<void> _add() async {
    final teachers = ref.read(adminTeachersProvider(null)).value ?? const [];
    if (teachers.where((t) => t.active).isEmpty) {
      showAppSnack(context, 'أضف معلماً واحداً على الأقل قبل إضافة الطلاب', error: true);
      return;
    }
    final r = await showModalBottomSheet<_StudentFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StudentForm(teachers: teachers.where((t) => t.active).toList()),
    );
    if (r == null) return;
    try {
      await ref.read(studentRepositoryProvider).addStudent(
            fullName: r.name,
            teacher: r.teacher!,
            guardianPhone: r.phone,
            notes: r.notes,
          );
      if (mounted) showAppSnack(context, 'تمت إضافة الطالب', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _edit(Student s) async {
    final r = await showModalBottomSheet<_StudentFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StudentForm(student: s),
    );
    if (r == null) return;
    try {
      await ref.read(studentRepositoryProvider).updateStudent(id: s.id, fullName: r.name, guardianPhone: r.phone, notes: r.notes);
      if (mounted) showAppSnack(context, 'تم حفظ التعديلات', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _transfer(Student s) async {
    final teachers = (ref.read(adminTeachersProvider(null)).value ?? const <Teacher>[])
        .where((t) => t.active && t.id != s.teacherId)
        .toList();
    final target = await showModalBottomSheet<Teacher>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('نقل ${s.fullName} إلى:', style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final t in teachers)
                ListTile(
                  leading: NameAvatar(t.displayName),
                  title: Text(t.displayName),
                  subtitle: Text(t.departmentId == s.departmentId ? t.departmentId.label : '${t.departmentId.label} (قسم مختلف)'),
                  onTap: () => Navigator.pop(ctx, t),
                ),
              if (teachers.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا يوجد معلمون آخرون')),
            ],
          ),
        ),
      ),
    );
    if (target == null || !mounted) return;
    if (target.departmentId != s.departmentId) {
      final ok = await confirmDialog(
        context,
        title: 'نقل إلى قسم آخر',
        message: 'سينتقل الطالب إلى ${target.departmentId.label}. يبقى سجله السابق محفوظاً باسم معلمه السابق. هل أنت متأكد؟',
      );
      if (!ok) return;
    }
    try {
      await ref.read(studentRepositoryProvider).transferStudent(student: s, newTeacher: target);
      if (mounted) showAppSnack(context, 'تم نقل الطالب إلى ${target.displayName}', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(Student s) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف الطالب',
      message: 'سيتم حذف ملف ${s.fullName}. يبقى سجل التسميع محفوظاً للأرشيف. لا يمكن التراجع.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(studentRepositoryProvider).deleteStudent(s);
      if (mounted) showAppSnack(context, 'تم حذف الطالب', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(allStudentsProvider(_dep));
    final teachers = ref.watch(adminTeachersProvider(_dep)).value ?? const <Teacher>[];
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_student'),
        onPressed: _add,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة طالب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: MaxWidth(
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() {
                      _q = v;
                      _visible = 30;
                    }),
                    decoration: const InputDecoration(hintText: 'ابحث عن طالب...', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Department?>(
                    segments: [
                      const ButtonSegment(value: null, label: Text('الكل')),
                      for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label)),
                    ],
                    selected: {_dep},
                    onSelectionChanged: (s) => setState(() {
                      _dep = s.first;
                      _teacherId = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: teachers.any((t) => t.id == _teacherId) ? _teacherId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'المعلم', isDense: true),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('جميع المعلمين')),
                            for (final t in teachers) DropdownMenuItem(value: t.id, child: Text(t.displayName)),
                          ],
                          onChanged: (v) => setState(() => _teacherId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<StudentSort>(
                        tooltip: 'الترتيب',
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => [for (final s in StudentSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                        child: Chip(avatar: const Icon(Icons.sort_rounded, size: 18), label: Text(_sort.label)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<Student>>(
              value: students,
              data: (raw) {
                final scoped = _teacherId == null ? raw : raw.where((s) => s.teacherId == _teacherId).toList();
                final list = applyStudentQuery(scoped, search: _q, sort: _sort, normalize: Fmt.searchKey);
                if (list.isEmpty) {
                  return EmptyState(icon: Icons.groups_rounded, title: raw.isEmpty ? 'لا يوجد طلاب بعد' : 'لا توجد نتائج');
                }
                final shown = list.take(_visible).toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: shown.length + 1,
                  itemBuilder: (_, i) {
                    if (i == shown.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: list.length > _visible
                              ? OutlinedButton(onPressed: () => setState(() => _visible += 30), child: const Text('عرض المزيد'))
                              : Text('عدد الطلاب: ${Fmt.digits(list.length)}', style: const TextStyle(color: AppColors.inkSoft)),
                        ),
                      );
                    }
                    final s = shown[i];
                    return MaxWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            onTap: () => context.push(Routes.student(s.id)),
                            leading: NameAvatar(s.fullName),
                            title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${s.teacherName} • ${s.departmentId.label} • ${Fmt.points(s.totalPoints)}'),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'خيارات',
                              onSelected: (a) => switch (a) {
                                'edit' => _edit(s),
                                'transfer' => _transfer(s),
                                'delete' => _delete(s),
                                _ => context.push(Routes.student(s.id)),
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'profile', child: Text('عرض السجل')),
                                PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(value: 'transfer', child: Text('نقل إلى معلم آخر')),
                                PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: AppColors.danger))),
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

class _StudentFormResult {
  const _StudentFormResult({required this.name, this.teacher, this.phone, this.notes});
  final String name;
  final Teacher? teacher;
  final String? phone;
  final String? notes;
}

class _StudentForm extends StatefulWidget {
  const _StudentForm({this.student, this.teachers = const []});
  final Student? student;
  final List<Teacher> teachers;

  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.fullName);
  late final _phone = TextEditingController(text: widget.student?.guardianPhone);
  late final _notes = TextEditingController(text: widget.student?.notes);
  Department _dep = Department.male;
  Teacher? _teacher;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null;
    final depTeachers = widget.teachers.where((t) => t.departmentId == _dep).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(editing ? 'تعديل بيانات الطالب' : 'إضافة طالب جديد', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('student_name'),
                controller: _name,
                validator: Validators.personName,
                decoration: const InputDecoration(labelText: 'اسم الطالب', prefixIcon: Icon(Icons.person_rounded)),
              ),
              if (!editing) ...[
                const SizedBox(height: 12),
                SegmentedButton<Department>(
                  segments: [for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label))],
                  selected: {_dep},
                  onSelectionChanged: (s) => setState(() {
                    _dep = s.first;
                    _teacher = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('student_teacher'),
                  initialValue: _teacher?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المعلم المسؤول', prefixIcon: Icon(Icons.badge_rounded)),
                  items: [for (final t in depTeachers) DropdownMenuItem(value: t.id, child: Text(t.displayName))],
                  onChanged: (id) => setState(() => _teacher = depTeachers.firstWhere((t) => t.id == id)),
                  validator: (v) => v == null ? 'يرجى اختيار المعلم' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'جوال ولي الأمر (اختياري)', prefixIcon: Icon(Icons.phone_rounded)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', prefixIcon: Icon(Icons.notes_rounded)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('student_save'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    _StudentFormResult(
                      name: _name.text.trim(),
                      teacher: _teacher,
                      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                    ),
                  );
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

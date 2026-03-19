import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../classrooms/presentation/classrooms_controller.dart';
import '../../data/student_model.dart';
import '../students_controller.dart';

class StudentsPage extends ConsumerWidget {
  const StudentsPage({super.key});

  static const double _actionBottomInset = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isParent = authSession?.isParent == true;
    final isAdmin = authSession?.isAdmin == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Alunos'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isAdmin
          ? Padding(
              padding: const EdgeInsets.only(bottom: _actionBottomInset),
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Novo aluno'),
              ),
            )
          : null,
      body: students.when(
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(studentsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              SectionHeading(
                eyebrow: 'Cadastro',
                title: isParent ? 'Meus alunos' : 'Todos os alunos',
                subtitle: isParent
                    ? 'Visualize apenas os alunos vinculados ao seu usuário.'
                    : 'Acompanhe os registros individuais e crie diários com mais rapidez.',
                trailing: StatusPill(
                  label: '${items.length} alunos',
                  color: const Color(0xFF14304A),
                ),
              ),
              const SizedBox(height: 16),
              MetricCard(
                icon: Icons.people_alt_outlined,
                label: isParent ? 'Alunos vinculados' : 'Alunos cadastrados',
                value: '${items.length}',
                tint: const Color(0xFF14304A),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                EmptyStateCard(
                  icon: Icons.people_outline_rounded,
                  title: isParent ? 'Nenhum aluno vinculado' : 'Nenhum aluno cadastrado',
                  subtitle: isParent
                      ? 'Quando houver vínculo com seu usuário, os alunos aparecerão aqui.'
                      : 'Adicione um aluno e vincule-o a uma turma para continuar.',
                ),
              for (final student in items) ...[
                _StudentCard(
                  student: student,
                  isParent: isParent,
                  onTap: () => context.push('/students/${student.id}'),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar alunos',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final classrooms = await ref.read(classroomRepositoryProvider).list();
    if (classrooms.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cadastre uma turma antes de cadastrar alunos.')));
      }
      return;
    }

    final name = TextEditingController();
    final lastName = TextEditingController();
    final parentName = TextEditingController();
    final parentLastName = TextEditingController();
    final parentContact = TextEditingController();
    DateTime? birthDate;
    String classroomId = classrooms.first.id;
    final formKey = GlobalKey<FormState>();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Novo aluno'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lastName,
                      decoration: const InputDecoration(labelText: 'Sobrenome'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o sobrenome' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: parentName,
                      decoration: const InputDecoration(labelText: 'Nome do responsável'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do responsável' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: parentLastName,
                      decoration: const InputDecoration(labelText: 'Sobrenome do responsável'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o sobrenome do responsável' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: parentContact,
                      decoration: const InputDecoration(labelText: 'Contato do responsável (celular BR)'),
                      keyboardType: TextInputType.phone,
                      validator: _validateParentContact,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: classroomId,
                      decoration: const InputDecoration(labelText: 'Turma'),
                      items: [
                        for (final c in classrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => classroomId = v ?? classroomId,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data de nascimento'),
                      subtitle: Text(birthDate == null ? '-' : birthDate!.toIso8601String().split('T').first),
                      trailing: const Icon(Icons.date_range_outlined),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(now.year - 10),
                          lastDate: now,
                          initialDate: birthDate ?? DateTime(now.year - 3),
                        );
                        if (picked != null) setState(() => birthDate = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Criar'),
              ),
            ],
          ),
        ),
      );

      if (ok == true) {
        try {
          await ref.read(studentRepositoryProvider).create(
                StudentCreateRequest(
                  name: name.text.trim(),
                  lastName: lastName.text.trim(),
                  birthDate: birthDate,
                  classroomId: classroomId,
                  parentName: parentName.text.trim(),
                  parentLastName: parentLastName.text.trim(),
                  parentContact: parentContact.text.trim(),
                ),
              );
          ref.invalidate(studentsByClassroomProvider(classroomId));
          await ref.read(studentsProvider.notifier).refresh();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
          }
        }
      }
    } finally {
      name.dispose();
      lastName.dispose();
      parentName.dispose();
      parentLastName.dispose();
      parentContact.dispose();
    }
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final bool isParent;
  final VoidCallback? onTap;

  const _StudentCard({required this.student, required this.isParent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF14304A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.child_care_outlined, color: Color(0xFF14304A)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Nascimento: ${student.birthDateLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (student.hasPendingParentNotes) ...[
                      const SizedBox(height: 10),
                      StatusPill(
                        label: _pendingNoteLabel(student.pendingParentNoteCount, isParent: isParent),
                        color: const Color(0xFFD96C06),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(width: 12),
            if (onTap != null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

String _pendingNoteLabel(int count, {required bool isParent}) {
  if (count == 1) {
    return isParent ? '1 recado aguardando leitura' : '1 recado novo';
  }
  return isParent ? '$count recados aguardando leitura' : '$count recados novos';
}

String? _validateParentContact(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Informe o contato do responsável';

  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final isValid = RegExp(r'^(55)?[1-9]{2}9\d{8}$').hasMatch(digits);
  if (!isValid) {
    return 'Use celular BR com DDD (ex.: 11988887766)';
  }

  return null;
}

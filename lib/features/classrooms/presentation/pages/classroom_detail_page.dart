import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../students/data/student_model.dart';
import '../../../students/presentation/students_controller.dart';
import '../../data/classroom_model.dart';
import '../classrooms_controller.dart';

class ClassroomDetailPage extends ConsumerStatefulWidget {
  final String classroomId;
  const ClassroomDetailPage({super.key, required this.classroomId});

  @override
  ConsumerState<ClassroomDetailPage> createState() => _ClassroomDetailPageState();
}

class _ClassroomDetailPageState extends ConsumerState<ClassroomDetailPage> {
  final _name = TextEditingController();
  bool? _active;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classroomsAsync = ref.watch(classroomsProvider);
    final studentsAsync = ref.watch(studentsByClassroomProvider(widget.classroomId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isAdmin = authSession?.isAdmin == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Turma')),
      body: classroomsAsync.when(
        data: (items) {
          final classroom = _findClassroom(items, widget.classroomId);
          if (classroom == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.class_outlined,
                  title: 'Turma não encontrada',
                  subtitle: 'Não foi possível localizar a turma selecionada.',
                ),
              ),
            );
          }

          _name.text = _name.text.isEmpty ? classroom.name : _name.text;
          _active ??= classroom.active;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentsByClassroomProvider(widget.classroomId));
              await ref.read(classroomsProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                SectionHeading(
                  eyebrow: 'Turma',
                  title: classroom.name,
                  subtitle: 'Visualize os alunos vinculados e acompanhe o status da turma.',
                  trailing: StatusPill(
                    label: classroom.active ? 'Ativa' : 'Inativa',
                    color: classroom.active ? const Color(0xFF0E7C86) : const Color(0xFFF7A45D),
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin)
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Nome da turma'),
                        ),
                      if (!isAdmin)
                        Text('Nome', style: Theme.of(context).textTheme.titleMedium),
                      if (!isAdmin) ...[
                        const SizedBox(height: 6),
                        Text(classroom.name, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                      const SizedBox(height: 16),
                      if (isAdmin)
                        SwitchListTile(
                          value: _active ?? true,
                          onChanged: (v) => setState(() => _active = v),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Turma ativa'),
                        ),
                      if (!isAdmin) ...[
                        Text('Status', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(classroom.active ? 'Ativa' : 'Inativa', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                      if (isAdmin) ...[
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await ref.read(classroomRepositoryProvider).update(
                                    widget.classroomId,
                                    ClassroomUpdateRequest(name: _name.text.trim(), active: _active ?? true),
                                  );
                              await ref.read(classroomsProvider.notifier).refresh();
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Turma atualizada.')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
                              }
                            }
                          },
                          child: const Text('Salvar alterações'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Excluir turma'),
                                content: const Text('Tem certeza?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              try {
                                await ref.read(classroomRepositoryProvider).remove(widget.classroomId);
                                await ref.read(classroomsProvider.notifier).refresh();
                                if (mounted) context.pop();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir turma'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Alunos da turma', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                studentsAsync.when(
                  data: (students) => _StudentsSection(students: students),
                  error: (e, _) => EmptyStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Falha ao carregar alunos',
                    subtitle: getFriendlyError(e),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar turma',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

Classroom? _findClassroom(List<Classroom> classrooms, String id) {
  for (final classroom in classrooms) {
    if (classroom.id == id) return classroom;
  }
  return null;
}

class _StudentsSection extends StatelessWidget {
  final List<Student> students;

  const _StudentsSection({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum aluno nesta turma',
        subtitle: 'Quando houver alunos vinculados, eles aparecerão aqui.',
      );
    }

    return Column(
      children: [
        for (final student in students) ...[
          SurfaceCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => context.push('/students/${student.id}'),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14304A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.child_friendly_outlined, color: Color(0xFF14304A)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Nascimento: ${student.birthDateLabel}', style: Theme.of(context).textTheme.bodyMedium),
                        if (student.hasPendingParentNotes) ...[
                          const SizedBox(height: 10),
                          StatusPill(
                            label: _pendingClassroomNoteLabel(student.pendingParentNoteCount),
                            color: const Color(0xFFD96C06),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _pendingClassroomNoteLabel(int count) {
  if (count == 1) return '1 recado novo';
  return '$count recados novos';
}

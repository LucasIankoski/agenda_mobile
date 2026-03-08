import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../diaries/presentation/diaries_controller.dart';
import '../../data/student_model.dart';
import '../students_controller.dart';

final studentDetailProvider = FutureProvider.family<Student, String>((ref, id) async {
  return ref.read(studentRepositoryProvider).get(id);
});

class StudentDetailPage extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  static const double _actionBottomInset = 96;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(diariesControllerProvider(widget.studentId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isAdmin = authSession?.isAdmin == true;
    final isParent = authSession?.isParent == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Aluno')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isParent
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: _actionBottomInset),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/diaries/new?studentId=${widget.studentId}');
                  if (!mounted) return;
                  ref.invalidate(diariesControllerProvider(widget.studentId));
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Novo diario'),
              ),
            ),
      body: studentAsync.when(
        data: (student) {
          final diariesAsync = ref.watch(diariesByStudentProvider(widget.studentId));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              SectionHeading(
                eyebrow: 'Perfil',
                title: student.fullName,
                subtitle: 'Nascimento: ${student.birthDateLabel}',
                trailing: const StatusPill(
                  label: 'Aluno',
                  color: Color(0xFF14304A),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (student.parentFullName != null || student.parentPrimaryContact != null || student.parentEmail != null) ...[
                      Text('Responsavel', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      if (student.parentFullName != null) ...[
                        Text(student.parentFullName!, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 6),
                      ],
                      if (student.parentPrimaryContact != null) ...[
                        Text('Contato: ${student.parentPrimaryContact!}', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 6),
                      ],
                      if (student.parentEmail != null && student.parentEmail != student.parentPrimaryContact) ...[
                        Text('Login: ${student.parentEmail!}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 16),
                    ],
                    if (!isParent) ...[
                      Text('Turma vinculada', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(student.classroomId, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Excluir aluno'),
                              content: const Text('Tem certeza?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            try {
                              final classroomId = student.classroomId;
                              await ref.read(studentRepositoryProvider).remove(widget.studentId);
                              ref.invalidate(studentsByClassroomProvider(classroomId));
                              await ref.read(studentsProvider.notifier).refresh();
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
                        label: const Text('Excluir aluno'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Diarios', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              diariesAsync.when(
                data: (page) {
                  if (page.items.isEmpty) {
                    return EmptyStateCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Nenhum diario cadastrado',
                      subtitle: isParent
                          ? 'Ainda nao ha diario registrado para este aluno.'
                          : 'Crie o primeiro diario para registrar a rotina deste aluno.',
                    );
                  }

                  return Column(
                    children: [
                      for (final diary in page.items) ...[
                        SurfaceCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => context.push('/diaries/${diary.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBE2F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF7E9DC6)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(diary.createdAtLabel, style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                      Text(
                                        diary.listSummary,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: page.page <= 0
                                  ? null
                                  : () => ref.read(diariesControllerProvider(widget.studentId).notifier).load(page.page - 1),
                              child: const Text('Anterior'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: page.isLast
                                  ? null
                                  : () => ref.read(diariesControllerProvider(widget.studentId).notifier).load(page.page + 1),
                              child: const Text('Proxima'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                error: (e, _) => EmptyStateCard(
                  icon: Icons.error_outline_rounded,
                  title: 'Falha ao carregar diarios',
                  subtitle: getFriendlyError(e),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar aluno',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

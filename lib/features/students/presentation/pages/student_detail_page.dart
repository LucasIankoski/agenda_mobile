import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../classrooms/data/classroom_model.dart';
import '../../../classrooms/presentation/classrooms_controller.dart';
import '../student_profile_controller.dart';
import '../students_controller.dart';

class StudentDetailPage extends ConsumerWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isAdmin = authSession?.isAdmin == true;
    final isParent = authSession?.isParent == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Aluno')),
      body: studentAsync.when(
        data: (student) {
          final classroomId = student.classroomId.trim();
          final classroomsAsync = isParent ? null : ref.watch(classroomsProvider);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              SectionHeading(
                eyebrow: 'Perfil',
                title: student.fullName,
                subtitle: 'Nascimento: ${student.birthDateLabel}',
                trailing: student.hasPendingParentNotes
                    ? StatusPill(
                        label: _studentSummaryPillLabel(student.pendingParentNoteCount),
                        color: const Color(0xFFD96C06),
                      )
                    : const StatusPill(
                        label: 'Aluno',
                        color: Color(0xFF14304A),
                      ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (student.parentFullName != null ||
                        student.parentPrimaryContact != null ||
                        student.parentEmail != null) ...[
                      Text('Responsável', style: Theme.of(context).textTheme.titleMedium),
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
                      Text(
                        _resolveClassroomName(classroomsAsync, classroomId),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Excluir aluno'),
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
                              final classroomId = student.classroomId;
                              await ref.read(studentRepositoryProvider).remove(studentId);
                              ref.invalidate(studentsByClassroomProvider(classroomId));
                              await ref.read(studentsProvider.notifier).refresh();
                              if (context.mounted) context.pop();
                            } catch (e) {
                              if (context.mounted) {
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
              SectionHeading(
                eyebrow: 'Acessos',
                title: 'Central do aluno',
                subtitle: 'Abra diários, recados e novas áreas do perfil por aqui.',
              ),
              const SizedBox(height: 12),
              _StudentMenuCard(
                icon: Icons.menu_book_rounded,
                title: 'Diários',
                subtitle: isParent
                    ? 'Veja o histórico da rotina e acompanhe os registros.'
                    : 'Consulte os registros e crie novos diários para este aluno.',
                accent: const Color(0xFF7E9DC6),
                onTap: () => context.push('/students/$studentId/diaries'),
              ),
              const SizedBox(height: 12),
              _StudentMenuCard(
                icon: Icons.markunread_mailbox_outlined,
                title: 'Recados',
                subtitle: isParent
                    ? 'Envie avisos para a escola e acompanhe a leitura.'
                    : 'Veja os recados dos responsáveis e sinalize leitura.',
                accent: const Color(0xFFD96C06),
                badgeLabel: student.hasPendingParentNotes
                    ? _studentSummaryPillLabel(student.pendingParentNoteCount)
                    : null,
                onTap: () => context.push('/students/$studentId/notes'),
              ),
              const SizedBox(height: 12),
              _StudentMenuCard(
                icon: Icons.photo_library_outlined,
                title: 'Galeria',
                subtitle: isParent
                    ? 'Veja as fotos publicadas pela escola para este aluno.'
                    : 'Publique fotos deste aluno e mantenha o historico visual atualizado.',
                accent: const Color(0xFF0E7C86),
                onTap: () => context.push('/students/$studentId/gallery'),
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

class _StudentMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? badgeLabel;
  final VoidCallback onTap;

  const _StudentMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (badgeLabel != null)
                        StatusPill(
                          label: badgeLabel!,
                          color: accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

String _studentSummaryPillLabel(int count) {
  if (count == 1) return '1 pendente';
  return '$count pendentes';
}

String _resolveClassroomName(AsyncValue<List<Classroom>>? classroomsAsync, String classroomId) {
  if (classroomsAsync == null || classroomId.isEmpty) return '-';

  return classroomsAsync.when(
    data: (items) {
      for (final classroom in items) {
        if (classroom.id == classroomId) {
          return classroom.name;
        }
      }
      return classroomId;
    },
    error: (error, stackTrace) => classroomId,
    loading: () => 'Carregando turma...',
  );
}

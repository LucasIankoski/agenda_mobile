import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/parent_note_model.dart';
import '../../data/student_model.dart';
import '../parent_notes_controller.dart';
import '../student_profile_controller.dart';
import '../students_controller.dart';

class StudentNotesPage extends ConsumerStatefulWidget {
  final String studentId;

  const StudentNotesPage({super.key, required this.studentId});

  @override
  ConsumerState<StudentNotesPage> createState() => _StudentNotesPageState();
}

class _StudentNotesPageState extends ConsumerState<StudentNotesPage> {
  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isParent = authSession?.isParent == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Recados')),
      body: studentAsync.when(
        data: (student) {
          final notesAsync = ref.watch(parentNotesByStudentProvider(widget.studentId));

          return RefreshIndicator(
            onRefresh: () => _refreshNotes(student),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                PageHeroCard(
                  eyebrow: 'Recados',
                  title: student.fullName,
                  subtitle: isParent
                      ? 'Envie avisos e acompanhe quando a escola visualizar.'
                      : 'Veja os recados enviados pelos responsáveis e marque a leitura com rapidez.',
                  icon: Icons.markunread_mailbox_outlined,
                  accent: const Color(0xFFE99073),
                  trailing: student.hasPendingParentNotes
                      ? StatusPill(
                          label: _studentSummaryPillLabel(student.pendingParentNoteCount),
                          color: const Color(0xFFE99073),
                        )
                      : const StatusPill(
                          label: 'Sem pendências',
                          color: Color(0xFF26978A),
                        ),
                ),
                const SizedBox(height: 12),
                if (isParent) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => _showCreateParentNoteDialog(context, student),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Novo recado'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!isParent && student.hasPendingParentNotes) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _markParentNotesAsRead(context, student),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: Text(_markNotesActionLabel(student.pendingParentNoteCount)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                notesAsync.when(
                  data: (notes) {
                    if (notes.isEmpty) {
                      return EmptyStateCard(
                        icon: Icons.markunread_mailbox_outlined,
                        title: isParent ? 'Nenhum recado enviado' : 'Nenhum recado recebido',
                        subtitle: isParent
                            ? 'Use este espaço para avisos importantes ao professor deste aluno.'
                            : 'Quando um responsável enviar recados, eles aparecerão aqui.',
                      );
                    }

                    return Column(
                      children: [
                        for (final note in notes) ...[
                          _ParentNoteCard(note: note, isParent: isParent),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                  error: (e, _) => EmptyStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Falha ao carregar recados',
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
              title: 'Falha ao carregar aluno',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showCreateParentNoteDialog(BuildContext context, Student student) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Novo recado'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                hintText: 'Ex.: Hoje ele precisa tomar um remédio após o almoço.',
              ),
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Escreva o recado.' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      );

      if (ok != true) return;

      await ref.read(parentNoteRepositoryProvider).create(
            widget.studentId,
            ParentNoteCreateRequest(message: controller.text.trim()),
          );
      await _refreshNotes(student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recado enviado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _markParentNotesAsRead(BuildContext context, Student student) async {
    try {
      await ref.read(parentNoteRepositoryProvider).markAllAsRead(widget.studentId);
      await _refreshNotes(student);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Recados marcados como visualizados.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
      }
    }
  }

  Future<void> _refreshNotes(Student student) async {
    ref.invalidate(parentNotesByStudentProvider(widget.studentId));
    ref.invalidate(studentDetailProvider(widget.studentId));
    if (student.classroomId.trim().isNotEmpty) {
      ref.invalidate(studentsByClassroomProvider(student.classroomId));
    }
    await ref.read(studentsProvider.notifier).refresh();
  }
}

class _ParentNoteCard extends StatelessWidget {
  final ParentNote note;
  final bool isParent;

  const _ParentNoteCard({required this.note, required this.isParent});

  @override
  Widget build(BuildContext context) {
    final statusColor = note.read ? const Color(0xFF26978A) : const Color(0xFFE99073);

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      tint: statusColor.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  note.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.createdAtLabel, style: Theme.of(context).textTheme.titleMedium),
                    if (!isParent && (note.createdByName?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Responsável: ${note.createdByName!}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusPill(
                label: note.read ? 'Visualizado' : 'Novo',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(note.message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text(
            _parentNoteFooterLabel(note, isParent: isParent),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667A91),
                ),
          ),
        ],
      ),
    );
  }
}

String _studentSummaryPillLabel(int count) {
  if (count == 1) return '1 pendente';
  return '$count pendentes';
}

String _markNotesActionLabel(int count) {
  if (count == 1) {
    return 'Marcar 1 recado como visualizado';
  }
  return 'Marcar $count recados como visualizados';
}

String _parentNoteFooterLabel(ParentNote note, {required bool isParent}) {
  if (note.read) {
    if (note.readAtLabel != null) {
      return 'Visualizado pela escola em ${note.readAtLabel!}.';
    }
    return 'Visualizado pela escola.';
  }

  return isParent ? 'Aguardando visualização da escola.' : 'Recado pendente para a equipe.';
}

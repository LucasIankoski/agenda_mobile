import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_logo.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/classroom_model.dart';
import '../classrooms_controller.dart';

class ClassroomsPage extends ConsumerWidget {
  const ClassroomsPage({super.key});

  static const double _actionBottomInset = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsProvider);
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isAdmin = authSession?.isAdmin == true;
    final isCompact = MediaQuery.sizeOf(context).width < 480;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppLogo(size: 34, showWordmark: true),
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
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova turma'),
              ),
            )
          : null,
      body: classrooms.when(
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(classroomsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              PageHeroCard(
                eyebrow: 'Turmas',
                title: 'Abra uma turma',
                subtitle: isCompact
                    ? 'Veja alunos e registros com poucos toques.'
                    : 'Acesse uma turma para acompanhar alunos, status e registros do dia a dia.',
                icon: Icons.class_outlined,
                accent: const Color(0xFF255A84),
                trailing: StatusPill(
                  label: '${items.length} total',
                  color: const Color(0xFF1F7A6E),
                ),
                badges: [
                  StatusPill(
                    label: '${items.where((item) => item.active).length} ativas',
                    color: const Color(0xFF1F7A6E),
                  ),
                  if (isAdmin)
                    const StatusPill(
                      label: 'Gestão liberada',
                      color: Color(0xFF16324A),
                    ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 170,
                      child: MetricCard(
                        icon: Icons.class_outlined,
                        label: 'Turmas ativas',
                        value: '${items.where((item) => item.active).length}',
                        tint: const Color(0xFF1F7A6E),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: MetricCard(
                        icon: Icons.pause_circle_outline_rounded,
                        label: 'Turmas inativas',
                        value: '${items.where((item) => !item.active).length}',
                        tint: const Color(0xFFBE4A3A),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (items.isEmpty)
                const EmptyStateCard(
                  icon: Icons.class_outlined,
                  title: 'Nenhuma turma cadastrada',
                  subtitle: 'Crie a primeira turma para começar a organizar os alunos.',
                ),
              for (final classroom in items) ...[
                _ClassroomCard(classroom: classroom),
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
              title: 'Falha ao carregar turmas',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nova turma'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      );

      if (ok == true) {
        try {
          await ref.read(classroomRepositoryProvider).create(ClassroomCreateRequest(controller.text.trim()));
          await ref.read(classroomsProvider.notifier).refresh();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
          }
        }
      }
    } finally {
      controller.dispose();
    }
  }
}

class _ClassroomCard extends StatelessWidget {
  final Classroom classroom;

  const _ClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final accent = classroom.active ? const Color(0xFF1F7A6E) : const Color(0xFFBE4A3A);

    return SurfaceCard(
      borderColor: accent.withValues(alpha: 0.14),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/classrooms/${classroom.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.auto_stories_outlined, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(classroom.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    classroom.active
                        ? 'Pronta para acompanhar alunos e registros.'
                        : 'Disponível para consulta e revisão.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    label: classroom.active ? 'Ativa' : 'Inativa',
                    color: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

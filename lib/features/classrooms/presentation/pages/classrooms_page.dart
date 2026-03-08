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
              SectionHeading(
                eyebrow: 'Painel',
                title: 'Turmas cadastradas',
                subtitle: 'Selecione uma turma para visualizar alunos e detalhes.',
                trailing: StatusPill(
                  label: '${items.length} total',
                  color: const Color(0xFF0E7C86),
                ),
              ),
              const SizedBox(height: 16),
              MetricCard(
                icon: Icons.class_outlined,
                label: 'Turmas ativas',
                value: '${items.where((item) => item.active).length}',
                tint: const Color(0xFF0E7C86),
              ),
              const SizedBox(height: 14),
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
    final accent = classroom.active ? const Color(0xFF0E7C86) : const Color(0xFFF7A45D);

    return SurfaceCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/classrooms/${classroom.id}'),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
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
                  StatusPill(
                    label: classroom.active ? 'Ativa' : 'Inativa',
                    color: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../diaries/presentation/diaries_controller.dart';
import '../student_profile_controller.dart';

class StudentDiariesPage extends ConsumerWidget {
  final String studentId;

  const StudentDiariesPage({super.key, required this.studentId});

  static const double _actionBottomInset = 96;
  static const double _actionButtonHeight = 56;
  static const double _contentBottomSpacing = _actionBottomInset + _actionButtonHeight + 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isParent = authSession?.isParent == true;
    final contentBottomPadding = isParent ? 120.0 : _contentBottomSpacing;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Diários')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isParent
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: _actionBottomInset),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/diaries/new?studentId=$studentId');
                  ref.invalidate(diariesControllerProvider(studentId));
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Novo diário'),
              ),
            ),
      body: studentAsync.when(
        data: (student) {
          final diariesAsync = ref.watch(diariesByStudentProvider(studentId));

          return diariesAsync.when(
            data: (page) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(diariesControllerProvider(studentId));
                ref.invalidate(studentDetailProvider(studentId));
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, contentBottomPadding),
                children: [
                  SectionHeading(
                    eyebrow: 'Diários',
                    title: student.fullName,
                    subtitle: isParent
                        ? 'Acompanhe os diários registrados para este aluno.'
                        : 'Consulte o histórico e crie novos diários para este aluno.',
                    trailing: StatusPill(
                      label: '${page.totalElements} registros',
                      color: const Color(0xFF7E9DC6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (page.items.isEmpty)
                    EmptyStateCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Nenhum diário cadastrado',
                      subtitle: isParent
                          ? 'Ainda não há diário registrado para este aluno.'
                          : 'Crie o primeiro diário para registrar a rotina deste aluno.',
                    ),
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
                  if (page.items.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: page.page <= 0
                                ? null
                                : () => ref.read(diariesControllerProvider(studentId).notifier).load(page.page - 1),
                            child: const Text('Anterior'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: page.isLast
                                ? null
                                : () => ref.read(diariesControllerProvider(studentId).notifier).load(page.page + 1),
                            child: const Text('Próxima'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.error_outline_rounded,
                  title: 'Falha ao carregar diários',
                  subtitle: getFriendlyError(e),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
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

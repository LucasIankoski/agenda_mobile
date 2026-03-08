import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../data/diary_models.dart';
import '../diaries_controller.dart';

final diaryDetailProvider = FutureProvider.family<Diary, String>((ref, id) async {
  return ref.read(diaryRepositoryProvider).get(id);
});

class DiaryDetailPage extends ConsumerWidget {
  final String diaryId;
  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryAsync = ref.watch(diaryDetailProvider(diaryId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Diário')),
      body: diaryAsync.when(
        data: (diary) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
          children: [
            SectionHeading(
              eyebrow: 'Registro',
              title: diary.createdAtLabel,
              subtitle: 'Criado por ${diary.createdByName}',
              trailing: StatusPill(
                label: diary.read ? 'Lido' : 'Novo',
                color: diary.read ? const Color(0xFF7E9DC6) : const Color(0xFFAEB9CF),
              ),
            ),
            const SizedBox(height: 12),
            _DiaryReader(diary: diary),
          ],
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar diário',
              subtitle: _friendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _friendlyError(Object e) {
  if (e is AppException) return e.message;
  return 'Erro inesperado.';
}

class _DiaryReader extends StatelessWidget {
  final Diary diary;

  const _DiaryReader({required this.diary});

  @override
  Widget build(BuildContext context) {
    final payload = diary.payload;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F8),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFD7DBE6)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _DiaryInfoCard(
                icon: Icons.restaurant_rounded,
                title: 'Alimentação',
                child: _ReadOnlyMealGrid(meals: payload.meals),
              ),
              const SizedBox(height: 10),
              _DiaryInfoCard(
                icon: Icons.bedtime_rounded,
                title: 'Sono',
                child: Column(
                  children: [
                    _ReadOnlySleepRow(label: 'Manhã', period: payload.sleep.morning),
                    const SizedBox(height: 8),
                    _ReadOnlySleepRow(label: 'Tarde', period: payload.sleep.afternoon),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DiaryInfoCard(
                icon: Icons.extension_rounded,
                title: 'Propostas pedagógicas',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReadOnlyCheck(label: 'Ativ. pedagógica', value: payload.pedagogicalProposals.pedagogicalActivity),
                    _ReadOnlyCheck(label: 'Música', value: payload.pedagogicalProposals.music),
                    _ReadOnlyCheck(label: 'Pátio', value: payload.pedagogicalProposals.patio),
                    _ReadOnlyCheck(label: 'Brincadeira livre', value: payload.pedagogicalProposals.freePlay),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DiaryInfoCard(
                icon: Icons.opacity_rounded,
                title: 'Necessidades',
                child: Column(
                  children: [
                    _ReadOnlyNeedRow(label: 'Xixi', need: payload.needs.pee),
                    const SizedBox(height: 8),
                    _ReadOnlyNeedRow(label: 'Cocô', need: payload.needs.poop),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DiaryInfoCard(
                icon: Icons.check_box_rounded,
                title: 'Trazer amanhã',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReadOnlyCheck(label: 'Fralda', value: payload.bringTomorrow.diaper),
                        _ReadOnlyCheck(label: 'Lenço', value: payload.bringTomorrow.wipes),
                        _ReadOnlyCheck(label: 'Pomada', value: payload.bringTomorrow.ointment),
                        _ReadOnlyCheck(label: 'Pasta de dente', value: payload.bringTomorrow.toothpaste),
                      ],
                    ),
                    if (payload.bringTomorrow.other?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Outro: ${payload.bringTomorrow.other!}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DiaryInfoCard(
                icon: Icons.edit_note_rounded,
                title: 'Recado da professora',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payload.teacherNote?.trim().isNotEmpty == true
                        ? payload.teacherNote!
                        : 'Sem recado registrado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DiaryInfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDFE3ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EAF2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF96A3BC)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF4F5F7B))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyMealGrid extends StatelessWidget {
  final DiaryMealGroup meals;

  const _ReadOnlyMealGrid({required this.meals});

  @override
  Widget build(BuildContext context) {
    const columns = [
      MealAmount.bem,
      MealAmount.metade,
      MealAmount.menosDaMetade,
      MealAmount.recusou,
    ];

    Widget buildRow(String label, MealAmount? selected) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(width: 104, child: Text(label)),
            for (final item in columns)
              Expanded(
                child: Icon(
                  selected == item ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected == item ? const Color(0xFF7E9DC6) : const Color(0xFFC0C7D7),
                  size: 22,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 112),
            for (final item in columns)
              Expanded(
                child: Text(
                  mealAmountLabel(item),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5F6981),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        buildRow('Café da manhã', meals.breakfast),
        buildRow('Almoço', meals.lunch),
        buildRow('Mamadeira', meals.bottle),
        buildRow('Fruta', meals.fruit),
        buildRow('Janta', meals.dinner),
        buildRow('Ceia', meals.supper),
      ],
    );
  }
}

class _ReadOnlySleepRow extends StatelessWidget {
  final String label;
  final DiarySleepPeriod period;

  const _ReadOnlySleepRow({
    required this.label,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
          StatusPill(
            label: period.summary,
            color: period.slept ? const Color(0xFF7E9DC6) : const Color(0xFF9EA8BA),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyCheck extends StatelessWidget {
  final String label;
  final bool value;

  const _ReadOnlyCheck({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFDDE6F5) : const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 18,
            color: value ? const Color(0xFF7E9DC6) : const Color(0xFFA9B2C6),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyNeedRow extends StatelessWidget {
  final String label;
  final DiaryCountableNeed need;

  const _ReadOnlyNeedRow({
    required this.label,
    required this.need,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  need.selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: need.selected ? const Color(0xFF7E9DC6) : const Color(0xFFA9B2C6),
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EAF3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${need.count}', style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

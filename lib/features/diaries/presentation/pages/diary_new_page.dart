import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../students/presentation/students_controller.dart';
import '../../data/diary_models.dart';
import '../diaries_controller.dart';

class DiaryNewPage extends ConsumerStatefulWidget {
  final String? prefilledStudentId;
  const DiaryNewPage({super.key, this.prefilledStudentId});

  @override
  ConsumerState<DiaryNewPage> createState() => _DiaryNewPageState();
}

class _DiaryNewPageState extends ConsumerState<DiaryNewPage> {
  static const double _actionBottomInset = 96;

  String? _studentId;
  final _teacherNote = TextEditingController();
  final _bringOther = TextEditingController();

  MealAmount? _breakfast;
  MealAmount? _lunch;
  MealAmount? _bottle;
  MealAmount? _fruit;
  MealAmount? _dinner;
  MealAmount? _supper;

  bool _morningSlept = true;
  DiaryClockTime? _morningStart = const DiaryClockTime(hour: 10, minute: 30);
  DiaryClockTime? _morningEnd = const DiaryClockTime(hour: 11, minute: 0);
  bool _afternoonSlept = false;
  DiaryClockTime? _afternoonStart;
  DiaryClockTime? _afternoonEnd;

  bool _pedagogicalActivity = true;
  bool _music = true;
  bool _patio = false;
  bool _freePlay = false;

  bool _peeSelected = true;
  int _peeCount = 1;
  bool _poopSelected = false;
  int _poopCount = 0;

  bool _bringDiaper = false;
  bool _bringWipes = false;
  bool _bringOintment = false;
  bool _bringToothpaste = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.prefilledStudentId;
  }

  @override
  void dispose() {
    _teacherNote.dispose();
    _bringOther.dispose();
    super.dispose();
  }

  DiaryV2Payload get _payload => DiaryV2Payload(
        meals: DiaryMealGroup(
          breakfast: _breakfast,
          lunch: _lunch,
          bottle: _bottle,
          fruit: _fruit,
          dinner: _dinner,
          supper: _supper,
        ),
        sleep: DiarySleepGroup(
          morning: DiarySleepPeriod(
            slept: _morningSlept,
            startTime: _morningSlept ? _morningStart : null,
            endTime: _morningSlept ? _morningEnd : null,
          ),
          afternoon: DiarySleepPeriod(
            slept: _afternoonSlept,
            startTime: _afternoonSlept ? _afternoonStart : null,
            endTime: _afternoonSlept ? _afternoonEnd : null,
          ),
        ),
        pedagogicalProposals: DiaryPedagogicalProposals(
          pedagogicalActivity: _pedagogicalActivity,
          music: _music,
          patio: _patio,
          freePlay: _freePlay,
        ),
        needs: DiaryNeeds(
          pee: DiaryCountableNeed(selected: _peeSelected, count: _peeSelected ? _peeCount : 0),
          poop: DiaryCountableNeed(selected: _poopSelected, count: _poopSelected ? _poopCount : 0),
        ),
        bringTomorrow: DiaryBringTomorrow(
          diaper: _bringDiaper,
          wipes: _bringWipes,
          ointment: _bringOintment,
          toothpaste: _bringToothpaste,
          other: _bringOther.text.trim().isEmpty ? null : _bringOther.text.trim(),
        ),
        teacherNote: _teacherNote.text.trim().isEmpty ? null : _teacherNote.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Diário')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: _actionBottomInset),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              if (_studentId == null) return;
              try {
                await ref.read(diaryRepositoryProvider).create(
                      DiaryCreateRequest(
                        studentId: _studentId!,
                        payload: _payload,
                      ),
                    );
                ref.invalidate(diariesControllerProvider(_studentId!));
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
                }
              }
            },
            child: const Text('Salvar diário'),
          ),
        ),
      ),
      body: students.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Nenhum aluno disponível',
                  subtitle: 'Cadastre um aluno antes de criar um diário.',
                ),
              ),
            );
          }

          _studentId ??= items.first.id;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 190),
            children: [
              _DiaryShell(
                child: Column(
                  children: [
                    _DiaryTopHeader(
                      child: DropdownButtonFormField<String>(
                        initialValue: _studentId,
                        decoration: const InputDecoration(
                          labelText: 'Aluno',
                          isDense: true,
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: [
                          for (final s in items) DropdownMenuItem(value: s.id, child: Text(s.fullName)),
                        ],
                        onChanged: (value) => setState(() => _studentId = value),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DiarySectionCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Alimentação',
                      child: _MealGrid(
                        breakfast: _breakfast,
                        lunch: _lunch,
                        bottle: _bottle,
                        fruit: _fruit,
                        dinner: _dinner,
                        supper: _supper,
                        onChanged: (mealKey, value) {
                          setState(() {
                            switch (mealKey) {
                              case _MealKey.breakfast:
                                _breakfast = value;
                                break;
                              case _MealKey.lunch:
                                _lunch = value;
                                break;
                              case _MealKey.bottle:
                                _bottle = value;
                                break;
                              case _MealKey.fruit:
                                _fruit = value;
                                break;
                              case _MealKey.dinner:
                                _dinner = value;
                                break;
                              case _MealKey.supper:
                                _supper = value;
                                break;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DiarySectionCard(
                      icon: Icons.bedtime_rounded,
                      title: 'Sono',
                      child: Column(
                        children: [
                          _SleepEditor(
                            label: 'Manhã',
                            slept: _morningSlept,
                            start: _morningStart,
                            end: _morningEnd,
                            onToggle: (value) => setState(() {
                              _morningSlept = value;
                              if (!value) {
                                _morningStart = null;
                                _morningEnd = null;
                              } else {
                                _morningStart ??= const DiaryClockTime(hour: 10, minute: 30);
                                _morningEnd ??= const DiaryClockTime(hour: 11, minute: 0);
                              }
                            }),
                            onPickStart: () async {
                              final picked = await _pickClock(context, _morningStart);
                              if (picked != null) setState(() => _morningStart = picked);
                            },
                            onPickEnd: () async {
                              final picked = await _pickClock(context, _morningEnd);
                              if (picked != null) setState(() => _morningEnd = picked);
                            },
                          ),
                          const SizedBox(height: 10),
                          _SleepEditor(
                            label: 'Tarde',
                            slept: _afternoonSlept,
                            start: _afternoonStart,
                            end: _afternoonEnd,
                            onToggle: (value) => setState(() {
                              _afternoonSlept = value;
                              if (!value) {
                                _afternoonStart = null;
                                _afternoonEnd = null;
                              } else {
                                _afternoonStart ??= const DiaryClockTime(hour: 13, minute: 30);
                                _afternoonEnd ??= const DiaryClockTime(hour: 15, minute: 0);
                              }
                            }),
                            onPickStart: () async {
                              final picked = await _pickClock(context, _afternoonStart);
                              if (picked != null) setState(() => _afternoonStart = picked);
                            },
                            onPickEnd: () async {
                              final picked = await _pickClock(context, _afternoonEnd);
                              if (picked != null) setState(() => _afternoonEnd = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DiarySectionCard(
                      icon: Icons.extension_rounded,
                      title: 'Propostas pedagógicas',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _CheckPill(
                            label: 'Ativ. pedagógica',
                            value: _pedagogicalActivity,
                            onChanged: (value) => setState(() => _pedagogicalActivity = value),
                          ),
                          _CheckPill(
                            label: 'Música',
                            value: _music,
                            onChanged: (value) => setState(() => _music = value),
                          ),
                          _CheckPill(
                            label: 'Pátio',
                            value: _patio,
                            onChanged: (value) => setState(() => _patio = value),
                          ),
                          _CheckPill(
                            label: 'Brincadeira livre',
                            value: _freePlay,
                            onChanged: (value) => setState(() => _freePlay = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stackCards = constraints.maxWidth < 430;

                        if (stackCards) {
                          return Column(
                            children: [
                              _buildNeedsCard(),
                              const SizedBox(height: 10),
                              _buildBringTomorrowCard(),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNeedsCard()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildBringTomorrowCard()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _DiarySectionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Recado da professora',
                      child: TextField(
                        controller: _teacherNote,
                        minLines: 3,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Escreva um recado para a família.',
                          filled: true,
                        ),
                      ),
                    ),
                  ],
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
              title: 'Falha ao carregar alunos',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildNeedsCard() {
    return _DiarySectionCard(
      icon: Icons.opacity_rounded,
      title: 'Necessidades',
      child: Column(
        children: [
          _NeedCounterRow(
            label: 'Xixi',
            value: _peeSelected,
            count: _peeCount,
            onChanged: (value) => setState(() {
              _peeSelected = value;
              if (!value) _peeCount = 0;
              if (value && _peeCount == 0) _peeCount = 1;
            }),
            onDecrease: () => setState(() {
              if (_peeCount > 1) _peeCount--;
            }),
            onIncrease: () => setState(() {
              _peeCount++;
              _peeSelected = true;
            }),
          ),
          const SizedBox(height: 8),
          _NeedCounterRow(
            label: 'Cocô',
            value: _poopSelected,
            count: _poopCount,
            onChanged: (value) => setState(() {
              _poopSelected = value;
              if (!value) _poopCount = 0;
              if (value && _poopCount == 0) _poopCount = 1;
            }),
            onDecrease: () => setState(() {
              if (_poopCount > 1) _poopCount--;
            }),
            onIncrease: () => setState(() {
              _poopCount++;
              _poopSelected = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBringTomorrowCard() {
    return _DiarySectionCard(
      icon: Icons.check_box_rounded,
      title: 'Trazer amanhã',
      child: Column(
        children: [
          _SimpleCheckboxRow(
            label: 'Fralda',
            value: _bringDiaper,
            onChanged: (value) => setState(() => _bringDiaper = value),
          ),
          _SimpleCheckboxRow(
            label: 'Lenço',
            value: _bringWipes,
            onChanged: (value) => setState(() => _bringWipes = value),
          ),
          _SimpleCheckboxRow(
            label: 'Pomada',
            value: _bringOintment,
            onChanged: (value) => setState(() => _bringOintment = value),
          ),
          _SimpleCheckboxRow(
            label: 'Pasta de dente',
            value: _bringToothpaste,
            onChanged: (value) => setState(() => _bringToothpaste = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bringOther,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Outro',
              hintText: 'Ex.: fantasia, roupa extra...',
            ),
          ),
        ],
      ),
    );
  }

  Future<DiaryClockTime?> _pickClock(BuildContext context, DiaryClockTime? initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial?.hour ?? 10, minute: initial?.minute ?? 0),
    );
    if (picked == null) return null;
    return DiaryClockTime(hour: picked.hour, minute: picked.minute);
  }
}

class _DiaryShell extends StatelessWidget {
  final Widget child;

  const _DiaryShell({required this.child});

  @override
  Widget build(BuildContext context) {
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
          child: child,
        ),
      ),
    );
  }
}

class _DiaryTopHeader extends StatelessWidget {
  final Widget child;

  const _DiaryTopHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7EAF2),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.assignment_ind_rounded, color: Color(0xFF7D8EAE)),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DiarySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DiarySectionCard({
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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          color: const Color(0xFF4F5F7B),
                        ),
                  ),
                ),
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

enum _MealKey { breakfast, lunch, bottle, fruit, dinner, supper }

class _MealGrid extends StatelessWidget {
  final MealAmount? breakfast;
  final MealAmount? lunch;
  final MealAmount? bottle;
  final MealAmount? fruit;
  final MealAmount? dinner;
  final MealAmount? supper;
  final void Function(_MealKey mealKey, MealAmount value) onChanged;

  const _MealGrid({
    required this.breakfast,
    required this.lunch,
    required this.bottle,
    required this.fruit,
    required this.dinner,
    required this.supper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const columns = [
      MealAmount.bem,
      MealAmount.metade,
      MealAmount.menosDaMetade,
      MealAmount.recusou,
    ];

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
        _MealRow(label: 'Café da manhã', selected: breakfast, mealKey: _MealKey.breakfast, onChanged: onChanged),
        _MealRow(label: 'Almoço', selected: lunch, mealKey: _MealKey.lunch, onChanged: onChanged),
        _MealRow(label: 'Mamadeira', selected: bottle, mealKey: _MealKey.bottle, onChanged: onChanged),
        _MealRow(label: 'Fruta', selected: fruit, mealKey: _MealKey.fruit, onChanged: onChanged),
        _MealRow(label: 'Janta', selected: dinner, mealKey: _MealKey.dinner, onChanged: onChanged),
        _MealRow(label: 'Ceia', selected: supper, mealKey: _MealKey.supper, onChanged: onChanged),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  final String label;
  final MealAmount? selected;
  final _MealKey mealKey;
  final void Function(_MealKey mealKey, MealAmount value) onChanged;

  const _MealRow({
    required this.label,
    required this.selected,
    required this.mealKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const columns = [
      MealAmount.bem,
      MealAmount.metade,
      MealAmount.menosDaMetade,
      MealAmount.recusou,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final item in columns)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(mealKey, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    selected == item ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected == item ? const Color(0xFF7E9DC6) : const Color(0xFFC0C7D7),
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SleepEditor extends StatelessWidget {
  final String label;
  final bool slept;
  final DiaryClockTime? start;
  final DiaryClockTime? end;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _SleepEditor({
    required this.label,
    required this.slept,
    required this.start,
    required this.end,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: slept,
                  onChanged: (value) => onToggle(value ?? false),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dormiu'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: !slept,
                  onChanged: (value) => onToggle(!(value ?? false)),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Não dormiu'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
          if (slept)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TimeChip(label: start?.label ?? '--:--', onTap: onPickStart),
                Text(
                  'até',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                _TimeChip(label: end?.label ?? '--:--', onTap: onPickEnd),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E6F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckPill({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _NeedCounterRow extends StatelessWidget {
  final String label;
  final bool value;
  final int count;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _NeedCounterRow({
    required this.label,
    required this.value,
    required this.count,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackContent = constraints.maxWidth < 210;
        final labelToggle = InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: (selected) => onChanged(selected ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    label,
                    maxLines: stackContent ? 2 : 1,
                    overflow: stackContent ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

        final counter = _CounterBox(
          count: count,
          enabled: value,
          onDecrease: onDecrease,
          onIncrease: onIncrease,
        );

        if (stackContent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelToggle,
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: counter,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: labelToggle),
            const SizedBox(width: 8),
            counter,
          ],
        );
      },
    );
  }
}

class _CounterBox extends StatelessWidget {
  final int count;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CounterBox({
    required this.count,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled ? onDecrease : null,
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
          ),
          Text('$count', style: Theme.of(context).textTheme.titleSmall),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SimpleCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SimpleCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (selected) => onChanged(selected ?? false),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

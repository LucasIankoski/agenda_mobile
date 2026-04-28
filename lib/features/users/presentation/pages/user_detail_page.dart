import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/user_model.dart';
import '../users_controller.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  bool _isDisabling = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Usuário')),
      body: userAsync.when(
        data: (user) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userDetailProvider(widget.userId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              PageHeroCard(
                eyebrow: 'Detalhes',
                title: user.name,
                subtitle: user.displayEmail,
                icon: _iconForType(user.type),
                accent: _accentForUser(user),
                trailing: StatusPill(
                  label: user.active ? 'Ativo' : 'Inativo',
                  color: user.active ? const Color(0xFF26978A) : const Color(0xFF6C7A90),
                ),
                badges: [
                  StatusPill(label: user.roleLabel, color: _accentForUser(user)),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackCards = constraints.maxWidth < 560;
                  final roleCard = MetricCard(
                    icon: _iconForType(user.type),
                    label: 'Perfil',
                    value: userTypeLabel(user.type),
                    tint: _accentForUser(user),
                  );
                  final statusCard = MetricCard(
                    icon: user.active ? Icons.verified_user_outlined : Icons.block_rounded,
                    label: 'Situação',
                    value: user.active ? 'Ativo' : 'Inativo',
                    tint: user.active ? const Color(0xFF26978A) : const Color(0xFF6C7A90),
                  );

                  if (stackCards) {
                    return Column(
                      children: [
                        roleCard,
                        const SizedBox(height: 12),
                        statusCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: roleCard),
                      const SizedBox(width: 12),
                      Expanded(child: statusCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeading(
                      eyebrow: 'Conta',
                      title: 'Dados do usuário',
                      subtitle: 'Informações disponíveis no backend atual para este perfil.',
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Nome', value: user.name),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'E-mail', value: user.displayEmail),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Tipo', value: user.roleLabel),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'ID', value: user.id),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (user.active)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _isDisabling ? null : () => _disableUser(context, user),
                    icon: _isDisabling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: Text(_isDisabling ? 'Desativando...' : 'Desativar usuário'),
                  ),
                )
              else
                SurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF6C7A90)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: const Text(
                          'Este usuário já está desativado. A reativação ainda não é suportada pelo backend atual.',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar usuário',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _disableUser(BuildContext context, ManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar usuário'),
        content: Text(
          'Deseja desativar o acesso de ${user.name}? Essa operação usa o endpoint atual do backend e não oferece reativação no app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDisabling = true);
    try {
      await ref.read(userRepositoryProvider).disable(user.id);
      ref.invalidate(usersProvider);
      ref.invalidate(userDetailProvider(widget.userId));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} foi desativado(a).')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isDisabling = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF667A91),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

Color _accentForUser(ManagedUser user) {
  if (!user.active) return const Color(0xFF6C7A90);

  return switch (user.type) {
    UserType.superAdmin => const Color(0xFF5A3E85),
    UserType.admin => const Color(0xFF17324B),
    UserType.teacher => const Color(0xFF2E658F),
    UserType.parent => const Color(0xFFE99073),
  };
}

IconData _iconForType(UserType type) {
  return switch (type) {
    UserType.superAdmin => Icons.workspace_premium_outlined,
    UserType.admin => Icons.admin_panel_settings_outlined,
    UserType.teacher => Icons.school_outlined,
    UserType.parent => Icons.family_restroom_outlined,
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/user_model.dart';
import '../users_controller.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  UserType? _roleFilter;
  bool? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          final filteredUsers = _filteredUsers(users);
          final activeCount = users.where((user) => user.active).length;
          final inactiveCount = users.length - activeCount;

          return RefreshIndicator(
            onRefresh: () => ref.read(usersProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                PageHeroCard(
                  eyebrow: 'Administração',
                  title: 'Usuários do sistema',
                  subtitle: 'Consulte perfis cadastrados, filtre por papel e acompanhe quem está ativo com mais clareza.',
                  icon: Icons.manage_accounts_outlined,
                  accent: const Color(0xFF17324B),
                  trailing: StatusPill(
                    label: '${users.length} no total',
                    color: const Color(0xFF2E658F),
                  ),
                  badges: [
                    StatusPill(label: '$activeCount ativos', color: const Color(0xFF26978A)),
                    StatusPill(label: '$inactiveCount inativos', color: const Color(0xFFE99073)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 170,
                      child: MetricCard(
                        icon: Icons.how_to_reg_outlined,
                        label: 'Usuários ativos',
                        value: '$activeCount',
                        tint: const Color(0xFF26978A),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: MetricCard(
                        icon: Icons.person_off_outlined,
                        label: 'Usuários inativos',
                        value: '$inactiveCount',
                        tint: const Color(0xFFE99073),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeading(
                        eyebrow: 'Filtros',
                        title: 'Encontrar um perfil',
                        subtitle: 'Busque por nome, e-mail ou papel e refine por status.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nome, e-mail ou perfil',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Perfil',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _roleFilter == null,
                            onSelected: (_) => setState(() => _roleFilter = null),
                          ),
                          for (final type in UserType.values)
                            ChoiceChip(
                              label: Text(userTypeLabel(type)),
                              selected: _roleFilter == type,
                              onSelected: (_) => setState(() => _roleFilter = type),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _activeFilter == null,
                            onSelected: (_) => setState(() => _activeFilter = null),
                          ),
                          ChoiceChip(
                            label: const Text('Ativos'),
                            selected: _activeFilter == true,
                            onSelected: (_) => setState(() => _activeFilter = true),
                          ),
                          ChoiceChip(
                            label: const Text('Inativos'),
                            selected: _activeFilter == false,
                            onSelected: (_) => setState(() => _activeFilter = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeading(
                  eyebrow: 'Resultados',
                  title: 'Perfis encontrados',
                  subtitle: 'A lista prioriza usuários ativos e ordena alfabeticamente dentro de cada grupo.',
                  trailing: StatusPill(
                    label: '${filteredUsers.length} exibidos',
                    color: const Color(0xFF17324B),
                  ),
                ),
                const SizedBox(height: 14),
                if (filteredUsers.isEmpty)
                  EmptyStateCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Nenhum usuário encontrado',
                    subtitle: _hasActiveFilters
                        ? 'Ajuste os filtros para visualizar outros usuários.'
                        : 'Quando houver usuários cadastrados, eles aparecerão aqui.',
                  ),
                for (final user in filteredUsers) ...[
                  _UserCard(
                    user: user,
                    onTap: () => context.push('/users/${user.id}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar usuários',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty || _roleFilter != null || _activeFilter != null;
  }

  List<ManagedUser> _filteredUsers(List<ManagedUser> users) {
    final query = _searchController.text;
    final filtered = users.where((user) {
      if (!user.matchesQuery(query)) return false;
      if (_roleFilter != null && user.type != _roleFilter) return false;
      if (_activeFilter != null && user.active != _activeFilter) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (a.active != b.active) {
        return a.active ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }
}

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentForUser(user);
    final statusColor = user.active ? const Color(0xFF26978A) : const Color(0xFF6C7A90);

    return SurfaceCard(
      tint: accent.withValues(alpha: 0.08),
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
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(_iconForType(user.type), color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    user.displayEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667A91),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(label: user.roleLabel, color: accent),
                      StatusPill(label: user.active ? 'Ativo' : 'Inativo', color: statusColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
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

Color _accentForUser(ManagedUser user) {
  if (!user.active) return const Color(0xFF6C7A90);

  return switch (user.type) {
    UserType.admin => const Color(0xFF17324B),
    UserType.teacher => const Color(0xFF2E658F),
    UserType.parent => const Color(0xFFE99073),
  };
}

IconData _iconForType(UserType type) {
  return switch (type) {
    UserType.admin => Icons.admin_panel_settings_outlined,
    UserType.teacher => Icons.school_outlined,
    UserType.parent => Icons.family_restroom_outlined,
  };
}

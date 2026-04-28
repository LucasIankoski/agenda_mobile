import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/school_model.dart';
import '../platform_controller.dart';

class SchoolsPage extends ConsumerStatefulWidget {
  const SchoolsPage({super.key});

  @override
  ConsumerState<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends ConsumerState<SchoolsPage> {
  bool _creatingSchool = false;

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Escolas'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton.extended(
          onPressed: _creatingSchool ? null : () => _showCreateSchoolDialog(context),
          icon: _creatingSchool
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_rounded),
          label: Text(_creatingSchool ? 'Criando...' : 'Nova escola'),
        ),
      ),
      body: schoolsAsync.when(
        data: (schools) => RefreshIndicator(
          onRefresh: () => ref.read(schoolsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              PageHeroCard(
                eyebrow: 'Plataforma',
                title: 'Escolas cadastradas',
                subtitle: 'Crie uma escola e o primeiro admin dela em uma unica operacao.',
                icon: Icons.apartment_rounded,
                accent: const Color(0xFF5A3E85),
                trailing: StatusPill(
                  label: '${schools.length} no total',
                  color: const Color(0xFF5A3E85),
                ),
                badges: [
                  StatusPill(
                    label: '${schools.where((school) => school.active).length} ativas',
                    color: const Color(0xFF26978A),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (schools.isEmpty)
                const EmptyStateCard(
                  icon: Icons.apartment_rounded,
                  title: 'Nenhuma escola cadastrada',
                  subtitle: 'Crie a primeira escola para liberar o acesso do admin responsavel.',
                ),
              for (final school in schools) ...[
                _SchoolCard(
                  school: school,
                  onCreateAdmin: () => _showCreateAdminDialog(context, school),
                ),
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
              title: 'Falha ao carregar escolas',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showCreateSchoolDialog(BuildContext context) async {
    final schoolNameController = TextEditingController();
    final schoolSlugController = TextEditingController();
    final adminNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final request = await showDialog<PlatformSchoolCreateRequest>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nova escola'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: schoolNameController,
                    decoration: const InputDecoration(labelText: 'Nome da escola'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a escola' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: schoolSlugController,
                    decoration: const InputDecoration(labelText: 'Codigo da escola'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o codigo' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: adminNameController,
                    decoration: const InputDecoration(labelText: 'Nome do admin'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o admin' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminEmailController,
                    decoration: const InputDecoration(labelText: 'E-mail do admin'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminPasswordController,
                    decoration: const InputDecoration(labelText: 'Senha inicial'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe a senha';
                      if (v.trim().length < 5) return 'Use ao menos 5 caracteres';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  PlatformSchoolCreateRequest(
                    schoolName: schoolNameController.text.trim(),
                    schoolSlug: schoolSlugController.text.trim(),
                    adminName: adminNameController.text.trim(),
                    adminEmail: adminEmailController.text.trim(),
                    adminPassword: adminPasswordController.text,
                  ),
                );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      );

      if (request == null || !mounted) return;

      setState(() => _creatingSchool = true);
      try {
        await ref.read(platformRepositoryProvider).createSchool(request);
        await ref.read(schoolsProvider.notifier).refresh();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escola criada com admin inicial.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
      } finally {
        if (mounted) {
          setState(() => _creatingSchool = false);
        }
      }
    } finally {
      schoolNameController.dispose();
      schoolSlugController.dispose();
      adminNameController.dispose();
      adminEmailController.dispose();
      adminPasswordController.dispose();
    }
  }

  Future<void> _showCreateAdminDialog(BuildContext context, ManagedSchool school) async {
    final adminNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final request = await showDialog<SchoolAdminCreateRequest>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Novo admin - ${school.name}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: adminNameController,
                    decoration: const InputDecoration(labelText: 'Nome do admin'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o admin' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminEmailController,
                    decoration: const InputDecoration(labelText: 'E-mail do admin'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminPasswordController,
                    decoration: const InputDecoration(labelText: 'Senha inicial'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe a senha';
                      if (v.trim().length < 5) return 'Use ao menos 5 caracteres';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  SchoolAdminCreateRequest(
                    name: adminNameController.text.trim(),
                    email: adminEmailController.text.trim(),
                    password: adminPasswordController.text,
                  ),
                );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      );

      if (request == null || !mounted) return;

      try {
        await ref.read(platformRepositoryProvider).createAdmin(school.id, request);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin criado para ${school.name}.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
      }
    } finally {
      adminNameController.dispose();
      adminEmailController.dispose();
      adminPasswordController.dispose();
    }
  }
}

class _SchoolCard extends StatelessWidget {
  final ManagedSchool school;
  final VoidCallback onCreateAdmin;

  const _SchoolCard({required this.school, required this.onCreateAdmin});

  @override
  Widget build(BuildContext context) {
    final accent = school.active ? const Color(0xFF5A3E85) : const Color(0xFF6C7A90);

    return SurfaceCard(
      tint: accent.withValues(alpha: 0.08),
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
            child: Icon(Icons.apartment_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  school.slug,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667A91),
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(label: school.active ? 'Ativa' : 'Inativa', color: accent),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                      label: const Text('Novo admin'),
                      onPressed: onCreateAdmin,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

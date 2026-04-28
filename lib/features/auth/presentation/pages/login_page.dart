import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_logo.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../data/auth_models.dart';
import '../auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _platformSlug = 'platform';

  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  String? _selectedSchoolSlug;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final schoolsAsync = ref.watch(loginSchoolOptionsProvider);

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          final msg = getFriendlyError(e);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              final isCompact = constraints.maxWidth < 640;

              final formCard = SurfaceCard(
                padding: EdgeInsets.all(isCompact ? 20 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Entrar', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Use seu e-mail ou celular para continuar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      _SchoolSelector(
                        schoolsAsync: schoolsAsync,
                        selectedSlug: _selectedSchoolSlug,
                        onChanged: (value) => setState(() => _selectedSchoolSlug = value),
                        onRetry: () => ref.invalidate(loginSchoolOptionsProvider),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _login,
                        decoration: const InputDecoration(
                          labelText: 'Login',
                          hintText: 'E-mail ou celular',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o login' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a senha' : null,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  await ref.read(authControllerProvider.notifier).login(
                                        schoolSlug: _selectedSchoolSlug,
                                        login: _login.text.trim(),
                                        password: _password.text,
                                      );
                                },
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(auth.isLoading ? 'Entrando...' : 'Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Seu perfil define automaticamente o que aparece dentro do app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );

              final compactHeader = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 62, showWordmark: true),
                  const SizedBox(height: 18),
                  Text(
                    'Entre para acompanhar a rotina escolar.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Turmas, alunos, diários e recados em uma experiência mais simples e amigável.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );

              final desktopHero = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 76, showWordmark: true),
                  const SizedBox(height: 24),
                  Text(
                    'A rotina escolar com menos ruído e mais clareza.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 38),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Acompanhe turmas, alunos, diários e recados em uma interface mais direta para quem usa o app todos os dias.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  const PageHeroCard(
                    eyebrow: 'Agenda Online',
                    title: 'Tudo importante em poucos toques.',
                    subtitle: 'Admins, professores e responsáveis usam o mesmo app, mas cada perfil enxerga apenas o que faz sentido para sua rotina.',
                    icon: Icons.auto_stories_rounded,
                    accent: Color(0xFF255A84),
                    badges: [
                      StatusPill(label: 'Admin', color: Color(0xFF16324A)),
                      StatusPill(label: 'Professor', color: Color(0xFF255A84)),
                      StatusPill(label: 'Responsável', color: Color(0xFF1F7A6E)),
                    ],
                  ),
                ],
              );

              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: desktopHero),
                        const SizedBox(width: 28),
                        SizedBox(width: 420, child: formCard),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        compactHeader,
                        const SizedBox(height: 18),
                        formCard,
                      ],
                    );

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, isCompact ? 16 : 20, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1040 : 420),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SchoolSelector extends StatelessWidget {
  static const _platformSlug = _LoginPageState._platformSlug;

  final AsyncValue<List<LoginSchoolOption>> schoolsAsync;
  final String? selectedSlug;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  const _SchoolSelector({
    required this.schoolsAsync,
    required this.selectedSlug,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return schoolsAsync.when(
      data: (schools) {
        final options = [
          const LoginSchoolOption(name: 'Administração da plataforma', slug: _platformSlug),
          ...schools,
        ];

        return DropdownButtonFormField<String>(
          value: selectedSlug,
          decoration: const InputDecoration(
            labelText: 'Escola',
            prefixIcon: Icon(Icons.apartment_rounded),
          ),
          items: [
            for (final school in options)
              DropdownMenuItem(
                value: school.slug,
                child: Text(school.name),
              ),
          ],
          onChanged: onChanged,
          validator: (value) => value == null || value.isEmpty ? 'Selecione a escola' : null,
        );
      },
      loading: () => TextFormField(
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'Carregando escolas',
          prefixIcon: Icon(Icons.apartment_rounded),
        ),
      ),
      error: (error, _) => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Falha ao carregar escolas',
          prefixIcon: const Icon(Icons.apartment_rounded),
          suffixIcon: IconButton(
            tooltip: 'Tentar novamente',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ),
    );
  }
}

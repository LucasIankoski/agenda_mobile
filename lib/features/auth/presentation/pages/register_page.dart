import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_logo.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../data/auth_models.dart';
import '../auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserType _type = UserType.parent;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

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
                      Text('Criar conta', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Preencha os dados principais e escolha o tipo de acesso.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nome,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de usuário',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: UserType.parent, child: Text('Responsável')),
                          DropdownMenuItem(value: UserType.teacher, child: Text('Professor')),
                          DropdownMenuItem(value: UserType.admin, child: Text('Admin')),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? UserType.parent),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  await ref.read(authControllerProvider.notifier).register(
                                        nome: _nome.text.trim(),
                                        email: _email.text.trim(),
                                        password: _password.text,
                                        type: _type,
                                      );
                                },
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(auth.isLoading ? 'Criando conta...' : 'Criar conta'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'O perfil escolhido continua determinando as permissões do usuário no app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => context.go('/auth/login'),
                          child: const Text('Já tenho conta'),
                        ),
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
                    'Crie seu acesso de forma simples.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha o perfil certo e continue com a mesma regra de negócio já existente.',
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
                    'Cadastro claro, direto e fácil de entender.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 38),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'O fluxo mantém as permissões atuais da aplicação, mas com uma apresentação mais leve e amigável.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  const PageHeroCard(
                    eyebrow: 'Perfis',
                    title: 'Cada tipo de usuário com o acesso certo.',
                    subtitle: 'Admins, professores e responsáveis continuam seguindo as mesmas regras de negócio, agora com uma experiência mais organizada.',
                    icon: Icons.badge_outlined,
                    accent: Color(0xFF1F7A6E),
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

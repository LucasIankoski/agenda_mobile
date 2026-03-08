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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 78, showWordmark: true),
                    const SizedBox(height: 28),
                    const SurfaceCard(
                      child: SectionHeading(
                        eyebrow: 'Cadastro',
                        title: 'Crie um acesso para administrar a rotina escolar.',
                        subtitle: 'Selecione o tipo de usuário e conclua o cadastro para entrar no app.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SurfaceCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Criar conta',
                              style: Theme.of(context).textTheme.headlineSmall,
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
                              child: FilledButton(
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
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                                      )
                                    : const Text('Criar conta'),
                              ),
                            ),
                            const SizedBox(height: 10),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

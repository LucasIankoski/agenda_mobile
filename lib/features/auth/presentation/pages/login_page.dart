import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_logo.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
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
                        eyebrow: 'Bem-vindo',
                        title: 'Rotina escolar com visual mais claro e rápido.',
                        subtitle: 'Entre na sua conta para acompanhar turmas, alunos e diários.',
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
                              'Entrar',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _login,
                              decoration: const InputDecoration(
                                labelText: 'Login (e-mail ou celular)',
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
                              child: FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        await ref
                                            .read(authControllerProvider.notifier)
                                            .login(login: _login.text.trim(), password: _password.text);
                                      },
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),
                            const SizedBox(height: 10),
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

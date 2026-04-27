import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_logo.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../auth_controller.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);

    return Scaffold(
      body: AppBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 78),
                    const SizedBox(height: 20),
                    const StatusPill(
                      label: 'Sincronizando acesso',
                      color: Color(0xFF2E658F),
                      icon: Icons.cloud_done_outlined,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Agenda Online',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Preparando uma experiência mais clara para turmas, alunos, diários e comunicação com a família.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: const [
                        StatusPill(label: 'Turmas', color: Color(0xFF17324B)),
                        StatusPill(label: 'Diários', color: Color(0xFF26978A)),
                        StatusPill(label: 'Recados', color: Color(0xFFE99073)),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3),
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

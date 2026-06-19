import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';

/// Pantalla mostrada al usuario cuya cuenta fue bloqueada por superar el umbral
/// de reportes falsos. [T-AUTH-07]
class BlockedPage extends ConsumerWidget {
  const BlockedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.blockedAccountTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.blockedAccountBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

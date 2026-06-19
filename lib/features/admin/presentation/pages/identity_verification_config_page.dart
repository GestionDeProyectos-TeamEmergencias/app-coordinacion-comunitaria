import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/identity_verification_config.dart';
import '../providers/identity_verification_config_provider.dart';

/// Panel del administrador para configurar la modalidad de verificación de
/// identidad del vecino. [T-AUTH-09]
class IdentityVerificationConfigPage extends ConsumerStatefulWidget {
  const IdentityVerificationConfigPage({super.key});

  @override
  ConsumerState<IdentityVerificationConfigPage> createState() =>
      _IdentityVerificationConfigPageState();
}

class _IdentityVerificationConfigPageState
    extends ConsumerState<IdentityVerificationConfigPage> {
  IdentityVerificationMode? _selected;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(identityVerificationConfigProvider);
    final isSaving = ref
        .watch(updateIdentityVerificationConfigNotifierProvider)
        .isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.identityVerification)),
      body: configAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          // Inicializa la selección con el valor remoto la primera vez.
          _selected ??= config.mode;
          final current = _selected!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.identityVerificationSubtitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ModeRadioTile(
                  mode: IdentityVerificationMode.manual,
                  groupValue: current,
                  title: AppStrings.identityModeManualLabel,
                  subtitle: AppStrings.identityModeManualDescription,
                  onChanged: (m) => setState(() => _selected = m),
                ),
                const SizedBox(height: 8),
                _ModeRadioTile(
                  mode: IdentityVerificationMode.proofUpload,
                  groupValue: current,
                  title: AppStrings.identityModeProofLabel,
                  subtitle: AppStrings.identityModeProofDescription,
                  onChanged: (m) => setState(() => _selected = m),
                ),
                const Spacer(),
                AppButton(
                  label: 'Guardar configuración',
                  icon: Icons.save,
                  isLoading: isSaving,
                  onPressed: isSaving || current == config.mode
                      ? null
                      : () => _save(current),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(IdentityVerificationMode mode) async {
    await ref
        .read(updateIdentityVerificationConfigNotifierProvider.notifier)
        .updateConfig(IdentityVerificationConfig(mode: mode));

    if (!mounted) return;
    final state = ref.read(updateIdentityVerificationConfigNotifierProvider);
    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.identityConfigUpdated);
    }
  }
}

class _ModeRadioTile extends StatelessWidget {
  const _ModeRadioTile({
    required this.mode,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final IdentityVerificationMode mode;
  final IdentityVerificationMode groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<IdentityVerificationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == groupValue;
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () => onChanged(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

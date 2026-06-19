import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../admin/domain/entities/identity_verification_config.dart';
import '../../../admin/presentation/providers/identity_verification_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/identity_proof_provider.dart';

class PendingApprovalPage extends ConsumerWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final configAsync = ref.watch(identityVerificationConfigProvider);
    final mode = configAsync.valueOrNull?.mode ??
        IdentityVerificationConfig.defaults.mode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                AppStrings.pendingApprovalTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.pendingApprovalBody,
                textAlign: TextAlign.center,
              ),
              if (mode == IdentityVerificationMode.proofUpload &&
                  user != null) ...[
                const SizedBox(height: 32),
                _IdentityProofSection(
                  userId: user.userId,
                  hasProof: user.identityProofUrl != null,
                ),
              ],
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

class _IdentityProofSection extends ConsumerWidget {
  const _IdentityProofSection({
    required this.userId,
    required this.hasProof,
  });

  final String userId;
  final bool hasProof;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(identityProofNotifierProvider);
    final isLoading = state.isLoading;

    return Column(
      children: [
        if (hasProof) ...[
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.identityProofPendingReview,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else ...[
          const Text(
            AppStrings.identityProofRequiredTitle,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.identityProofRequiredBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(hasProof
              ? AppStrings.identityProofReupload
              : AppStrings.identityProofUploadButton),
          onPressed: isLoading ? null : () => _showSourcePicker(context, ref),
        ),
        if (isLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _showSourcePicker(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text(AppStrings.identityProofSourceCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.identityProofSourceGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await _pickAndUpload(context, ref, source);
  }

  Future<void> _pickAndUpload(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null || !context.mounted) return;

    await ref.read(identityProofNotifierProvider.notifier).upload(
          userId: userId,
          photo: File(picked.path),
        );

    if (!context.mounted) return;
    final state = ref.read(identityProofNotifierProvider);
    if (state.hasError) {
      // Muestra el mensaje real del error y deja el genérico como fallback.
      final message = state.error?.toString().isNotEmpty == true
          ? state.error.toString()
          : AppStrings.identityProofUploadError;
      context.showSnackBar(message, isError: true);
    } else {
      context.showSnackBar(AppStrings.identityProofUploaded);
    }
  }
}

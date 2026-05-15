import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/incidents_provider.dart';

// RF-REP-01: botón de reporte rápido. Captura GPS + usuario + timestamp.
// Tiempo objetivo: ≤ 3 segundos (RNF-REN-01 / T-TEST-03).
class QuickReportButton extends ConsumerWidget {
  const QuickReportButton({super.key});

  Future<Position?> _getLocation(BuildContext context) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final granted = await Geolocator.requestPermission();
      if (granted == LocationPermission.denied) {
        if (context.mounted) {
          context.showSnackBar('Permiso de ubicación requerido.', isError: true);
        }
        return null;
      }
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(reportNotifierProvider).isLoading;
    final user = ref.watch(authStateProvider).valueOrNull;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed: (isLoading || user == null)
          ? null
          : () async {
              final position = await _getLocation(context);
              if (position == null || !context.mounted) return;

              await ref.read(reportNotifierProvider.notifier).submitQuick(
                userId: user.userId,
                latitude: position.latitude,
                longitude: position.longitude,
              );

              if (!context.mounted) return;
              final error = ref.read(reportNotifierProvider).error;
              if (error != null) {
                context.showSnackBar(error.toString(), isError: true);
              } else {
                context.showSnackBar(AppStrings.reportSentSuccess);
              }
            },
      icon: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.warning_amber_rounded),
      label: const Text(
        AppStrings.quickReport,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

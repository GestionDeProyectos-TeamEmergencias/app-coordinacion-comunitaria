import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/incidents_provider.dart';

// RF-REP-01: botón de reporte rápido. Captura GPS + usuario + timestamp.
// Tiempo objetivo: ≤ 3 segundos (RNF-REN-01 / T-TEST-03).
class QuickReportButton extends ConsumerStatefulWidget {
  const QuickReportButton({super.key});

  @override
  ConsumerState<QuickReportButton> createState() => _QuickReportButtonState();
}

class _QuickReportButtonState extends ConsumerState<QuickReportButton> {
  bool _isSubmitting = false;

  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationServiceDisabled, isError: true);
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationPermissionPermanentlyDenied,
            isError: true);
        await Geolocator.openAppSettings();
      }
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          context.showSnackBar(AppStrings.locationPermissionRequired,
              isError: true);
        }
        return null;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // medium: triangulación por red (< 500 ms). Cumple RNF-REN-01 ≤ 3 s.
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } on TimeoutException catch (_) {
      if (mounted) {
        context.showSnackBar(AppStrings.errorLocationTimeout, isError: true);
      }
      return null;
    } catch (_) {
      if (mounted) {
        context.showSnackBar(AppStrings.errorLocationUnknown, isError: true);
      }
      return null;
    }
  }

  Future<void> _onPressed(String userId) async {
    setState(() => _isSubmitting = true);
    // Feedback inmediato persistente durante todo el flujo.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(AppStrings.sendingReport),
        duration: Duration(minutes: 1),
      ),
    );
    try {
      final position = await _getLocation();
      if (position == null || !mounted) return;

      await ref.read(reportNotifierProvider.notifier).submitQuick(
            userId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
          );

      if (!mounted) return;
      final error = ref.read(reportNotifierProvider).error;
      if (error != null) {
        context.showSnackBar(error.toString(), isError: true);
      } else {
        context.showSnackBar(AppStrings.reportSentSuccess);
      }
    } finally {
      messenger.hideCurrentSnackBar();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifierIsLoading = ref.watch(reportNotifierProvider).isLoading;
    final user = ref.watch(authStateProvider).valueOrNull;
    final isBusy = _isSubmitting || notifierIsLoading;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed:
          (isBusy || user == null) ? null : () => _onPressed(user.userId),
      icon: isBusy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.warning_amber_rounded),
      label: Text(
        isBusy ? AppStrings.sendingReport : AppStrings.quickReport,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

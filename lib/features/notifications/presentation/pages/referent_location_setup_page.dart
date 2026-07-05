import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Pantalla bloqueante para que el Referente Barrial registre su ubicación de
/// cobertura. Sin `coverageLat`/`coverageLng` en `users/{uid}`, el backend
/// (`findNearbyReferentes`) lo descarta y nunca recibe push. [D-01]
///
/// El router redirige a esta pantalla cuando un usuario activo con rol
/// `referente_barrial` no tiene ubicación seteada.
class ReferentLocationSetupPage extends ConsumerStatefulWidget {
  const ReferentLocationSetupPage({super.key});

  @override
  ConsumerState<ReferentLocationSetupPage> createState() =>
      _ReferentLocationSetupPageState();
}

class _ReferentLocationSetupPageState
    extends ConsumerState<ReferentLocationSetupPage> {
  bool _saving = false;
  String? _error;

  Future<void> _captureAndSave() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const _LocationError('El GPS está desactivado. Activalo.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationError(
          'Permiso de ubicación denegado. Habilitalo desde configuración.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        throw const _LocationError('Sesión expirada.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.userId)
          .update({
        'coverageLat': position.latitude,
        'coverageLng': position.longitude,
      });

      if (!mounted) return;
      context.showSnackBar('Ubicación registrada. ¡Listo!');
      // El router observa el `authStateProvider` y, al actualizarse el doc
      // (stream), saca al user de esta pantalla automáticamente.
    } on _LocationError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo capturar la ubicación.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.my_location,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Registrá tu zona de cobertura',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Como Referente Barrial, necesitamos tu ubicación para enviarte '
                'alertas de incidentes cercanos. Tocá el botón para capturarla '
                'desde tu GPS actual.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AppButton(
                label: 'Capturar mi ubicación',
                icon: Icons.gps_fixed,
                isLoading: _saving,
                onPressed: _saving ? null : _captureAndSave,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: _saving
                    ? null
                    : () => ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationError implements Exception {
  const _LocationError(this.message);
  final String message;
}

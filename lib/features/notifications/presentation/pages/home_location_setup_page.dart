import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Pantalla opt-in para que un vecino registre su ubicación de interés
/// (`homeLat`/`homeLng`). Sin esto, los broadcasts zonales del admin no le
/// llegan — solo los globales.
///
/// Accesible desde Perfil. NO es bloqueante (a diferencia del setup del
/// referente que sí lo es porque sin coverage no recibe nada).
class HomeLocationSetupPage extends ConsumerStatefulWidget {
  const HomeLocationSetupPage({super.key});

  @override
  ConsumerState<HomeLocationSetupPage> createState() =>
      _HomeLocationSetupPageState();
}

class _HomeLocationSetupPageState
    extends ConsumerState<HomeLocationSetupPage> {
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
        'homeLat': position.latitude,
        'homeLng': position.longitude,
      });

      if (!mounted) return;
      context.showSnackBar('Ubicación guardada. ¡Listo!');
      unawaited(Navigator.of(context).maybePop());
    } on _LocationError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo capturar la ubicación.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.userId)
          .update({
        'homeLat': FieldValue.delete(),
        'homeLng': FieldValue.delete(),
      });
      if (!mounted) return;
      context.showSnackBar('Ubicación borrada.');
      unawaited(Navigator.of(context).maybePop());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo borrar la ubicación.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final hasHome = user?.homeLocation != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi ubicación de interés')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.home_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                hasHome
                    ? 'Tenés una ubicación guardada'
                    : 'Definí dónde te interesan los avisos',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Si el Administrador envía un aviso para una zona específica, '
                'lo vas a recibir solo si la zona incluye este punto. Los '
                'avisos generales del barrio te llegan igual.',
                textAlign: TextAlign.center,
              ),
              if (hasHome) ...[
                const SizedBox(height: 12),
                Text(
                  'Lat: ${user!.homeLocation!.latitude.toStringAsFixed(5)}, '
                  'Lng: ${user.homeLocation!.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
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
                label: hasHome
                    ? 'Actualizar con mi ubicación actual'
                    : 'Usar mi ubicación actual',
                icon: Icons.gps_fixed,
                isLoading: _saving,
                onPressed: _saving ? null : _captureAndSave,
              ),
              if (hasHome) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Borrar mi ubicación'),
                  onPressed: _saving ? null : _clear,
                ),
              ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/terms_config.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/terms_provider.dart';

/// Pantalla de Términos y Condiciones. Se usa en dos modos: [D-04]
///
/// * **Gate** (`mode = TermsPageMode.gate`) — onboarding obligatorio.
///   El usuario debe aceptar para seguir usando la app. Sin botón atrás.
///   El router redirige acá cuando `termsAcceptedVersion < currentVersion`.
///
/// * **Reader** (`mode = TermsPageMode.reader`) — consulta desde Perfil.
///   Solo muestra el texto y un botón "Cerrar"; no permite re-aceptar
///   (el state ya está aceptado).
enum TermsPageMode { gate, reader }

class TermsPage extends ConsumerStatefulWidget {
  const TermsPage({super.key, this.mode = TermsPageMode.gate});

  final TermsPageMode mode;

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage> {
  bool _agreed = false;

  Future<void> _accept() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    await ref
        .read(termsAcceptanceNotifierProvider.notifier)
        .accept(user.userId);
    if (!mounted) return;
    final state = ref.read(termsAcceptanceNotifierProvider);
    if (state.hasError) {
      context.showSnackBar(
        'No se pudo registrar tu aceptación. Intentá de nuevo.',
        isError: true,
      );
      return;
    }
    // El router observa el stream del doc y, al actualizarse, saca al usuario
    // automáticamente de esta pantalla. No navegamos manualmente.
  }

  @override
  Widget build(BuildContext context) {
    final isGate = widget.mode == TermsPageMode.gate;
    final isLoading = ref.watch(termsAcceptanceNotifierProvider).isLoading;

    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      // En modo gate no permitimos salir con back: la única salida es aceptar
      // o cerrar sesión. En reader sí permitimos volver atrás.
      canPop: !isGate,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(TermsConfig.title),
          automaticallyImplyLeading: !isGate,
        ),
        body: Column(
          children: [
            // Banner inicial con el highlight del disclaimer. Alta visibilidad
            // para que aun el usuario que no lea todo el documento se quede
            // con el mensaje fuerte: NO es para emergencias.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: scheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: scheme.error, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      TermsConfig.disclaimerHighlight,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  TermsConfig.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (isGate)
              _GateActions(
                agreed: _agreed,
                isLoading: isLoading,
                onAgreedChanged: (v) => setState(() => _agreed = v ?? false),
                onAccept: _accept,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
              )
            else
              _ReaderActions(
                acceptedVersion: ref
                    .watch(authStateProvider)
                    .valueOrNull
                    ?.termsAcceptedVersion,
              ),
          ],
        ),
      ),
    );
  }
}

class _GateActions extends StatelessWidget {
  const _GateActions({
    required this.agreed,
    required this.isLoading,
    required this.onAgreedChanged,
    required this.onAccept,
    required this.onLogout,
  });

  final bool agreed;
  final bool isLoading;
  final ValueChanged<bool?> onAgreedChanged;
  final VoidCallback onAccept;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: agreed,
                onChanged: isLoading ? null : onAgreedChanged,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Leí y acepto los Términos y Condiciones. Entiendo que esta '
                  'aplicación NO es un servicio de emergencias.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle),
                onPressed: (agreed && !isLoading) ? onAccept : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(isLoading ? 'Guardando…' : 'Acepto y continuar'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.logout),
                onPressed: isLoading ? null : onLogout,
                label: const Text('No acepto, cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderActions extends StatelessWidget {
  const _ReaderActions({this.acceptedVersion});

  final int? acceptedVersion;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (acceptedVersion != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Aceptaste la versión $acceptedVersion. Versión vigente: '
                    '${TermsConfig.currentVersion}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                label: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

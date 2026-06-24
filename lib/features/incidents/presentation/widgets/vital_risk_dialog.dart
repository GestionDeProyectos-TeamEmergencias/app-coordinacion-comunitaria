import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/services/vital_risk_check_service.dart';

/// Diálogo de derivación a servicios de emergencia (911/107) que se muestra
/// cuando `checkVitalRiskCallable` detecta riesgo vital en la descripción de
/// un reporte. [D-03 / RF-PRI-05]
///
/// Diseño:
/// - **No es dismissible** por tap fuera ni botón atrás: la única salida es
///   "Entendido". Esto evita que un toque accidental cierre el aviso de un
///   reporte crítico.
/// - **Los botones 911/107 abren un `tel:` deeplink** vía `url_launcher`. En
///   web el deeplink puede no funcionar; mostramos el número grande para que
///   el usuario lo marque manualmente.
/// - **No persiste el reporte**: la decisión de producto (D-03) es que un
///   reporte con riesgo vital no debería ensuciar la cola de incidents
///   comunitarios. El usuario va a emergencias, no al sistema barrial.
class VitalRiskDialog extends StatelessWidget {
  const VitalRiskDialog({super.key, required this.result});

  final VitalRiskCheckResult result;

  /// Helper: muestra el diálogo bloqueante. Resuelve cuando el usuario lo cierra.
  static Future<void> show(BuildContext context, VitalRiskCheckResult result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VitalRiskDialog(result: result),
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    // launchUrl puede tirar PlatformException en web o en builds sin permiso
    // del intent. No queremos crashear el diálogo por eso — best-effort.
    try {
      await launchUrl(uri);
    } catch (_) {/* swallow */}
  }

  @override
  Widget build(BuildContext context) {
    final numbers = result.emergencyNumbers.isEmpty
        ? const ['911']
        : result.emergencyNumbers;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text(
          AppStrings.vitalRiskTitle,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AppStrings.vitalRiskBody),
            const SizedBox(height: 16),
            ...numbers.map((n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.phone),
                    onPressed: () => _call(n),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    label: Text(
                      n == '911'
                          ? AppStrings.emergencyCall911
                          : (n == '107'
                              ? AppStrings.emergencyCall107
                              : 'Llamar al $n'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
            if (result.matchedTerms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Términos detectados: ${result.matchedTerms.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido, no envío el reporte'),
          ),
        ],
      ),
    );
  }
}

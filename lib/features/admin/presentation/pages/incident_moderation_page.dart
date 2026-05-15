import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';

// RF-MOD-03: marcar reporte como falso/malintencionado. [T-AUTH-07]
// RF-ADM-02: actualizar estado de resolución de incidentes.
class IncidentModerationPage extends StatelessWidget {
  const IncidentModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.incidentModeration)),
      // TODO(T-AUTH-07): implementar moderación de incidentes.
      body: const AppLoading(message: 'Tarea T-AUTH-07 / T-REP-06 pendiente de implementación'),
    );
  }
}

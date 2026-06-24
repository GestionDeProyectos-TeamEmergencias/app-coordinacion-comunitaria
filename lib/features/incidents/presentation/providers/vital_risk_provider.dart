import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/vital_risk_check_service.dart';

/// Provider singleton del servicio de chequeo de riesgo vital. Sobrecargable
/// en tests vía `overrideWithValue`. [D-03]
final vitalRiskCheckServiceProvider = Provider<VitalRiskCheckService>((ref) {
  return VitalRiskCheckService();
});

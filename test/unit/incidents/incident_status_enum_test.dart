import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentStatus.fromString', () {
    test('mapea los estados originales del MVP', () {
      expect(IncidentStatus.fromString('recibido'), IncidentStatus.recibido);
      expect(
          IncidentStatus.fromString('programado'), IncidentStatus.programado);
      expect(
        IncidentStatus.fromString('en_reparacion'),
        IncidentStatus.enReparacion,
      );
      expect(
        IncidentStatus.fromString('solucionado'),
        IncidentStatus.solucionado,
      );
      expect(
        IncidentStatus.fromString('rechazado_fuera_de_cobertura'),
        IncidentStatus.rechazadoFueraDeCobertura,
      );
      expect(IncidentStatus.fromString('falso'), IncidentStatus.falso);
    });

    // D-03: si el backend marca uno de estos estados, el cliente DEBE
    // reconocerlos en vez de caer al default `recibido`, que es exactamente el
    // bug que motivó D-03 (un reporte con riesgo vital se mostraba como
    // "Recibido" sin ninguna alerta).
    test('mapea vital_risk_detected y rechazado_autor_inactivo', () {
      expect(
        IncidentStatus.fromString('vital_risk_detected'),
        IncidentStatus.vitalRiskDetected,
      );
      expect(
        IncidentStatus.fromString('rechazado_autor_inactivo'),
        IncidentStatus.rechazadoAutorInactivo,
      );
    });

    test('valores desconocidos caen al default recibido', () {
      expect(IncidentStatus.fromString(''), IncidentStatus.recibido);
      expect(
          IncidentStatus.fromString('cualquier_cosa'), IncidentStatus.recibido);
    });
  });

  group('IncidentStatus.firestoreValue', () {
    test('es bidireccional con fromString para todos los valores', () {
      for (final s in IncidentStatus.values) {
        expect(IncidentStatus.fromString(s.firestoreValue), s,
            reason: 'roundtrip failed for ${s.name}');
      }
    });
  });

  group('IncidentStatus.displayName', () {
    test('todos los estados tienen un displayName no vacío', () {
      for (final s in IncidentStatus.values) {
        expect(s.displayName, isNotEmpty,
            reason: 'empty displayName for ${s.name}');
      }
    });
  });
}

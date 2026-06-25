import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentStatus.allowedTransitions', () {
    test('recibido → {programado, en_reparacion, solucionado}', () {
      expect(
        IncidentStatus.recibido.allowedTransitions,
        unorderedEquals([
          IncidentStatus.programado,
          IncidentStatus.enReparacion,
          IncidentStatus.solucionado,
        ]),
      );
    });

    test('programado → puede volver a recibido + avanzar', () {
      expect(
        IncidentStatus.programado.allowedTransitions,
        unorderedEquals([
          IncidentStatus.recibido,
          IncidentStatus.enReparacion,
          IncidentStatus.solucionado,
        ]),
      );
    });

    test('en_reparacion → solo programado o solucionado', () {
      expect(
        IncidentStatus.enReparacion.allowedTransitions,
        unorderedEquals([
          IncidentStatus.programado,
          IncidentStatus.solucionado,
        ]),
      );
    });

    test('solucionado es terminal (F-05 abrirá disputa ortogonal)', () {
      expect(IncidentStatus.solucionado.allowedTransitions, isEmpty);
    });

    test('estados marcadores del backend son terminales desde cliente', () {
      const markers = [
        IncidentStatus.falso,
        IncidentStatus.rechazadoFueraDeCobertura,
        IncidentStatus.vitalRiskDetected,
        IncidentStatus.rechazadoAutorInactivo,
      ];
      for (final s in markers) {
        expect(s.allowedTransitions, isEmpty,
            reason: '${s.name} no debe permitir transiciones manuales');
      }
    });

    test('ningún allowedTransitions incluye estados marcadores', () {
      const markers = {
        IncidentStatus.falso,
        IncidentStatus.rechazadoFueraDeCobertura,
        IncidentStatus.vitalRiskDetected,
        IncidentStatus.rechazadoAutorInactivo,
      };
      for (final s in IncidentStatus.values) {
        for (final next in s.allowedTransitions) {
          expect(markers.contains(next), isFalse,
              reason:
                  '${s.name} no debe permitir transición a marcador ${next.name}');
        }
      }
    });
  });

  group('IncidentStatus.canTransitionTo', () {
    test('identidad siempre es válida', () {
      for (final s in IncidentStatus.values) {
        expect(s.canTransitionTo(s), isTrue, reason: '${s.name} → ${s.name}');
      }
    });

    test('saltos inválidos son rechazados', () {
      expect(
        IncidentStatus.recibido.canTransitionTo(IncidentStatus.falso),
        isFalse,
      );
      expect(
        IncidentStatus.solucionado.canTransitionTo(IncidentStatus.recibido),
        isFalse,
      );
      expect(
        IncidentStatus.enReparacion.canTransitionTo(IncidentStatus.recibido),
        isFalse,
        reason: 'desde en_reparacion no se debe poder volver a recibido',
      );
      expect(
        IncidentStatus.falso.canTransitionTo(IncidentStatus.solucionado),
        isFalse,
      );
    });

    test('admin puede revertir programado → recibido (caso de "anular plan")',
        () {
      expect(
        IncidentStatus.programado.canTransitionTo(IncidentStatus.recibido),
        isTrue,
      );
    });
  });

  group('IncidentStatus.canBeMarkedAsFalse (único camino vía callable)', () {
    test('estados activos del ciclo pueden ir a falso', () {
      expect(IncidentStatus.recibido.canBeMarkedAsFalse, isTrue);
      expect(IncidentStatus.programado.canBeMarkedAsFalse, isTrue);
      expect(IncidentStatus.enReparacion.canBeMarkedAsFalse, isTrue);
    });

    test('terminales no pueden volverse falsos', () {
      expect(IncidentStatus.solucionado.canBeMarkedAsFalse, isFalse);
      expect(IncidentStatus.falso.canBeMarkedAsFalse, isFalse);
      expect(
          IncidentStatus.rechazadoFueraDeCobertura.canBeMarkedAsFalse, isFalse);
      expect(IncidentStatus.vitalRiskDetected.canBeMarkedAsFalse, isFalse);
      expect(IncidentStatus.rechazadoAutorInactivo.canBeMarkedAsFalse, isFalse);
    });
  });
}

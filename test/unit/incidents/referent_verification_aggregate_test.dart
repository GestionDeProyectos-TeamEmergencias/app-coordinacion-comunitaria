import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/referent_verification_aggregate.dart';
import 'package:flutter_test/flutter_test.dart';

ReferentVerification _v(
  String by,
  ReferentVerificationState state,
  DateTime at,
) =>
    ReferentVerification(state: state, by: by, at: at, photoUrl: 'p.jpg');

void main() {
  const confirmed = ReferentVerificationState.confirmed;
  const dismissed = ReferentVerificationState.dismissed;

  group('aggregateReferentVerification', () {
    test('historial vacío -> none', () {
      final r = aggregateReferentVerification(const []);
      expect(r.state, ReferentAggregateState.none);
      expect(r.confirms, 0);
      expect(r.dismisses, 0);
    });

    test('un aval -> confirmed (1/0)', () {
      final r = aggregateReferentVerification([
        _v('r1', confirmed, DateTime(2026, 6, 1)),
      ]);
      expect(r.state, ReferentAggregateState.confirmed);
      expect(r.confirms, 1);
      expect(r.dismisses, 0);
    });

    test('un descarte -> dismissed (0/1)', () {
      final r = aggregateReferentVerification([
        _v('r1', dismissed, DateTime(2026, 6, 1)),
      ]);
      expect(r.state, ReferentAggregateState.dismissed);
      expect(r.confirms, 0);
      expect(r.dismisses, 1);
    });

    test('dos referentes distintos avalan -> confirmed (2/0)', () {
      final r = aggregateReferentVerification([
        _v('r1', confirmed, DateTime(2026, 6, 1)),
        _v('r2', confirmed, DateTime(2026, 6, 2)),
      ]);
      expect(r.state, ReferentAggregateState.confirmed);
      expect(r.confirms, 2);
      expect(r.dismisses, 0);
    });

    test('conflicto entre referentes -> disputed (1/1)', () {
      final r = aggregateReferentVerification([
        _v('r1', confirmed, DateTime(2026, 6, 1)),
        _v('r2', dismissed, DateTime(2026, 6, 2)),
      ]);
      expect(r.state, ReferentAggregateState.disputed);
      expect(r.confirms, 1);
      expect(r.dismisses, 1);
    });

    test('mismo referente cambia de opinión: gana su última postura', () {
      // r1 avala y luego descarta -> cuenta como descarte (0/1, dismissed).
      final r = aggregateReferentVerification([
        _v('r1', confirmed, DateTime(2026, 6, 1)),
        _v('r1', dismissed, DateTime(2026, 6, 2)),
      ]);
      expect(r.state, ReferentAggregateState.dismissed);
      expect(r.confirms, 0);
      expect(r.dismisses, 1);
    });

    test('entradas fuera de orden: igual gana el `at` más reciente', () {
      // El descarte es más reciente aunque venga primero en la lista.
      final r = aggregateReferentVerification([
        _v('r1', dismissed, DateTime(2026, 6, 5)),
        _v('r1', confirmed, DateTime(2026, 6, 1)),
      ]);
      expect(r.state, ReferentAggregateState.dismissed);
    });

    test('duplicados del mismo referente y estado: dedupe por referente', () {
      final r = aggregateReferentVerification([
        _v('r1', confirmed, DateTime(2026, 6, 1)),
        _v('r1', confirmed, DateTime(2026, 6, 2)),
      ]);
      expect(r.state, ReferentAggregateState.confirmed);
      expect(r.confirms, 1);
    });
  });
}

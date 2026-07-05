import 'entities/incident_event.dart';

/// Estado agregado de la verificación de los referentes barriales sobre un
/// incidente, derivado **en vivo** del historial (`referentVerificationHistory`).
///
/// Es la señal de **veracidad** (ortogonal a la prioridad/urgencia): NO modifica
/// el `priorityScore`. Solo se usa para mostrar un indicador al admin/referente.
enum ReferentAggregateState {
  /// Ningún referente intervino todavía.
  none,

  /// Al menos un referente avala y ninguno descarta.
  confirmed,

  /// Al menos un referente descarta y ninguno avala.
  dismissed,

  /// Hay referentes que avalan y otros que descartan (sin resolución automática).
  disputed,
}

class ReferentVerificationAggregate {
  const ReferentVerificationAggregate({
    required this.state,
    required this.confirms,
    required this.dismisses,
  });

  final ReferentAggregateState state;

  /// Cantidad de referentes **distintos** cuya última postura es avalar.
  final int confirms;

  /// Cantidad de referentes **distintos** cuya última postura es descartar.
  final int dismisses;
}

/// Agrega el historial de verificaciones a un único estado de veracidad.
///
/// Reglas:
/// - Se considera la **última postura de cada referente** (dedupe por `by`,
///   gana el `at` más reciente) — soporta que un referente cambie de opinión y
///   que el historial tenga entradas duplicadas.
/// - El conflicto (avales y descartes a la vez) queda en `disputed`: es
///   informativo, no se resuelve automáticamente (lo decide el admin con sus
///   acciones de moderación).
ReferentVerificationAggregate aggregateReferentVerification(
  List<ReferentVerification> history,
) {
  final latestByReferent = <String, ReferentVerification>{};
  for (final v in history) {
    final existing = latestByReferent[v.by];
    if (existing == null || v.at.isAfter(existing.at)) {
      latestByReferent[v.by] = v;
    }
  }

  var confirms = 0;
  var dismisses = 0;
  for (final v in latestByReferent.values) {
    switch (v.state) {
      case ReferentVerificationState.confirmed:
        confirms++;
      case ReferentVerificationState.dismissed:
        dismisses++;
    }
  }

  final ReferentAggregateState state;
  if (confirms == 0 && dismisses == 0) {
    state = ReferentAggregateState.none;
  } else if (confirms > 0 && dismisses > 0) {
    state = ReferentAggregateState.disputed;
  } else if (confirms > 0) {
    state = ReferentAggregateState.confirmed;
  } else {
    state = ReferentAggregateState.dismissed;
  }

  return ReferentVerificationAggregate(
    state: state,
    confirms: confirms,
    dismisses: dismisses,
  );
}

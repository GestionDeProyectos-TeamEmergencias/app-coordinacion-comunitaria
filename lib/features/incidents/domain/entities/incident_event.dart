import 'package:equatable/equatable.dart';

// Contrato T-INF-04: objeto "Evento de Incidente" que unifica los 3 métodos de reporte.
// Campos userID, timestamp, coordenadas, descripción y categoría siempre presentes
// o explícitamente nulos.

enum SourceType {
  quick, // RF-REP-01: botón rápido
  form, // RF-REP-03: formulario detallado
  voice; // RF-REP-02: voz con Speech-to-Text on-device

  String get value => name;

  static SourceType fromString(String value) => switch (value) {
        'quick' => SourceType.quick,
        'form' => SourceType.form,
        'voice' => SourceType.voice,
        _ => SourceType.quick,
      };
}

enum IncidentCategory {
  electrico,
  vial,
  sanitario,
  espaciosVerdes,
  seguridad;

  static IncidentCategory fromString(String value) => switch (value) {
        'electrico' => IncidentCategory.electrico,
        'vial' => IncidentCategory.vial,
        'sanitario' => IncidentCategory.sanitario,
        'espacios_verdes' => IncidentCategory.espaciosVerdes,
        'seguridad' => IncidentCategory.seguridad,
        _ => IncidentCategory.vial,
      };

  String get firestoreValue => switch (this) {
        IncidentCategory.electrico => 'electrico',
        IncidentCategory.vial => 'vial',
        IncidentCategory.sanitario => 'sanitario',
        IncidentCategory.espaciosVerdes => 'espacios_verdes',
        IncidentCategory.seguridad => 'seguridad',
      };

  String get displayName => switch (this) {
        IncidentCategory.electrico => 'Eléctrico',
        IncidentCategory.vial => 'Vial',
        IncidentCategory.sanitario => 'Sanitario',
        IncidentCategory.espaciosVerdes => 'Espacios verdes',
        IncidentCategory.seguridad => 'Seguridad',
      };

  String get emoji => switch (this) {
        IncidentCategory.electrico => '⚡',
        IncidentCategory.vial => '🚧',
        IncidentCategory.sanitario => '🚰',
        IncidentCategory.espaciosVerdes => '🌳',
        IncidentCategory.seguridad => '🚨',
      };
}

enum IncidentStatus {
  recibido,
  programado,
  enReparacion,
  solucionado,
  // Marcado por el backend cuando el GPS del reporte queda fuera del área de
  // cobertura configurada. [T-AUTH-06]
  rechazadoFueraDeCobertura,
  // Marcado por un admin/referente como reporte falso o malintencionado. [T-AUTH-07]
  falso,
  // Marcado por el backend cuando detecta riesgo vital en la descripción
  // (`vitalRiskDetectionFlow`). El pipeline se corta y NO se generan alertas
  // comunitarias; el cliente muestra derivación a 911/107. [D-03 / RF-PRI-05]
  vitalRiskDetected,
  // Marcado por el backend cuando el autor del reporte no está activo
  // (`pending`/`blocked`/`rejected`). [D-03 / T-AUTH-07]
  rechazadoAutorInactivo;

  static IncidentStatus fromString(String value) => switch (value) {
        'recibido' => IncidentStatus.recibido,
        'programado' => IncidentStatus.programado,
        'en_reparacion' => IncidentStatus.enReparacion,
        'solucionado' => IncidentStatus.solucionado,
        'rechazado_fuera_de_cobertura' =>
          IncidentStatus.rechazadoFueraDeCobertura,
        'falso' => IncidentStatus.falso,
        'vital_risk_detected' => IncidentStatus.vitalRiskDetected,
        'rechazado_autor_inactivo' => IncidentStatus.rechazadoAutorInactivo,
        _ => IncidentStatus.recibido,
      };

  String get firestoreValue => switch (this) {
        IncidentStatus.recibido => 'recibido',
        IncidentStatus.programado => 'programado',
        IncidentStatus.enReparacion => 'en_reparacion',
        IncidentStatus.solucionado => 'solucionado',
        IncidentStatus.rechazadoFueraDeCobertura =>
          'rechazado_fuera_de_cobertura',
        IncidentStatus.falso => 'falso',
        IncidentStatus.vitalRiskDetected => 'vital_risk_detected',
        IncidentStatus.rechazadoAutorInactivo => 'rechazado_autor_inactivo',
      };

  String get displayName => switch (this) {
        IncidentStatus.recibido => 'Recibido',
        IncidentStatus.programado => 'Programado',
        IncidentStatus.enReparacion => 'En reparación',
        IncidentStatus.solucionado => 'Solucionado',
        IncidentStatus.rechazadoFueraDeCobertura => 'Fuera de cobertura',
        IncidentStatus.falso => 'Falso',
        IncidentStatus.vitalRiskDetected => 'Riesgo vital — derivado a 911/107',
        IncidentStatus.rechazadoAutorInactivo => 'Rechazado (autor inactivo)',
      };

  /// Transiciones válidas que el Administrador puede ejecutar desde el cliente
  /// para `this` como estado actual. Excluye **siempre** los estados
  /// marcadores (`falso`, `rechazadoFueraDeCobertura`, `vitalRiskDetected`,
  /// `rechazadoAutorInactivo`): esos los pone el backend con Admin SDK y no
  /// están bajo el control del dropdown manual. [D-07 / RF-ADM-02 / O4]
  ///
  /// `falso` queda con **un solo camino**: el callable `moderateFalseReport`
  /// (T-AUTH-07), que dispara el decremento de reputación (D-08).
  ///
  /// `solucionado` es terminal por D-07: F-05 (cierre bilateral) gestionará
  /// disputa/reapertura con un campo **ortogonal** (`closureConfirmation`),
  /// no tocando `status` hacia atrás.
  List<IncidentStatus> get allowedTransitions => switch (this) {
        IncidentStatus.recibido => const [
            IncidentStatus.programado,
            IncidentStatus.enReparacion,
            IncidentStatus.solucionado,
          ],
        IncidentStatus.programado => const [
            IncidentStatus.recibido,
            IncidentStatus.enReparacion,
            IncidentStatus.solucionado,
          ],
        IncidentStatus.enReparacion => const [
            IncidentStatus.programado,
            IncidentStatus.solucionado,
          ],
        // Terminales: ni el ciclo operativo ni los marcadores tienen salida
        // manual desde el dropdown.
        IncidentStatus.solucionado ||
        IncidentStatus.falso ||
        IncidentStatus.rechazadoFueraDeCobertura ||
        IncidentStatus.vitalRiskDetected ||
        IncidentStatus.rechazadoAutorInactivo =>
          const [],
      };

  /// `true` si la transición `this → next` es válida. La identidad
  /// (`this == next`) cuenta como válida (no es un cambio efectivo). [D-07]
  bool canTransitionTo(IncidentStatus next) =>
      next == this || allowedTransitions.contains(next);

  /// `true` si desde `this` se puede marcar como `falso` vía callable. No
  /// permitimos moderar incidents ya cerrados o ya sancionados. [D-07]
  bool get canBeMarkedAsFalse => switch (this) {
        IncidentStatus.recibido ||
        IncidentStatus.programado ||
        IncidentStatus.enReparacion =>
          true,
        _ => false,
      };
}

enum IncidentPriority {
  urgente,
  alta,
  media,
  baja;

  static IncidentPriority fromString(String value) => switch (value) {
        'urgente' => IncidentPriority.urgente,
        'alta' => IncidentPriority.alta,
        'media' => IncidentPriority.media,
        'baja' => IncidentPriority.baja,
        _ => IncidentPriority.baja,
      };

  String get displayName => switch (this) {
        IncidentPriority.urgente => 'Urgente',
        IncidentPriority.alta => 'Alta',
        IncidentPriority.media => 'Media',
        IncidentPriority.baja => 'Baja',
      };
}

/// Estado de la validación bilateral del cierre. Ortogonal al `status` para no
/// contaminar la máquina de estados documentada en el SRS (decisión §5.2 de la
/// devolución). [F-05]
enum ClosureConfirmationState {
  pendiente,
  confirmado,
  disputado;

  String get firestoreValue => switch (this) {
        ClosureConfirmationState.pendiente => 'pendiente',
        ClosureConfirmationState.confirmado => 'confirmado',
        ClosureConfirmationState.disputado => 'disputado',
      };

  String get displayName => switch (this) {
        ClosureConfirmationState.pendiente => 'Pendiente de confirmación',
        ClosureConfirmationState.confirmado => 'Cierre confirmado',
        ClosureConfirmationState.disputado => 'Cierre disputado',
      };

  static ClosureConfirmationState? fromString(String? value) => switch (value) {
        'pendiente' => ClosureConfirmationState.pendiente,
        'confirmado' => ClosureConfirmationState.confirmado,
        'disputado' => ClosureConfirmationState.disputado,
        _ => null,
      };
}

class ClosureConfirmation extends Equatable {
  const ClosureConfirmation({
    required this.state,
    required this.by,
    required this.at,
    this.note,
  });

  final ClosureConfirmationState state;
  // uid de quien cerró el reporte (admin/referente) si state=pendiente.
  // uid del reportero si state=confirmado/disputado.
  final String by;
  final DateTime at;
  // Obligatoria si state=disputado. Opcional en otros estados.
  final String? note;

  @override
  List<Object?> get props => [state, by, at, note];
}

/// Reacción de un vecino activo sobre un incident — "Confirmo" o "No es así".
/// Persistida en `incidents/{id}/reactions/{userId}`. El backend (F-04) agrega
/// los contadores en el doc del incident. [F-04]
enum ReactionType {
  confirm,
  dispute;

  String get firestoreValue => switch (this) {
        ReactionType.confirm => 'confirm',
        ReactionType.dispute => 'dispute',
      };

  static ReactionType? fromString(String? value) => switch (value) {
        'confirm' => ReactionType.confirm,
        'dispute' => ReactionType.dispute,
        _ => null,
      };
}

/// Verificación de campo del Referente Barrial sobre un incidente. [D-05 /
/// RF-ROL-02(b)]
///
/// Ortogonal al `status` del incidente: el referente confirma o descarta lo
/// que vio en terreno; el admin gestiona el ciclo de vida operativo. La
/// confirmación del referente es señal **autoritativa**, distinta de la señal
/// social blanda que va a aportar la comunidad (F-04).
enum ReferentVerificationState {
  confirmed,
  dismissed;

  String get firestoreValue => switch (this) {
        ReferentVerificationState.confirmed => 'confirmed',
        ReferentVerificationState.dismissed => 'dismissed',
      };

  String get displayName => switch (this) {
        ReferentVerificationState.confirmed => 'Confirmado por referente',
        ReferentVerificationState.dismissed => 'Descartado por referente',
      };

  static ReferentVerificationState? fromString(String? value) =>
      switch (value) {
        'confirmed' => ReferentVerificationState.confirmed,
        'dismissed' => ReferentVerificationState.dismissed,
        _ => null,
      };
}

class ReferentVerification extends Equatable {
  const ReferentVerification({
    required this.state,
    required this.by,
    required this.at,
    required this.photoUrl,
    this.byDisplayName,
    this.note,
  });

  final ReferentVerificationState state;
  final String by; // uid del referente
  final String? byDisplayName;
  final DateTime at;
  final String? note;
  // Evidencia fotográfica obligatoria (RF-ROL-02(b)).
  final String photoUrl;

  @override
  List<Object?> get props => [state, by, byDisplayName, at, note, photoUrl];
}

/// Acción de resolución registrada por el Administrador en el ciclo de vida
/// del incidente. Parte del feed de auditoría visible al vecino dueño. [D-06 /
/// RF-ADM-03]
class ResolutionAction extends Equatable {
  const ResolutionAction({
    required this.note,
    required this.by,
    required this.at,
    this.byDisplayName,
  });

  final String note;
  final String by; // uid del admin
  final String? byDisplayName;
  final DateTime at;

  @override
  List<Object?> get props => [note, by, byDisplayName, at];
}

class IncidentStatusChange extends Equatable {
  const IncidentStatusChange({
    required this.status,
    required this.timestamp,
    this.changedBy,
  });

  final IncidentStatus status;
  final DateTime timestamp;
  final String? changedBy;

  @override
  List<Object?> get props => [status, timestamp, changedBy];
}

class IncidentEvent extends Equatable {
  const IncidentEvent({
    this.eventId,
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.description,
    this.category,
    required this.sourceType,
    this.photoUrl,
    this.status = IncidentStatus.recibido,
    this.priority,
    this.priorityScore,
    this.statusHistory = const [],
    this.referentVerification,
    this.referentVerificationHistory = const [],
    this.actions = const [],
    this.categoryChangedBy,
    this.categoryChangedAt,
    this.confirmsCount = 0,
    this.disputesCount = 0,
    this.confirmationScore = 0.0,
    this.communityValidated = false,
    this.closureConfirmation,
    this.resolutionEvidenceUrl,
  });

  final String? eventId;
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? description;
  final IncidentCategory? category;
  final SourceType sourceType;
  final String? photoUrl;
  final IncidentStatus status;
  final IncidentPriority? priority;
  final double? priorityScore;
  final List<IncidentStatusChange> statusHistory;
  // Última verificación autoritativa hecha por un Referente Barrial. [D-05]
  final ReferentVerification? referentVerification;
  // Histórico de verificaciones (incluye re-verificaciones). El último coincide
  // con `referentVerification`. Es el feed de auditoría visible al admin. [D-05]
  final List<ReferentVerification> referentVerificationHistory;
  // Acciones registradas por el Administrador en el ciclo de resolución.
  // Visible al vecino dueño como rendición de cuentas. [D-06 / RF-ADM-03]
  final List<ResolutionAction> actions;
  // Auditoría del último cambio manual de categoría (uid + timestamp). El
  // valor de `category` ya refleja la corrección; estos dos campos guardan
  // quién la hizo, para que el dueño vea que el admin intervino. [D-06]
  final String? categoryChangedBy;
  final DateTime? categoryChangedAt;
  // Conteos y score de reacciones de la comunidad. Lo persiste el trigger
  // `aggregateReactionsOnWritten`. [F-04]
  final int confirmsCount;
  final int disputesCount;
  final double confirmationScore;
  final bool communityValidated;
  // Validación bilateral del cierre. Null hasta que admin/referente cierra; ahí
  // se setea con state=pendiente y luego el reportero confirma/disputa o el
  // auto-cierre programado lo confirma por timeout. [F-05]
  final ClosureConfirmation? closureConfirmation;
  // Foto opcional de evidencia de la reparación. La sube admin/referente al
  // pasar el incident a `solucionado`. Null si no se adjuntó. Visible a todos
  // en el detalle como rendición de cuentas. [F-06]
  final String? resolutionEvidenceUrl;

  IncidentEvent copyWith({
    String? eventId,
    String? userId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? description,
    IncidentCategory? category,
    SourceType? sourceType,
    String? photoUrl,
    IncidentStatus? status,
    IncidentPriority? priority,
    double? priorityScore,
    List<IncidentStatusChange>? statusHistory,
    ReferentVerification? referentVerification,
    List<ReferentVerification>? referentVerificationHistory,
    List<ResolutionAction>? actions,
    String? categoryChangedBy,
    DateTime? categoryChangedAt,
    int? confirmsCount,
    int? disputesCount,
    double? confirmationScore,
    bool? communityValidated,
    ClosureConfirmation? closureConfirmation,
    String? resolutionEvidenceUrl,
  }) {
    return IncidentEvent(
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      priorityScore: priorityScore ?? this.priorityScore,
      statusHistory: statusHistory ?? this.statusHistory,
      referentVerification: referentVerification ?? this.referentVerification,
      referentVerificationHistory:
          referentVerificationHistory ?? this.referentVerificationHistory,
      actions: actions ?? this.actions,
      categoryChangedBy: categoryChangedBy ?? this.categoryChangedBy,
      categoryChangedAt: categoryChangedAt ?? this.categoryChangedAt,
      confirmsCount: confirmsCount ?? this.confirmsCount,
      disputesCount: disputesCount ?? this.disputesCount,
      confirmationScore: confirmationScore ?? this.confirmationScore,
      communityValidated: communityValidated ?? this.communityValidated,
      closureConfirmation: closureConfirmation ?? this.closureConfirmation,
      resolutionEvidenceUrl:
          resolutionEvidenceUrl ?? this.resolutionEvidenceUrl,
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        userId,
        timestamp,
        latitude,
        longitude,
        description,
        category,
        sourceType,
        photoUrl,
        status,
        priority,
        priorityScore,
        statusHistory,
        referentVerification,
        referentVerificationHistory,
        actions,
        categoryChangedBy,
        categoryChangedAt,
        confirmsCount,
        disputesCount,
        confirmationScore,
        communityValidated,
        closureConfirmation,
        resolutionEvidenceUrl,
      ];
}

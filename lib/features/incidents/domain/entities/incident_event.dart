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
}

enum IncidentStatus {
  recibido,
  programado,
  enReparacion,
  solucionado;

  static IncidentStatus fromString(String value) => switch (value) {
        'recibido' => IncidentStatus.recibido,
        'programado' => IncidentStatus.programado,
        'en_reparacion' => IncidentStatus.enReparacion,
        'solucionado' => IncidentStatus.solucionado,
        _ => IncidentStatus.recibido,
      };

  String get firestoreValue => switch (this) {
        IncidentStatus.recibido => 'recibido',
        IncidentStatus.programado => 'programado',
        IncidentStatus.enReparacion => 'en_reparacion',
        IncidentStatus.solucionado => 'solucionado',
      };

  String get displayName => switch (this) {
        IncidentStatus.recibido => 'Recibido',
        IncidentStatus.programado => 'Programado',
        IncidentStatus.enReparacion => 'En reparación',
        IncidentStatus.solucionado => 'Solucionado',
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
      ];
}

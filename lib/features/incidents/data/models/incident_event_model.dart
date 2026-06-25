import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/incident_event.dart';

// Colección Firestore: 'incidents'
class IncidentEventModel {
  const IncidentEventModel({
    required this.eventId,
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.description,
    this.category,
    required this.sourceType,
    this.photoUrl,
    required this.status,
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
  });

  final String eventId;
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? description;
  final String? category;
  final String sourceType;
  final String? photoUrl;
  final String status;
  final String? priority;
  final double? priorityScore;
  final List<Map<String, dynamic>> statusHistory;
  // Raw maps de Firestore; se convierten a `ReferentVerification` en `toDomain`.
  final Map<String, dynamic>? referentVerification;
  final List<Map<String, dynamic>> referentVerificationHistory;
  // Raw maps de Firestore; se convierten a `ResolutionAction` en `toDomain`. [D-06]
  final List<Map<String, dynamic>> actions;
  // Auditoría del último cambio manual de categoría. [D-06]
  final String? categoryChangedBy;
  final DateTime? categoryChangedAt;
  // Persisten desde el trigger `aggregateReactionsOnWritten`. [F-04]
  final int confirmsCount;
  final int disputesCount;
  final double confirmationScore;
  final bool communityValidated;

  factory IncidentEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final ts = data['timestamp'];
    final datetime = ts is Timestamp ? ts.toDate() : DateTime.now();
    final history = (data['statusHistory'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final verificationHistory =
        (data['referentVerificationHistory'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final actions = (data['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return IncidentEventModel(
      eventId: doc.id,
      userId: data['userId'] as String,
      timestamp: datetime,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      description: data['description'] as String?,
      category: data['category'] as String?,
      sourceType: data['sourceType'] as String? ?? 'quick',
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String? ?? 'recibido',
      priority: data['priority'] as String?,
      priorityScore: (data['priorityScore'] as num?)?.toDouble(),
      statusHistory: history,
      referentVerification: data['referentVerification'] is Map
          ? Map<String, dynamic>.from(
              data['referentVerification'] as Map<dynamic, dynamic>)
          : null,
      referentVerificationHistory: verificationHistory,
      actions: actions,
      categoryChangedBy: data['categoryChangedBy'] as String?,
      categoryChangedAt: (data['categoryChangedAt'] as Timestamp?)?.toDate(),
      confirmsCount: (data['confirmsCount'] as num?)?.toInt() ?? 0,
      disputesCount: (data['disputesCount'] as num?)?.toInt() ?? 0,
      confirmationScore: (data['confirmationScore'] as num?)?.toDouble() ?? 0.0,
      communityValidated: data['communityValidated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        'sourceType': sourceType,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'status': status,
        if (priority != null) 'priority': priority,
        if (priorityScore != null) 'priorityScore': priorityScore,
      };

  IncidentEvent toDomain() => IncidentEvent(
        eventId: eventId,
        userId: userId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        description: description,
        category:
            category != null ? IncidentCategory.fromString(category!) : null,
        sourceType: SourceType.fromString(sourceType),
        photoUrl: photoUrl,
        status: IncidentStatus.fromString(status),
        priority:
            priority != null ? IncidentPriority.fromString(priority!) : null,
        priorityScore: priorityScore,
        statusHistory: statusHistory.map(_statusChangeFromMap).toList(),
        referentVerification:
            _referentVerificationFromMap(referentVerification),
        referentVerificationHistory: referentVerificationHistory
            .map(_referentVerificationFromMap)
            .whereType<ReferentVerification>()
            .toList(),
        actions: actions
            .map(_resolutionActionFromMap)
            .whereType<ResolutionAction>()
            .toList(),
        categoryChangedBy: categoryChangedBy,
        categoryChangedAt: categoryChangedAt,
        confirmsCount: confirmsCount,
        disputesCount: disputesCount,
        confirmationScore: confirmationScore,
        communityValidated: communityValidated,
      );

  factory IncidentEventModel.fromDomain(IncidentEvent event) =>
      IncidentEventModel(
        eventId: event.eventId ?? '',
        userId: event.userId,
        timestamp: event.timestamp,
        latitude: event.latitude,
        longitude: event.longitude,
        description: event.description,
        category: event.category?.firestoreValue,
        sourceType: event.sourceType.value,
        photoUrl: event.photoUrl,
        status: event.status.firestoreValue,
        priority: event.priority?.name,
        priorityScore: event.priorityScore,
      );
}

IncidentStatusChange _statusChangeFromMap(Map<String, dynamic> m) {
  final ts = m['timestamp'];
  return IncidentStatusChange(
    status: IncidentStatus.fromString(m['status'] as String? ?? 'recibido'),
    timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    changedBy: m['changedBy'] as String?,
  );
}

Map<String, dynamic> statusChangeToMap(IncidentStatusChange change) => {
      'status': change.status.firestoreValue,
      'timestamp': Timestamp.fromDate(change.timestamp),
      if (change.changedBy != null) 'changedBy': change.changedBy,
    };

ReferentVerification? _referentVerificationFromMap(Map<String, dynamic>? m) {
  if (m == null) return null;
  final state = ReferentVerificationState.fromString(m['state'] as String?);
  final by = m['by'] as String?;
  final photoUrl = m['photoUrl'] as String?;
  if (state == null || by == null || photoUrl == null) return null;
  final at = m['at'];
  return ReferentVerification(
    state: state,
    by: by,
    byDisplayName: m['byDisplayName'] as String?,
    note: m['note'] as String?,
    photoUrl: photoUrl,
    at: at is Timestamp ? at.toDate() : DateTime.now(),
  );
}

Map<String, dynamic> referentVerificationToMap(ReferentVerification v) => {
      'state': v.state.firestoreValue,
      'by': v.by,
      if (v.byDisplayName != null) 'byDisplayName': v.byDisplayName,
      if (v.note != null && v.note!.trim().isNotEmpty) 'note': v.note!.trim(),
      'photoUrl': v.photoUrl,
      'at': Timestamp.fromDate(v.at),
    };

ResolutionAction? _resolutionActionFromMap(Map<String, dynamic> m) {
  final note = m['note'] as String?;
  final by = m['by'] as String?;
  if (note == null || by == null || note.trim().isEmpty) return null;
  final at = m['at'];
  return ResolutionAction(
    note: note,
    by: by,
    byDisplayName: m['byDisplayName'] as String?,
    at: at is Timestamp ? at.toDate() : DateTime.now(),
  );
}

Map<String, dynamic> resolutionActionToMap(ResolutionAction a) => {
      'note': a.note.trim(),
      'by': a.by,
      if (a.byDisplayName != null) 'byDisplayName': a.byDisplayName,
      'at': Timestamp.fromDate(a.at),
    };

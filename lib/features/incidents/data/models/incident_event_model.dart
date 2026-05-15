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

  factory IncidentEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final ts = data['timestamp'];
    final datetime = ts is Timestamp ? ts.toDate() : DateTime.now();
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
    category: category != null ? IncidentCategory.fromString(category!) : null,
    sourceType: SourceType.fromString(sourceType),
    photoUrl: photoUrl,
    status: IncidentStatus.fromString(status),
    priority: priority != null ? IncidentPriority.fromString(priority!) : null,
    priorityScore: priorityScore,
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

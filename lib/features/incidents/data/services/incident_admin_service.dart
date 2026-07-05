import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/incident_event.dart';
import '../models/incident_event_model.dart';

/// Operaciones del Administrador sobre el incident que cierran RF-ADM-03:
/// (re)asignar categoría y registrar acciones de resolución. [D-06]
///
/// La autorización la hacen las reglas Firestore: solo `isAdmin()` puede tocar
/// `category`, `categoryChangedBy`, `categoryChangedAt` y `actions`. El servicio
/// asume que el caller ya pasó por la regla — no re-valida.
class IncidentAdminService {
  IncidentAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> reassignCategory({
    required String incidentId,
    required IncidentCategory category,
    required String adminUid,
  }) async {
    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'category': category.firestoreValue,
        'categoryChangedBy': adminUid,
        'categoryChangedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'Error al reasignar la categoría.',
      );
    }
  }

  Future<void> addAction({
    required String incidentId,
    required String note,
    required String adminUid,
    String? adminDisplayName,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw const FirestoreException(
        'La acción no puede estar vacía.',
      );
    }
    final action = ResolutionAction(
      note: trimmed,
      by: adminUid,
      byDisplayName: adminDisplayName,
      at: DateTime.now(),
    );
    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'actions': FieldValue.arrayUnion([resolutionActionToMap(action)]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'Error al registrar la acción.',
      );
    }
  }
}

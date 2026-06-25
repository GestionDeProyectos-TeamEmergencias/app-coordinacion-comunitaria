import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/incident_event.dart';

/// Persiste / borra la reacción de un vecino sobre un incident. [F-04]
///
/// Path: `incidents/{incidentId}/reactions/{userId}`. Las reglas Firestore
/// validan que el caller es activo, que el doc tiene su uid y que no es el
/// dueño del incident.
class ReactionsService {
  ReactionsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Suscribe a la reacción del user sobre el incident. Emite `null` si todavía
  /// no votó.
  Stream<ReactionType?> watchMyReaction({
    required String incidentId,
    required String userId,
  }) {
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('reactions')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ReactionType.fromString(doc.data()?['type'] as String?);
    });
  }

  /// Crea o actualiza la reacción. Si el user ya votó lo mismo, no hace nada
  /// (idempotencia). Si el user quiere retirar el voto se usa `remove`.
  Future<void> setReaction({
    required String incidentId,
    required String userId,
    required ReactionType type,
  }) async {
    try {
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('reactions')
          .doc(userId)
          .set({
        'type': type.firestoreValue,
        'by': userId,
        'at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'No se pudo registrar tu reacción.',
      );
    }
  }

  Future<void> removeReaction({
    required String incidentId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('reactions')
          .doc(userId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'No se pudo retirar tu reacción.',
      );
    }
  }
}

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/incident_event.dart';
import '../models/incident_event_model.dart';

/// Persiste la verificación de campo del Referente Barrial sobre un incidente.
/// [D-05 / RF-ROL-02(b)]
///
/// Diseño:
/// - La foto es **obligatoria** (es la evidencia que pide el RF). Sin ella el
///   servicio rechaza la operación.
/// - Sube la evidencia a `incidents/{incidentId}/verifications/{uuid}.jpg`
///   (path separado de las fotos del reportero para auditoría más fácil y
///   para diferenciar permisos cuando se agreguen `storage.rules` (D-09)).
/// - Actualiza el doc del incidente con `referentVerification` (último estado)
///   y agrega al `referentVerificationHistory` (auditoría). Las reglas del
///   referente solo le permiten tocar esos dos campos (D-05 acompaña).
class ReferentVerificationService {
  ReferentVerificationService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> verify({
    required String incidentId,
    required ReferentVerificationState state,
    required Uint8List photoBytes,
    required String photoName,
    required String referentUid,
    String? referentDisplayName,
    String? note,
  }) async {
    if (photoBytes.isEmpty) {
      throw const StorageException(
        'La verificación requiere una foto como evidencia.',
      );
    }

    final String photoUrl;
    try {
      final ext = photoName.contains('.') ? photoName.split('.').last : 'jpg';
      final path =
          'incidents/$incidentId/verifications/${const Uuid().v4()}.$ext';
      final ref = _storage.ref(path);
      await ref.putData(
        photoBytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      photoUrl = await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        e.message ?? 'Error al subir la foto de evidencia.',
      );
    }

    final verification = ReferentVerification(
      state: state,
      by: referentUid,
      byDisplayName: referentDisplayName,
      at: DateTime.now(),
      note: note,
      photoUrl: photoUrl,
    );
    final map = referentVerificationToMap(verification);

    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'referentVerification': map,
        'referentVerificationHistory': FieldValue.arrayUnion([map]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'Error al registrar la verificación.',
      );
    }
  }
}

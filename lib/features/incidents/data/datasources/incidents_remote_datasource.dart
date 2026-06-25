import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/incident_event.dart';
import '../models/incident_event_model.dart';

class IncidentsRemoteDataSource {
  IncidentsRemoteDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  /// Sube foto a Storage como bytes y retorna la URL de descarga. [T-REP-03]
  ///
  /// Usa `putData` en lugar de `putFile` para que funcione tanto en mobile
  /// como en Flutter Web (donde `dart:io.File` no está disponible).
  Future<String> uploadPhoto(
    Uint8List bytes,
    String fileName,
    String userId,
  ) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final path = 'incidents/$userId/${const Uuid().v4()}.$ext';
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(e.message ?? 'Error al subir la foto.');
    }
  }

  /// Envía el evento como documento a Firestore y retorna el eventId.
  /// Inicializa `statusHistory` con la primera entrada (estado inicial). [T-REP-06]
  Future<String> submitIncident(IncidentEvent event) async {
    try {
      final model = IncidentEventModel.fromDomain(event);
      final doc = await _incidents.add({
        ...model.toFirestore(),
        'statusHistory': [
          {
            'status': model.status,
            'timestamp': Timestamp.fromDate(event.timestamp),
            'changedBy': model.userId,
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error al enviar el reporte.');
    }
  }

  Stream<List<IncidentEventModel>> watchIncidents() {
    return _incidents.orderBy('timestamp', descending: true).snapshots().map(
          (snap) => snap.docs.map(IncidentEventModel.fromFirestore).toList(),
        );
  }

  /// Stream de los incidents propios del user actual, sin filtro de status
  /// (incluye solucionados, falsos, etc.). Ordenado por fecha desc. [F-01]
  Stream<List<IncidentEventModel>> watchMyIncidents(String userId) {
    return _incidents
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(IncidentEventModel.fromFirestore).toList(),
        );
  }

  /// Actualiza los campos editables por el dueño en estado `recibido`.
  /// Solo se persisten los campos no-null pasados. La regla Firestore valida
  /// que el caller es el dueño activo y que el incident sigue en `recibido`.
  /// [F-01]
  Future<void> updateOwnIncidentDraft(
    String eventId, {
    String? description,
    String? category,
    String? photoUrl,
  }) async {
    final patch = <String, dynamic>{
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
    if (patch.isEmpty) return;
    try {
      await _incidents.doc(eventId).update(patch);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'No se pudo actualizar el reporte.',
      );
    }
  }

  Future<IncidentEventModel> getIncidentById(String eventId) async {
    final doc = await _incidents.doc(eventId).get();
    if (!doc.exists) {
      throw FirestoreException('Incidente $eventId no encontrado.');
    }
    return IncidentEventModel.fromFirestore(doc);
  }

  Stream<IncidentEventModel> watchIncidentById(String eventId) {
    return _incidents.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) {
        throw FirestoreException('Incidente $eventId no encontrado.');
      }
      return IncidentEventModel.fromFirestore(doc);
    });
  }

  Future<void> updateStatus(
    String eventId,
    String status, {
    String? changedBy,
  }) async {
    // F-05: cuando el cierre llega a `solucionado`, inicializamos la validación
    // bilateral con `closureConfirmation.state = pendiente`. El reportero verá
    // los botones Confirmar/Disputar y recibirá push (trigger backend).
    final patch = <String, dynamic>{
      'status': status,
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'timestamp': Timestamp.now(),
          if (changedBy != null) 'changedBy': changedBy,
        }
      ]),
    };
    if (status == 'solucionado' && changedBy != null) {
      patch['closureConfirmation'] = {
        'state': 'pendiente',
        'by': changedBy,
        'at': Timestamp.now(),
      };
    }
    await _incidents.doc(eventId).update(patch);
  }

  /// El reportero confirma el cierre. Solo aplicable cuando
  /// `closureConfirmation.state == pendiente`. [F-05]
  Future<void> confirmOwnClosure({
    required String eventId,
    required String ownerUid,
  }) async {
    try {
      await _incidents.doc(eventId).update({
        'closureConfirmation': {
          'state': 'confirmado',
          'by': ownerUid,
          'at': Timestamp.now(),
        },
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'No se pudo confirmar el cierre.',
      );
    }
  }

  /// El reportero disputa el cierre con nota obligatoria. La regla Firestore
  /// permite la transición simultánea: status → en_reparacion y
  /// closureConfirmation.state → disputado. [F-05]
  Future<void> disputeOwnClosure({
    required String eventId,
    required String ownerUid,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw const FirestoreException(
        'La disputa requiere una nota.',
      );
    }
    try {
      await _incidents.doc(eventId).update({
        'status': 'en_reparacion',
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'en_reparacion',
            'timestamp': Timestamp.now(),
            'changedBy': ownerUid,
          }
        ]),
        'closureConfirmation': {
          'state': 'disputado',
          'by': ownerUid,
          'at': Timestamp.now(),
          'note': trimmed,
        },
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        e.message ?? 'No se pudo registrar tu disputa.',
      );
    }
  }
}

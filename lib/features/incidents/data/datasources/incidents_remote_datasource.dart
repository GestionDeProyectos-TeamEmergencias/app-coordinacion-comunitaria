import 'dart:io';

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

  /// Sube foto a Storage y retorna la URL de descarga. [T-REP-03]
  Future<String> uploadPhoto(File photo, String userId) async {
    try {
      final ext = photo.path.split('.').last;
      final path = 'incidents/$userId/${const Uuid().v4()}.$ext';
      final ref = _storage.ref(path);
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(e.message ?? 'Error al subir la foto.');
    }
  }

  /// Envía el evento como documento a Firestore y retorna el eventId.
  Future<String> submitIncident(IncidentEvent event) async {
    try {
      final model = IncidentEventModel.fromDomain(event);
      final doc = await _incidents.add({
        ...model.toFirestore(),
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

  Future<IncidentEventModel> getIncidentById(String eventId) async {
    final doc = await _incidents.doc(eventId).get();
    if (!doc.exists)
      throw FirestoreException('Incidente $eventId no encontrado.');
    return IncidentEventModel.fromFirestore(doc);
  }

  Future<void> updateStatus(String eventId, String status) async {
    await _incidents.doc(eventId).update({'status': status});
  }
}

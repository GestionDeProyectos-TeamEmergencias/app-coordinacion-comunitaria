import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/app_exception.dart';

/// Sube el comprobante de servicio a Firebase Storage y registra la URL en el
/// documento del usuario. Path en Storage: `identity_proofs/{uid}/proof.{ext}`.
/// [T-AUTH-09 + D-09]
///
/// El path cambió de `identity_proofs/{uid}.{ext}` (legacy) a una carpeta
/// dedicada para que `storage.rules` pueda matcher por dueño con sintaxis
/// estándar (sin regex). La re-subida sobreescribe el archivo anterior, lo
/// que evita acumular comprobantes huérfanos. Los archivos legacy quedan
/// accesibles por read-only via una regla específica en `storage.rules`.
///
/// Usa `putData` con bytes para que funcione tanto en mobile como en Flutter
/// Web (donde `dart:io.File` no está disponible).
class IdentityProofUploader {
  IdentityProofUploader({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<String> uploadProof({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final path = 'identity_proofs/$userId/proof.$ext';
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(userId).update({
        'identityProofUrl': url,
        'identityProofUploadedAt': FieldValue.serverTimestamp(),
      });
      return url;
    } on FirebaseException catch (e) {
      throw StorageException(e.message ?? 'Error al subir el comprobante.');
    }
  }
}

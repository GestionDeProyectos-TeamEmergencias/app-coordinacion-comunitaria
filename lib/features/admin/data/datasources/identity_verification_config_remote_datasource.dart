import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/identity_verification_config.dart';

/// Datasource para `config/identity_verification`. [T-AUTH-09]
class IdentityVerificationConfigRemoteDataSource {
  IdentityVerificationConfigRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.collection('config').doc('identity_verification');

  Stream<IdentityVerificationConfig> watchConfig() {
    return _docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return IdentityVerificationConfig.defaults;
      }
      final mode = snapshot.data()?['mode'] as String? ?? 'manual';
      return IdentityVerificationConfig(
        mode: IdentityVerificationMode.fromString(mode),
      );
    });
  }

  Future<void> updateConfig(IdentityVerificationConfig config) async {
    await _docRef.set({
      'mode': config.mode.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

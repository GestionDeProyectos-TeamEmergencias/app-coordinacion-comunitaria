import 'package:cloud_firestore/cloud_firestore.dart';

/// Persiste el consentimiento del usuario sobre los Términos y Condiciones
/// en `users/{uid}`. [D-04]
///
/// Las reglas Firestore (firestore.rules:62-67) ya permiten al dueño editar su
/// propio doc salvo los campos `role`, `status`, `reputationScore` y
/// `falseReportsCount`; `termsAcceptedAt` y `termsAcceptedVersion` no están en
/// esa blacklist, así que este update funciona sin cambiar reglas.
class TermsAcceptanceService {
  TermsAcceptanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> accept({required String userId, required int version}) {
    return _firestore.collection('users').doc(userId).update({
      'termsAcceptedVersion': version,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    });
  }
}

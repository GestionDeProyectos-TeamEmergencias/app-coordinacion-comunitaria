import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _users
          .doc(firebaseUser.uid)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (s, _) => s.data()!,
            toFirestore: (d, _) => d,
          )
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    });
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final model = UserModel(
        userId: uid,
        email: email,
        displayName: displayName,
        role: 'vecino_informante',
        status: 'pending',
        reputationScore: 100.0,
      );
      await _users.doc(uid).set({
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Error al registrar.');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _users
          .doc(credential.user!.uid)
          .get();
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Error al iniciar sesión.');
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final doc = await _users.doc(firebaseUser.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}

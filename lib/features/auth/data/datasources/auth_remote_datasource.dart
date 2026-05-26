import 'dart:async';

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

  /// Stream en tiempo real del usuario autenticado. [T-AUTH-01]
  ///
  /// Combina Firebase Auth state changes con un listener en tiempo real del
  /// documento Firestore del usuario, de modo que cuando el admin aprueba o
  /// rechaza la cuenta, el cambio se propaga automáticamente sin reiniciar la app.
  Stream<UserModel?> get authStateChanges {
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;

    // ignore: close_sinks  — el ciclo de vida lo gestiona onCancel
    late final StreamController<UserModel?> controller;
    controller = StreamController<UserModel?>.broadcast(
      onListen: () {
        authSub = _auth.authStateChanges().listen(
          (firebaseUser) {
            // Cuando cambia el usuario autenticado, cancelamos el listener
            // anterior del documento y abrimos uno nuevo.
            docSub?.cancel();
            docSub = null;

            if (firebaseUser == null) {
              controller.add(null);
              return;
            }

            docSub = _users.doc(firebaseUser.uid).snapshots().listen(
                  (doc) => controller.add(
                    doc.exists ? UserModel.fromFirestore(doc) : null,
                  ),
                  // ignore: avoid_types_on_closure_parameters
                  onError: (Object e, StackTrace st) =>
                      controller.addError(e, st),
                );
          },
          // ignore: avoid_types_on_closure_parameters
          onError: (Object e, StackTrace st) => controller.addError(e, st),
        );
      },
      onCancel: () {
        docSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
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
      final doc = await _users.doc(credential.user!.uid).get();
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Error al iniciar sesión.');
    }
  }

  // ── Gestión de usuarios pendientes (T-AUTH-01) ────────────────────────────

  /// Stream en tiempo real de documentos con status == "pending".
  Stream<List<UserModel>> get pendingUsersStream =>
      _users.where('status', isEqualTo: 'pending').snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );

  /// Cambia el status del usuario a "active" (aprobación). [T-AUTH-01]
  Future<void> approveUser(String uid) async {
    try {
      await _users.doc(uid).update({'status': 'active'});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error al aprobar usuario.');
    }
  }

  /// Cambia el status del usuario a "rejected" (rechazo). [T-AUTH-01]
  Future<void> rejectUser(String uid) async {
    try {
      await _users.doc(uid).update({'status': 'rejected'});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error al rechazar usuario.');
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

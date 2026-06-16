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
        falseReportsCount: 0,
        isBlocked: false,
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
      String errorMessage;

      // Intercept the Firebase error code and swap it for a friendly message
      switch (e.code) {
        case 'invalid-credential':
          errorMessage =
              'El correo o la contraseña son incorrectos. Por favor, verifica tus datos e intenta de nuevo.';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        case 'user-disabled':
          errorMessage =
              'Esta cuenta ha sido deshabilitada por la administración vecinal.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Demasiados intentos fallidos. Por favor, esperá unos minutos e intenta de nuevo.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Error de conexión. Revisa tu internet e intenta de nuevo.';
          break;
        default:
          errorMessage =
              'Ocurrió un error inesperado al iniciar sesión. (Código: ${e.code})';
      }

      // Throw the new translated string instead of e.message
      throw AuthException(errorMessage);
    } catch (e) {
      // A good fallback just in case something fails outside of Firebase Auth
      throw const AuthException(
          'Ocurrió un error inesperado. Por favor, intentá de nuevo.');
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

  Future<void> resetPassword({required String email}) async {
    if (email.trim().isEmpty) {
      throw const AuthException('Por favor, ingresá un correo electrónico.');
    }

    try {
      // Firebase handles sending the email automatically
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        // Note: Depending on your Firebase email enumeration protection settings,
        // 'auth/user-not-found' might not be thrown anymore. It's good to catch it just in case.
        case 'user-not-found':
          errorMessage =
              'No encontramos ninguna cuenta vinculada a este correo.';
          break;
        default:
          errorMessage =
              'Ocurrió un error al enviar el enlace. (Código: ${e.code})';
      }

      throw AuthException(errorMessage);
    } catch (e) {
      throw const AuthException(
          'Ocurrió un error inesperado. Por favor, intentá de nuevo.');
    }
  }
}

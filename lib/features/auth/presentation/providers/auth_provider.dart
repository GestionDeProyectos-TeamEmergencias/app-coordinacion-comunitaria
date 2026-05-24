import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/approve_user_usecase.dart';
import '../../domain/usecases/get_pending_users_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reject_user_usecase.dart';

// ── Infraestructura ────────────────────────────────────────────────────────────

final _firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(_firebaseAuthProvider),
    ref.watch(_firestoreProvider),
  );
});

final _authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(_authDataSourceProvider));
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(_authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(_authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(_authRepositoryProvider));
});

// ── Use cases — gestión de usuarios pendientes (T-AUTH-01) ───────────────────

final getPendingUsersUseCaseProvider = Provider<GetPendingUsersUseCase>((ref) {
  return GetPendingUsersUseCase(ref.watch(_authRepositoryProvider));
});

final approveUserUseCaseProvider = Provider<ApproveUserUseCase>((ref) {
  return ApproveUserUseCase(ref.watch(_authRepositoryProvider));
});

final rejectUserUseCaseProvider = Provider<RejectUserUseCase>((ref) {
  return RejectUserUseCase(ref.watch(_authRepositoryProvider));
});

// ── Estado de autenticación (stream) ──────────────────────────────────────────

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(_authRepositoryProvider).authStateChanges;
});

/// Stream en tiempo real de usuarios pendientes de aprobación. [T-AUTH-01]
final pendingUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(getPendingUsersUseCaseProvider)();
});

// ── Notifier para operaciones de auth ─────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(loginUseCaseProvider)(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(registerUseCaseProvider)(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(logoutUseCaseProvider)(),
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);

// ── Notifier para operaciones del admin sobre usuarios (T-AUTH-01) ────────────

/// Maneja las acciones de aprobación y rechazo de cuentas pendientes.
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  UserManagementNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> approveUser(String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(approveUserUseCaseProvider)(uid),
    );
  }

  Future<void> rejectUser(String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(rejectUserUseCaseProvider)(uid),
    );
  }
}

final userManagementNotifierProvider =
    StateNotifierProvider<UserManagementNotifier, AsyncValue<void>>(
  (ref) => UserManagementNotifier(ref),
);

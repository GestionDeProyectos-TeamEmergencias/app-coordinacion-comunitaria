import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/approve_user_usecase.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/reject_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ApproveUserUseCase approveUseCase;
  late RejectUserUseCase rejectUseCase;

  const tUid = 'uid-pendiente-123';

  setUp(() {
    mockRepo = MockAuthRepository();
    approveUseCase = ApproveUserUseCase(mockRepo);
    rejectUseCase = RejectUserUseCase(mockRepo);
  });

  group('ApproveUserUseCase', () {
    test('delega correctamente en el repositorio al aprobar', () async {
      when(() => mockRepo.approveUser(any())).thenAnswer((_) async {});

      await approveUseCase(tUid);

      verify(() => mockRepo.approveUser(tUid)).called(1);
    });

    test('propaga FirestoreException si el repositorio falla', () async {
      when(() => mockRepo.approveUser(any()))
          .thenThrow(const FirestoreException('Error de Firestore.'));

      expect(
        () => approveUseCase(tUid),
        throwsA(isA<FirestoreException>()),
      );
    });
  });

  group('RejectUserUseCase', () {
    test('delega correctamente en el repositorio al rechazar', () async {
      when(() => mockRepo.rejectUser(any())).thenAnswer((_) async {});

      await rejectUseCase(tUid);

      verify(() => mockRepo.rejectUser(tUid)).called(1);
    });

    test('propaga FirestoreException si el repositorio falla', () async {
      when(() => mockRepo.rejectUser(any()))
          .thenThrow(const FirestoreException('Error de Firestore.'));

      expect(
        () => rejectUseCase(tUid),
        throwsA(isA<FirestoreException>()),
      );
    });
  });
}

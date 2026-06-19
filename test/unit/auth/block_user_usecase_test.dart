import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/block_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  const tUid = 'uid-123';

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('BlockUserUseCase', () {
    test('delega en el repositorio al bloquear', () async {
      when(() => mockRepo.blockUser(any())).thenAnswer((_) async {});
      final useCase = BlockUserUseCase(mockRepo);

      await useCase(tUid);

      verify(() => mockRepo.blockUser(tUid)).called(1);
    });

    test('propaga FirestoreException si el repositorio falla', () async {
      when(() => mockRepo.blockUser(any()))
          .thenThrow(const FirestoreException('boom'));
      final useCase = BlockUserUseCase(mockRepo);

      expect(() => useCase(tUid), throwsA(isA<FirestoreException>()));
    });
  });
}

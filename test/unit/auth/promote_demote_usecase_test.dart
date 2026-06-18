import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/demote_to_vecino_usecase.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/get_active_users_usecase.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/promote_to_referent_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  const tUid = 'uid-123';

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('PromoteToReferentUseCase', () {
    test('delega en el repositorio al promover', () async {
      when(() => mockRepo.promoteToReferent(any())).thenAnswer((_) async {});
      final useCase = PromoteToReferentUseCase(mockRepo);

      await useCase(tUid);

      verify(() => mockRepo.promoteToReferent(tUid)).called(1);
    });

    test('propaga FirestoreException si el repositorio falla', () async {
      when(() => mockRepo.promoteToReferent(any()))
          .thenThrow(const FirestoreException('boom'));
      final useCase = PromoteToReferentUseCase(mockRepo);

      expect(() => useCase(tUid), throwsA(isA<FirestoreException>()));
    });
  });

  group('DemoteToVecinoUseCase', () {
    test('delega en el repositorio al degradar', () async {
      when(() => mockRepo.demoteToVecino(any())).thenAnswer((_) async {});
      final useCase = DemoteToVecinoUseCase(mockRepo);

      await useCase(tUid);

      verify(() => mockRepo.demoteToVecino(tUid)).called(1);
    });

    test('propaga FirestoreException si el repositorio falla', () async {
      when(() => mockRepo.demoteToVecino(any()))
          .thenThrow(const FirestoreException('boom'));
      final useCase = DemoteToVecinoUseCase(mockRepo);

      expect(() => useCase(tUid), throwsA(isA<FirestoreException>()));
    });
  });

  group('GetActiveUsersUseCase', () {
    test('forwardea el filtro de rol al repositorio', () {
      when(() => mockRepo.activeUsersStream(role: any(named: 'role')))
          .thenAnswer((_) => const Stream.empty());
      final useCase = GetActiveUsersUseCase(mockRepo);

      useCase(role: UserRole.referenteBarrial);

      verify(() => mockRepo.activeUsersStream(role: UserRole.referenteBarrial))
          .called(1);
    });

    test('llama sin filtro cuando role es null', () {
      when(() => mockRepo.activeUsersStream(role: any(named: 'role')))
          .thenAnswer((_) => const Stream.empty());
      final useCase = GetActiveUsersUseCase(mockRepo);

      useCase();

      verify(() => mockRepo.activeUsersStream(role: null)).called(1);
    });
  });
}

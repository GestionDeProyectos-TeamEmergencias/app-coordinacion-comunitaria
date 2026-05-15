import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase sut;
  late MockAuthRepository mockRepo;

  const tUser = AppUser(
    userId: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test User',
    role: UserRole.vecinoInformante,
    status: UserStatus.active,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = LoginUseCase(mockRepo);
  });

  test('devuelve AppUser cuando las credenciales son válidas', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => tUser);

    final result = await sut(email: 'test@example.com', password: 'password123');

    expect(result, tUser);
    verify(() => mockRepo.login(email: 'test@example.com', password: 'password123')).called(1);
  });

  test('propaga AuthException cuando las credenciales son inválidas', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenThrow(const AuthException('Credenciales inválidas.'));

    expect(
      () => sut(email: 'test@example.com', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });
}

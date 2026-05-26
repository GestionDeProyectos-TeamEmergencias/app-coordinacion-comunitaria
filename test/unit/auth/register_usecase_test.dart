import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase sut;
  late MockAuthRepository mockRepo;

  const tUser = AppUser(
    userId: 'uid-nuevo',
    email: 'vecino@example.com',
    displayName: 'Vecino Nuevo',
    role: UserRole.vecinoInformante,
    status: UserStatus.pending,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = RegisterUseCase(mockRepo);
  });

  test('retorna AppUser con status pending al registrarse correctamente',
      () async {
    when(
      () => mockRepo.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => tUser);

    final result = await sut(
      email: 'vecino@example.com',
      password: 'password123',
      displayName: 'Vecino Nuevo',
    );

    expect(result, tUser);
    expect(result.status, UserStatus.pending);
    expect(result.role, UserRole.vecinoInformante);
    verify(
      () => mockRepo.register(
        email: 'vecino@example.com',
        password: 'password123',
        displayName: 'Vecino Nuevo',
      ),
    ).called(1);
  });

  test('propaga AuthException cuando el email ya está en uso', () async {
    when(
      () => mockRepo.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(const AuthException('El email ya está registrado.'));

    expect(
      () => sut(
        email: 'vecino@example.com',
        password: 'password123',
        displayName: 'Vecino Nuevo',
      ),
      throwsA(isA<AuthException>()),
    );
  });
}

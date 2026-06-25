import 'package:app_coordinacion_comunitaria/core/constants/terms_config.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/terms/presentation/providers/terms_provider.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user({int? acceptedVersion, DateTime? acceptedAt}) => AppUser(
      userId: 'u1',
      email: 'a@b.com',
      displayName: 'Vecino',
      role: UserRole.vecinoInformante,
      status: UserStatus.active,
      termsAcceptedVersion: acceptedVersion,
      termsAcceptedAt: acceptedAt,
    );

void main() {
  group('hasAcceptedCurrentTerms', () {
    test('false si el usuario nunca aceptó (version null)', () {
      expect(hasAcceptedCurrentTerms(_user()), isFalse);
    });

    test('false si aceptó una versión anterior', () {
      expect(
        hasAcceptedCurrentTerms(
            _user(acceptedVersion: TermsConfig.currentVersion - 1)),
        isFalse,
      );
    });

    test('true si aceptó la versión actual', () {
      expect(
        hasAcceptedCurrentTerms(
            _user(acceptedVersion: TermsConfig.currentVersion)),
        isTrue,
      );
    });

    test('true si aceptó una versión superior (degradación de doc)', () {
      // No debería pasar, pero si pasa, no obligamos a re-aceptar una versión
      // más vieja: el usuario ya está cubierto.
      expect(
        hasAcceptedCurrentTerms(
            _user(acceptedVersion: TermsConfig.currentVersion + 1)),
        isTrue,
      );
    });
  });
}

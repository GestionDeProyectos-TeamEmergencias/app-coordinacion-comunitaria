import 'package:app_coordinacion_comunitaria/app/router.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests del redirect real del router (`resolveRedirect`), no de una copia.
// `null` significa "ubicación permitida"; un string es la ruta de redirección.

AppUser _user(
  UserRole role, {
  UserStatus status = UserStatus.active,
}) {
  return AppUser(
    userId: 'uid',
    email: 'user@test.com',
    displayName: 'Test User',
    role: role,
    status: status,
    // T&C aceptados (versión alta para no depender de TermsConfig.currentVersion).
    termsAcceptedVersion: 999999,
    // El referente necesita coverage para no caer en el setup obligatorio.
    coverageAreaCenter:
        role == UserRole.referenteBarrial ? (latitude: 0, longitude: 0) : null,
  );
}

String? _redirect(AppUser? user, String location, {bool loading = false}) {
  return resolveRedirect(
    auth: loading ? const AsyncLoading<AppUser?>() : AsyncData<AppUser?>(user),
    location: location,
    uri: Uri.parse(location),
  );
}

void main() {
  group('resolveRedirect — RBAC', () {
    test('unauthenticated: loading → splash, sin user → login', () {
      expect(_redirect(null, AppRoutes.home, loading: true), AppRoutes.splash);
      expect(_redirect(null, AppRoutes.home), AppRoutes.login);
    });

    test(
        'vecinoInformante: accede a home/map/profile/reportForm, detalle y mapa '
        'del incidente; NO a admin/adminIncidents/alerts', () {
      final vecino = _user(UserRole.vecinoInformante);

      // Permitidas (null = sin redirección)
      expect(_redirect(vecino, AppRoutes.home), isNull);
      expect(_redirect(vecino, AppRoutes.map), isNull);
      expect(_redirect(vecino, AppRoutes.profile), isNull);
      expect(_redirect(vecino, AppRoutes.reportForm), isNull);
      // [fix] el detalle es la vista pública del barrio: el vecino lo abre.
      expect(_redirect(vecino, AppRoutes.incidentDetailPath('123')), isNull);
      // [feat] subruta de mini-mapa del incidente: también accesible.
      expect(_redirect(vecino, AppRoutes.incidentMapPath('123')), isNull);

      // Bloqueadas → unauthorized
      expect(_redirect(vecino, AppRoutes.admin), AppRoutes.unauthorized);
      expect(_redirect(vecino, AppRoutes.adminUsers), AppRoutes.unauthorized);
      expect(
          _redirect(vecino, AppRoutes.adminIncidents), AppRoutes.unauthorized);
      expect(_redirect(vecino, AppRoutes.alerts), AppRoutes.unauthorized);
    });

    test('referenteBarrial: accede a detalle y alerts; NO a rutas admin', () {
      final referente = _user(UserRole.referenteBarrial);

      expect(_redirect(referente, AppRoutes.home), isNull);
      expect(_redirect(referente, AppRoutes.map), isNull);
      expect(_redirect(referente, AppRoutes.incidentDetailPath('123')), isNull);
      expect(_redirect(referente, AppRoutes.incidentMapPath('123')), isNull);
      expect(_redirect(referente, AppRoutes.alerts), isNull);

      expect(_redirect(referente, AppRoutes.admin), AppRoutes.unauthorized);
      expect(
          _redirect(referente, AppRoutes.adminUsers), AppRoutes.unauthorized);
      expect(_redirect(referente, AppRoutes.adminIncidents),
          AppRoutes.unauthorized);
    });

    test('administrador: accede a todas las rutas', () {
      final admin = _user(UserRole.administrador);

      expect(_redirect(admin, AppRoutes.home), isNull);
      expect(_redirect(admin, AppRoutes.map), isNull);
      expect(_redirect(admin, AppRoutes.incidentDetailPath('123')), isNull);
      expect(_redirect(admin, AppRoutes.incidentMapPath('123')), isNull);
      expect(_redirect(admin, AppRoutes.admin), isNull);
      expect(_redirect(admin, AppRoutes.adminUsers), isNull);
      expect(_redirect(admin, AppRoutes.adminIncidents), isNull);
      expect(_redirect(admin, AppRoutes.alerts), isNull);
    });

    test('cuenta no activa: pending/rejected/blocked redirigen a su página',
        () {
      final pending =
          _user(UserRole.vecinoInformante, status: UserStatus.pending);
      final rejected =
          _user(UserRole.vecinoInformante, status: UserStatus.rejected);
      final blocked =
          _user(UserRole.vecinoInformante, status: UserStatus.blocked);

      expect(_redirect(pending, AppRoutes.home), AppRoutes.pending);
      expect(_redirect(rejected, AppRoutes.home), AppRoutes.rejected);
      expect(_redirect(blocked, AppRoutes.home), AppRoutes.blocked);
    });
  });
}

import 'package:app_coordinacion_comunitaria/app/router.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAppUser extends Mock implements AppUser {}

// Helper para crear un GoRouter con el authStateProvider mockeado
GoRouter _setupRouter(AsyncValue<AppUser?> authState) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoading = authState.isLoading; // Use isLoading from AsyncValue
      final loc = state.matchedLocation;

      // Show splash while Firebase Auth resolves (T-REP-01)
      if (isLoading) return loc == AppRoutes.splash ? null : AppRoutes.splash;

      final user = authState.valueOrNull; // Use valueOrNull from AsyncValue
      final isOnAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

      if (user == null) return isOnAuthPage ? null : AppRoutes.login;

      if (user.status == UserStatus.pending) {
        return loc == AppRoutes.pending ? null : AppRoutes.pending;
      }

      // Cuenta rechazada: redirigir a página de rechazo. [T-AUTH-01]
      if (user.status == UserStatus.rejected) {
        return loc == AppRoutes.rejected ? null : AppRoutes.rejected;
      }

      if (isOnAuthPage ||
          loc == AppRoutes.splash ||
          loc == AppRoutes.pending ||
          loc == AppRoutes.rejected) {
        return AppRoutes.home;
      }

      // --- RBAC: Restricciones de acceso por rol (T-AUTH-03) ---

      // Rutas de administrador
      if (loc.startsWith(AppRoutes.admin)) {
        if (user.role != UserRole.administrador) {
          return AppRoutes.unauthorized;
        }
      }

      // Rutas de moderación (Referente Barrial o Administrador)
      if (loc.startsWith(AppRoutes.incidentDetail.split(':')[0]) ||
          loc == AppRoutes.adminIncidents ||
          loc == AppRoutes.alerts) {
        if (!user.role.canVerify) {
          return AppRoutes.unauthorized;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.pending, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.rejected, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.reportForm, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.map, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const SizedBox()),
      GoRoute(
          path: AppRoutes.incidentDetail, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.admin, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.adminUsers, builder: (_, __) => const SizedBox()),
      GoRoute(
          path: AppRoutes.adminIncidents, builder: (_, __) => const SizedBox()),
      GoRoute(path: AppRoutes.alerts, builder: (_, __) => const SizedBox()),
      GoRoute(
          path: AppRoutes.unauthorized, builder: (_, __) => const SizedBox()),
    ],
  );
}

void main() {
  group('GoRouter RBAC', () {
    late MockAppUser mockVecino;
    late MockAppUser mockReferente;
    late MockAppUser mockAdmin;

    setUp(() {
      // Setup mock users
      mockVecino = MockAppUser();
      when(() => mockVecino.role).thenReturn(UserRole.vecinoInformante);
      when(() => mockVecino.status).thenReturn(UserStatus.active);

      mockReferente = MockAppUser();
      when(() => mockReferente.role).thenReturn(UserRole.referenteBarrial);
      when(() => mockReferente.status).thenReturn(UserStatus.active);

      mockAdmin = MockAppUser();
      when(() => mockAdmin.role).thenReturn(UserRole.administrador);
      when(() => mockAdmin.status).thenReturn(UserStatus.active);
    });

    testWidgets('unauthenticated user is redirected to login', (tester) async {
      final router =
          _setupRouter(const AsyncLoading()); // Simulate loading state
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle(); // Wait for redirect

      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.splash);

      final router2 = _setupRouter(const AsyncData(null)); // Simulate no user
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: router2),
      ));
      await tester.pumpAndSettle(); // Wait for redirect

      expect(router2.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.login);
    });

    testWidgets(
        'vecinoInformante can access home, map, profile, reportForm, but not admin or incidentDetail',
        (tester) async {
      final router = _setupRouter(AsyncData(mockVecino));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Accessible routes
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.home);

      router.go(AppRoutes.map);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.map);

      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.profile);

      router.go(AppRoutes.reportForm);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.reportForm);

      // Inaccessible routes should redirect to unauthorized
      router.go(AppRoutes.admin);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      router.go(AppRoutes.adminUsers);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      router.go(AppRoutes.adminIncidents);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      router.go(AppRoutes.incidentDetailPath('123'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      // [T-AUTH-04] /alerts requiere canVerify
      router.go(AppRoutes.alerts);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);
    });

    testWidgets(
        'referenteBarrial can access home, map, profile, reportForm, incidentDetail, but not admin routes',
        (tester) async {
      final router = _setupRouter(AsyncData(mockReferente));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Accessible routes
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.home);

      router.go(AppRoutes.map);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.map);

      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.profile);

      router.go(AppRoutes.reportForm);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.reportForm);

      router.go(AppRoutes.incidentDetailPath('123'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.incidentDetailPath('123'));

      // Inaccessible routes should redirect to unauthorized
      router.go(AppRoutes.admin);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      router.go(AppRoutes.adminUsers);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      router.go(AppRoutes.adminIncidents);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.unauthorized);

      // [T-AUTH-04] referente puede ingresar a /alerts
      router.go(AppRoutes.alerts);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.alerts);
    });

    testWidgets('administrador can access all routes', (tester) async {
      final router = _setupRouter(AsyncData(mockAdmin));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Accessible routes
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.home);

      router.go(AppRoutes.map);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.map);

      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.profile);

      router.go(AppRoutes.reportForm);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.reportForm);

      router.go(AppRoutes.incidentDetailPath('123'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.incidentDetailPath('123'));

      router.go(AppRoutes.admin);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.admin);

      router.go(AppRoutes.adminUsers);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.adminUsers);

      router.go(AppRoutes.adminIncidents);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.adminIncidents);

      // [T-AUTH-04] administrador también puede ingresar a /alerts
      router.go(AppRoutes.alerts);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.alerts);
    });
  });
}

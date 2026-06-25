import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_broadcast_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/algorithm_config_page.dart';
import '../features/admin/presentation/pages/coverage_config_page.dart';
import '../features/admin/presentation/pages/identity_verification_config_page.dart';
import '../features/admin/presentation/pages/incident_moderation_page.dart';
import '../features/admin/presentation/pages/users_management_page.dart';
import '../features/alerts/presentation/pages/referent_alerts_page.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/pages/blocked_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/pending_approval_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/rejected_page.dart';
import '../features/auth/presentation/pages/unauthorized_access_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/incidents/presentation/pages/home_page.dart';
import '../features/incidents/presentation/pages/incident_detail_page.dart';
import '../features/incidents/presentation/pages/report_form_page.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../features/notifications/presentation/pages/referent_location_setup_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/terms/presentation/pages/terms_page.dart';
import '../features/terms/presentation/providers/terms_provider.dart';
import 'main_shell.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const pending = '/pending';
  static const rejected = '/rejected';
  static const blocked = '/blocked';
  static const home = '/home';
  static const reportForm = '/report/form';
  static const map = '/map';
  static const profile = '/profile';
  static const incidentDetail = '/incident/:id';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminIncidents = '/admin/incidents';
  static const adminCoverage = '/admin/coverage';
  static const adminIdentityVerification = '/admin/identity-verification';
  static const adminAlgorithmConfig = '/admin/algorithm-config';
  static const adminBroadcast = '/admin/broadcast';
  static const alerts = '/alerts';
  static const unauthorized = '/unauthorized';
  // Setup obligatorio de ubicación para Referentes Barriales. [D-01]
  static const referentLocationSetup = '/referent/setup-location';
  // Términos y Condiciones (gate y reader, según query param). [D-04]
  static const terms = '/terms';

  static String incidentDetailPath(String id) => '/incident/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final loc = state.matchedLocation;

      // Show splash while Firebase Auth resolves (T-REP-01)
      if (isLoading) return loc == AppRoutes.splash ? null : AppRoutes.splash;

      final user = authState.valueOrNull;
      final isOnAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

      if (user == null) return isOnAuthPage ? null : AppRoutes.login;

      if (user.status == UserStatus.pending) {
        return loc == AppRoutes.pending ? null : AppRoutes.pending;
      }

      // Cuenta rechazada: redirigir a página de rechazo. [T-AUTH-01]
      if (user.status == UserStatus.rejected) {
        return loc == AppRoutes.rejected ? null : AppRoutes.rejected;
      }

      // Cuenta bloqueada por reportes falsos: redirigir a página de bloqueo. [T-AUTH-07]
      if (user.status == UserStatus.blocked) {
        return loc == AppRoutes.blocked ? null : AppRoutes.blocked;
      }

      if (isOnAuthPage ||
          loc == AppRoutes.splash ||
          loc == AppRoutes.pending ||
          loc == AppRoutes.rejected ||
          loc == AppRoutes.blocked) {
        return AppRoutes.home;
      }

      // Referente Barrial activo sin ubicación de cobertura → setup obligatorio.
      // El backend (findNearbyReferentes) descarta referentes sin coverageLat/Lng,
      // por lo que no recibirían pushes hasta completar este paso. [D-01]
      if (user.role == UserRole.referenteBarrial &&
          user.coverageAreaCenter == null) {
        return loc == AppRoutes.referentLocationSetup
            ? null
            : AppRoutes.referentLocationSetup;
      }

      // Una vez seteada la ubicación, no permitir volver a la pantalla de setup.
      if (loc == AppRoutes.referentLocationSetup) {
        return AppRoutes.home;
      }

      // Usuario activo sin T&C aceptados (o con versión obsoleta) → gate. [D-04]
      // El modo `reader` (accedido desde Perfil) lleva query `?mode=read` y NO
      // es bloqueado: el usuario ya aceptó, está consultando.
      final isReaderMode = state.uri.queryParameters['mode'] == 'read';
      if (!hasAcceptedCurrentTerms(user) && !isReaderMode) {
        return loc == AppRoutes.terms ? null : AppRoutes.terms;
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
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (_, __) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: AppRoutes.rejected,
        builder: (_, __) => const RejectedPage(),
      ),
      GoRoute(
        path: AppRoutes.blocked,
        builder: (_, __) => const BlockedPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.reportForm,
              builder: (_, __) => const ReportFormPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (_, __) => const MapPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfilePage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.incidentDetail,
        builder: (_, state) => IncidentDetailPage(
          incidentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (_, __) => const UsersManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.adminIncidents,
        builder: (_, __) => const IncidentModerationPage(),
      ),
      GoRoute(
        path: AppRoutes.adminCoverage,
        builder: (_, __) => const CoverageConfigPage(),
      ),
      GoRoute(
        path: AppRoutes.adminIdentityVerification,
        builder: (_, __) => const IdentityVerificationConfigPage(),
      ),
      GoRoute(
        path: AppRoutes.adminAlgorithmConfig,
        builder: (_, __) => const AlgorithmConfigPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBroadcast,
        builder: (_, __) => const AdminBroadcastPage(),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (_, __) => const ReferentAlertsPage(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (_, __) => const UnauthorizedAccessPage(),
      ),
      GoRoute(
        path: AppRoutes.referentLocationSetup,
        builder: (_, __) => const ReferentLocationSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, state) {
          final isReader = state.uri.queryParameters['mode'] == 'read';
          return TermsPage(
            mode: isReader ? TermsPageMode.reader : TermsPageMode.gate,
          );
        },
      ),
    ],
  );
});

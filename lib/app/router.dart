import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/incident_moderation_page.dart';
import '../features/admin/presentation/pages/users_management_page.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/pending_approval_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/incidents/presentation/pages/home_page.dart';
import '../features/incidents/presentation/pages/incident_detail_page.dart';
import '../features/incidents/presentation/pages/report_form_page.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'main_shell.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const pending = '/pending';
  static const home = '/home';
  static const reportForm = '/report/form';
  static const map = '/map';
  static const profile = '/profile';
  static const incidentDetail = '/incident/:id';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminIncidents = '/admin/incidents';

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

      if (isOnAuthPage || loc == AppRoutes.splash || loc == AppRoutes.pending) {
        return AppRoutes.home;
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
    ],
  );
});

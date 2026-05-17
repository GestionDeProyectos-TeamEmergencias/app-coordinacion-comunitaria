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

// Rutas de la aplicación
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const pending = '/pending';
  static const home = '/home';
  static const reportForm = '/report/form';
  static const map = '/map';
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
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isOnAuthPage) return AppRoutes.login;

      final user = authState.valueOrNull;
      if (user != null && user.status == UserStatus.pending) {
        if (state.matchedLocation != AppRoutes.pending) {
          return AppRoutes.pending;
        }
      }

      if (isLoggedIn && isOnAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: AppRoutes.pending,
          builder: (_, __) => const PendingApprovalPage()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
      GoRoute(
          path: AppRoutes.reportForm,
          builder: (_, __) => const ReportFormPage()),
      GoRoute(path: AppRoutes.map, builder: (_, __) => const MapPage()),
      GoRoute(
        path: AppRoutes.incidentDetail,
        builder: (_, state) => IncidentDetailPage(
          incidentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
          path: AppRoutes.admin,
          builder: (_, __) => const AdminDashboardPage()),
      GoRoute(
          path: AppRoutes.adminUsers,
          builder: (_, __) => const UsersManagementPage()),
      GoRoute(
          path: AppRoutes.adminIncidents,
          builder: (_, __) => const IncidentModerationPage()),
    ],
  );
});

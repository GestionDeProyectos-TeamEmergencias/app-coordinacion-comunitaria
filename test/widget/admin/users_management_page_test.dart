import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/admin/presentation/pages/users_management_page.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user({
  required String id,
  required String name,
  required UserRole role,
  UserStatus status = UserStatus.active,
}) =>
    AppUser(
      userId: id,
      email: '$id@test.com',
      displayName: name,
      role: role,
      status: status,
    );

Widget _wrap({
  List<AppUser> pending = const [],
  List<AppUser> active = const [],
}) {
  return ProviderScope(
    overrides: [
      pendingUsersProvider.overrideWith((ref) => Stream.value(pending)),
      activeUsersProvider(null).overrideWith((ref) => Stream.value(active)),
      activeUsersProvider(UserRole.vecinoInformante).overrideWith((ref) =>
          Stream.value(active
              .where((u) => u.role == UserRole.vecinoInformante)
              .toList())),
      activeUsersProvider(UserRole.referenteBarrial).overrideWith((ref) =>
          Stream.value(active
              .where((u) => u.role == UserRole.referenteBarrial)
              .toList())),
    ],
    child: const MaterialApp(home: UsersManagementPage()),
  );
}

void main() {
  group('UsersManagementPage', () {
    testWidgets('renderiza las dos pestañas Pendientes y Activos',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text(AppStrings.tabPending), findsOneWidget);
      expect(find.text(AppStrings.tabActive), findsOneWidget);
    });

    testWidgets('al cambiar al tab Activos muestra los filtros de rol',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.text(AppStrings.tabActive));
      await tester.pumpAndSettle();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text(AppStrings.roleVecino), findsWidgets);
      expect(find.text(AppStrings.roleReferente), findsWidgets);
    });

    testWidgets(
        'muestra acción Promover en card de vecino y oculta acciones para admin',
        (tester) async {
      await tester.pumpWidget(_wrap(active: [
        _user(id: 'v1', name: 'Vecino Uno', role: UserRole.vecinoInformante),
        _user(id: 'a1', name: 'Admin Uno', role: UserRole.administrador),
      ]));
      await tester.pump();

      await tester.tap(find.text(AppStrings.tabActive));
      await tester.pumpAndSettle();

      expect(find.text('Vecino Uno'), findsOneWidget);
      expect(find.text('Admin Uno'), findsOneWidget);
      expect(find.text(AppStrings.promoteToReferent), findsOneWidget);
      // El admin no debe tener acciones de promover ni degradar.
      expect(find.text(AppStrings.demoteToVecino), findsNothing);
    });

    testWidgets('muestra acción Degradar en card de referente', (tester) async {
      await tester.pumpWidget(_wrap(active: [
        _user(id: 'r1', name: 'Referente Uno', role: UserRole.referenteBarrial),
      ]));
      await tester.pump();

      await tester.tap(find.text(AppStrings.tabActive));
      await tester.pumpAndSettle();

      expect(find.text('Referente Uno'), findsOneWidget);
      expect(find.text(AppStrings.demoteToVecino), findsOneWidget);
      expect(find.text(AppStrings.promoteToReferent), findsNothing);
    });

    testWidgets('muestra acción Bloquear en card de vecino y referente', (tester) async {
      await tester.pumpWidget(_wrap(active: [
        _user(id: 'v1', name: 'Vecino Uno', role: UserRole.vecinoInformante),
        _user(id: 'r1', name: 'Referente Uno', role: UserRole.referenteBarrial),
      ]));
      await tester.pump();

      await tester.tap(find.text(AppStrings.tabActive));
      await tester.pumpAndSettle();

      expect(find.text('Vecino Uno'), findsOneWidget);
      expect(find.text('Referente Uno'), findsOneWidget);
      expect(find.text(AppStrings.blockUser), findsNWidgets(2));
    });

    testWidgets('muestra empty state cuando no hay usuarios activos',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.text(AppStrings.tabActive));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noActiveUsers), findsOneWidget);
    });
  });
}

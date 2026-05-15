import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';

// RF-ADM-03: lista de usuarios con filtros por rol y reputación. [T-AUTH-08]
class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.usersManagement)),
      // TODO(T-AUTH-08): implementar lista de usuarios con filtros y acciones.
      // Acciones: promover, degradar, bloquear, desbloquear.
      body: const AppLoading(message: 'Tarea T-AUTH-08 pendiente de implementación'),
    );
  }
}

abstract final class AppStrings {
  static const appName = 'Coordinación Comunitaria';
  static const appTagline = 'Reportá. Verificá. Mejorá tu barrio.';

  // Auth
  static const login = 'Iniciar sesión';
  static const register = 'Crear cuenta';
  static const logout = 'Cerrar sesión';
  static const email = 'Correo electrónico';
  static const password = 'Contraseña';
  static const displayName = 'Nombre completo';
  static const pendingApprovalTitle = 'Cuenta en revisión';
  static const pendingApprovalBody =
      'Tu cuenta fue creada correctamente y está siendo revisada por el administrador. '
      'Recibirás una notificación cuando sea aprobada.';

  // Reporte de incidentes
  static const quickReport = 'Reporte rápido';
  static const formReport = 'Reporte detallado';
  static const voiceReport = 'Reporte por voz';
  static const reportDescription = 'Descripción del incidente';
  static const selectCategory = 'Seleccioná una categoría';
  static const addPhoto = 'Agregar foto';
  static const sendReport = 'Enviar reporte';
  static const reportSentSuccess = 'Reporte enviado correctamente.';

  // Categorías
  static const categoryElectrico = 'Eléctrico';
  static const categoryVial = 'Vial';
  static const categorySanitario = 'Sanitario';
  static const categoryEspaciosVerdes = 'Espacios verdes';
  static const categorySeguridad = 'Seguridad';

  // Prioridades
  static const priorityUrgent = 'Urgente';
  static const priorityHigh = 'Alta';
  static const priorityMedium = 'Media';
  static const priorityLow = 'Baja';

  // Estados
  static const statusReceived = 'Recibido';
  static const statusScheduled = 'Programado';
  static const statusInProgress = 'En reparación';
  static const statusSolved = 'Solucionado';

  // Alerta riesgo vital (RF-PRI-05)
  static const vitalRiskTitle = '⚠️ Situación de riesgo vital detectada';
  static const vitalRiskBody =
      'Esta situación parece requerir atención de emergencia. '
      'Por favor, contactá a los servicios de emergencias:';
  static const emergencyCall911 = 'Llamar al 911';
  static const emergencyCall107 = 'Llamar al 107 (SAME)';

  // Mapa
  static const mapTitle = 'Mapa de incidencias';

  // Navegación principal
  static const navHome = 'Inicio';
  static const navReport = 'Reportar';
  static const navMap = 'Mapa';
  static const navProfile = 'Perfil';

  // Admin
  static const adminDashboard = 'Panel de administración';
  static const usersManagement = 'Gestión de usuarios';
  static const incidentModeration = 'Moderación de incidentes';

  // Registro pendiente / rechazado [T-AUTH-01]
  static const rejectedTitle = 'Solicitud rechazada';
  static const rejectedBody =
      'Tu solicitud de cuenta fue rechazada por el administrador. '
      'Podés comunicarte con la organización para más información.';

  // Flujo de aprobación [T-AUTH-01]
  static const pendingUsers = 'Usuarios pendientes';
  static const noPendingUsers = 'No hay solicitudes pendientes de aprobación';
  static const approveUser = 'Aprobar';
  static const rejectUser = 'Rechazar';
  static const approveConfirmTitle = '¿Aprobar esta cuenta?';
  static const approveConfirmBody =
      'El usuario obtendrá acceso completo como vecino informante.';
  static const rejectConfirmTitle = '¿Rechazar esta cuenta?';
  static const rejectConfirmBody =
      'El usuario verá un mensaje de rechazo al iniciar sesión.';
  static const userApproved = 'Cuenta aprobada correctamente.';
  static const userRejected = 'Cuenta rechazada.';

  // Errores genéricos
  static const errorUnknown = 'Ocurrió un error inesperado. Intentá de nuevo.';
  static const errorNoInternet = 'Sin conexión a internet.';
  static const errorOutOfCoverage =
      'Tu ubicación está fuera del área de cobertura configurada.';
}

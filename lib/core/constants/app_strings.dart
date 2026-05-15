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

  // Admin
  static const adminDashboard = 'Panel de administración';
  static const usersManagement = 'Gestión de usuarios';
  static const incidentModeration = 'Moderación de incidentes';

  // Errores genéricos
  static const errorUnknown = 'Ocurrió un error inesperado. Intentá de nuevo.';
  static const errorNoInternet = 'Sin conexión a internet.';
  static const errorOutOfCoverage =
      'Tu ubicación está fuera del área de cobertura configurada.';
}

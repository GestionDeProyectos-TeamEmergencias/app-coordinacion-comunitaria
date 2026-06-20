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
  static const sendingReport = 'Enviando reporte...';
  static const locationPermissionRequired =
      'Permiso de ubicación requerido para reportar.';
  static const locationPermissionPermanentlyDenied =
      'Permiso de ubicación bloqueado. Habilitalo desde Configuración.';
  static const locationServiceDisabled =
      'El GPS está desactivado. Activalo desde Configuración.';
  static const reportModeText = 'Texto';
  static const reportModeVoice = 'Voz';
  static const selectCategoryError = 'Seleccioná una categoría.';
  static const descriptionError = 'Describí el incidente';
  static const photoSelected = 'Foto seleccionada ✓';
  static const locationUnavailable =
      'No se pudo obtener tu ubicación. Verificá el GPS.';
  static const locationTimeout =
      'Tiempo de espera agotado al buscar ubicación. Intentá salir al exterior.';

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

  // Detalle de incidente [T-REP-06]
  static const incidentDetailTitle = 'Detalle del incidente';
  static const updateStatusTitle = 'Actualizar estado';
  static const statusHistoryTitle = 'Histórico de cambios';
  static const statusHistoryEmpty = 'Aún no hay cambios de estado registrados.';
  static const statusUpdatedSuccess = 'Estado actualizado correctamente.';

  // Alerta riesgo vital (RF-PRI-05)
  static const vitalRiskTitle = '⚠️ Situación de riesgo vital detectada';
  static const vitalRiskBody =
      'Esta situación parece requerir atención de emergencia. '
      'Por favor, contactá a los servicios de emergencias:';
  static const emergencyCall911 = 'Llamar al 911';
  static const emergencyCall107 = 'Llamar al 107 (SAME)';

  // Mapa
  static const mapTitle = 'Mapa de incidencias';
  static const loadingMap = 'Cargando mapa...';
  static const mapLegend = 'Leyenda';
  static const mapLegendTitle = 'Colores por prioridad';
  static const mapNoPriority = 'Sin clasificar';
  static const mapDefaultCategory = 'Incidente';
  static const mapCategoryFilters = 'Filtrar por categoría';
  static const mapCoverageArea = 'Área de cobertura';
  static const mapRecenter = 'Centrar en cobertura';

  // Navegación principal
  static const navHome = 'Inicio';
  static const navReport = 'Reportar';
  static const navMap = 'Mapa';
  static const navProfile = 'Perfil';

  // Admin
  static const adminDashboard = 'Panel de Administración';
  static const usersManagement = 'Gestión de usuarios';
  static const incidentModeration = 'Moderación de incidentes';
  static const coverageConfig = 'Área de cobertura';
  static const coverageConfigSubtitle = 'Configurar radio y centro del área.';

  // Configuración del algoritmo NLP [T-NLP-06]
  // Notificaciones masivas [T-NLP-09]
  static const broadcastTitle = 'Notificaciones masivas';
  static const broadcastSubtitle =
      'Enviá un push a todos los vecinos activos o a una zona geográfica específica.';
  static const broadcastSendButton = 'Enviar notificación';
  static const broadcastUseAreaToggle = 'Limitar a una zona geográfica';
  static const broadcastUseAreaSubtitle =
      'Si está desactivado, se envía a todos los vecinos activos.';
  static const broadcastConfirmTitle = '¿Enviar notificación masiva?';
  static const broadcastConfirmGlobal =
      'La notificación se enviará a todos los vecinos activos con tokens registrados.';
  static const broadcastConfirmZonal =
      'La notificación se enviará a los vecinos activos dentro del área indicada.';
  static const broadcastGenericError = 'Error al enviar la notificación.';
  static const broadcastRadiusTooLarge =
      'El radio no puede superar 100 000 m (100 km).';
  static String broadcastSentSummary(int success, int failure) =>
      'Enviada a $success dispositivos (fallaron $failure).';

  static const algorithmConfig = 'Configuración del algoritmo NLP';
  static const algorithmConfigSubtitle =
      'Calibrar umbrales de prioridad sin redeploy.';
  static const algorithmConfigUpdated = 'Calibración guardada correctamente.';
  static const coverageConfigUpdated =
      'Configuración de cobertura actualizada correctamente.';

  // Validaciones genéricas de formularios [T-AUTH-06]
  static const fieldRequired = 'Campo requerido.';
  static const invalidNumber = 'Ingresá un número válido.';
  static const latitudeOutOfRange = 'La latitud debe estar entre -90 y 90.';
  static const longitudeOutOfRange = 'La longitud debe estar entre -180 y 180.';
  static const radiusMustBePositive = 'El radio debe ser mayor a 0.';
  static const radiusTooLarge = 'El radio no puede superar 1 000 000 m.';

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

  // Gestión de roles [T-AUTH-04]
  static const tabPending = 'Pendientes';
  static const tabActive = 'Activos';
  static const filterByRole = 'Filtrar por rol';
  static const roleVecino = 'Vecino informante';
  static const roleReferente = 'Referente barrial';
  static const roleAdmin = 'Administrador';
  static const promoteToReferent = 'Promover a referente';
  static const demoteToVecino = 'Degradar a vecino';
  static const promoteConfirmTitle = '¿Promover a referente barrial?';
  static const promoteConfirmBody =
      'El usuario podrá recibir alertas geolocalizadas y verificar incidentes en su zona.';
  static const demoteConfirmTitle = '¿Degradar a vecino informante?';
  static const demoteConfirmBody =
      'El usuario perderá el acceso a las alertas y a la verificación de incidentes.';
  static const userPromoted = 'Usuario promovido a referente barrial.';
  static const userDemoted = 'Usuario degradado a vecino informante.';
  static const noActiveUsers = 'No hay usuarios activos en este filtro.';

  // Moderación de reportes falsos [T-AUTH-07]
  static const markAsFalseReport = 'Marcar como falso';
  static const markAsFalseConfirmTitle = '¿Marcar como reporte falso?';
  static const markAsFalseConfirmBody =
      'Esta acción suma un reporte falso al historial del autor. Si supera el umbral, su cuenta será bloqueada automáticamente.';
  static const reportMarkedAsFalse = 'Reporte marcado como falso.';
  static const reportAlreadyModerated =
      'Este reporte ya estaba marcado como falso.';
  static const userAutoBlocked =
      'El usuario quedó bloqueado por superar el umbral de reportes falsos.';
  static const tabBlocked = 'Bloqueados';
  static const blockUser = 'Bloquear';
  static const blockConfirmTitle = '¿Bloquear esta cuenta?';
  static const blockConfirmBody =
      'El usuario no podrá iniciar sesión ni reportar incidentes hasta que sea desbloqueado.';
  static const userBlocked = 'Usuario bloqueado correctamente.';
  static const unblockUser = 'Desbloquear';
  static const unblockConfirmTitle = '¿Desbloquear esta cuenta?';
  static const unblockConfirmBody =
      'El usuario podrá volver a iniciar sesión y reportar incidentes. Su contador de reportes falsos se reseteará.';
  static const userUnblocked = 'Usuario desbloqueado correctamente.';
  static const noBlockedUsers = 'No hay usuarios bloqueados.';
  static const blockedAccountTitle = 'Cuenta bloqueada';
  static const blockedAccountBody =
      'Tu cuenta fue bloqueada por superar el umbral de reportes falsos. Contactá al administrador para más información.';

  // Verificación de identidad [T-AUTH-09]
  static const identityVerification = 'Verificación de identidad';
  static const identityVerificationSubtitle =
      'Configurar la modalidad de verificación de domicilio.';
  static const identityModeManualLabel = 'Aprobación manual';
  static const identityModeManualDescription =
      'El administrador aprueba la cuenta sin documentación adicional.';
  static const identityModeProofLabel = 'Comprobante de servicio';
  static const identityModeProofDescription =
      'El vecino debe adjuntar una foto de un comprobante de servicio antes de poder ser aprobado.';
  static const identityConfigUpdated =
      'Modalidad de verificación actualizada correctamente.';
  static const identityProofRequiredTitle = 'Verificá tu domicilio';
  static const identityProofRequiredBody =
      'Para que tu cuenta sea aprobada, adjuntá una foto clara de un comprobante de servicio (luz, gas, agua) a tu nombre.';
  static const identityProofUploadButton = 'Adjuntar comprobante';
  static const identityProofUploaded =
      'Comprobante enviado. El administrador lo revisará.';
  static const identityProofPendingReview =
      'Tu comprobante está siendo revisado.';
  static const identityProofViewLabel = 'Comprobante adjuntado';
  static const identityProofMissingLabel =
      'Sin comprobante (modalidad activa: requerido)';
  static const identityProofUploadError =
      'No se pudo subir el comprobante. Reintentá.';
  static const identityProofReupload = 'Subir otro comprobante';
  static const identityProofSourceCamera = 'Tomar foto con la cámara';
  static const identityProofSourceGallery = 'Elegir de la galería';
  static const lowReputationWarning = 'Reputación baja:';

  // Pantalla de gestión de alertas [T-AUTH-04 / RF-ROL-02]
  static const referentAlertsTitle = 'Alertas geolocalizadas';
  static const referentAlertsSubtitle =
      'Incidentes urgentes y de alta prioridad cerca de tu zona';
  static const noActiveAlerts = 'No hay alertas activas por ahora.';
  static const cancel = 'Cancelar';

  // Errores genéricos
  static const errorUnknown = 'Ocurrió un error inesperado. Intentá de nuevo.';
  static const errorNoInternet = 'Sin conexión a internet.';
  static const errorLocationTimeout =
      'Tiempo de espera agotado. Intentá salir al exterior e intentá nuevamente.';
  static const errorLocationUnknown =
      'Error inesperado al obtener la ubicación.';
  static const errorOutOfCoverage =
      'Tu ubicación está fuera del área de cobertura configurada.';

  // Unauthorized Access
  static const unauthorizedAccess = 'Acceso no autorizado';
  static const unauthorizedAccessTitle = 'Permiso denegado';
  static const unauthorizedAccessMessage =
      'No tenés los permisos necesarios para acceder a esta sección.';
  static const goToHome = 'Ir a Inicio';
}

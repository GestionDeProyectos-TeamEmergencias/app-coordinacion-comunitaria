/// Configuración de Términos y Condiciones + Disclaimer de seguridad. [D-04]
///
/// **Versionado:** cualquier cambio sustantivo en `body` requiere incrementar
/// `currentVersion`. El router compara `users/{uid}.termsAcceptedVersion` con
/// este valor: si el del user es menor (o ausente), se lo redirige al gate
/// hasta que vuelva a aceptar.
///
/// **Importante:** este texto es un placeholder técnicamente funcional. El
/// equipo legal del cliente (Municipio/Comuna/Sociedad de Fomento) debe
/// validarlo o reemplazarlo antes del despliegue a producción. Cuando lo
/// reemplacen, deben **subir `currentVersion`** para forzar reaceptación.
abstract final class TermsConfig {
  /// Versión actual del documento. Subir cuando cambia el texto. [D-04]
  static const int currentVersion = 1;

  /// Título de la pantalla y del enlace en perfil.
  static const String title = 'Términos y Condiciones';

  /// Resumen corto del disclaimer (banner inicial — alta visibilidad).
  static const String disclaimerHighlight =
      'Esta aplicación NO reemplaza al 911 ni al 107. '
      'No la uses para reportar emergencias activas. '
      'Si hay riesgo a la vida, llamá a emergencias antes que reportar acá.';

  /// Cuerpo completo del documento (Markdown plano, sin links activos).
  static const String body = '''
1. PROPÓSITO Y ALCANCE

"Coordinación Comunitaria" es una herramienta de **gestión urbana participativa**
que permite a los vecinos de una zona delimitada reportar incidentes de
infraestructura, espacios públicos y servicios (baches, luminarias, ruidos
molestos, recolección, espacios verdes y similares). El objetivo es asistir a
la administración local en la priorización y trazabilidad de esos reportes.

2. ⚠️ NO ES UN SERVICIO DE EMERGENCIAS

Esta aplicación NO está diseñada para situaciones de riesgo a la vida, la
integridad física, la seguridad o la salud de las personas. Si te encontrás
ante una emergencia, contactá a los servicios oficiales:

   • 911 — Emergencias / Seguridad
   • 107 — Emergencias médicas (SAME)
   • 100 — Bomberos
   • 144 — Violencia de género

No uses esta aplicación para reportar:
   • Heridos, accidentes con víctimas, personas inconscientes.
   • Incendios activos, fugas de gas, electrocución.
   • Delitos en curso, agresiones, robos.
   • Situaciones de violencia de cualquier tipo.

Si el sistema detecta que tu reporte describe una situación de riesgo vital,
NO lo va a procesar y te va a derivar a 911/107.

3. RESPONSABILIDAD DEL USUARIO

Te comprometés a:

   a) Hacer reportes verídicos. Los reportes falsos o malintencionados
      afectan tu reputación y pueden llevar al bloqueo de tu cuenta.
   b) No usar la aplicación para acosar, difamar o dañar a terceros.
   c) No subir fotografías que contengan rostros identificables sin
      consentimiento, datos personales sensibles, ni contenido inapropiado.
   d) Respetar la convivencia y el espíritu colaborativo del barrio.

4. RESPONSABILIDAD DEL ADMINISTRADOR LOCAL

El Administrador (Municipio / Comuna / Sociedad de Fomento) gestiona los
reportes con la mejor capacidad operativa disponible, pero NO garantiza
tiempos de respuesta, ni que todos los reportes deriven en una intervención.
La aplicación es una herramienta de coordinación, no un compromiso contractual
de servicio.

5. PRIVACIDAD Y USO DE DATOS

Al usar la aplicación aceptás que:

   a) Tu ubicación (al reportar) se persiste en cada incidente y queda
      visible para vecinos activos del barrio, referentes y administradores.
   b) Tu nombre, foto y rol son visibles para el Administrador y, si
      sos Referente Barrial, para los vecinos de tu zona.
   c) Los reportes (descripción, foto, ubicación) son visibles para los
      demás usuarios activos del barrio. NO subas información sensible.
   d) Tus datos de contacto y el comprobante de domicilio (si lo subiste)
      solo son accesibles para vos y para el Administrador.
   e) Podés solicitar la baja de tu cuenta y la supresión de tus datos al
      Administrador en cualquier momento.

6. NOTIFICACIONES PUSH

Si tu rol es Referente Barrial o si el Administrador envía notificaciones
masivas, podés recibir notificaciones push. Podés desactivarlas desde la
configuración del sistema operativo de tu dispositivo, aunque al hacerlo dejás
de recibir alertas de incidentes en tu zona.

7. LIMITACIÓN DE RESPONSABILIDAD

El servicio se ofrece "tal cual" (as-is). Los desarrolladores y el
Administrador local no se hacen responsables por:

   • Daños derivados del uso o mal uso de la aplicación.
   • Errores, retrasos o falta de procesamiento de un reporte.
   • Decisiones que tomes basándote en información publicada por
     terceros usuarios de la aplicación.

8. MODIFICACIONES

El Administrador puede modificar estos Términos cuando lo considere
necesario. Cuando los modifique, vas a recibir esta pantalla nuevamente y
vas a tener que aceptarlos para seguir usando la aplicación.

9. ACEPTACIÓN

Al tocar "Acepto los Términos y Condiciones" declarás que leíste,
comprendiste y aceptás este documento, y que entendés que esta aplicación
NO es un servicio de emergencias.
''';
}

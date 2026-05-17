# ![][image1]

# UNIVERSIDAD NACIONAL DEL NOROESTE DE LA PROVINCIA DE BUENOS AIRES Gestión de Proyectos | 1° Cuatrimestre 2026

# **Planificación del Producto — Segunda Iteración**

## App de Coordinación Comunitaria para la Gestión Urbana Participativa

---

**Grupo D**

**Integrantes:** Elias Uribe, Eric Doyle, Lucas Lovizzio, Agustín Campagna, Tomás Miquelez, Joaquín Hubner, Jeremías Aguirres 

**Versión:** 1.3  
**Fecha:** 3/05/2026

---

## Tabla de Contenidos

1. Introducción y Marco de Planificación  
2. Stack Tecnológico  
3. División del Equipo por Módulos  
4. Identificación y Descomposición de Tareas  
5. Red de Tareas y Dependencias (AON)  
6. Estimación de Tiempos y Recursos  
7. Calendarización (Gantt)  
8. Herramientas de Ejecución y Proceso

---

## 1\. Introducción y Marco de Planificación

El presente documento constituye la entrega de la Segunda Iteración de la fase de Planificación del Trabajo Práctico Integrador. Tiene como punto de partida la Especificación de Requisitos del Software (SRS) desarrollada en la Primera Iteración, de la cual se derivan exhaustivamente todas las tareas necesarias para implementar los requisitos allí definidos.

### 1.1 Cliente y stakeholders del sistema

El cliente principal del sistema es la organización vecinal adoptante: una junta vecinal, sociedad de fomento, comisión de barrio privado o municipio pequeño que decide implementar la plataforma para gestionar incidentes urbanos en su área de cobertura. Esta organización designa al menos un Administrador Vecinal responsable de la plataforma, quien es creado directamente en el sistema por el equipo de desarrollo en el momento del despliegue (cuenta inicial de bootstrap). A partir de ese momento, el Administrador Vecinal puede crear otros administradores si lo necesita.

Los usuarios finales del sistema son tres: el Vecino Informante (ciudadano del área que reporta incidentes), el Referente Barrial (vecino verificado que actúa como validador de campo) y el Administrador Vecinal (representante de la organización que gestiona la plataforma). El sistema no tiene usuarios anónimos: toda interacción requiere una cuenta registrada, pero el registro es abierto y no requiere aprobación previa para crearse.

### 1.2 Parámetros del proyecto

| Parámetro | Valor |
| :---- | :---- |
| Fecha de inicio | 01/05/2026 |
| Fecha límite de entrega | 26/06/2026 |
| Semanas disponibles | 8 semanas |
| Integrantes del equipo | 7 personas |
| Horas mínimas por persona por semana | 4 horas/persona (estimación conservadora; puede variar entre 4 y 6 h según disponibilidad semanal de cada integrante) |
| Presupuesto total de horas | 224 horas totales del equipo (7 personas × 4 h/semana × 8 semanas)  |

### 1.3 Criterio de descomposición

Las tareas se derivaron directamente de los requisitos funcionales del SRS (Primera Iteración), garantizando trazabilidad completa entre cada tarea y el requisito que implementa. El nivel de granularidad elegido apunta a tareas de entre 2 y 6 horas/persona, lo cual permite su ejecución dentro de una o dos semanas al ritmo de trabajo definido (4 h/persona/semana) y facilita el seguimiento en el tablero de gestión del proyecto.

---

## 2\. Stack Tecnológico

La selección tecnológica se realizó priorizando la arquitectura serverless, la gratuidad del entorno y la integración nativa entre componentes.

| Capa | Tecnología | Justificación |
| :---- | :---- | :---- |
| **Mobile (iOS \+ Android)** | Flutter (Dart) | Codebase único para ambas plataformas, SDK maduro, soporte oficial de Firebase |
| **Autenticación** | Firebase Authentication | Integración nativa con Flutter, manejo de sesiones y roles |
| **Base de datos** | Cloud Firestore | Base de datos NoSQL en tiempo real, sincronización automática con el cliente Flutter |
| **Lógica de negocio / NLP** | Cloud Functions (Node.js) \+ Firebase Genkit \+ Gemini 2.5 Flash-Lite  | Permite ejecutar el motor de priorización serverless sin infraestructura dedicada. Firebase Genkit orquesta los flujos de IA sobre Cloud Functions, utilizando Gemini 2.5 Flash-Lite para clasificación semántica de incidentes. Disponible en Firebase Blaze Plan; costo estimado inferior a $0.01 por cada 100 reportes procesados.  |
| **Push notifications** | Firebase Cloud Messaging (FCM) \+ APNs | Servicio oficial para Android e iOS, sin costo adicional |
| **Geolocalización / Mapas** | Google Maps SDK for Flutter | Integración directa, API gratuita con límites más que suficientes para uso académico |
| **Almacenamiento de imágenes** | Firebase Storage | Integración nativa con Firebase y Flutter, permitiendo una arquitectura unificada sin servicios externos. Las imágenes se suben desde el cliente y su URL se almacena en Firestore. Requiere plan Blaze (pago por uso), con un tier gratuito inicial, adecuado para proyectos académicos o escalables. |
| **Speech-to-Text** | speech\_to\_text (Flutter package, on-device) | Usa el reconocimiento de voz nativo del sistema operativo (iOS Speech Framework / Android SpeechRecognizer). No requiere API externa, funciona sin conexión y es completamente gratuito. La transcripción ocurre en el dispositivo y el texto resultante se envía al backend como string. |
| **Infraestructura / Hosting** | Firebase Blaze Plan | Plan pago por uso con tier gratuito generoso. Requiere habilitar facturación (tarjeta de crédito), pero el uso académico del proyecto se mantiene dentro del tier gratuito. |
| **Control de versiones** | Git \+ GitHub | Repositorio compartido con branches por módulo |
| **Gestión de tareas** | Jira | Seguimiento de tareas con dependencias, estimaciones y asignaciones |

**Nota sobre el motor NLP:** Se evaluó el uso de keyword matching manual en Node.js puro como alternativa de menor costo y complejidad. Se optó por Firebase Genkit \+ Gemini 2.5 Flash-Lite dado que el costo es despreciable para el volumen académico (menos de $0.01 cada 100 reportes con el plan Blaze activo), la integración es nativa con Cloud Functions en Node.js/TypeScript, y la clasificación semántica mejora significativamente la detección de riesgo vital y la precisión de priorización frente a un diccionario fijo. El procesamiento ocurre íntegramente en el servidor; no se envían datos a APIs externas fuera del ecosistema Google.

**Nota sobre Firebase Storage:** Firebase Storage requiere el plan Blaze (con facturación habilitada) incluso para acceder a su capa gratuita de 5 GB. Esta limitación fue identificada durante la planificación y aceptada dado el scope académico del proyecto, habilitando el plan Blaze con facturación activa pero manteniéndose dentro del tier gratuito de uso.

---

## 3\. División del Equipo por Módulos

El equipo se organizó en tres grupos funcionales más un rol de PM, minimizando las dependencias entre equipos. El único punto de acoplamiento crítico entre equipos es el contrato de la interfaz del objeto "Evento de Incidente" (tarea T-INF-04), que se define en la semana 1 para desbloquear el trabajo paralelo.

| Equipo | Integrantes | Módulos SRS cubiertos | Horas disponibles |
| :---- | :---- | :---- | :---- |
| **PM \+ Infraestructura** | 1 persona | Setup Firebase, repositorio, entornos, contrato de interfaz, integración final | 16 hs |
| **Equipo A: Auth, Roles y Reputación** | 2 personas | RF-ROL-01/02/03, RF-MOD-01/02/03, RF-ADM-03/08 | 38 hs |
| **Equipo B: Reporte e Interfaz** | 2 personas | RF-REP-01/02/03, RF-SAL-01, RF-ADM-01/02 | 32 hs |
| **Equipo C: Motor NLP y Notificaciones** | 2 personas | RF-PRO-01/02/03, RF-PRI-01/02/03/04/05, RF-SAL-02, RF-ADM-04 | 32 hs |

---

## 4\. Identificación y Descomposición de Tareas

### 4.1 PM e Infraestructura

| ID | Nombre de la Tarea | Descripción | RF/RNF Asociado | Horas estimadas |
| :---- | :---- | :---- | :---- | :---- |
| **T-INF-01** | Configuración del repositorio Git | Crear repositorio en GitHub, definir estructura de branches (main, develop, feature/equipo-x), configurar .gitignore para Flutter y Node.js. | — | 2 hs |
| **T-INF-02** | Configuración del proyecto Firebase  | Crear proyecto Firebase, habilitar Authentication, Firestore, Storage, Cloud Functions y FCM. Configurar reglas de seguridad iniciales de Firestore. | RNF-SEG-01, RNF-SEG-03 | 5 hs |
| **T-INF-03** | Setup del entorno de desarrollo Flutter | Instalar Flutter SDK, configurar emuladores Android/iOS, integrar FlutterFire (plugin oficial de Firebase para Flutter), verificar build exitoso en ambas plataformas. | — | 2 hs |
| **T-INF-04** | Definición del contrato de interfaz "Evento de Incidente" | Especificar y documentar el esquema JSON del objeto "Evento de Incidente" que Equipo B envía y Equipo C procesa. El esquema unifica las tres modalidades de reporte (botón rápido, formulario y voz) en una estructura de datos común, garantizando que independientemente del origen del reporte los campos userID, timestamp, coordenadas GPS, descripción de texto y categoría estén siempre presentes o explícitamente nulos. Esta tarea responde directamente a la necesidad de convergencia estructural entre RF-REP-01, RF-REP-02 y RF-REP-03, diferenciando internamente el tipo de reporte mediante el campo sourceType: {quick | form | voice}. Define el contrato entre ambos equipos para permitir desarrollo paralelo. | RF-PRO-01 | 2 hs |
| **T-INF-05** | Integración final y smoke test end-to-end | Verificar el flujo completo: reporte vecino → Cloud Function NLP → Firestore → alerta push → referente barrial. Resolver conflictos de integración entre branches. | — | 4 hs |
| **T-INF-06** | Actualización de documentación técnica | Actualizar README con instrucciones de setup, variables de entorno y arquitectura del sistema. | — | 2 hs |

**Total PM: 17 hs**

---

### 4.2 Equipo A: Auth, Roles y Reputación

| ID | Nombre de la Tarea | Descripción | RF/RNF Asociado | Horas estimadas |
| :---- | :---- | :---- | :---- | :---- |
| **T-AUTH-01** | Registro de vecinos informantes | Registro de vecinos informantes	Implementar pantalla de registro abierto: cualquier persona puede crear una cuenta con email y contraseña sin necesidad de código de invitación previo. Al registrarse, la cuenta queda en estado "pendiente de verificación". El usuario puede iniciar sesión pero ve una pantalla de bienvenida que le indica que su cuenta está en revisión. El Administrador Vecinal recibe una notificación de nueva cuenta y puede aprobarla o rechazarla desde el panel. Una vez aprobada, la cuenta obtiene el rol "vecino\_informante" y acceso completo a la app. Este flujo responde a RF-ROL-01 y resuelve la tensión entre acceso abierto y control de cobertura: el registro no tiene barreras, pero la habilitación sí requiere validación por parte de la organización adoptante. | RF-ROL-01 | 5 hs |
| **T-AUTH-02** | Login y autenticación Firebase Auth | Implementar pantalla de login con email/contraseña usando Firebase Authentication. Manejo de sesión persistente y recuperación de contraseña. | RF-ROL-01 | 3 hs |
| **T-AUTH-03** | Control de acceso por roles | Implementar middleware de verificación de rol en la aplicación Flutter. Restringir acceso a pantallas y funcionalidades según rol (vecino\_informante, referente\_barrial, administrador). Retornar error ante acceso no autorizado. | RF-ROL-03, RNF-SEG-03 | 3 hs |
| **T-AUTH-04** | Promoción de referente barrial | Implementar funcionalidad en el panel del administrador para promover un vecino al rol de referente barrial. Al ser promovido, el referente barrial obtiene los siguientes privilegios adicionales respecto al vecino informante: recepción de alertas push geolocalizadas de incidentes cercanos a su zona, capacidad de confirmar o descartar la veracidad de un incidente in situ desde la app, y posibilidad de adjuntar fotografías como evidencia de verificación. El referente actúa como intermediario de campo entre los vecinos informantes y el administrador vecinal: valida que el incidente existe, actualiza su estado preliminar y deriva al administrador los casos que requieren intervención institucional. La tarea incluye actualizar el documento de usuario en Firestore, revocar/otorgar permisos correspondientes y habilitar la pantalla de gestión de alertas exclusiva para este rol. | RF-ROL-02 | 3 hs |
| **T-AUTH-05** | Sistema de reputación por usuario | Implementar campo de puntaje de reputación en el documento de usuario en Firestore. Implementar lógica de incremento/decremento automático según validación de reportes. Mostrar advertencia en panel cuando reputación es baja. | RF-MOD-01 | 5 hs |
| **T-AUTH-06** | Validación geográfica de reportes | Implementar verificación de que la ubicación GPS del dispositivo al momento del reporte coincida con el área de cobertura configurada. Bloquear reporte y notificar al usuario si está fuera del rango. | RF-MOD-02 | 4 hs |
| **T-AUTH-07** | Gestión de reportes falsos y bloqueos | Implementar en el panel del administrador la acción de marcar reporte como "Falso/Malintencionado". Implementar lógica de bloqueo automático del usuario al superar el umbral de reportes falsos. | RF-MOD-03 | 3 hs |
| **T-AUTH-08** | Panel de administración — gestión de usuarios | Implementar vista de lista de usuarios con filtros por rol y reputación. Acciones disponibles: promover, degradar, bloquear, desbloquear usuarios. | RF-ADM-03 | 5 hs |
| **T-AUTH-09**  | Verificación de identidad del vecino (opcional por organización)  | Implementar mecanismo de verificación de domicilio configurable por el Administrador Vecinal. La organización adoptante puede elegir entre tres modalidades: (1) aprobación manual por el administrador sin documentación adicional, (2) carga de comprobante de servicio (foto desde la app, almacenada en Firebase Storage, visible solo para el administrador), o (3) integración con un servicio externo de verificación de identidad como Truora o IDenfy, que validan documento de identidad y domicilio mediante API. La modalidad activa se configura en el panel de administración. Esta tarea implementa la modalidad (1) y (2); la modalidad (3) queda documentada como extensión futura dado el costo de los servicios externos (\~$1-3 USD por verificación)  | RF-ROL-01, RF-MOD-02  | 4 hs  |

**Total Equipo A: 38 hs**

---

### 4.3 Equipo B: Reporte e Interfaz

| ID | Nombre de la Tarea | Descripción | RF/RNF Asociado | Horas estimadas |
| :---- | :---- | :---- | :---- | :---- |
| **T-REP-01** | UI principal y navegación | Implementar estructura de navegación principal de la app Flutter: bottom navigation bar, rutas entre pantallas (home, reporte, mapa, perfil). Pantalla de splash y carga inicial. | RNF-USA-01 | 4 hs |
| **T-REP-02** | Botón de reporte rápido con captura GPS | Implementar botón de acceso rápido en pantalla principal. Al presionarlo: captura automática de GPS, identificación del usuario autenticado, registro de timestamp y envío del evento al esquema definido en T-INF-04. | RF-REP-01, RNF-REN-01 | 3 hs |
| **T-REP-03** | Formulario de reporte detallado con foto | Implementar formulario con campos: descripción de texto libre, selector de categoría de incidente, captura de foto opcional desde cámara o galería. La foto se sube directamente a Firebase Storage desde el cliente Flutter usando Firebase Storage. La URL de descarga devuelta por Firebase Storage se incluye como campo en el objeto del reporte enviado al esquema T-INF-04.  | RF-REP-03 | 4 hs |
| **T-REP-04** | Reporte por voz con Speech-to-Text on-device | Integrar el paquete speech\_to\_text de Flutter, que utiliza el motor de reconocimiento de voz nativo del sistema operativo (iOS Speech Framework en Apple, SpeechRecognizer de Android en Google). Implementar grabación de audio, transcripción en el dispositivo sin llamadas a API externas, y envío del texto resultante al módulo de procesamiento. Manejar permisos de micrófono y casos sin conectividad. | RF-REP-02, RNF-PRE-02 | 5 hs |
| **T-REP-05** | Mapa de incidencias geolocalizado | Implementar vista de mapa (Google Maps SDK for Flutter) con marcadores de incidentes activos obtenidos desde Firestore en tiempo real. Diferenciación visual por nivel de prioridad y categoría. Listener de Firestore para actualizaciones en tiempo real. | RF-ADM-01, RNF-PRE-01 | 6 hs |
| **T-REP-06** | Visualización del estado de resolución | Implementar en la pantalla de detalle de incidente la visualización del estado de resolución actualizado por el administrador (Recibido / Programado / En Reparación / Solucionado) con histórico de cambios. | RF-ADM-02 | 3 hs |

**Total Equipo B: 25 hs**

---

### 4.4 Equipo C: Motor NLP y Notificaciones

| ID | Nombre de la Tarea | Descripción | RF/RNF Asociado | Horas estimadas |
| :---- | :---- | :---- | :---- | :---- |
| **T-NLP-01** | Configuración de Firebase Genkit y Gemini | Instalar y configurar Firebase Genkit en el proyecto Cloud Functions. Configurar el plugin de Gemini (modelo gemini-2.5-flash-lite), definir el flow principal de clasificación de incidentes con su esquema de entrada/salida tipado, y validar el pipeline con un caso de prueba de extremo a extremo. | RF-PRI-01, RF-PRI-02 | 3 hs |
| **T-NLP-02** | Cloud Function: normalización y enriquecimiento del evento | Implementar Cloud Function en Node.js que recibe el objeto "Evento de Incidente" crudo (T-INF-04), lo normaliza a formato estructurado, consulta historial del usuario y detecta incidentes cercanos duplicados. | RF-PRO-01, RF-PRO-02, RF-PRO-03 | 4 hs |
| **T-NLP-03** | Genkit Flow: extracción semántica de categoría e intención | Implementar Genkit flow que envía el texto del incidente a Gemini 2.5 Flash-Lite con un prompt estructurado. El modelo retorna un objeto JSON tipado con: categoría de incidente (eléctrico, vial, sanitario, espacios verdes, seguridad), intención del reporte y términos relevantes detectados. | RF-PRI-01, RNF-PRE-02 | 4 hs |
| **T-NLP-04** | Genkit Flow: clasificación de prioridad y score | Implementar Genkit flow que, a partir de la salida de T-NLP-03 más el historial del usuario y la detección de incidentes cercanos duplicados, solicita a Gemini la asignación de nivel de prioridad operativa {Urgente, Alta, Media, Baja} con score numérico justificado. El modelo recibe contexto estructurado y retorna JSON tipado validado por Genkit.  | RF-PRI-02, RF-PRI-03, RNF-REN-02 | 4 hs |
| **T-NLP-05** | Cloud Function: detección de riesgo vital | Implementar Cloud Function que analiza el texto del incidente contra un diccionario de términos de alta criticidad. Si detecta riesgo vital: interrumpe el flujo, no genera alerta comunitaria, retorna respuesta para mostrar botones de 911/107. | RF-PRI-05 | 3 hs |
| **T-NLP-06** | Cloud Function: calibración del algoritmo | Implementar endpoint en Cloud Functions que permite al administrador actualizar el diccionario de palabras clave y los pesos desde el panel, sin necesidad de redeploy. Persiste la configuración en Firestore. | RF-PRI-04 | 2 hs |
| **T-NLP-07** | Sistema de alertas push FCM/APNs | Implementar Cloud Function que, una vez clasificado el incidente, consulta en Firestore los referentes barriales activos dentro del radio de proximidad operativo y envía notificación push via FCM (Android) y APNs (iOS) con nivel de prioridad y ubicación. | RF-SAL-01, RNF-REN-03, RNF-REN-04 | 4 hs |
| **T-NLP-08** | Persistencia y auditoría en Firestore | Implementar escritura del evento procesado y clasificado en Firestore con todos los campos requeridos: datos del evento, usuario informante, timestamps de cada etapa, estado inicial "Recibido". | RF-SAL-02 | 3 hs |
| **T-NLP-09** | Notificaciones masivas del administrador | Implementar Cloud Function que permite al administrador enviar notificaciones push a todos los vecinos del área de cobertura o a una zona geográfica específica. | RF-ADM-04 | 2 hs |

**Total Equipo C: 29 hs**

---

### 4.5 Tareas de Seguridad y RNF (PM)

Estas tareas implementan los requisitos no funcionales de seguridad que no quedan cubiertos automáticamente por el stack tecnológico elegido y requieren configuración explícita.

| ID | Nombre de la Tarea | Descripción | RF/RNF Asociado | Horas estimadas |
| :---- | :---- | :---- | :---- | :---- |
| **T-RNF-01** | Configuración de reglas de seguridad Firestore | Definir e implementar las reglas de seguridad de Firestore que garanticen: acceso autenticado obligatorio, lectura/escritura según rol (vecino, referente, administrador), y que ningún usuario pueda acceder a datos personales de otros usuarios con rol de vecino. Verificar que los datos sensibles se almacenen encriptados mediante las configuraciones propias de Firestore. | RNF-SEG-01, RNF-SEG-02, RNF-SEG-03, RNF-SEG-04 | 3 hs |

**Total PM con RNF: 19 hs**

---

### 4.6 Tareas de Verificación y Pruebas

Las tareas de prueba se ejecutan en paralelo con las últimas semanas de desarrollo, siguiendo la suite de pruebas definida en la Sección 6 del SRS (Primera Iteración). El registro de ejecución se realiza en la planilla compartida de Google Sheets provista por la cátedra, constituyendo la evidencia formal del proceso de verificación.

Cada equipo es responsable de las pruebas de su propio módulo. El PM coordina las pruebas de integración y la ejecución final de la suite completa.

| ID | Nombre de la Tarea | Descripción | Tests del SRS asociados | Horas estimadas | Equipo |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **T-TEST-01** | Setup de la planilla de suite de pruebas | Descargar la plantilla provista por la cátedra, generar copia en Google Sheets, compartir con integrantes y docentes. Completar la primera hoja con todos los casos de prueba definidos en la Sección 6 del SRS, organizados por módulo. | Sección 6 SRS completa | 2 hs | PM |
| **T-TEST-02** | Ejecución de pruebas — Módulo Auth y Roles | Ejecutar los casos T-ROL-01, T-MOD-01 y T-MOD-02 del SRS. Verificar control de acceso por rol (HTTP 403), sistema de reputación y bloqueo por reportes falsos, y validación geográfica. Registrar resultados en la planilla. | T-ROL-01, T-MOD-01, T-MOD-02, T-ADM-01 | 3 hs | Equipo A |
| **T-TEST-03** | Ejecución de pruebas — Módulo Reporte e Interfaz | Ejecutar los casos T-REP-01, T-REP-02 y T-PRO-01 del SRS. Verificar que el botón de reporte rápido registra el evento con GPS y timestamp en ≤ 3 segundos, que el audio transcripto coincide en ≥ 90% con el original, y que el flujo completo de 7 etapas se ejecuta sin interrupciones. Registrar resultados. | T-REP-01, T-REP-02, T-PRO-01 | 3 hs | Equipo B |
| **T-TEST-04** | Ejecución de pruebas — Motor NLP y Notificaciones | Ejecutar los casos T-PRI-01 y T-PRI-02 del SRS. Verificar que el sistema clasifica correctamente los 10 casos de prueba del diccionario urbano (cable pelado → Urgente, basura acumulada → Media) y que ante textos de riesgo vital no genera alerta comunitaria sino que muestra botones de servicios oficiales. Registrar resultados. | T-PRI-01, T-PRI-02 | 3 hs | Equipo C |
| **T-TEST-05** | Ejecución de pruebas de RNF | Ejecutar los casos T-REN-01, T-REN-02, T-DIS-01, T-DIS-02, T-USA-01, T-PRE-01 y T-SEG-01 del SRS. Medir tiempos de procesamiento con herramientas de profiling, ejecutar prueba de carga con 100 reportes simultáneos, realizar test de usuario con 5 personas externas, comparar coordenadas GPS contra punto geodésico conocido y auditar encriptación en base de datos. | T-REN-01, T-REN-02, T-DIS-01, T-DIS-02, T-USA-01, T-PRE-01, T-SEG-01 | 4 hs | PM |
| **T-TEST-06** | Ejecución final de la suite completa — registro OK | Ejecutar la suite de pruebas completa de forma integral sobre el sistema integrado (post T-INF-05). Corregir los defectos pendientes identificados en ejecuciones anteriores. La última ejecución registrada debe mostrar resultado "OK" en todos y cada uno de los tests. Este registro constituye la evidencia formal de verificación exigida por la cátedra. | Suite completa | 3 hs | PM |

**Total tareas de prueba: 18 hs**

---

## 5\. Red de Tareas y Dependencias (AON)

### 5.1 Tabla de precedencias

Cada tarea lista las tareas que deben estar completas antes de que pueda iniciarse (predecesoras inmediatas).

| ID Tarea | Predecesoras | Puede ejecutarse en paralelo con | En camino crítico |
| :---- | :---- | :---- | :---- |
| **T-INF-01** | — | — | Si |
| **T-INF-02** | T-INF-01 | — | Si |
| **T-INF-03** | T-INF-02 | T-INF-04 | Si |
| **T-INF-04** | T-INF-02 | T-INF-03 | No |
| **T-AUTH-01** | T-INF-03 | T-REP-01, T-NLP-01 | No |
| **T-AUTH-02** | T-AUTH-01 | — | No |
| **T-AUTH-03** | T-AUTH-02 | — | No |
| **T-AUTH-04** | T-AUTH-03 | T-AUTH-08 | No |
| **T-AUTH-05** | T-AUTH-04 | — | No |
| **T-AUTH-06** | T-AUTH-05 | T-AUTH-07 | No |
| **T-AUTH-07** | T-AUTH-05 | T-AUTH-06 | No |
| **T-AUTH-08** | T-AUTH-06, T-AUTH-07 | — | No |
| **T-AUTH-09** | T-AUTH-08  |  | No |
| **T-REP-01** | T-INF-03 | T-AUTH-01, T-NLP-01 | No |
| **T-REP-02** | T-REP-01, T-INF-04 | T-REP-03, T-REP-04 | No |
| **T-REP-03** | T-REP-01, T-INF-04 | T-REP-02, T-REP-04 | No |
| **T-REP-04** | T-REP-01, T-INF-04 | T-REP-02, T-REP-03 | No |
| **T-REP-05** | T-REP-02, T-REP-03, T-REP-04, T-INF-04 | — | No |
| **T-REP-06** | T-REP-05 | T-AUTH-08, T-NLP-08, T-NLP-09 | No |
| **T-NLP-01** | T-INF-03 | T-AUTH-01, T-REP-01 | Si |
| **T-NLP-02** | T-NLP-01, T-INF-04 | — | Si |
| **T-NLP-03** | T-NLP-02 | — | Si |
| **T-NLP-04** | T-NLP-03 | T-NLP-05 | Si |
| **T-NLP-05** | T-NLP-03 | T-NLP-04 | No |
| **T-NLP-06** | T-NLP-04, T-NLP-05 | — | No |
| **T-NLP-07** | T-NLP-04 | T-NLP-06 | Si |
| **T-NLP-08** | T-NLP-07 | T-NLP-09 | Si |
| **T-NLP-09** | T-NLP-07 | T-NLP-08 | No |
| **T-INF-05** | T-AUTH-03, T-NLP-08, T-REP-05 | — | Si |
| **T-INF-06** | T-INF-05 | — | Si |
| **T-RNF-01** | T-INF-02 | T-AUTH-01, T-REP-01, T-NLP-01 | No |
| **T-TEST-01** | T-INF-03 | T-AUTH-01, T-REP-01, T-NLP-01 | No |
| **T-TEST-02** | T-AUTH-03, T-TEST-01 | T-TEST-03, T-TEST-04 | No |
| **T-TEST-03** | T-REP-04, T-TEST-01 | T-TEST-02, T-TEST-04 | No |
| **T-TEST-04** | T-NLP-05, T-TEST-01 | T-TEST-02, T-TEST-03 | No |
| **T-TEST-05** | T-INF-05, T-TEST-01 | — | No |
| **T-TEST-06** | T-TEST-02, T-TEST-03, T-TEST-04, T-TEST-05 | — | No |

### 5.2 Camino crítico

El camino crítico es la secuencia de tareas más larga que determina la duración mínima del proyecto. Cualquier demora en una tarea del camino crítico retrasa la entrega final.

**Camino crítico identificado:**

T-INF-01 → T-INF-02 → T-INF-04 → T-INF-03 → T-NLP-01 → T-NLP-02 → T-NLP-03 → T-NLP-04 → T-NLP-07 → T-NLP-08 → T-INF-05 → T-INF-06

**Duración total del camino crítico:** 2 \+ 4 \+ 2 \+ 3 \+ 4 \+ 4 \+ 4 \+ 4 \+ 3 \+ 4 \+ 2 \= **36 horas**

Con 4 horas/semana disponibles por persona y el camino crítico distribuido entre el PM y los dos integrantes del Equipo C, las 36 horas del camino crítico se ejecutan en aproximadamente 5 semanas de trabajo efectivo, lo cual es compatible con las 8 semanas disponibles y deja margen para absorber imprevistos. Es fundamental que T-INF-02 y T-INF-04 sean completados por el PM en las primeras dos semanas, ya que de ellos depende el inicio paralelo de los tres equipos.

**Tareas de holgura cero (no pueden retrasarse):** T-INF-01, T-INF-02, T-INF-03, T-NLP-01, T-NLP-02, T-NLP-03, T-NLP-04, T-NLP-07, T-NLP-08, T-INF-05, T-INF-06.

**Nota sobre tareas de prueba:** T-TEST-06 (ejecución final de la suite) depende de T-INF-05 y de las pruebas de módulo (T-TEST-02 a T-TEST-05). Si T-INF-05 se demora, T-TEST-06 no puede ejecutarse, lo que impide la entrega de la evidencia de verificación exigida por la cátedra. Por este motivo, el PM debe priorizar T-INF-05 sin tolerancia a demoras.

![][image2]  
**Figura 1\.** Red de tareas AON — dependencias e identificadores por equipo. El diagrama se construyó en draw.io a partir de la tabla de precedencias de la Sección 5.1 y se adjunta como imagen en alta resolución junto a este documento. En el diagrama se distinguen visualmente: las tareas del camino crítico (borde rojo, grosor 2px), las tareas de prueba (borde punteado violeta), las dependencias entre equipos (líneas punteadas grises) y las dependencias internas de cada equipo (líneas sólidas del color del equipo).

---

## 6\. Estimación de Tiempos y Recursos

### 6.1 Resumen de estimaciones por tarea

| ID | Tarea | Equipo | Horas estimadas | Semanas (a 4h/sem) | Recursos adicionales |
| :---- | :---- | :---- | :---- | :---- | :---- |
| T-INF-01 | Config. repositorio Git | PM | 2 hs | 1 | GitHub account |
| T-INF-02 | Config. Firebase | PM | 5 hs | 3 | Firebase account (Blaze), Firebase Storage |
| T-INF-03 | Setup entorno Flutter | PM | 2 hs | 1 | Android Studio / VS Code, emuladores |
| T-INF-04 | Contrato interfaz Evento | PM | 2 hs | 1 | — |
| T-INF-05 | Integración final | PM | 4 hs | 2 | Dispositivos físicos para prueba |
| T-INF-06 | Documentación técnica | PM | 2 hs | 1 | — |
| T-RNF-01 | Reglas de seguridad Firestore | PM | 3 hs | 2 | — |
| T-TEST-01 | Setup planilla de suite de pruebas | PM | 2 hs | 1 | Plantilla Google Sheets cátedra |
| T-TEST-05 | Pruebas de RNF | PM | 4 hs | 2 | Herramientas de profiling, dispositivos físicos |
| T-TEST-06 | Ejecución final suite — registro OK | PM | 3 hs | 2 | Google Sheets compartido |
| T-AUTH-01 | Registro vecinos | Equipo A | 4 hs | 2 | — |
| T-AUTH-02 | Login Firebase Auth | Equipo A | 3 hs | 2 | — |
| T-AUTH-03 | Control acceso por roles | Equipo A | 3 hs | 2 | — |
| T-AUTH-04 | Promoción ref. barrial | Equipo A | 3 hs | 2 | — |
| T-AUTH-05 | Sistema de reputación | Equipo A | 5 hs | 3 | — |
| T-AUTH-06 | Validación geográfica | Equipo A | 4 hs | 2 | — |
| T-AUTH-07 | Gestión rep. falsos | Equipo A | 3 hs | 2 | — |
| T-AUTH-08 | Panel admin usuarios | Equipo A | 5 hs | 3 | — |
| T-AUTH-09 | Verificación identidad vecino | Equipo A | 4 hs  | 2  | Firebase Storage  |
| T-TEST-02 | Pruebas módulo Auth y Roles | Equipo A | 3 hs | 2 | Planilla Google Sheets |
| T-REP-01 | UI principal y nav. | Equipo B | 4 hs | 2 | — |
| T-REP-02 | Botón reporte rápido | Equipo B | 3 hs | 2 | Dispositivo con GPS |
| T-REP-03 | Formulario detallado | Equipo B | 4 hs | 2 | Firebase Storage, paquete firebase\_storage  |
| T-REP-04 | Reporte por voz STT on-device | Equipo B | 5 hs | 3 | Paquete speech\_to\_text (Flutter), sin API externa |
| T-REP-05 | Mapa de incidencias | Equipo B | 6 hs | 3 | Google Maps API key |
| T-REP-06 | Visualización estados | Equipo B | 3 hs | 2 | — |
| T-TEST-03 | Pruebas módulo Reporte | Equipo B | 3 hs | 2 | Planilla Google Sheets, audio pregrabado |
| T-NLP-01 | Config. Genkit y Gemini | Equipo C | 3 hs | 2 | — |
| T-NLP-02 | CF: normalización evento | Equipo C | 4 hs | 2 | Node.js, Firebase CLI |
| T-NLP-03 | Genkit Flow: extracción semántica | Equipo C | 4 hs | 2 | — |
| T-NLP-04 | Genkit Flow: clasificación prioridad | Equipo C | 4 hs | 2 | — |
| T-NLP-05 | CF: detección riesgo vital | Equipo C | 3 hs | 2 | — |
| T-NLP-06 | CF: calibración algoritmo | Equipo C | 2 hs | 1 | — |
| T-NLP-07 | Alertas push FCM/APNs | Equipo C | 4 hs | 2 | Certificados APNs (Apple Dev. Account) |
| T-NLP-08 | Persistencia Firestore | Equipo C | 3 hs | 2 | — |
| T-NLP-09 | Notif. masivas admin | Equipo C | 2 hs | 1 | — |
| T-TEST-04 | Pruebas motor NLP | Equipo C | 3 hs | 2 | Planilla Google Sheets, casos de prueba del diccionario |

### 6.2 Recursos de infraestructura requeridos

| Recurso | Responsable de provisión | Costo | Notas |
| :---- | :---- | :---- | :---- |
| Firebase Blaze Plan | PM | Gratuito | Requiere habilitar facturación, pero el tier gratuito incluye 5 GB storage, Auth, Firestore, Cloud Functions y FCM. Suficiente para uso académico dentro del free tier.  |
| Firebase Genkit \+ Gemini 2.5 Flash-Lite | Equipo C  | \~$0.00/mes | Costo estimado \< $0.30/mes para el volumen académico del proyecto (\~5.000 reportes). Integración nativa con Cloud Functions en Node.js. Requiere plan Blaze activo (ya habilitado).  |
| GitHub (repositorio) | PM | Gratuito | Plan Free, repositorio público ilimitado o privado con colaboradores. |
| Google Maps API Key | PM | Gratuito (dentro del límite de uso) | $200 de crédito mensual gratuito de Google Cloud. Suficiente para uso académico. |
| speech\_to\_text Flutter package | Equipo B | Gratuito | Paquete pub.dev. Usa el motor STT nativo del SO, sin API externa. |
| Apple Developer Account | Equipo B | $99/año (opcional) | Solo necesario para pruebas en dispositivos iOS físicos. El simulador Xcode no requiere cuenta. |
| Android Studio / VS Code | Cada integrante | Gratuito | Entorno de desarrollo local. |
| Firebase CLI | Equipo C | Gratuito | Para deploy de Cloud Functions desde terminal. |
| Jira | PM | Gratuito (plan Free, hasta 10 usuarios) | Herramienta de gestión del proyecto. Cada tarea de este documento corresponde a un issue en Jira con estimación, asignado y estado. |
| Planilla de suite de pruebas (Google Sheets) | PM (coordinador de turno) | Gratuito | Plantilla provista por la cátedra. El coordinador la descarga, genera una copia en línea y la comparte con integrantes y docentes antes de iniciar T-TEST-01. |

### 6.3 Justificación de estimaciones

Las estimaciones se realizaron considerando los siguientes factores:

**Nivel de experiencia del equipo:** Se asume familiaridad básica con Flutter y Firebase. Las tareas que involucran tecnologías nuevas o de mayor complejidad (T-REP-04 STT on-device, T-REP-05 Maps, T-NLP-01 a T-NLP-05 Cloud Functions con Genkit/Gemini, T-REP-03 Firebase Storage) tienen estimaciones más conservadoras que las tareas de UI estándar.

**Ajuste de T-INF-02:** Se incrementó de 4 a 5 horas para incluir la configuración completa de Firebase Storage (habilitación del plan Blaze, configuración de reglas de seguridad de Storage y validación de integración con Flutter) junto con la configuración de Firebase. 

**Ajuste de T-REP-04:** Se redujo de 6 a 5 horas respecto a la versión anterior. El enfoque on-device con el paquete speech\_to\_text elimina la complejidad de integrar una API externa (autenticación, manejo de errores de red, latencia), simplificando la implementación.

**Complejidad técnica:** Las Cloud Functions del motor NLP (T-NLP-02 a T-NLP-05) son las más complejas porque combinan lógica de negocio, procesamiento de texto y escritura en Firestore. Las tareas de UI tienen menor varianza de estimación.

**Factor de integración:** Se reservaron 4 horas para la integración final (T-INF-05) como buffer ante incompatibilidades entre los módulos desarrollados en paralelo.

**Buffer de holgura:** Cada equipo tiene entre 2 y 6 horas de margen respecto a su presupuesto de 32 horas, destinadas a resolver imprevistos, retrabajos y revisiones.

---

## 7\. Calendarización (Gantt)

La calendarización se distribuye en 8 semanas. Las tareas se asignan respetando las dependencias identificadas en la sección 5 y la disponibilidad de 4 horas/persona/semana como base conservadora. Las tareas que requieren más de 4 horas se extienden en múltiples semanas.

| Semana | Fechas | PM | Equipo A | Equipo B | Equipo C |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **1** | 01/05 – 07/05 | T-INF-01, T-INF-02 (inicio) | — | — | — |
| **2** | 08/05 – 14/05 | T-INF-02 (fin), T-INF-03, T-INF-04, T-RNF-01 (inicio) | T-AUTH-01 (inicio) | T-REP-01 (inicio) | T-NLP-01 (inicio) |
| **3** | 15/05 – 21/05 | T-RNF-01 (fin) | T-AUTH-01 (fin), T-AUTH-02 (inicio) | T-REP-01 (fin), T-REP-02 (inicio) | T-NLP-01 (fin), T-NLP-02 (inicio) |
| **4** | 22/05 – 28/05 | — | T-AUTH-02 (fin), T-AUTH-03 (inicio) | T-REP-02 (fin), T-REP-03 (inicio) | T-NLP-02 (fin), T-NLP-03 (inicio) |
| **5** | 29/05 – 04/06 | T-TEST-01 | T-AUTH-03 (fin), T-AUTH-04 (inicio) | T-REP-03 (fin), T-REP-04 (inicio) | T-NLP-03 (fin), T-NLP-04 (inicio) ‖ T-NLP-05 (inicio) |
| **6** | 05/06 – 11/06 | — | T-AUTH-04 (fin), T-AUTH-05 (inicio) | T-REP-04 (continúa), T-REP-05 (inicio) | T-NLP-04 (fin) ‖ T-NLP-05 (fin), T-NLP-07 (inicio), T-NLP-06 (inicio) |
| **7** | 12/06 – 18/06 | — | T-AUTH-05 (fin), T-AUTH-06 (inicio) ‖ T-AUTH-07 (inicio), T-TEST-02 (inicio) | T-REP-04 (fin), T-REP-05 (continúa), T-TEST-03 (inicio) | T-NLP-07 (fin), T-NLP-08 (inicio) ‖ T-NLP-09 (inicio), T-TEST-04 (inicio) |
| **8** | 19/06 – 26/06 | T-INF-05, T-INF-06, T-TEST-05, T-TEST-06 | T-AUTH-06 (fin), T-AUTH-07 (fin), T-AUTH-08, T-AUTH-09, T-TEST-02 (fin)  | T-REP-05 (fin), T-REP-06, T-TEST-03 (fin) | T-NLP-08 (fin), T-NLP-09 (fin), T-NLP-06 (fin), T-TEST-04 (fin) |

**Referencia:** ‖ indica ejecución en paralelo dentro del mismo equipo.

---

## 8\. Herramientas de Ejecución y Proceso

Esta sección documenta las herramientas y prácticas de trabajo que el equipo debe utilizar durante la fase de ejecución, sirviendo de referencia para las fases de Ejecución, Verificación y Cierre del TPI.

### 8.1 Control de versiones — Git \+ GitHub

El repositorio se organiza con la siguiente estructura de branches:

- **main**: rama estable, solo recibe merges desde develop tras integración exitosa.  
- **develop**: rama de integración continua del equipo.  
- **feature/equipo-a, feature/equipo-b, feature/equipo-c**: una rama por equipo para desarrollo paralelo.  
- **hotfix/\***: para correcciones urgentes post-integración.

Cada integrante debe registrar sus commits con mensajes descriptivos que referencien el ID de la tarea correspondiente (ej. **\[T-AUTH-03\] Implementar middleware de control de acceso por rol**). Este historial de commits constituye evidencia individual de participación en la fase de ejecución.

### 8.2 Gestión de proyectos — Jira

Cada tarea definida en este documento corresponde a un issue en Jira con los siguientes campos mínimos: ID unívoco (T-INF-01, T-AUTH-01, etc.), estimación en horas, asignado, sprint asignado y estado (To Do / In Progress / Done). El coordinador de turno es responsable semanal de actualizar los estados, registrar las horas efectivamente trabajadas y documentar cualquier desvío respecto a la planificación original.

### 8.3 PSP — Personal Software Process

Cada integrante aplica PSP registrando por cada tarea: tiempo estimado vs. tiempo real, defectos encontrados y tiempo de corrección. Este registro individual es complementario al seguimiento grupal en Jira y será solicitado como evidencia durante la evaluación.

### 8.4 Planilla de suite de pruebas — Google Sheets

El coordinador de turno descarga la plantilla provista por la cátedra en la semana 5 (T-TEST-01), genera una copia en línea y la comparte con todos los integrantes y con los docentes antes de iniciar las ejecuciones. La hoja 1 contiene los casos de prueba definidos en la Sección 6 del SRS. La hoja 2 registra los resultados de cada ejecución. La evidencia de verificación exigida es que la última ejecución registrada muestre resultado "OK" en todos los casos sin excepción.

### 8.5 Referencia para la fase de Cierre

El documento de cierre (máximo 2 páginas, sin contar carátula) debe incluir al inicio: alcance del producto construido, trabajo realizado en implementación y seguimiento, pruebas ejecutadas y herramientas utilizadas (Git, GitHub, Jira, Firebase, Firebase Storage, Google Sheets). Al final, las lecciones aprendidas con reflexiones positivas, negativas y neutrales sobre la gestión del proyecto.

---

*Fin del documento — V 1.3*   


[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>
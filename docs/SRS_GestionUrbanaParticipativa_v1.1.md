# ![][image1]

# UNIVERSIDAD NACIONAL DEL NOROESTE DE LA PROVINCIA DE BUENOS AIRES Gestión de Proyectos | 1° Cuatrimestre 2026

**Especificación de Requisitos de Software (SRS)**

App de Coordinación Comunitaria para la Gestión Urbana Participativa 

---

**Grupo D**

**Integrantes:** Elias Uribe, Eric Doyle, Lucas Lovizzio, Agustín Campagna, Tomás Miquelez, Joaquín Hubner, Jeremías Aguirres 

**Versión:** 1.1  
**Fecha:** Abril 2026  
**Formato:** IEEE 830

---

## Historial de Versiones

| Versión | Fecha | Autores | Descripción de Cambios |
| :---- | :---- | :---- | :---- |
| 0.1 | Marzo 2026 | Grupo D | Borradores iniciales de los módulos: requerimientos de incidentes (Tarea 1), gestión de roles (Tarea 2), métricas (Tarea 3), trazabilidad (Tarea 4), diagramas (Tarea 5\) y criterios de validación (Tarea 6). |
| 0.2 | Abril 2026 | Grupo D | Ajuste del enfoque del sistema: transición de emergencias asistenciales críticas a incidentes urbanos no críticos. Actualización de terminología: "botón de pánico" → "botón de reporte rápido"; "voluntario verificado" → "referente barrial". Reemplazo de ejemplos del dominio médico por ejemplos del dominio urbano. |
| 0.3 | Abril 2026 | Grupo D | Incorporación de secciones faltantes según IEEE 830: Glosario (sección 1.3), Interfaces Externas (sección 3.1), Supuestos y Dependencias (sección 2.5). Resolución de inconsistencia en tiempo de procesamiento (unificado en 4 segundos). Expansión de la RTM. Incorporación de sección de Seguridad y Privacidad (RNF-SEG). |
| 1.0 | Abril 2026 | Grupo D | Versión final. Aplicación del checklist de validación de Pressman (sección 5.1). Historial de versiones agregado. Revisión integral de consistencia terminológica y referencial. |
| 1.1 | Mayo 2026 | Grupo D | Revisión post-retroalimentación docente: precisión de convenciones deberá/debería (IEEE 830); reemplazo de anglicismo “gracefully”; tipificación de salidas de RF-REP-01/02/03 (Reporte Preliminar, Abreviado y Completo); actualización de RF-PRO-01 con convergencia de estructura de datos; ampliación de RF-ROL-02 (privilegios y responsabilidades del Referente Barrial); nota de alcance MVP en sección 1.4; aclaración de alcance parcial de la validación en sección 5.1. |

---

## Tabla de Contenidos

1. Introducción  
   - 1.1 Propósito  
   - 1.2 Convenciones del Documento  
   - 1.3 Audiencia Objetivo y Sugerencias de Lectura  
   - 1.4 Alcance  
   - 1.5 Definiciones, Acrónimos y Abreviaciones  
   - 1.6 Referencias  
   - 1.7 Visión General del Documento  
2. Descripción General del Producto  
3. Requisitos Específicos  
4. Diagramas del Sistema  
5. Gestión de Trazabilidad  
6. Criterios de Validación y Pruebas

---

## 1\. Introducción

### 1.1 Propósito

El presente documento constituye la Especificación de Requisitos del Software (SRS) para la aplicación móvil de coordinación comunitaria orientada a la gestión urbana participativa. Su propósito es definir de manera formal, completa y no ambigua los requisitos funcionales y no funcionales del sistema, sirviendo como referencia contractual entre el equipo de desarrollo y los stakeholders del proyecto.

Se adopta **IEEE 830** (IEEE Std 830-1998) como base estructural del documento, siguiendo el formato de especificación propuesto por Wiegers y referenciado por Pressman en el Capítulo 5 de *Ingeniería de Software: Un Enfoque Práctico*. Dicha base se complementa con una sección de gestión de trazabilidad (Sección 5\) y una sección de criterios de validación y pruebas (Sección 6), incorporadas en respuesta a los requerimientos específicos del Trabajo Práctico Integrador de la asignatura Gestión de Proyectos (UNNOBA, 1er cuatrimestre 2026). Esta decisión de formato está alineada con la consigna del trabajo, que habilita explícitamente el uso de estándares existentes o la creación de un formato propio justificado.

Este documento es la entrega correspondiente a la Primera Iteración de la fase de Planificación del Trabajo Práctico Integrador de la asignatura Gestión de Proyectos.

### 1.2 Convenciones del Documento

Este documento adopta las siguientes convenciones:

- Los identificadores de requisitos funcionales siguen el formato **RF-XXX-NN**, donde XXX identifica el módulo y NN es un número secuencial (ej. RF-REP-01).  
- Los identificadores de requisitos no funcionales siguen el formato **RNF-XXX-NN**, donde XXX identifica la categoría (ej. RNF-REN-01).  
- Los identificadores de casos de prueba siguen el formato **T-XXX-NN** (ej. T-REP-01).  
- El término **deberá** indica un requisito obligatorio (equivalente a “shall” en IEEE 830), cuyo incumplimiento constituye una no-conformidad del sistema. El término **debería** indica un requisito recomendado (equivalente a “should” en IEEE 830), cuya implementación es deseable pero no imprescindible para la aceptación del sistema.  
- Las celdas marcadas con **—** en tablas indican que el campo no aplica o no tiene observaciones adicionales.

### 1.3 Audiencia Objetivo y Sugerencias de Lectura

Este documento está dirigido a los siguientes lectores:

| Audiencia | Secciones de Interés Principal |
| :---- | :---- |
| **Equipo de desarrollo** | Secciones 3 (Requisitos Específicos), 4 (Diagramas) y 6 (Validación) |
| **Docentes evaluadores** | Documento completo, con énfasis en secciones 1, 5 y 6 |
| **Administradores vecinales (clientes)** | Secciones 1.2, 2 y 3.2 (Requisitos Funcionales) |
| **Stakeholders no técnicos** | Secciones 1.2, 2.2 (Funciones) y 2.3 (Usuarios) |

Se recomienda leer el documento en orden secuencial en la primera lectura. En revisiones posteriores, utilizar la Tabla de Contenidos y los identificadores de requisitos para navegación directa.

### 1.4 Alcance

El sistema a desarrollar es una aplicación móvil multiplataforma (Android e iOS) que permite a los vecinos de localidades medianas y barrios en desarrollo reportar incidentes urbanos no críticos para la vida humana (baches, luminarias defectuosas, cables colgando, caída de ramas, micro-basurales, calles anegadas, entre otros), con el objetivo de visibilizarlos, priorizarlos y facilitar su resolución coordinada entre la comunidad y las autoridades vecinales.

El sistema actúa como plataforma de ciencia ciudadana: los vecinos operan como red de sensores distribuidos que alimentan información estructurada a los administradores vecinales, quienes coordinan la respuesta y resolución de los incidentes reportados.

El sistema **no reemplaza a los servicios de emergencia oficiales** (911, 107, Policía, Bomberos, Ambulancias). Ante la detección de situaciones de riesgo vital, el sistema deriva automáticamente al usuario a dichos servicios.

**Alcance del MVP académico:** El alcance completo descripto en esta SRS representa la visión integral del sistema. Para los fines del Trabajo Práctico Integrador, el MVP que constituye el núcleo funcional obligatorio comprende: (1) reporte de incidentes mediante formulario (RF-REP-03) y botón de reporte rápido (RF-REP-01); (2) procesamiento básico con NLP para clasificación de prioridad (RF-PRO-01, RF-PRO-03, RF-PRI-01, RF-PRI-02); (3) gestión de roles vecino informante y administrador vecinal (RF-ROL-01, RF-ROL-03); (4) panel de administración con mapa y gestión del ciclo de vida del incidente (RF-ADM-01, RF-ADM-02); y (5) validación geográfica de reportes (RF-MOD-02). Las siguientes funcionalidades se consideran de iteraciones futuras y quedan fuera del MVP: reporte por voz (RF-REP-02), sistema de reputación (RF-MOD-01), calibración del algoritmo por administrador (RF-PRI-04), notificaciones push a la comunidad (RF-ADM-04), y el rol de Referente Barrial (RF-ROL-02). Esta priorización permite validar el flujo principal del sistema en el contexto académico sin comprometer la completitud de la especificación.

### 1.5 Definiciones, Acrónimos y Abreviaciones

| Término | Definición |
| :---- | :---- |
| **Vecino Informante** | Usuario base registrado en el sistema con capacidad para reportar incidentes urbanos no críticos mediante interfaz gráfica o comandos de voz. |
| **Referente Barrial** | Usuario verificado con rol de moderador de campo, habilitado para recibir alertas push geolocalizadas y verificar incidentes in situ. |
| **Administrador Vecinal** | Usuario con privilegios de gestión del sistema, encargado de moderar la plataforma, gestionar usuarios y coordinar la resolución de incidentes. |
| **Incidente Urbano** | Problema no crítico para la vida humana detectado en el espacio público (baches, luminarias defectuosas, cables colgando, micro-basurales, etc.). |
| **Reporte** | Registro estructurado de un incidente urbano generado por un vecino informante. |
| **Motor de Priorización** | Algoritmo interno que clasifica automáticamente la urgencia de cada incidente reportado en base a palabras clave y reglas configurables. |
| **Score de Prioridad** | Valor numérico calculado por el motor de priorización que determina el nivel de urgencia de un incidente. |
| **Ciencia Ciudadana** | Modelo de participación comunitaria en el que los ciudadanos actúan como sensores activos para la detección y reporte de problemas urbanos. |
| **NLP** | Natural Language Processing. Conjunto de técnicas de inteligencia artificial para procesar y analizar texto en lenguaje natural. |
| **Speech-to-Text** | Tecnología de conversión de audio hablado a texto escrito. |
| **FCM** | Firebase Cloud Messaging. Servicio de Google para envío de notificaciones push en dispositivos Android. |
| **APNs** | Apple Push Notification Service. Servicio de Apple para envío de notificaciones push en dispositivos iOS. |
| **GPS** | Global Positioning System. Sistema de posicionamiento global para geolocalización. |
| **SLA** | Service Level Agreement. Acuerdo de nivel de servicio que garantiza tiempos de respuesta mínimos por parte de un proveedor. |
| **SRS** | Software Requirements Specification. Especificación de Requisitos del Software. |
| **RTM** | Requirements Traceability Matrix. Matriz de trazabilidad de requisitos. |
| **RF** | Requisito Funcional. |
| **RNF** | Requisito No Funcional. |

### 1.6 Referencias

- IEEE Std 830-1998. *IEEE Recommended Practice for Software Requirements Specifications*.  
- Pressman, R. S. (2010). *Ingeniería de Software: Un Enfoque Práctico* (7ma ed.). McGraw-Hill. Capítulo 5: "Comprensión de los requerimientos" — Lista de verificación para validar requerimientos.  
- Informe de Viabilidad del Proyecto (Grupo D, 2026).  
- Consigna del Trabajo Práctico Integrador — Gestión de Proyectos, 1er cuatrimestre 2026, UNNOBA.

### 1.7 Visión General del Documento

Este documento está organizado en seis secciones principales. La Sección 1 presenta la introducción, convenciones, audiencia objetivo, alcance, glosario y referencias. La Sección 2 describe el producto desde una perspectiva general, incluyendo el contexto del sistema, sus funciones principales, las características de los usuarios, restricciones, supuestos y dependencias. La Sección 3 contiene los requisitos específicos: interfaces externas, requisitos funcionales organizados por módulo y requisitos no funcionales. La Sección 4 presenta los diagramas del sistema. La Sección 5 establece la metodología de validación con el checklist de Pressman y la matriz de trazabilidad. La Sección 6 define los criterios de validación y pruebas con casos de prueba concretos.

---

## 2\. Descripción General del Producto

### 2.1 Perspectiva del Producto

La aplicación es un sistema nuevo e independiente, sin integración directa con sistemas gubernamentales existentes en su versión inicial. Opera como una plataforma autónoma de ciencia ciudadana que puede ser adoptada por comunas o asociaciones vecinales como herramienta de gestión participativa del espacio público.

El sistema se compone de los siguientes módulos internos:

- Módulo de Reporte de Incidentes (interfaz gráfica y voz)  
- Motor de Priorización (NLP y reglas configurables)  
- Módulo de Geolocalización  
- Sistema de Alertas Push  
- Módulo de Gestión de Usuarios y Roles  
- Panel de Administración  
- Módulo de Moderación y Reputación

### 2.2 Funciones del Producto

El sistema deberá:

- Permitir a los vecinos reportar incidentes urbanos mediante formulario, botón de reporte rápido o comandos de voz.  
- Procesar y clasificar automáticamente la urgencia de cada reporte mediante NLP.  
- Geolocalizar automáticamente el origen de cada reporte.  
- Notificar a los referentes barriales más cercanos al incidente reportado.  
- Permitir a los referentes barriales verificar y dar seguimiento a los incidentes en campo.  
- Proporcionar al administrador un panel centralizado de gestión de incidentes, usuarios y recursos.  
- Mantener un sistema de reputación por usuario para mitigar reportes falsos.  
- Detectar y filtrar automáticamente situaciones de riesgo vital, derivando al usuario a los servicios oficiales.  
- Registrar un historial auditable de todos los incidentes para trazabilidad y rendición de cuentas.

### 2.3 Características de los Usuarios

| Rol | Perfil | Nivel Técnico | Necesidades Clave |
| :---- | :---- | :---- | :---- |
| **Vecino Informante** | Ciudadano general, rango etario amplio, potencialmente en movimiento al reportar | Básico | Interfaz simple, máximo 2 interacciones para emitir un reporte, opción de voz |
| **Referente Barrial** | Vecino verificado con conducta colaborativa sostenida, conoce el barrio | Intermedio | Alertas geolocalizadas, capacidad de verificar y confirmar incidentes en campo |
| **Administrador Vecinal** | Personal de junta vecinal o sociedad de fomento | Intermedio- Avanzado | Panel centralizado, filtros, estados de resolución, notificaciones masivas |

### 2.4 Restricciones

- El sistema debe ser compatible con Android e iOS en sus versiones mayoritariamente adoptadas al momento del desarrollo.  
- El sistema no proveerá hardware (dispositivos móviles) ni planes de conectividad a los usuarios.  
- El sistema no procesará ni distribuirá reportes de emergencias críticas que impliquen riesgo vital.  
- El registro de vecinos requiere acreditación de domicilio en el área de cobertura (código de invitación o comprobante de servicio).  
- El sistema debe cumplir con las disposiciones legales aplicables en materia de protección de datos personales.

### 2.5 Supuestos y Dependencias

**Supuestos:**

- El usuario dispone de un dispositivo móvil con sistema operativo Android o iOS.  
- El dispositivo cuenta con GPS habilitado y funcional al momento de emitir un reporte.  
- El dispositivo tiene conectividad a internet (WiFi o datos móviles) al momento de usar la aplicación.  
- La comuna o asociación vecinal que adopte el sistema designa al menos un administrador responsable.  
- Los vecinos que deseen registrarse pueden acreditar domicilio en el área de cobertura definida por el administrador.

**Dependencias:**

- La funcionalidad de conversión de voz a texto depende de la disponibilidad de un servicio externo de Speech-to-Text (ver Sección 3.1.3).  
- Las notificaciones push dependen de la disponibilidad de FCM (Android) y APNs (iOS).  
- La visualización cartográfica de incidentes depende de una API de mapas externa.  
- La clasificación automática de incidentes depende de la disponibilidad de un servicio o biblioteca de NLP.

---

## 3\. Requisitos Específicos

### 3.1 Requisitos de Interfaces Externas

#### 3.1.1 Interfaces de Usuario

La aplicación proveerá dos interfaces principales:

- **Interfaz móvil para vecinos informantes y referentes barriales:** pantalla de reporte rápido, mapa de incidencias activas del barrio, historial de reportes propios y estado de resolución.  
- **Panel de administración:** accesible desde la misma aplicación con credenciales de administrador. Incluye mapa de incidencias con filtros, gestión de usuarios, asignación de categorías y actualización de estados de resolución.

#### 3.1.2 Interfaces de Hardware

- **GPS del dispositivo:** el sistema accede a la ubicación del dispositivo para geolocalizar automáticamente el reporte. El usuario debe haber concedido permiso de ubicación a la aplicación.  
- **Micrófono del dispositivo:** utilizado para captura de audio en la funcionalidad de reporte por voz. El usuario debe haber concedido permiso de micrófono a la aplicación.  
- **Cámara del dispositivo (opcional):** utilizada por el referente barrial para adjuntar fotografías al verificar un incidente en campo.

#### 3.1.3 Interfaces de Software (Servicios Externos)

| Servicio | Propósito | Notas |
| :---- | :---- | :---- |
| **API Speech-to-Text** (ej. Google Speech-to-Text, Whisper) | Conversión de audio capturado a texto para el módulo de reporte por voz | Requiere conectividad. Ante la ausencia de respuesta del servicio, el sistema deberá informar al usuario mediante un mensaje de error descriptivo y permitir el reenvío del reporte o su almacenamiento local para sincronización posterior. |
| **Biblioteca/API NLP** (ej. spaCy, transformers) | Extracción de palabras clave y clasificación automática de prioridad de incidentes | Puede implementarse como servicio propio o integrado en el backend. |
| **FCM (Firebase Cloud Messaging)** | Envío de notificaciones push a dispositivos Android | Requiere cuenta de Firebase configurada. |
| **APNs (Apple Push Notification service)** | Envío de notificaciones push a dispositivos iOS | Requiere certificados Apple Developer configurados. |
| **API de Mapas** (ej. Google Maps, OpenStreetMap/Leaflet) | Visualización del mapa de incidencias geolocalizadas | Puede requerir clave de API según proveedor elegido. |
| **Base de datos** (backend propio) | Persistencia de usuarios, reportes, estados y auditoría | A definir en la fase de diseño arquitectónico. |

#### 3.1.4 Interfaces de Comunicación

- Toda comunicación entre la aplicación móvil y el backend deberá realizarse mediante HTTPS.  
- Las notificaciones push se enviarán a través de los canales estándar FCM y APNs respectivamente.

---

### 3.2 Requisitos Funcionales

Los requisitos funcionales se organizan por módulo. Cada requisito sigue el formato: identificador, descripción, entradas, procesamiento, salidas, precondiciones y postcondiciones cuando aplica.

---

#### 3.2.1 Módulo de Reporte de Incidentes

##### RF-REP-01 — Emisión de Reporte mediante Botón de Reporte Rápido

- **Descripción:** El sistema deberá permitir al usuario emitir un reporte de incidente urbano mediante un botón de acceso rápido disponible en la pantalla principal de la aplicación.  
- **Entradas:** Acción del usuario (presión del botón).  
- **Procesamiento:** Captura automática de geolocalización del dispositivo; identificación del usuario autenticado; registro de timestamp del evento.  
- **Salidas:** Reporte Preliminar: objeto con los campos {userID, timestamp, coordenadas GPS}. Dado que este mecanismo no captura descripción textual ni categoría, se clasifica como Reporte Preliminar. La normalización a la estructura común de datos ocurre en RF-PRO-01.  
- **Precondición:** El usuario debe estar autenticado. El dispositivo debe tener habilitada la geolocalización.  
- **Postcondición:** El Reporte Preliminar es enviado al módulo de procesamiento para su normalización y clasificación.  
- **Nota — Área de cobertura:** El área de cobertura es definida y configurada por el Administrador Vecinal mediante el Panel de Administración (ver RF-ADM-01), quien establece un perímetro geográfico representado como polígono o radio sobre el mapa del sistema. El vecino puede verificar si se encuentra dentro del área desde la pantalla principal de la aplicación, que indica visualmente si la ubicación actual está dentro o fuera de la zona habilitada. Si al presionar el botón de reporte rápido la ubicación del dispositivo se encuentra fuera del área de cobertura, el sistema informa al vecino mediante un mensaje descriptivo y bloquea la emisión del reporte (ver RF-MOD-02). Si el vecino detecta un incidente fuera del área pero considera que es relevante, deberá contactar directamente al Administrador Vecinal por los canales externos habilitados por la organización.

##### RF-REP-02 — Emisión de Reporte mediante Voz (NLP)

- **Descripción:** El sistema deberá permitir al usuario emitir un reporte de incidente urbano mediante comandos de voz, facilitando el uso en situaciones donde el usuario está en movimiento, conduce o necesita mantener las manos libres.  
- **Entradas:** Audio capturado desde el micrófono del dispositivo.  
- **Procesamiento:** Conversión de voz a texto mediante servicio de Speech-to-Text; normalización del texto resultante.  
- **Salidas:** Reporte Abreviado: objeto con los campos {userID, timestamp, coordenadas GPS, texto transcripto}. Dado que no se captura categoría ni fotografía, se clasifica como Reporte Abreviado. La normalización a la estructura común de datos ocurre en RF-PRO-01.  
- **Precondición:** El dispositivo debe contar con micrófono funcional. El usuario debe haber concedido permisos de acceso al micrófono.  
- **Postcondición:** El texto es enviado al módulo de procesamiento para su análisis y clasificación.  
- **Restricción:** Requiere conectividad a internet para el servicio de Speech-to-Text.

##### RF-REP-03 — Emisión de Reporte mediante Formulario Detallado

- **Descripción:** El sistema deberá permitir al usuario emitir un reporte mediante un formulario con campos de texto libre, selección de categoría de incidente y posibilidad de adjuntar fotografía.  
- **Entradas:** Texto descriptivo del incidente; categoría seleccionada (opcional); fotografía adjunta (opcional).  
- **Procesamiento:** Captura de geolocalización; identificación del usuario; registro de timestamp.  
- **Salidas:** Reporte Completo: objeto con los campos {userID, timestamp, coordenadas GPS, texto descriptivo, categoría (opcional), fotografía adjunta (opcional)}. Este mecanismo genera el tipo de reporte con mayor riqueza de datos. La normalización a la estructura común de datos ocurre en RF-PRO-01.  
- **Postcondición:** El evento es enviado al módulo de procesamiento.

---

#### 3.2.2 Módulo de Procesamiento del Evento

##### RF-PRO-01 — Normalización del Evento

- **Descripción:** El sistema deberá transformar todas las entradas de reporte (voz transcripta, formulario o botón rápido) en un objeto de datos estructurado unificado.  
- **Entradas:** Texto del incidente; ubicación GPS; identificador de usuario; timestamp.  
- **Procesamiento:** Normalización de los tres tipos de reporte entrantes (Reporte Preliminar de RF-REP-01, Reporte Abreviado de RF-REP-02, Reporte Completo de RF-REP-03) a una estructura común. Los campos opcionales ausentes (descripción, categoría, fotografía) se completan con valores nulos o por defecto según corresponda. Asociación de metadatos adicionales.  
- **Salidas:** Objeto estructurado "Evento de Incidente" en formato homogéneo.

##### RF-PRO-02 — Enriquecimiento del Evento

- **Descripción:** El sistema deberá complementar el evento con información contextual relevante.  
- **Procesamiento:** Consulta del historial de reputación del usuario informante; análisis de incidentes cercanos activos para detección de duplicados; evaluación preliminar del tipo de incidente.  
- **Salidas:** Evento enriquecido con contexto adicional.

##### RF-PRO-03 — Flujo de Procesamiento de Incidente

- **Descripción:** El sistema deberá ejecutar el siguiente flujo secuencial de procesamiento para cada reporte recibido:  
    
  1. Captura de entrada (voz, formulario o botón rápido)  
  2. Conversión a texto (si la entrada es por voz)  
  3. Normalización del contenido  
  4. Detección de palabras clave mediante NLP  
  5. Evaluación del tipo de incidente (urbano no crítico vs. situación de riesgo vital)  
  6. Cálculo del score de prioridad operativa  
  7. Clasificación del evento y generación de alerta

---

#### 3.2.3 Motor de Priorización

##### RF-PRI-01 — Extracción de Palabras Clave

- **Descripción:** El sistema deberá identificar palabras clave relevantes del texto del incidente mediante técnicas de NLP.  
- **Entradas:** Texto normalizado del evento.  
- **Procesamiento:** Aplicación de técnicas de NLP (tokenización, análisis semántico); comparación con un diccionario de palabras clave configurable por el administrador.  
- **Salidas:** Lista de palabras clave detectadas con peso asociado.

##### RF-PRI-02 — Clasificación de Prioridad Operativa

- **Descripción:** El sistema deberá asignar un nivel de prioridad operativa al evento en base a las palabras clave detectadas y las reglas de clasificación configuradas.  
- **Procesamiento:** Evaluación de palabras clave y sus pesos; aplicación de reglas de clasificación.  
- **Salidas:** Nivel de prioridad: {Urgente, Alta, Media, Baja}.  
- **Ejemplo:** Un reporte con la palabra clave "cable pelado" o "poste caído" deberá clasificarse como Urgente; un reporte con "basura acumulada" deberá clasificarse como Media.

##### RF-PRI-03 — Cálculo de Score de Prioridad

- **Descripción:** El sistema deberá calcular un valor numérico de prioridad que permita ordenar los incidentes en el panel de administración.  
- **Procesamiento:** Función ponderada que considera: palabras clave detectadas y sus pesos; ubicación geográfica (zona de alta o baja densidad); historial de reportes previos en la misma ubicación; nivel de reputación del vecino informante.  
- **Salidas:** Score numérico de prioridad.

##### RF-PRI-04 — Calibración del Algoritmo de Priorización

- **Actor:** Administrador Vecinal.  
- **Descripción:** El sistema deberá permitir al administrador modificar los parámetros del algoritmo de priorización sin necesidad de actualizar la aplicación.  
- **Entradas:** Configuración del diccionario de palabras clave; ajuste de pesos por categoría de incidente; definición de zonas geográficas de prioridad.  
- **Salidas:** Configuración actualizada del motor de priorización aplicada en tiempo real.

##### RF-PRI-05 — Detección de Incidentes Fuera de Alcance (Riesgo Vital)

- **Descripción:** El sistema deberá detectar automáticamente aquellos reportes que describan situaciones de riesgo vital (incendios de gran magnitud, accidentes con víctimas, situaciones médicas críticas, etc.) y derivar al usuario a los servicios oficiales.  
- **Procesamiento:** Análisis del texto mediante NLP; comparación con diccionario de términos de alta criticidad.  
- **Comportamiento ante detección:** Se interrumpe el flujo normal de procesamiento. No se genera alerta comunitaria.  
- **Salidas:** Notificación en pantalla indicando que el incidente excede el alcance del sistema; visualización de botones de contacto con servicios oficiales (911, 107).  
- **Postcondición:** El evento queda excluido del sistema de coordinación comunitaria. Puede registrarse en log de auditoría sin distribuirse.

---

#### 3.2.4 Módulo de Salida del Sistema

##### RF-SAL-01 — Generación de Alerta Clasificada

- **Descripción:** El sistema deberá generar una alerta estructurada lista para su distribución a los referentes barriales cercanos al incidente.  
- **Salidas:** Nivel de prioridad operativa; ubicación GPS del incidente; descripción del incidente; categoría asignada; timestamp.

##### RF-SAL-02 — Persistencia del Evento

- **Descripción:** El sistema deberá almacenar todos los eventos generados en la base de datos para fines de auditoría, seguimiento y rendición de cuentas.  
- **Salidas:** Registro persistente que incluye: datos del evento, usuario informante, timestamps de cada cambio de estado, acciones de referentes y administrador.

---

#### 3.2.5 Módulo de Gestión de Usuarios y Roles

##### RF-ROL-01 — Registro de Vecinos Informantes

- **Descripción:** El sistema deberá permitir el registro de vecinos mediante validación de domicilio en el área de cobertura, a través de alguno de los siguientes mecanismos: código de invitación generado por el administrador, o carga de un comprobante de servicio que acredite domicilio en la zona.  
- **Salidas:** Cuenta de usuario activa con rol de Vecino Informante.

##### RF-ROL-02 — Verificación y Promoción de Referentes Barriales

- **Actor:** Administrador Vecinal.  
- **Descripción:** El sistema deberá permitir al administrador promover a un vecino informante al rol de Referente Barrial, previa verificación de conducta colaborativa sostenida (historial de reportes verídicos y, cuando aplique, validación presencial por la organización administradora).  
- **Precondición sugerida:** El vecino debe haber emitido al menos 5 reportes validados como verídicos.  
- **Salidas:** Cuenta de usuario actualizada al rol de Referente Barrial con privilegios ampliados. Al ser promovido, el vecino gana acceso a las siguientes funcionalidades adicionales: (a) recepción de alertas push geolocalizadas de incidentes cercanos a su zona asignada; (b) capacidad de verificar incidentes en campo y marcarlos como “Confirmado” o “Descartado” con evidencia fotográfica adjunta; (c) visibilidad del estado de resolución de todos los incidentes activos en su zona. El Referente Barrial interviene ante el Administrador Vecinal, a quien reporta sus verificaciones de campo. Sus responsabilidades son: confirmar o descartar incidentes reportados por vecinos informantes, notificar al administrador cuando un incidente requiere derivación urgente, y no gestionar por sí mismo la resolución definitiva del incidente (esa función corresponde al Administrador Vecinal).

##### RF-ROL-03 — Control de Acceso por Roles

- **Descripción:** El sistema deberá garantizar que cada tipo de usuario acceda únicamente a las funcionalidades correspondientes a su rol. Un vecino informante no podrá acceder al panel de administración ni a funcionalidades de referente barrial.  
- **Comportamiento ante acceso no autorizado:** El sistema deberá retornar un error de acceso denegado (HTTP 403 o equivalente) e impedir la operación solicitada.

---

#### 3.2.6 Panel de Administración

##### RF-ADM-01 — Mapa de Incidencias Centralizado

- **Descripción:** El sistema deberá proveer al administrador una vista de mapa con todos los incidentes activos del área de cobertura, diferenciados visualmente por nivel de prioridad y categoría.  
- **Salidas:** Mapa interactivo con marcadores geolocalizados, filtros por prioridad, categoría y estado.

##### RF-ADM-02 — Gestión del Ciclo de Vida del Incidente

- **Descripción:** El sistema deberá permitir al administrador actualizar el estado de resolución de cada incidente para mantener informada a la comunidad.  
- **Estados disponibles:** Recibido → Programado → En Reparación → Solucionado.  
- **Salidas:** Estado actualizado visible para todos los usuarios en el mapa de incidencias.

##### RF-ADM-03 — Gestión de Categorías y Recursos

- **Descripción:** El sistema deberá permitir al administrador asignar cada incidente a una categoría de mantenimiento (ej. "Mantenimiento Eléctrico", "Espacios Verdes", "Pavimentación", "Saneamiento") y registrar las acciones tomadas para su resolución.  
- **Salidas:** Registro de acciones asociado al incidente.

##### RF-ADM-04 — Comunicación Directa con la Comunidad

- **Descripción:** El sistema deberá permitir al administrador enviar notificaciones push a todos los vecinos del barrio o a una zona geográfica específica, informando avances o alertas generales.  
- **Salidas:** Notificación push enviada al segmento de usuarios seleccionado.

---

#### 3.2.7 Módulo de Moderación y Reputación

##### RF-MOD-01 — Sistema de Reputación por Usuario

- **Descripción:** El sistema deberá mantener un puntaje de confiabilidad para cada vecino informante, basado en el historial de veracidad de sus reportes previos. Los reportes de usuarios con baja reputación deberán mostrarse con advertencia en el panel del administrador.  
- **Comportamiento:** Cada reporte validado como verídico incrementa el puntaje; cada reporte marcado como falso lo decrementa. El puntaje es visible para el administrador.

##### RF-MOD-02 — Validación Geográfica de Reportes

- **Descripción:** El sistema deberá verificar que la ubicación GPS del dispositivo al momento del reporte coincida con el área de cobertura declarada para el usuario. Reportes emitidos desde fuera del área de cobertura configurada deberán ser bloqueados.  
- **Comportamiento ante violación:** El sistema bloquea el reporte e informa al usuario que se encuentra fuera del rango de cobertura.

##### RF-MOD-03 — Gestión de Reportes Falsos

- **Actor:** Administrador Vecinal.  
- **Descripción:** El sistema deberá permitir al administrador marcar un reporte como "Falso/Malintencionado". Esta acción deberá decrementar el puntaje de reputación del emisor y, ante incumplimientos reiterados, bloquear la capacidad de reporte del usuario.  
- **Salidas:** Puntaje de reputación actualizado; usuario bloqueado si supera el umbral de reportes falsos configurado.

---

### 3.3 Requisitos No Funcionales

#### 3.3.1 Rendimiento

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-REN-01** | Tiempo máximo para registrar un reporte desde la interacción del usuario | ≤ 5 segundos |
| **RNF-REN-02** | Tiempo máximo para completar el procesamiento completo del incidente (normalización, NLP y clasificación) | ≤ 10 segundos |
| **RNF-REN-03** | Latencia máxima de envío de alertas push desde la clasificación del evento | ≤ 5 segundos |
| **RNF-REN-04** | Latencia máxima de recepción de alertas push en el dispositivo del referente barrial | ≤ 5 segundos |

#### 3.3.2 Precisión

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-PRE-01** | Precisión mínima del sistema de geolocalización en entornos urbanos | ± 10 metros |
| **RNF-PRE-02** | Precisión mínima del motor de clasificación de prioridades, validada con datos de referencia | ≥ 80% |
| **RNF-PRE-03** | Porcentaje máximo de falsos positivos (incidentes clasificados como Urgentes sin serlo) | ≤ 10% |

#### 3.3.3 Disponibilidad y Escalabilidad

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-DIS-01** | Disponibilidad mínima mensual del sistema | ≥ 99% (máximo 7,2 horas de caída mensual) |
| **RNF-DIS-02** | Capacidad de concurrencia sin degradación significativa del rendimiento | ≥ 100 reportes simultáneos |
| **RNF-DIS-03** | Incremento máximo del tiempo de respuesta bajo picos de alta carga respecto a los valores nominales | ≤ 30% |

#### 3.3.4 Usabilidad

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-USA-01** | Número máximo de interacciones para completar un reporte | ≤ 2 interacciones |
| **RNF-USA-02** | Tiempo promedio máximo para completar un reporte | ≤ 60 segundos |

#### 3.3.5 Eficiencia Operativa

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-EFI-01** | Tiempo promedio máximo para que un referente barrial confirme o descarte un incidente | ≤ 5 minutos |
| **RNF-EFI-02** | Reducción del tiempo de detección de incidentes respecto a canales informales (grupos de WhatsApp) | ≥ 50% |
| **RNF-EFI-03** | Tiempo máximo para que el administrador gestione un reporte identificado como falso | ≤ 10 minutos |

#### 3.3.6 Calidad y Confiabilidad

| ID | Descripción | Valor |
| :---- | :---- | :---- |
| **RNF-CAL-01** | Porcentaje máximo de reportes falsos sobre el total de reportes generados | ≤ 15% |
| **RNF-CAL-02** | El sistema debe mantener consistencia en la clasificación ante entradas semánticamente similares | Verificable mediante pruebas de regresión con conjunto de datos de referencia |

#### 3.3.7 Seguridad y Privacidad

| ID | Descripción |
| :---- | :---- |
| **RNF-SEG-01** | Toda la comunicación entre la aplicación móvil y el backend deberá realizarse mediante HTTPS con certificado válido. |
| **RNF-SEG-02** | Los datos personales de los usuarios deberán almacenarse encriptados en la base de datos. |
| **RNF-SEG-03** | El sistema deberá implementar autenticación basada en tokens con expiración configurable. |
| **RNF-SEG-04** | El sistema no deberá exponer datos personales de un usuario a otros usuarios con rol de Vecino Informante o Referente Barrial. |

---

## 4\. Diagramas del Sistema

### 4.1 Diagrama de Casos de Uso

Este diagrama muestra las interacciones de los tres actores principales (Vecino Informante, Referente Barrial y Administrador Vecinal) con los casos de uso del sistema: Reportar Incidente (voz/formulario/botón rápido), Visualizar Mapa de Incidencias, Verificar Incidente en Campo, Gestionar Estado de Resolución, Administrar Usuarios y Calibrar Motor de Priorización.

### 

### 4.2 Diagrama de Secuencia

Este diagrama ilustra el flujo temporal de mensajes entre la aplicación cliente, el backend, el módulo NLP y los servicios de notificaciones push, desde que el vecino emite un reporte hasta que el referente barrial recibe la alerta push clasificada.

### 

### 4.3 Diagrama de Flujo

Este diagrama representa el flujo de procesamiento interno de un reporte, detallando los puntos de decisión: detección de riesgo vital (derivación a servicios oficiales), clasificación de prioridad y distribución de alertas a referentes barriales cercanos.

![][image2]

---

## 5\. Gestión de Trazabilidad

### 5.1 Metodología y Aplicación del Checklist de Pressman

Para garantizar la calidad y consistencia del proyecto, se implementa una Matriz de Trazabilidad de Requisitos (RTM) que vincula cada requisito con su origen, prioridad, estado y criterio de validación.

En conformidad con la Lista de Verificación para Validar Requerimientos propuesta por Pressman (Capítulo 5, *Ingeniería de Software: Un Enfoque Práctico*, 7ma ed.), se evaluaron las siguientes preguntas sobre un conjunto representativo de requisitos, seleccionando uno por cada módulo principal del sistema. **Alcance de la revisión: la aplicación del checklist es parcial y no exhaustiva**: se seleccionó un requisito representativo por módulo (12 en total sobre los 28 requisitos del documento). Los requisitos no incluidos en la tabla fueron revisados internamente de manera informal, pero no cuentan con registro formal de la verificación.

**Preguntas aplicadas a nivel de requisito individual:**

| N° | Pregunta de Verificación (Pressman) |
| :---- | :---- |
| P1 | ¿Los requerimientos están enunciados con claridad? ¿Podrían interpretarse mal? |
| P2 | ¿Está identificada la fuente del requerimiento? ¿Se ha estudiado el planteamiento final en comparación con la fuente original? |
| P3 | ¿El requerimiento está acotado en términos cuantitativos? |
| P4 | ¿Qué otros requerimientos se relacionan con éste? ¿Están comparados con claridad mediante una matriz de referencia cruzada u otro mecanismo? |
| P5 | ¿El requerimiento viola alguna restricción del dominio? |
| P6 | ¿Puede someterse a prueba? ¿Es posible especificar criterios de validación para ensayarlo? |
| P7 | ¿Puede rastrearse hasta algún modelo del sistema que se haya creado? |
| P8 | ¿Es posible seguirlo hasta los objetivos del sistema o producto? |

**Preguntas aplicadas a nivel del documento como un todo:**

| N° | Pregunta de Verificación (Pressman) | Resultado |
| :---- | :---- | :---- |
| P9 | ¿La especificación está estructurada de forma que facilita su comprensión, con referencias y traducción fácil a productos de trabajo más técnicos? | Sí. El documento adopta IEEE 830, con numeración jerárquica, IDs unívocos por requisito y tabla de contenidos. |
| P10 | ¿Se ha creado un índice para la especificación? | Sí. La Tabla de Contenidos actúa como índice de navegación. Los IDs de requisitos permiten referencia cruzada directa. |
| P11 | ¿Están enunciadas con claridad las asociaciones de los requerimientos con las características de rendimiento, comportamiento y operación? ¿Cuáles requerimientos parecen ser implícitos? | Sí. Las secciones 3.3.1 a 3.3.7 documentan explícitamente rendimiento, usabilidad, disponibilidad y seguridad. No se detectaron requisitos implícitos sin documentar en la revisión interna. |

**Resultados de la evaluación por requisito representativo:**

| Requisito | P1 Claridad | P2 Fuente | P3 Cuantificado | P4 Relaciones | P5 Dom. | P6 Prueba | P7 Modelo | P8 Objetivo | Resultado | Observaciones |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **RF-REP-01** Botón de reporte rápido | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Relacionado con RNF-REN-01 (tiempo ≤ 3 seg). Trazable a objetivo de reporte ágil. |
| **RF-REP-02** Reporte por voz | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Depende de servicio externo Speech-to-Text; documentado en sección 2.5. |
| **RF-PRO-03** Flujo de procesamiento | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado con obs. | No cuantificado individualmente; sus etapas quedan acotadas por RNF-REN-01 y RNF-REN-02. |
| **RF-PRI-02** Clasificación de prioridad | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Relacionado con RF-PRI-01 y RF-PRI-03. Ejemplos del dominio urbano explicitados. |
| **RF-PRI-05** Detección de riesgo vital | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Comportamiento ante detección definido explícitamente. No viola restricciones del dominio; las refuerza. |
| **RF-ROL-03** Control de acceso | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Respuesta ante acceso no autorizado cuantificada (HTTP 403). |
| **RF-MOD-01** Sistema de reputación | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado con obs. | El umbral de bloqueo no está cuantificado; queda delegado a RF-PRI-04 (calibración por administrador). |
| **RF-ADM-02** Gestión de estados | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Estados del ciclo de vida enumerados. Relacionado con RF-ADM-01 (mapa de incidencias). |
| **RNF-REN-01** Tiempo de registro | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Valor cuantitativo (≤ 5 seg). Verificable con herramientas de profiling. |
| **RNF-PRE-01** Precisión GPS | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Valor cuantitativo (± 10 metros). Condicionado a hardware del dispositivo (documentado en 2.5). |
| **RNF-DIS-01** Disponibilidad | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Valor cuantitativo (≥ 99% mensual \= máx. 7,2 hs de caída). |
| **RNF-SEG-02** Encriptación de datos | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Aprobado | Verificable mediante auditoría directa de base de datos. |

**Síntesis:** Dos requisitos presentaron observación en P3 (acotamiento cuantitativo): RF-PRO-03 y RF-MOD-01. En ambos casos la observación fue resuelta: RF-PRO-03 queda acotado indirectamente por los RNF de rendimiento; RF-MOD-01 delega el umbral numérico de bloqueo a la calibración del administrador (RF-PRI-04), lo cual es una decisión de diseño justificada para adaptarse a distintos contextos comunitarios. No se detectaron requisitos que violen restricciones del dominio ni requisitos sin fuente identificable. Como resultado de la revisión, los siguientes requisitos fueron reformulados: RF-REP-01 (se precisó el concepto de área de cobertura y se tipificó la salida como Reporte Preliminar), RF-REP-02 (tipificada su salida como Reporte Abreviado), RF-REP-03 (tipificada su salida como Reporte Completo), RF-PRO-01 (se explicitó la convergencia de los tres tipos de reporte en la estructura común de datos), y RF-ROL-02 (se detallan los privilegios, responsabilidades e interlocutores del rol de Referente Barrial).

### 5.2 Análisis de Consistencia

Se realizó una sesión de revisión interna para detectar requisitos huérfanos (sin origen claro) y contradicciones.

**Resultados:** Se unificó el tiempo de procesamiento del incidente en 4 segundos (RNF-REN-02), resolviendo la inconsistencia entre versiones previas del documento. Se reemplazaron todas las referencias a "incendio" como ejemplo de alta prioridad por ejemplos pertenecientes al dominio urbano no crítico (cables pelados, postes caídos). Se eliminaron referencias a "botón de pánico" en favor de "botón de reporte rápido". Se renombró el rol "Voluntario Verificado" a "Referente Barrial" en todos los requisitos.

### 5.3 Matriz de Trazabilidad de Requisitos (RTM)

| ID Req. | Tipo | Origen / Necesidad | Descripción | Prioridad | Estado | Criterio de Validación |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **RF-REP-01** | Funcional | Necesidad de reporte ágil sin interrumpir actividad | El sistema debe permitir emitir un reporte mediante botón de acceso rápido con captura automática de GPS. | Alta | Definido | Prueba funcional: pulsación del botón genera evento con userID, timestamp y coordenadas en ≤ 5 segundos. |
| **RF-REP-02** | Funcional | Accesibilidad para usuarios en movimiento o con manos ocupadas | El sistema debe permitir emitir reportes mediante comandos de voz con transcripción automática. | Alta | Definido | Prueba con audio de referencia: texto generado coincide en ≥ 80% con el audio original. |
| **RF-REP-03** | Funcional | Necesidad de reportes con mayor detalle y evidencia fotográfica | El sistema debe permitir emitir reportes mediante formulario con categoría y foto. | Media | Definido | Prueba funcional: reporte con texto, categoría y foto almacenado correctamente en la base de datos. |
| **RF-PRO-03** | Funcional | Garantía de procesamiento completo y sin errores | El flujo de procesamiento completo (captura → clasificación) debe ejecutarse sin interrupciones. | Alta | Definido | Prueba de integración: el evento pasa por las 7 etapas sin errores de interrupción. |
| **RF-PRI-02** | Funcional | Priorización automática para reducir carga del administrador | El algoritmo debe clasificar incidentes urbanos por nivel de urgencia relativa. | Alta | Definido | Simulación de 10 casos de prueba: el sistema clasifica correctamente según diccionario configurado (ej. "cable pelado" → Urgente, "basura acumulada" → Media). |
| **RF-PRI-04** | Funcional | Adaptabilidad del sistema a distintos contextos barriales | El administrador debe poder calibrar los parámetros del motor de priorización. | Alta | Definido | Prueba de configuración: cambio en pesos del diccionario se refleja en clasificaciones subsiguientes. |
| **RF-PRI-05** | Funcional | Restricción legal y operativa sobre el alcance del sistema | El sistema no debe procesar incidentes de riesgo vital como reportes comunitarios. | Alta | Definido | Prueba con textos de riesgo vital: el sistema no genera alerta comunitaria y muestra botones de servicios oficiales. |
| **RF-ROL-01** | Funcional | Garantía de que solo vecinos del área accedan al sistema | El registro de vecinos debe requerir acreditación de domicilio. | Alta | Definido | Prueba: intento de registro sin código de invitación ni comprobante es rechazado. |
| **RF-ROL-03** | Funcional | Seguridad y separación de privilegios entre roles | El acceso a funcionalidades debe estar restringido por rol. | Alta | Definido | Prueba: acceso al panel de administrador con cuenta de vecino retorna error 403\. |
| **RF-MOD-01** | Funcional | Reducción de reportes falsos y abuso del sistema | El sistema debe mantener un puntaje de reputación por usuario. | Alta | Definido | Prueba: marcar 3 reportes de un usuario como falsos decrementa su puntaje y activa advertencia en panel. |
| **RF-MOD-02** | Funcional | Validación de que los reportes provienen del área de cobertura | El sistema debe bloquear reportes emitidos fuera del área de cobertura. | Alta | Definido | Prueba: intento de reporte desde 500 metros fuera del área configurada es bloqueado con mensaje informativo. |
| **RF-ADM-02** | Funcional | Transparencia y rendición de cuentas hacia la comunidad | El administrador debe poder actualizar el estado de resolución del incidente. | Alta | Definido | Prueba: cambio de estado de "Recibido" a "Solucionado" es visible para todos los usuarios en el mapa. |
| **RNF-REN-01** | No Funcional | Experiencia de usuario fluida al reportar | El tiempo de registro de un reporte debe ser ≤ 3 segundos. | Alta | Definido | Prueba de rendimiento con herramientas de profiling: tiempo medido entre interacción y registro en BD. |
| **RNF-PRE-01** | No Funcional | Precisión de geolocalización para coordinar respuesta territorial | La geolocalización debe tener un margen de error ≤ 10 metros. | Alta | Definido | Comparación de coordenadas obtenidas con punto geodésico conocido. |
| **RNF-DIS-01** | No Funcional | Confiabilidad operativa del sistema | La disponibilidad mensual debe ser ≥ 99%. | Alta | Definido | Monitoreo de uptime durante 30 días: caída máxima de 7,2 horas. |
| **RNF-USA-01** | No Funcional | Accesibilidad para usuarios con perfil técnico básico | El reporte debe completarse en ≤ 2 interacciones. | Alta | Definido | Test de usuario con 5 personas externas: el 100% logra emitir el reporte en ≤ 2 interacciones. |
| **RNF-SEG-02** | No Funcional | Protección de datos personales de los usuarios | Los datos personales deben almacenarse encriptados. | Media | Definido | Auditoría de base de datos: verificación de encriptación de campos sensibles. |

---

## 6\. Criterios de Validación y Pruebas

Los criterios de validación se organizan por módulo, siguiendo el formato: identificador, requisito asociado, método de validación (test) y criterio de éxito.

### 6.1 Validación de Requisitos Funcionales — Módulo de Incidentes

| ID Test | Req. Asociado | Método de Validación | Criterio de Éxito |
| :---- | :---- | :---- | :---- |
| **T-REP-01** | RF-REP-01 | Simulación de pulsación del botón de reporte rápido en dispositivo físico con GPS activo. | El sistema crea un registro en la BD con userID, timestamp y coordenadas en ≤ 5 segundos. |
| **T-REP-02** | RF-REP-02 | Ingreso de audio pregrabado: *"Hay un cable pelado en la vereda de Rivadavia al 500"*. | El sistema genera texto que coincide en ≥ 80% con el audio original. |
| **T-PRO-01** | RF-PRO-03 | Ejecución de un reporte completo desde la entrada hasta la alerta generada. | El evento pasa por las 7 etapas del flujo de procesamiento sin errores de interrupción. |
| **T-PRI-01** | RF-PRI-02 | Inyección de 10 casos de prueba con palabras clave del dominio urbano (ej. "cable pelado", "poste caído", "luminaria rota", "bache", "basura acumulada"). | El sistema asigna "Urgente" a riesgos de alta peligrosidad y "Baja" a molestias menores según el diccionario configurado. |
| **T-PRI-02** | RF-PRI-05 | Ingreso de texto con términos de riesgo vital: *"Me estoy infartando"* y *"Hay un tiroteo en la calle"*. | El sistema NO genera alerta comunitaria y muestra en pantalla los botones de contacto con 911/107, y si el USUARIO lo habilita se podría llamar automáticamente al 911/107 a través de la voz. |

### 6.2 Validación de Gestión de Roles y Moderación

| ID Test | Req. Asociado | Método de Validación | Criterio de Éxito |
| :---- | :---- | :---- | :---- |
| **T-ROL-01** | RF-ROL-03 | Intento de acceso al Panel de Administrador con una cuenta de Vecino Informante. | El sistema retorna error 403 y deniega el acceso. |
| **T-MOD-01** | RF-MOD-01 | Marcar 3 reportes de un usuario como "Falsos" desde el panel de administrador. | El puntaje de reputación del usuario baja automáticamente y se muestra la advertencia en el panel. |
| **T-MOD-02** | RF-MOD-02 | Intento de emitir un reporte desde una ubicación GPS a 500 metros del área de cobertura configurada. | El sistema bloquea el reporte con mensaje: "Fuera del rango de cobertura". |
| **T-ADM-01** | RF-ADM-02 | Actualización del estado de un incidente de "Recibido" a "Solucionado" desde el panel de administrador. | El cambio de estado es visible para todos los usuarios en el mapa de incidencias en tiempo real. |

### 6.3 Validación de Requisitos No Funcionales

| ID Test | RNF Asociado | Método de Validación | Criterio de Éxito |
| :---- | :---- | :---- | :---- |
| **T-REN-01** | RNF-REN-01 | Medición con herramientas de profiling (ej. Chrome DevTools, Firebase Performance) del tiempo entre interacción del usuario y registro en BD. | Tiempo medido ≤ 10 segundos en al menos el 95% de los casos de prueba. |
| **T-REN-02** | RNF-REN-02 | Medición del tiempo total de procesamiento (normalización \+ NLP \+ clasificación). | Tiempo medido ≤ 20 segundos en al menos el 95% de los casos de prueba. |
| **T-DIS-01** | RNF-DIS-01 | Monitoreo de uptime del sistema durante 30 días consecutivos. | El servicio está operativo ≥ 99% del tiempo (máximo 7,2 horas de caída mensual). |
| **T-DIS-02** | RNF-DIS-02 | Prueba de carga con 100 reportes simultáneos simulados. | El tiempo de respuesta no supera en más del 30% los valores nominales definidos en RNF-REN-01 y RNF-REN-02. |
| **T-USA-01** | RNF-USA-01 | Test de usuario con 5 personas externas sin experiencia previa con la aplicación. | El 100% de los participantes logra emitir un reporte completo con ≤ 2 interacciones. |
| **T-PRE-01** | RNF-PRE-01 | Comparación de coordenadas obtenidas por la aplicación con un punto geodésico conocido en distintas condiciones (interior de edificio, calle abierta). | El margen de error medido es ≤ 10 metros en condiciones de calle abierta. |
| **T-SEG-01** | RNF-SEG-02 | Auditoría directa de la base de datos para verificar el estado de los campos que contienen datos personales. | Los campos de datos personales (nombre, dirección, teléfono) se almacenan encriptados. |

---

*Fin del documento — Versión 1.1*  


[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>
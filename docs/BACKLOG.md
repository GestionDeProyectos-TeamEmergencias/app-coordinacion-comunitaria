# Backlog — App de Coordinación Comunitaria

**Proyecto Jira:** [KAN — comunidad-team-nb4pgq0v.atlassian.net](https://comunidad-team-nb4pgq0v.atlassian.net)
**Última sincronización:** 2026-05-17

---

## Leyenda

| Símbolo | Estado |
|---|---|
| ✅ | Finalizado |
| 🔄 | En curso |
| ⬜ | Por hacer |

---

## Resumen por Estado

| Estado | Cantidad |
|---|---|
| ✅ Finalizado | 13 |
| 🔄 En curso | 3 |
| ⬜ Por hacer | 40 |
| **Total** | **56** |

---

## Épica 1 — Infraestructura y Base del Proyecto (KAN-28)

| Clave | Tarea | Estado | Responsable | Prioridad |
|---|---|---|---|---|
| KAN-33 | [T-INF-01] Configuración del repositorio Git | ✅ Finalizado | Eric Doyle | Highest |
| KAN-35 | [T-INF-02] Configuración del proyecto Firebase | ✅ Finalizado | Elias Uribe | Highest |
| KAN-36 | [T-INF-03] Setup del entorno de desarrollo Flutter | ✅ Finalizado | Elias Uribe | High |
| KAN-37 | [T-INF-04] Definición del contrato de interfaz "Evento de Incidente" | 🔄 En curso | Elias Uribe | Medium |
| KAN-40 | [T-RNF-01] Configuración de reglas de seguridad Firestore | 🔄 En curso | Eric Doyle | Medium |
| KAN-39 | [T-INF-06] Actualización de documentación técnica | 🔄 En curso | Eric Doyle | Low |
| KAN-38 | [T-INF-05] Integración final y smoke test end-to-end | ⬜ Por hacer | Eric Doyle | Medium |

---

## Épica 2 — Gestión de Usuarios y Seguridad (KAN-29)

| Clave | Tarea | Estado | Responsable | Prioridad |
|---|---|---|---|---|
| KAN-42 | [T-AUTH-01] Registro de vecinos informantes | ⬜ Por hacer | tmiquelez | Medium |
| KAN-43 | [T-AUTH-02] Login y autenticación Firebase Auth | ⬜ Por hacer | Jeremías Aguirres | Medium |
| KAN-44 | [T-AUTH-03] Control de acceso por roles | ⬜ Por hacer | tmiquelez | Medium |
| KAN-45 | [T-AUTH-04] Promoción de referente barrial | ⬜ Por hacer | Jeremías Aguirres | Medium |
| KAN-46 | [T-AUTH-05] Sistema de reputación por usuario | ⬜ Por hacer | tmiquelez | Medium |
| KAN-48 | [T-AUTH-06] Validación geográfica de reportes | ⬜ Por hacer | Jeremías Aguirres | Medium |
| KAN-49 | [T-AUTH-07] Gestión de reportes falsos y bloqueos | ⬜ Por hacer | tmiquelez | Medium |
| KAN-50 | [T-AUTH-08] Panel de administración — gestión de usuarios | ⬜ Por hacer | Jeremías Aguirres | Medium |
| KAN-51 | [T-AUTH-09] Verificación de identidad del vecino (configurable) | ⬜ Por hacer | tmiquelez | Medium |

---

## Épica 3 — Interfaz de Usuario y Reportes (KAN-30)

| Clave | Tarea | Estado | Responsable | Prioridad |
|---|---|---|---|---|
| KAN-68 | [T-REP-01] UI principal y navegación | ⬜ Por hacer | Elias Uribe | Medium |
| KAN-41 | [T-REP-02] Botón de reporte rápido con captura GPS | ⬜ Por hacer | Joaquín Hubner | Medium |
| KAN-47 | [T-REP-03] Formulario de reporte detallado con foto | ⬜ Por hacer | Elias Uribe | Medium |
| KAN-52 | [T-REP-04] Reporte por voz con Speech-to-Text on-device | ⬜ Por hacer | Joaquín Hubner | Medium |
| KAN-57 | [T-REP-05] Mapa de incidencias geolocalizado | ⬜ Por hacer | Elias Uribe | Medium |
| KAN-60 | [T-REP-06] Visualización del estado de resolución | ⬜ Por hacer | Joaquín Hubner | Medium |

---

## Épica 4 — Inteligencia Artificial y Lógica Backend (KAN-32)

| Clave | Tarea | Estado | Responsable | Prioridad |
|---|---|---|---|---|
| KAN-54 | [T-NLP-01] Configuración de Firebase Genkit y Gemini | ⬜ Por hacer | Eric Doyle | Medium |
| KAN-55 | [T-NLP-02] Cloud Function: normalización y enriquecimiento del evento | ⬜ Por hacer | Lucas Lovizzio | Medium |
| KAN-56 | [T-NLP-03] Genkit Flow: extracción semántica de categoría e intención | ⬜ Por hacer | Eric Doyle | Medium |
| KAN-58 | [T-NLP-04] Genkit Flow: clasificación de prioridad y score | ⬜ Por hacer | Lucas Lovizzio | Medium |
| KAN-59 | [T-NLP-05] Cloud Function: detección de riesgo vital | ⬜ Por hacer | Eric Doyle | Medium |
| KAN-64 | [T-NLP-06] Cloud Function: calibración del algoritmo | ⬜ Por hacer | Lucas Lovizzio | Medium |
| KAN-65 | [T-NLP-07] Sistema de alertas push FCM/APNs | ⬜ Por hacer | Eric Doyle | Medium |
| KAN-66 | [T-NLP-08] Persistencia y auditoría en Firestore | ⬜ Por hacer | Lucas Lovizzio | Medium |
| KAN-67 | [T-NLP-09] Notificaciones masivas del administrador | ⬜ Por hacer | Eric Doyle | Medium |

---

## Épica 5 — Testing, Documentación y Cierre (KAN-31)

| Clave | Tarea | Estado | Responsable | Prioridad |
|---|---|---|---|---|
| KAN-69 | [T-TEST-01] Setup de la planilla de suite de pruebas | ⬜ Por hacer | Elias Uribe | Medium |
| KAN-61 | [T-TEST-02] Ejecución de pruebas — Módulo Auth y Roles | ⬜ Por hacer | Jeremías Aguirres | Medium |
| KAN-62 | [T-TEST-03] Ejecución de pruebas — Módulo Reporte e Interfaz | ⬜ Por hacer | Joaquín Hubner | Medium |
| KAN-34 | [T-TEST-04] Ejecución de pruebas — Motor NLP y Notificaciones | ⬜ Por hacer | Eric Doyle | Medium |
| KAN-71 | [T-TEST-05] Ejecución de pruebas de RNF | ⬜ Por hacer | Elias Uribe | Medium |
| KAN-72 | [T-TEST-06] Ejecución final de la suite completa — registro OK | ⬜ Por hacer | Eric Doyle | Medium |

---

## Iteración 1 — Entregables Completados (Archivo)

> Estas tareas pertenecen a las iteraciones de planificación previas al desarrollo. Están cerradas.

### Análisis de Viabilidad (KAN-16)

| Clave | Tarea | Responsable |
|---|---|---|
| KAN-1 | Tarea 1.1: Redactar Definición del Problema | Eric Doyle |
| KAN-2 | Tarea 1.2: Definir el Alcance del Producto | Elias Uribe |
| KAN-3 | Tarea 1.3: Realizar Análisis de Mercado y Competidores | Joaquín Hubner |
| KAN-4 | Tarea 1.4: Elaborar Análisis de Riesgos | Agustín Campagna |
| KAN-5 | Tarea 1.5: Recopilar Evidencias y Fundamentación | Lucas Lovizzio |
| KAN-6 | Tarea 1.6: Redactar Conclusión de Viabilidad | tmiquelez |
| KAN-7 | Tarea 1.7: Edición Final y Armado del Documento | Jeremías Aguirres |
| KAN-19 | Tarea 1.7.1: Reescribir Informe de Viabilidad (nuevo enfoque) | Elias Uribe |

### Especificación de Requisitos — ERS (KAN-17)

| Clave | Tarea | Responsable |
|---|---|---|
| KAN-8 | Tarea 2.1: Redactar requerimientos de la emergencia | Lucas Lovizzio |
| KAN-9 | Tarea 2.2: Redactar requerimientos de gestión y roles | Elias Uribe |
| KAN-11 | Tarea 2.3: Redactar apartado de cuantificación y rendimiento (Métricas) | Joaquín Hubner |
| KAN-12 | Tarea 2.4: Redactar apartado de trazabilidad y matriz de referencia | Agustín Campagna |
| KAN-13 | Tarea 2.5: Modelado y restricciones de dominio | Jeremías Aguirres |
| KAN-14 | Tarea 2.6: Criterios de validación y pruebas | tmiquelez |
| KAN-15 | Tarea 2.7: Armar la estructura del doc y organizar entrega | Eric Doyle |
| KAN-18 | Tarea 2.1.1: Reescribir requerimientos (nuevo enfoque) | Lucas Lovizzio |

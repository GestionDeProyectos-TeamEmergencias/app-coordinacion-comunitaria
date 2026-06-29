# Auditoría de Trazabilidad — Promesas vs. Implementación

> **Origen:** ampliación de F-02 pedida para validar que lo prometido (SRS v1.1 + Informe de Viabilidad V2) está efectivamente implementado en el código actual, detectar gaps y evaluar la coherencia del producto.
> **Fecha:** 2026-06-27 (act. 2026-06-29: cierre de G-1 push web) · **Alcance:** estado del repo a la fecha (post F-01…F-07 y cierre de deudas D-01…D-10).
> **Método:** verificación **basada en evidencia** — cada veredicto se respaldó leyendo el archivo/símbolo real, no resúmenes. Las rutas citadas son verificables.

## Leyenda de estado

| Símbolo | Significado |
|---|---|
| ✅ | Implementado y verificado en código |
| ⚠️ | Parcial / con salvedad documentada |
| ❌ | Ausente |
| ➖ | Fuera de alcance (no exigible) / no verificable estáticamente |

---

## 1. Veredicto ejecutivo

El producto **cumple lo prometido** en sus cuatro pilares de valor, todos operativos end-to-end en el código:

1. **Ciencia ciudadana (vecino ve el barrio):** ✅ reglas de `incidents` permiten lectura a todo usuario activo (`firestore.rules:170`).
2. **Alertas focalizadas (referente recibe push):** ✅ registro de token FCM en cliente + envío por cercanía en backend, **web incluido** (VAPID key baked + service worker).
3. **Moderación anti-reportes-falsos:** ✅ marcar `falso` decrementa reputación y bloquea al umbral (`reputationManager.ts:35`).
4. **Trazabilidad / rendición de cuentas:** ✅ historial de estados, acciones del admin, evidencia de cierre y auditoría persistida.

**Las 10 deudas críticas/altas de la DEVOLUCIÓN (D-01…D-10) están cerradas.** Los gaps remanentes son menores y no comprometen la propuesta de valor (ver §4). La devolución describía el estado *previo*; esta auditoría confirma el estado *actual*.

---

## 2. Matriz de Requisitos Funcionales (SRS §3)

### Reporte (REP)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-REP-01 | Reporte rápido (GPS + timestamp) en área de cobertura | ✅ in | ✅ | `SubmitQuickReportUseCase`; `SourceType.quick` (`incident_event.dart:8`) |
| RF-REP-02 | Reporte por voz (Speech-to-Text) manos libres | ➖ out | ✅ | `submit_voice_report_usecase.dart:22` persiste `SourceType.voice` (cierra D-10) |
| RF-REP-03 | Formulario detallado (descripción + categoría + foto) | ✅ in | ✅ | `report_form_page.dart`; `SubmitFormReportUseCase` |

### Procesamiento (PRO)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-PRO-01 | Normalización a estructura común | ✅ in | ✅ | `functions/src/incidentNormalization.ts` |
| RF-PRO-02 | Enriquecimiento (reputación, duplicados, tipo) | ✅ in | ✅ | `incidentEnrichment.ts`, `incidentDuplicates.ts` |
| RF-PRO-03 | Flujo secuencial completo | ✅ in | ✅ | orquestación en `functions/src/index.ts` |

### Priorización (PRI)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-PRI-01 | Extracción de palabras clave (NLP) | ✅ in | ✅ | `semanticExtraction.ts` (Genkit/Gemini) |
| RF-PRI-02 | Clasificación {Urgente, Alta, Media, Baja} | ✅ in | ✅ | `priorityCalculation.ts`; `IncidentPriority` (`incident_event.dart:170`) |
| RF-PRI-03 | Score numérico ponderado | ✅ in | ✅ | `priorityCalculation.ts` (categoría + términos + duplicados + reputación) |
| RF-PRI-04 | Calibración por admin sin redeploy | ➖ out | ✅ | `algorithmConfig.ts` + `algorithm_config_page.dart` |
| RF-PRI-05 | Detección de riesgo vital → 911/107 | ✅ in | ✅ | `vitalRiskDetection.ts`; `vital_risk_dialog.dart`; estado `vitalRiskDetected` (cierra D-03) |

### Salida (SAL)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-SAL-01 | Alerta estructurada a referentes cercanos | ✅ in | ✅ | `pushNotifications.ts` (`findNearbyReferentes` por Haversine) |
| RF-SAL-02 | Persistencia con auditoría completa | ✅ in | ✅ | `incidentPersistence.ts`; subcolección de auditoría |

### Roles (ROL)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-ROL-01 | Registro de vecino + acreditación de domicilio | ✅ in | ✅ | `register_usecase.dart`; `identity_proof_uploader.dart` |
| RF-ROL-02 | Promoción y acción de Referente Barrial | ➖ out | ✅ | `promote_to_referent_usecase.dart`; verificación con foto (`ReferentVerification`, cierra D-05) |
| RF-ROL-03 | Control de acceso por roles (bloqueo no autorizado) | ✅ in | ✅ | `firestore.rules` (`isAdmin`/`isReferente`/`isActive`); `router_rbac_test.dart` |

### Administración (ADM)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-ADM-01 | Mapa centralizado filtrable | ✅ in | ✅ | `admin_dashboard_page.dart`; `map_page.dart` |
| RF-ADM-02 | Ciclo de vida del incidente | ✅ in | ✅ | `IncidentStatus.allowedTransitions` (`incident_event.dart:129`) espejado en `firestore.rules:90` (cierra D-07) |
| RF-ADM-03 | (Re)asignar categoría + registrar acciones | ➖ out | ✅ | `ResolutionAction`, `categoryChangedBy/At` (`incident_event.dart:313`, cierra D-06) |
| RF-ADM-04 | Notificaciones push masivas (global/zona) | ➖ out | ✅ | `adminBroadcast.ts`; `admin_broadcast_page.dart` |

### Moderación (MOD)

| RF | Descripción | MVP | Estado | Evidencia |
|---|---|---|---|---|
| RF-MOD-01 | Reputación por usuario (sube/baja) | ➖ out | ✅ | `reputationManager.ts`: +5 al validar, **−15** al `moderatedAsFalse` (cierra D-08) |
| RF-MOD-02 | Validación geográfica (bloquear fuera de cobertura) | ✅ in | ✅ | `coverageValidation.ts` (círculo + polígono F-07) |
| RF-MOD-03 | Gestión de reportes falsos + bloqueo al umbral (3) | ✅ in | ✅ | `moderation.ts` (`moderateFalseReport`, auto-bloqueo) |

---

## 3. Verificación de cierre de deudas (DEVOLUCIÓN §11, D-01…D-10)

| Deuda | Severidad original | Estado actual | Evidencia de cierre |
|---|---|---|---|
| **D-01** Push e2e (token FCM nunca registrado) | 🔴 Crítico | ✅ Cerrada | `fcm_service.dart:99` persiste `fcmTokens` con `arrayUnion`; `referent_location_setup_page.dart` captura ubicación. **Web incluido:** `getToken` recibe la `vapidKey` (VAPID public key baked como default en `fcm_service.dart:23-30`, sobreescribible por `--dart-define`) + service worker `web/firebase-messaging-sw.js` |
| **D-02** Visibilidad del vecino bloqueada por reglas | 🔴 Crítico | ✅ Cerrada | `firestore.rules:170` `allow read: if isActive()`; sanitización de UID en UI |
| **D-03** Derivación 911/107 no cableada en cliente | 🔴 Alto | ✅ Cerrada | enum `vitalRiskDetected` con displayName de derivación (`incident_event.dart:76,113`); `vital_risk_dialog.dart` |
| **D-04** Disclaimer + TyC inexistentes | 🟡 Medio | ✅ Cerrada | `terms/` (`terms_page.dart`, `terms_provider.dart`, `terms_config.dart`) |
| **D-05** Acción del referente (verificación in situ) | 🟡 Medio | ✅ Cerrada | `ReferentVerification` con `photoUrl` obligatoria (`incident_event.dart:288`); `referent_verification_service.dart` |
| **D-06** RF-ADM-03 a medias (categoría/acciones) | 🟡 Medio | ✅ Cerrada | `ResolutionAction` + `categoryChangedBy/At`; allowlist en `firestore.rules:209` |
| **D-07** Máquina de estados sin validación | 🟢 Bajo | ✅ Cerrada | `allowedTransitions`/`canBeMarkedAsFalse` en cliente + `isValidStatusTransition` en reglas (`firestore.rules:90`) |
| **D-08** Reputación nunca decrementa (campo mismatch) | 🔴 Alto | ✅ Cerrada | `reputationManager.ts:35` lee `moderatedAsFalse` (antes `verifiedAsFalse`); comentario documenta el bug raíz |
| **D-09** Storage sin reglas (PII expuesta) | 🔴 Alto (seg.) | ✅ Cerrada | `storage.rules` existe; `identity_proofs/{userId}` lectura solo dueño+admin (`storage.rules:49`) |
| **D-10** Voz persistida como `sourceType: form` | 🟢 Bajo | ✅ Cerrada | `submit_voice_report_usecase.dart:22` usa `SourceType.voice` |

---

## 4. Gaps remanentes y recomendaciones (priorizado)

Los ítems de la nota de revisión (prioridades, derivación 911/107 y reputación) **se
corrigieron en esta iteración**, junto con **G-1**, **G-2** y **G-5** (ver §4.1). Solo queda
abierto **G-3** (tests e2e con emuladores); **G-4** está fuera de alcance académico. Ninguno
compromete la propuesta de valor para la defensa.

| # | Gap | Severidad | Estado | Recomendación |
|---|---|---|---|---|
| G-1 | **Push web roto**: `getToken` se llamaba sin `vapidKey` y faltaba el service worker → en web no se registraba token y el referente no recibía push en navegador | Media | ✅ Resuelto | (1) `FcmService` pasa la `vapidKey` a `getToken`, con la **VAPID public key baked como default** (`fcm_service.dart:23-30`; no es secreta, igual que `firebase_options.dart`); (2) service worker `web/firebase-messaging-sw.js` agregado (lo exige FCM web). Funciona en un build web normal **sin flags**; `--dart-define=FCM_VAPID_KEY=...` queda como override opcional si rota la key |
| G-2 | **La verificación del referente no se aprovechaba**: la confirmación in-situ no se reflejaba en el panel | Baja | ✅ Resuelto (como veracidad) | Indicador de **veracidad** (badges Avalado/En disputa/Descartado) derivado en vivo del historial. **Deliberadamente NO se cableó al `priorityScore`**: prioridad=urgencia y verificación=veracidad son ortogonales |
| G-3 | **Sin tests de integración e2e**: las suites son unitarias con mocks; no hay prueba end-to-end del pipeline completo | Media | ⚠️ Abierto | Test de integración con emuladores (Firestore + Functions) para el flujo reporte→alerta |
| G-4 | **Escala: sin geohashing**: `findNearbyReferentes` trae candidatos y filtra por distancia; correcto a escala barrial, costoso a gran escala | Baja | ➖ Fuera de alcance | Geohashing/consulta espacial si se proyecta crecimiento (fuera de alcance académico) |
| G-5 | **Limpieza proactiva de tokens FCM rotados**: el token viejo quedaba en el array hasta que el backend lo detectaba inválido | Baja | ✅ Resuelto | `cleanupInvalidTokens` (`adminBroadcast.ts`) hace `arrayRemove` de los tokens muertos tras cada envío (merge de develop) |

### 4.1 Resueltos en esta iteración (post-auditoría)

Los tres puntos de la nota de revisión se implementaron con **TDD** (suite de Cloud Functions
verde: 143 tests, `tsc` limpio):

- **Reputación** (`reputationManager.ts`): idempotencia separada por evento
  (`reputationRewarded` / `reputationPenalized`). Un reporte validado (+5) y **luego** moderado
  como falso ya recibe también el −15; antes el flag único lo bloqueaba.
- **Derivación 911/107** (`vitalRiskDetection.ts`): matching por **límite de palabra** (evita
  falsos positivos por substring), **lista de contexto no-emergencia** (`simulacro`, `evitar`,
  `en caso de`…; sin "no" genérico, para no romper `no respira`), **triage de categoría
  explícito** y **diccionario ampliado** para falsos negativos (`tiro`, `puñalada`, etc.).
- **Prioridades** (`algorithmConfig.ts`): calibración de defaults — `urgente` ahora es
  alcanzable por señal textual fuerte (multiplicador 10→13, umbral 80→72) y la reputación
  pondera en más casos (umbrales 30/80→45/70, ajuste 10→15).

Además se cerraron dos gaps de la tabla (frontend Flutter, TDD, suite verde: 186 tests, `analyze` limpio):

- **G-1 — Push web** (`fcm_service.dart` + `web/firebase-messaging-sw.js`): el push web requería
  **dos** piezas, ambas resueltas: (1) `FcmService` pasa la `vapidKey` a `getToken` con la
  **VAPID public key baked como default** (`fcm_service.dart:23-30`; el plugin la ignora en mobile;
  test que verifica que la key llega a `getToken`); (2) se agregó el **service worker**
  `firebase-messaging-sw.js` que FCM web exige para registrar el token (el plugin lo registra
  automáticamente). Funciona en un build web normal **sin flags**; `--dart-define=FCM_VAPID_KEY=...`
  queda como override opcional si rota la key.
- **G-2 — Sello de referente** (`referent_verification_aggregate.dart` + badge en
  `incident_moderation_page.dart`): indicador de **veracidad** derivado en vivo del historial
  (`aggregateReferentVerification`: dedup última postura por referente → `confirmed` /
  `dismissed` / `disputed` / `none`). Badge en la lista (Avalado / En disputa / Descartado;
  `none` sin badge). **No toca la prioridad** (ortogonalidad urgencia↔veracidad) y no guarda
  estado de resolución (informativo; el admin resuelve con sus acciones de moderación).

---

## 5. RNF y promesas del Informe

### RNF verificables estáticamente

| RNF | Promesa | Estado | Evidencia |
|---|---|---|---|
| RNF-USA-01 | ≤ 2 interacciones para reportar | ✅ | reporte rápido de 1 toque (`SubmitQuickReportUseCase`) |
| RNF-SEG-04 | No exponer PII de un vecino a otros | ✅ | `users/{uid}` legible solo por dueño+admin (`firestore.rules:133`); PII de comprobantes protegida (`storage.rules:49`) |
| RNF-SEG-01 | HTTPS móvil↔backend | ✅ | Firebase usa HTTPS/TLS por defecto |

### RNF NO verificables estáticamente (requieren medición/test de carga)

| RNF | Promesa | Estado | Recomendación |
|---|---|---|---|
| RNF-REN-01..04 | Tiempos ≤ 5–10 s (reporte, procesamiento, push) | ➖ | Medir con emulador/entorno real; instrumentar latencias del pipeline |
| RNF-DIS-01/02 | ≥ 99% disponibilidad; ≥ 100 reportes concurrentes | ➖ | Test de carga; apoyarse en SLAs de Firebase |
| RNF-PRE-02/03 | Precisión NLP ≥ 80%, falsos positivos ≤ 10% | ➖ | Suite de regresión con set etiquetado (RNF-CAL-02) |

### Promesas del Informe (alcance / ventajas competitivas)

| Promesa | Estado | Evidencia |
|---|---|---|
| Reporte híbrido (gráfico + voz/NLP) | ✅ | tres `SourceType` (quick/form/voice) |
| Alertas focalizadas (solo cercanos) | ✅ | `pushNotifications.ts` filtra por radio |
| Clasificación automática por urgencia | ✅ | `priorityCalculation.ts` + Gemini |
| Geolocalización en tiempo real | ✅ | `map_page.dart`; GPS en reporte |
| Auto-organización comunitaria | ✅ | roles + reacciones (F-04) + validación bilateral (F-05) |

---

## 6. Conclusión

El estado actual del código **respalda lo documentado** en SRS v1.1 e Informe de Viabilidad V2: todos los RF del MVP están implementados, las extensiones fuera del MVP también, y las 10 deudas de la última devolución están cerradas con evidencia. Los gaps que quedan (§4) son acotados, no bloquean la propuesta de valor y tienen recomendación. **El producto final es coherente y defendible.**

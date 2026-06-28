# Auditoría de Trazabilidad — Promesas vs. Implementación

> **Origen:** ampliación de F-02 pedida para validar que lo prometido (SRS v1.1 + Informe de Viabilidad V2) está efectivamente implementado en el código actual, detectar gaps y evaluar la coherencia del producto.
> **Fecha:** 2026-06-27 · **Alcance:** estado del repo a la fecha (post F-01…F-07 y cierre de deudas D-01…D-10).
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
2. **Alertas focalizadas (referente recibe push):** ✅ registro de token FCM en cliente + envío por cercanía en backend. ⚠️ con salvedad de push **web** (vapidKey).
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
| **D-01** Push e2e (token FCM nunca registrado) | 🔴 Crítico | ✅ Cerrada (⚠️ web) | `fcm_service.dart:62` persiste `fcmTokens` con `arrayUnion`; `referent_location_setup_page.dart` captura ubicación. **Salvedad:** en web `getToken` devuelve null sin `vapidKey` (`fcm_service.dart:54-58`) |
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

Ninguno compromete la propuesta de valor para la defensa; se proponen como **tickets nuevos** (no se corrigen en F-02).

| # | Gap | Severidad | Recomendación |
|---|---|---|---|
| G-1 | **Push web sin `vapidKey`**: `getToken` devuelve null en web, no se registra token → el referente no recibe push en navegador | Media | Configurar `vapidKey` en `firebase_options`/consola; si la demo es web, validar el flujo end-to-end o demostrar en mobile |
| G-2 | **`referentVerification` no pondera el score**: la verificación autoritativa del referente no realimenta `priorityCalculation` | Baja | Integrar la señal del referente como input del score (documentado como trabajo futuro) |
| G-3 | **Sin tests de integración e2e**: las suites son unitarias con mocks; no hay prueba end-to-end del pipeline completo | Media | Agregar test de integración con emuladores (Firestore + Functions) para el flujo reporte→alerta |
| G-4 | **Escala: sin geohashing**: `findNearbyReferentes` trae candidatos y filtra por distancia; correcto a escala barrial, costoso a gran escala | Baja | Geohashing/consulta espacial si se proyecta crecimiento (fuera de alcance académico) |
| G-5 | **Limpieza proactiva de tokens FCM rotados**: el token viejo queda en el array hasta que el backend lo detecta inválido | Baja | Aceptable; el backend ya limpia tokens muertos al enviar |
Arreglar/calibrar como se asignan prioridades, como se detecta si derivar al 911/100 sin dejar que el reporte se cree. Ademas de tener que probar que ande bien la funcion de reputacion
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

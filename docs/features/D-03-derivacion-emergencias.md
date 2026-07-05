# D-03 — Derivación a 911/107 + alinear enum de estados con backend

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.3)
> **Tickets relacionados:** RF-PRI-05, T-NLP-05 (`vitalRiskDetectionFlow`), Informe de Viabilidad §4 (principal riesgo del producto)
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Cierra el gap más sensible legalmente del MVP: cuando un vecino reporta una situación que dispara términos de **riesgo vital** (electrocutado, persona inconsciente, incendio, etc.), el sistema **no debe** procesarlo como incident comunitario — debe **derivar al 911/107**. El pipeline backend ya detectaba el riesgo y marcaba el doc con `status: vital_risk_detected` (`functions/src/index.ts:183`), pero:

1. **El cliente Flutter nunca se enteraba:** el envío era fire-and-forget, navegaba a Home con "Reporte enviado correctamente" antes de que el pipeline corriera.
2. **El enum `IncidentStatus` no conocía `vital_risk_detected` ni `rechazado_autor_inactivo`:** caían al default `recibido`, así que un incident crítico se mostraba al admin como "Recibido" sin ninguna alerta.
3. **Los strings de UI (`vitalRiskTitle`, `emergencyCall911`, `emergencyCall107`) y la excepción (`VitalRiskDetectedException`) estaban definidos pero nunca usados.**

D-03 cierra los tres frentes.

## 2. Justificación

RF-PRI-05 es un **"deberá"** del SRS. El Informe de Viabilidad §4 lo nombra como el **principal riesgo del producto** y declara explícitamente la derivación a 911/107 como mitigación. Tener el pipeline backend funcional sin nada visible al usuario es una falsa seguridad: la app cumple el RF en código pero **falla en producción**, lo que en caso de incidente real puede tener consecuencias legales y humanas. Deuda crítica del MVP, no extensión.

## 3. Decisión arquitectónica (callable síncrono vs. listener)

Se eligió **callable síncrono pre-envío** sobre dos alternativas:

| Approach | Pros | Contras | Veredicto |
| --- | --- | --- | --- |
| **A. Callable `checkVitalRiskCallable` pre-envío** (elegido) | Respuesta inmediata (~150ms). Backend = única fuente de verdad del diccionario. **No crea el incident** si hay riesgo (Firestore queda limpio). | Requiere una Cloud Function nueva. ~150ms de latencia adicional antes de crear un reporte con texto. | ✅ |
| B. Listener sobre el doc creado | Aprovecha el pipeline backend existente (sin Function nueva). | El incident sí se crea y queda con `vital_risk_detected` en Firestore (basura para el admin). UX con loading de 10-15s antes de saber si fue vital risk. Timeouts y race conditions a manejar. | ❌ |
| C. Solo aviso en detalle | Cero cambios en el flujo de envío. | UX inaceptable para emergencia: el usuario ve "enviado con éxito" y solo encuentra el aviso si abre el detalle del incident. | ❌ |

Razón principal de A sobre B: **un reporte de riesgo vital no debería ser un incident comunitario**. El usuario no quiere coordinar al barrio; quiere una ambulancia. Persistirlo contamina la cola del admin y manda señales contradictorias.

## 4. Defense-in-depth: el pipeline backend sigue activo

A pesar del check pre-envío, **se conservó el check defensivo del pipeline** (`functions/src/index.ts:168-198`). Esto cubre tres escenarios:

1. **Versión vieja del cliente** que no llama al callable.
2. **Race condition** donde el incident se crea entre la respuesta del callable y un cambio del diccionario (`config/algorithm`).
3. **Bug del cliente** que skipea el check.

En esos casos el doc queda con `status: vital_risk_detected`, **no se generan alertas comunitarias** (`return` corta el pipeline), y al abrir el detalle del incident el reportero ve un **banner persistente** con botones 911/107 (componente `_VitalRiskBanner` en `incident_detail_page.dart`). Es una mitigación adicional, no la primaria.

## 5. Decisiones secundarias

### 5.1 `checkVitalRiskCallable` solo requiere autenticación, no rol específico

Cualquier usuario autenticado puede invocar el callable. No exigimos `isActive` porque también un user `pending` puede tipear una descripción de riesgo vital mientras espera aprobación. Lo que vale es que el aviso 911/107 llegue cuanto antes; la validación de rol/status pasa cuando intenta persistir el incident (reglas Firestore).

### 5.2 Errores de red NO bloquean el envío

Si el callable falla por red (`unavailable`, `internal`), el servicio retorna `isVitalRisk: false` y deja pasar el envío. Razón: preferimos un falso negativo (el pipeline backend lo detectará y el detalle mostrará el banner) antes que bloquear reportes legítimos por un problema transitorio de red. Esto está documentado en el código (`vital_risk_check_service.dart`) y en el test.

Excepciones que **sí propagamos**: `unauthenticated` y `invalid-argument`. Son bugs del cliente, no condiciones de red.

### 5.3 El diálogo es no-dismissible

`PopScope(canPop: false)` + `barrierDismissible: false`: la única salida es tocar "Entendido, no envío el reporte". Razón: un toque accidental fuera del diálogo en un caso de emergencia es exactamente el tipo de UX que el SRS quiere evitar.

### 5.4 Reporte rápido no requiere check

`submitQuick` no tiene `description` (es solo botón + GPS). No hay texto que evaluar. El check se aplica solo a `submitForm` (y, transitivamente, al modo voz, que reutiliza el mismo `_submit()`).

### 5.5 El callable retorna también `matchedTerms`

Aunque no es estrictamente necesario para el diálogo, los términos coincidentes se muestran en el diálogo en pequeño. Es transparencia útil para el usuario ("¿por qué me derivás?") y evita la sensación de caja negra.

## 6. Archivos modificados / creados

### Backend
- `functions/src/index.ts` — nuevo `checkVitalRiskCallable`. Auth required, sin rol.

### Cliente — entidades y mapeo
- `lib/features/incidents/domain/entities/incident_event.dart` — enum `IncidentStatus` gana `vitalRiskDetected` y `rechazadoAutorInactivo`; `fromString`, `firestoreValue` y `displayName` actualizados.
- `lib/features/incidents/data/repositories/incidents_repository_impl.dart` — `watchActiveIncidents` excluye los dos nuevos estados del feed público.
- `lib/features/incidents/presentation/widgets/incident_status_badge.dart` — switch exhaustivo cubre los nuevos estados.

### Cliente — servicio y UI
- `lib/features/incidents/data/services/vital_risk_check_service.dart` — nuevo `VitalRiskCheckService` que invoca `checkVitalRiskCallable`.
- `lib/features/incidents/presentation/providers/vital_risk_provider.dart` — provider del servicio.
- `lib/features/incidents/presentation/widgets/vital_risk_dialog.dart` — diálogo no-dismissible con botones `tel:911` / `tel:107`.
- `lib/features/incidents/presentation/pages/report_form_page.dart` — invoca el check antes de pedir GPS / persistir.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — banner defensivo (`_VitalRiskBanner`) si un incident llega en `vital_risk_detected`.

### Tests
- `test/unit/incidents/incident_status_enum_test.dart` — 5 tests del enum (roundtrip + nuevos valores).
- `test/unit/incidents/vital_risk_check_service_test.dart` — 4 tests del servicio (positivo, negativo, error de red, error de auth).

### Otros
- `pubspec.yaml` — agrega `url_launcher: ^6.3.1` para deeplinks `tel:`.

## 7. Impacto

| Antes de D-03 | Después de D-03 |
| --- | --- |
| Reporte con "persona electrocutada" → "Reporte enviado correctamente", navega a Home, sin ningún aviso. | Reporte con "persona electrocutada" → diálogo de derivación a 911/107 antes de crear el incident. No se persiste nada en Firestore. |
| `vital_risk_detected` se mostraba como "Recibido" en el detalle (cae al default del enum). | Se reconoce y muestra correctamente. Si llega por ruta defensiva, banner persistente con 911/107. |
| `rechazado_autor_inactivo` (T-AUTH-07) también se mostraba como "Recibido". | Se reconoce y muestra "Rechazado (autor inactivo)". |
| `VitalRiskDetectedException` y strings de emergencia eran código muerto. | Strings consumidos por el diálogo y el banner. (La excepción quedó sin uso — se eliminará en cleanup futuro si nadie la levanta.) |

## 8. Limitaciones conocidas

- **El callable se invoca una vez por envío, sin caching.** Si el usuario edita la descripción y vuelve a tocar enviar, se llama de nuevo. Es ~150ms y barato; no optimizamos.
- **`launchUrl(tel:)` puede fallar en web.** El diálogo muestra el número grande para que el usuario lo marque manualmente como fallback.
- **El `VitalRiskCheckService` solo se usa desde `report_form_page`.** Cuando D-10 reescriba el flujo de voz para usar `SubmitVoiceReportUseCase`, hay que asegurarse de invocar el check ahí también (queda anotado en el doc de D-10).
- **Fallback de red abre la posibilidad de un falso negativo.** Si el cliente no puede consultar el callable y el incident se crea, el pipeline backend lo agarra y el reportero ve el banner al abrir el detalle. Aceptable por el principio de "no bloquear reportes legítimos por red".
- **El diálogo no logguea métricas de uso.** Una mejora futura sería trackear cuántos reportes se abortan por riesgo vital, para validar la calibración del diccionario (T-NLP-06).
- **No se cubre el escenario "el usuario igual quiere reportarlo".** Decisión explícita: si la app detecta vital risk, NO hay opción "envialo de todas formas". Si el equipo quiere agregar esa salida en el futuro, debería ir con confirmación explícita y métricas.

## 9. Comandos de verificación

```bash
# Backend
cd functions && npm test
# 99/99 passed (incluye los 4 tests existentes de vitalRiskDetectionFlow)

cd functions && npx tsc --noEmit
# limpio

# Cliente
flutter analyze --no-pub
# No issues found!

flutter test
# 102/102 passed (9 nuevos: 5 enum + 4 servicio)
```

### Pruebas manuales (recomendadas antes de mergear)

1. Crear un reporte por formulario con descripción "hay una persona electrocutada en el cable de luz". Esperado: diálogo 911/107, NO se crea el incident.
2. Tocar "Llamar al 911" → debe abrir el dialer del SO (en mobile) o intentar el deeplink (en web).
3. Cerrar el diálogo y verificar que NO se navegó a Home — el formulario sigue editable.
4. Crear un reporte con descripción "bache en la calle". Esperado: flujo normal sin diálogo.
5. (Defense-in-depth) Forzar manualmente un incident con `status: 'vital_risk_detected'` en Firestore. Abrir el detalle. Esperado: banner rojo con botones 911/107.

## 10. Próximos pasos relacionados

- **D-07** (integridad de la máquina de estados): definir transiciones válidas que respeten que `vital_risk_detected` es **terminal** (no se reabre).
- **D-10**: el reporte por voz debe pasar también por el check de vital risk (hoy ya lo hace transitivamente porque comparte `_submit()`, pero cuando D-10 invoque `SubmitVoiceReportUseCase` directamente, hay que reincorporarlo).
- **Calibración**: el dictionary `config/algorithm.vitalRiskTerms` (T-NLP-06) es la fuente que dispara D-03. Conviene revisarlo con casos reales durante la demo y ajustar antes de la entrega.
- **Métricas**: instrumentar cuántas veces se dispara el diálogo en producción para evaluar si la sensibilidad del diccionario es la correcta.

# F-05 — Validación bilateral al cerrar el reporte

> **Tipo:** `extra` (extensión nueva sobre RF-ADM-02 — cierre bilateral)
> **Tickets relacionados:** O5 (docente), RF-ADM-02 (cierre actual unilateral)
> **Fecha de implementación:** 2026-06-25
> **Estado:** completado

## 1. Qué es

Cuando el admin o referente cambia el estado de un incident a `solucionado`, el sistema **no** lo da por cerrado de manera unilateral. Setea un campo ortogonal `closureConfirmation: { state: pendiente, by, at }` y dispara un push al reportero. En el detalle, el reportero ve dos botones:

- **Confirmar**: `closureConfirmation.state → confirmado`. Status queda en `solucionado` (cierre real).
- **Disputar** (con nota obligatoria): `closureConfirmation.state → disputado` y status vuelve a `enReparacion`. La nota queda visible para el admin.

Si el reportero no responde en N días (default 7, configurable desde `AlgorithmConfig.closureConfirmation.autoConfirmAfterDays`), una Cloud Function programada lo confirma automáticamente.

## 2. Por qué se hizo

La observación **O5** del docente: hoy el cierre lo hace el admin sin que el reportero tenga voz, lo que erosiona la confianza del sistema. F-05 cierra el loop social: el sistema le pregunta al reportero "¿está realmente resuelto?". Si no responde, asume razonable que sí. Si dispute, el problema vuelve a estar abierto y el admin lo ve.

Es alcance **`extra`**: RF-ADM-02 define cierre unilateral. F-05 amplía con un sub-estado de confirmación.

## 3. Decisiones de diseño

### 3.1 Campo ortogonal, NO ampliar `IncidentStatus`

Decisión §5.2 de la devolución del plan, aplicada acá. El enum `status` mantiene los 4 valores operativos del SRS:

```
recibido → programado → enReparacion → solucionado
```

Y un nuevo campo paralelo `closureConfirmation: { state, by, at, note? }`. Razones:

- No contamina la documentación pública del enum.
- Migración trivial: incidents existentes sin el campo se tratan como **confirmados implícitos** — la UI los muestra como cerrados normales, sin badges adicionales.
- Permite que el grafo D-07 siga siendo declarativo en el caso general; F-05 introduce **una sola excepción** explícita (disputar = solucionado → enReparacion).

### 3.2 Regla Firestore nueva (no opcional)

Hasta F-05, la regla del dueño no permitía tocar nada con `status != recibido`. F-05 abre dos caminos específicos del dueño activo cuando el incident está en `solucionado` con `closureConfirmation.state == pendiente`:

- **Confirmar**: `affectedKeys().hasOnly(['closureConfirmation'])` + nuevo state == `'confirmado'`.
- **Disputar**: `affectedKeys().hasOnly(['closureConfirmation', 'status', 'statusHistory'])` + nuevo state == `'disputado'` + nuevo status == `'en_reparacion'` + nota no vacía.

La validación de la **nota obligatoria** vive en la regla, no solo en cliente. Eso garantiza el contrato incluso si un cliente desactualizado o un SDK directo intenta saltarlo.

Trade-off: la regla acepta tocar `statusHistory` junto al status. Es necesario porque el cliente agrega la entrada de auditoría al pasar a `en_reparacion` (consistente con T-REP-06).

### 3.3 Excepción al grafo D-07: disputar abre `solucionado → en_reparacion`

D-07 dejó `solucionado` como terminal en el grafo del admin. F-05 documenta **una sola excepción** consciente: el reportero que dispute vuelve el incident a `en_reparacion`. La excepción está en la regla del dueño, no en `isValidStatusTransition` — el admin sigue sin poder retroceder ese estado por dropdown. Esto preserva la propiedad "el admin no anula su propia decisión por error".

### 3.4 Push del reportero vía Cloud Function trigger

`notifyClosurePending` corre `onDocumentUpdated` y detecta cuando `closureConfirmation.state` pasa **a** `pendiente`. Manda push al uid del `userId` (reportero) usando los tokens FCM que D-01 dejó registrados. Si no hay tokens, loggea y sigue (no falla la operación).

Alternativa descartada: que el cliente del admin mande el push directo. Imposible — push requiere Admin SDK (privilegios). Y mover la lógica al trigger evita acoplar el cliente admin con el ID del reportero o sus tokens.

### 3.5 Auto-confirm con `onSchedule` (Cloud Scheduler)

`autoConfirmExpiredClosures` corre cada hora (configurable) en la zona horaria `America/Argentina/Buenos_Aires`. Busca incidents con `closureConfirmation.state == pendiente` Y `closureConfirmation.at <= cutoff` (cutoff = ahora − threshold días). Los pasa a `confirmado` con `by: 'auto'` para que la UI los distinga.

- El `where('closureConfirmation.state', '==', 'pendiente').where('closureConfirmation.at', '<=', cutoff)` requiere un **índice compuesto** Firestore — el deploy lo crea on-demand la primera vez con un link en logs, o se puede agregar a `firestore.indexes.json` previsoriamente.
- Límite de 500 docs por corrida para no exceder timeout / cuotas. Para volumen MVP es de sobra.

### 3.6 Threshold configurable desde `AlgorithmConfig`

Mismo patrón de F-04 y T-NLP-06: `closureConfirmation: { autoConfirmAfterDays }` en `AlgorithmConfig`. Default 7 días. El admin lo ajusta desde el panel de calibración sin redeploy. Útil porque distintos clientes (municipio chico vs. comuna grande) pueden tener tolerancias distintas.

### 3.7 La UI separa "acción pendiente" de "resumen pasivo"

`_ClosureConfirmationSection` (call-to-action interactiva) se muestra **solo al reportero cuando hay pendiente**.

`_ClosureConfirmationSummary` (pasivo, lectura) se muestra a **todos** cuando hay confirmado o disputado. El admin lo ve para entender el resultado; el resto del barrio lo ve como contexto.

Si `closureConfirmation` es null (incidents legacy), no se renderiza nada — la migración lazy del plan se respeta.

## 4. Impacto en el sistema

### Creados
- `functions/src/closureConfirmation.ts` — `notifyClosurePending` + `autoConfirmExpiredClosures` + lógica pura `isClosureExpired`.
- `functions/src/closureConfirmation.test.ts` — 6 tests del cálculo de expiry.
- `lib/features/incidents/presentation/providers/closure_confirmation_provider.dart` — `ClosureConfirmationNotifier` con `confirm` / `dispute`.
- `test/unit/incidents/closure_confirmation_test.dart` — 5 tests del datasource (auto-init en updateStatus, confirmOwn, disputeOwn, nota vacía).

### Modificados
- `functions/src/algorithmConfig.ts` — schema, defaults y merge de `closureConfirmation: { autoConfirmAfterDays }`.
- `functions/src/index.ts` — exports.
- `firestore.rules` — funciones helper `isOwnerConfirmingClosure` / `isOwnerDisputingClosure` + integración en `allow update` de incidents.
- `lib/features/incidents/domain/entities/incident_event.dart` — enum `ClosureConfirmationState`, clase `ClosureConfirmation`, campo en `IncidentEvent`.
- `lib/features/incidents/data/models/incident_event_model.dart` — (de)serialización + helpers.
- `lib/features/incidents/domain/repositories/incidents_repository.dart` — métodos `confirmOwnClosure`, `disputeOwnClosure`.
- `lib/features/incidents/data/datasources/incidents_remote_datasource.dart` — implementación; `updateStatus` extendido para inicializar `closureConfirmation` al pasar a `solucionado`.
- `lib/features/incidents/data/repositories/incidents_repository_impl.dart` — passthrough.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — widgets `_ClosureConfirmationSection`, `_ClosureConfirmationSummary`, `_DisputeDialog`.
- Tests existentes (`update_status_notifier_test.dart`, `edit_own_incident_notifier_test.dart`): stubs de los métodos nuevos del repo.

### No modificados (verificados pero ya correctos)
- D-07 (`isValidStatusTransition`): se preserva intacta. La excepción al grafo vive en la regla del dueño, no en la del admin.
- D-01 (FCM): el push reutiliza los tokens registrados. Sin cambios.

## 5. Limitaciones conocidas

- **No hay UI para reabrir disputas resueltas.** Si el reportero dispute y luego el admin no responde, no hay re-pregunta. Mejora futura: cuando el admin vuelve a marcar `solucionado` tras una disputa, F-05 dispara de nuevo el pendiente.
- **El auto-cierre no notifica al reportero.** Si el sistema le confirmó por timeout, no recibe push. Aceptable porque hubo 7 días de inacción; agregar pong si el cliente lo pide.
- **Sin throttling en disputas repetidas.** Un reportero podría disputar, el admin re-cerrar, y disputar de nuevo en loop. Es UX no malicia, pero si se vuelve un problema, agregar un contador `disputeCount` que el admin pueda ver y eventualmente ignorar.
- **Sin tests de reglas Firestore.** Mismo trade-off documentado desde D-02. Las dos helpers (`isOwnerConfirmingClosure`, `isOwnerDisputingClosure`) son los lugares más complejos del rule set y son buenos candidatos para los futuros tests de reglas en CI.
- **Índice de la scheduled function**: la primera corrida que filtra por `closureConfirmation.state` + `closureConfirmation.at` pide crear índice compuesto. Si el equipo lo quiere preparado, agregarlo a `firestore.indexes.json` antes del deploy.
- **`closureConfirmation.note` solo se persiste en disputa.** Si el reportero quiere agregar un comentario al confirmar ("anduvieron rápido, gracias"), la UI no lo permite. Mejora candidata para iteraciones futuras.

## 6. Comandos de verificación

```bash
# Backend
cd functions && npx tsc --noEmit
# limpio
cd functions && npm test
# 116/116 passed (incluye 6 nuevos del expiry)

# Cliente
flutter analyze --no-pub
# No issues found!
flutter test
# All tests passed! (159/159)
```

### Pruebas manuales con emulador

1. `firebase emulators:start --only firestore,functions,auth`.
2. Crear `vecino-1` (reportero), `admin-1`.
3. Crear `incidents/inc-1` con `userId: 'vecino-1'`, status inicial `recibido`.
4. Como `admin-1`, llamar `updateStatus('inc-1', 'solucionado', changedBy: 'admin-1')` → verificar que `closureConfirmation.state == pendiente` y que el push se intenta (sin FCM real, los logs lo muestran).
5. Como `vecino-1`, llamar `confirmOwnClosure` → verificar que `closureConfirmation.state == confirmado`. Status sigue en `solucionado`.
6. Crear `inc-2` y repetir steps 4 con admin.
7. Como `vecino-1`, llamar `disputeOwnClosure(note: 'sigue roto')` → verificar status == `en_reparacion`, `closureConfirmation.state == disputado`.
8. Forzar auto-cierre: setear `closureConfirmation.at` en el pasado, correr la scheduled function manualmente (`firebase emulators:exec`) → debería pasar a `confirmado` con `by: 'auto'`.

### Deploy obligatorio antes de demo

```bash
firebase deploy --only firestore:rules
firebase deploy --only functions:notifyClosurePending,functions:autoConfirmExpiredClosures
```

## 7. Próximos pasos relacionados

- **F-06 (evidencia de cierre)**: cuando se sube foto de resolución, debería disparar el mismo flujo F-05. Coordinar.
- **Métricas**: trackear qué porcentaje de cierres son confirmados, disputados o auto-cierre. Buen feedback para calibrar `autoConfirmAfterDays`.
- **Coordinación con D-08 (reputación)**: si un admin tiene tasa alta de disputas, su reputación operativa podría reflejarlo (futuro). Por ahora F-05 deja la data; no la consume.
- **Tests de reglas en CI**: F-05 es muy buen caso de prueba para introducirlos (los helpers `isOwnerConfirmingClosure`/`isOwnerDisputingClosure` son complejos y críticos).
- **Auto-cierre con notificación**: agregar push del trigger schedule al reportero cuando lo cierra por timeout. Una línea extra dentro del batch.

# F-04 — Reacciones de la comunidad con `confirmationScore`

> **Tipo:** `extra` (alcance nuevo — el SRS solo tenía reputación por usuario, no por reporte)
> **Tickets relacionados:** O4 (observación del docente), RF-MOD-01 (reputación de usuario, no de reporte)
> **Fecha de implementación:** 2026-06-25
> **Estado:** completado

## 1. Qué es

Los vecinos activos pueden marcar un reporte ajeno como **"Confirmo"** o **"No es así"**. La reacción se persiste en `incidents/{id}/reactions/{userId}` con `{type, by, at}`. Un trigger de Cloud Function (`aggregateReactionsOnWritten`) cuenta confirms/disputes y persiste en el doc del incident:

```json
{
  "confirmsCount": 5,
  "disputesCount": 1,
  "confirmationScore": 0.833,
  "communityValidated": true,
  "communityValidatedAt": "<server timestamp>"
}
```

Cuando el score supera el umbral configurable (default `0.7` con `>=3` reacciones), el incident se etiqueta con `communityValidated: true` y muestra un badge **"Validado por la comunidad"**.

## 2. Por qué se hizo

La observación **O4** del docente: el flujo de cierre del reporte es opaco, no hay reglas claras de qué hace que un reporte sea creíble, y no hay forma de que la reputación del reporte mejore con interacciones de otros vecinos. F-04 atacó la segunda parte: agregar señal social sobre veracidad.

Es alcance **`extra`**: el SRS solo modela reputación **por usuario** (RF-MOD-01); reputación **por reporte** es nueva. Da al motor NLP una entrada extra para calibrar prioridad y blinda mínimamente el sistema contra reportes falsos sin necesidad de moderación admin manual.

## 3. Decisiones de diseño

### 3.1 Jerarquía con D-05 (referente autoritativo vs. comunidad blanda)

La devolución (§5.4) advirtió que F-04 podía **diluir el rol del Referente Barrial** (RF-ROL-02b) si se le daba peso equivalente al voto de cualquier vecino. La regla de diseño explícita es:

- **Referente** = señal autoritativa. Verificación de campo con foto (D-05).
- **Vecinos** = señal social blanda. Útil para "esto le pasa a más gente" y triage.

Aplicación en UI: en `IncidentDetailPage`, el bloque de **verificación del referente** (D-05) se renderiza **arriba** del bloque de validación comunitaria. Si ambos existen, el usuario los lee en ese orden.

Aplicación en futuro motor NLP: cuando el `priorityCalculationFlow` use estos campos, el peso del `referentVerification.state` debe ser mayor que el de `confirmationScore`. Eso queda como contrato documentado, no implementado en F-04.

### 3.2 Score persistido por trigger (no calculado en cliente)

El ticket permitía cliente o function. Elegí **function** porque:

- Una vez calculado, queda como campo del doc → cualquier consumidor (motor NLP, panel admin, queries de filtrado) lo lee de un campo simple sin recorrer la subcolección.
- El cálculo siempre usa el config actual de `algorithmConfig.communityValidation` — el umbral lo administra el admin desde T-NLP-06 sin redeploy.
- Cliente nunca tiene que sumar; menos riesgo de skew si se cambia el algoritmo.

Trade-off: hay ~200ms de latencia entre la escritura de la reacción y la actualización del campo agregado. Aceptable: la UI muestra el feedback del voto inmediatamente (el botón cambia a "activo"); el badge "validado" puede tardar un instante.

### 3.3 Umbrales configurables, no hardcodeados

Agregué `communityValidation: { threshold, minReactions }` a `AlgorithmConfig` (T-NLP-06). Defaults:

- `threshold = 0.7` — más del 70% de los votos confirman.
- `minReactions = 3` — al menos 3 votos en total.

El admin puede ajustar desde el panel de calibración existente sin redeploy. Si el barrio es pequeño y nunca llega a 3 reacciones, baja `minReactions` a 1 y `threshold` a 0.51.

### 3.4 Reglas con `get()` del doc padre (corrección al sketch del plan)

El plan original (§5.3 de la devolución) tenía un sketch incorrecto: `resource.data.userId != incidents.data.userId` (`incidents.data` no es ref válida en el match de la subcolección). La corrección es:

```
get(/databases/$(database)/documents/incidents/$(incidentId)).data.userId
  != request.auth.uid
```

El `get()` lee el doc padre dentro de la rule. Costo: 1 lectura Firestore extra por intento de escritura de reacción. Aceptable para volumen MVP; en producción a escala se podría cachear con Custom Claims (mismo argumento que D-09 §3.5).

### 3.5 Una reacción por usuario, toggle por re-tap

`incidents/{id}/reactions/{userId}` con uid como doc id garantiza una reacción por par (incident, votante). Acciones:

- Primer tap en un botón → crea/sobreescribe el doc.
- Tap en el botón opuesto → cambia el `type`.
- Tap en el botón ya activo → **retira el voto** (delete del doc).

Es coherente con UX de like/dislike de redes sociales. El delete dispara el trigger igual y los contadores se recalculan.

### 3.6 Dueño / referente / admin no votan

El dueño está prohibido por reglas (`get()` del padre). En la UI también se le esconde la sección de botones para que no intente. Los referentes y admins **sí pueden** votar técnicamente — la decisión fue habilitarlos: el referente tiene su propia herramienta (D-05) con peso mayor, y el voto comunitario es información complementaria. Si el equipo decide después que solo "ciudadanos plenos" votan, se agrega el guard en la regla.

### 3.7 Sin auto-ajuste de prioridad

F-04 deja el flag `communityValidated` persistido pero **no toca el `priorityScore`** automáticamente. El motor NLP (`priorityCalculationFlow`) podría consumirlo en una iteración futura — por ahora, es señal pasiva. Razones:

- Cambiar `priorityScore` automáticamente desde un trigger es complejo (race con el pipeline NLP que recién lo calculó).
- Quien quiera usar `communityValidated` puede hacerlo en query/filtro/panel del admin.

## 4. Impacto en el sistema

### Creados
- `functions/src/reactionsAggregator.ts` — lógica pura `computeReactionAggregates` + trigger `onWritten`.
- `functions/src/reactionsAggregator.test.ts` — 9 tests del cálculo (borde: 0, 1, empate, umbral exacto, etc.).
- `lib/features/incidents/data/services/reactions_service.dart` — `setReaction`, `removeReaction`, `watchMyReaction`.
- `lib/features/incidents/presentation/providers/reactions_provider.dart` — providers + `ReactionsNotifier` (con toggle).
- `test/unit/incidents/reactions_service_test.dart` — 5 tests del servicio del cliente.

### Modificados
- `functions/src/algorithmConfig.ts` — schema, defaults y merge de `communityValidation`.
- `functions/src/index.ts` — export del trigger.
- `firestore.rules` — bloque `match /incidents/{id}/reactions/{userId}` con `get()` del padre.
- `lib/features/incidents/domain/entities/incident_event.dart` — enum `ReactionType`, campos `confirmsCount`, `disputesCount`, `confirmationScore`, `communityValidated` en `IncidentEvent`.
- `lib/features/incidents/data/models/incident_event_model.dart` — (de)serialización.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — widget `_CommunityValidationSection` con dos botones, contador, badge "Validado por la comunidad". Aparece **debajo** del bloque de verificación del referente.

### No modificados (verificados pero ya correctos)
- `priorityCalculationFlow` — no consume los nuevos campos por ahora. Si en una iteración futura se calibra que sí, se patchea sin tocar F-04.

## 5. Limitaciones conocidas

- **Cualquier vecino activo puede votar**, sin filtrar por proximidad geográfica. Un user que vive a 50 cuadras puede confirmar/disputar igual. Mejora futura: solo permitir votar si `distance(user.coverage, incident.location) < threshold`.
- **Sin penalización por votos sostenidos.** Si un user vota "dispute" en todo, el sistema no lo identifica como troll. Mejora futura: integrar con el sistema de reputación de usuario (D-08); usuarios con score < 30 pesan menos o no votan.
- **Sin notificación al dueño cuando alguien vota.** Cierra el loop social. Cuando D-01 esté operativo se puede agregar opt-in.
- **`communityValidated` no decae con el tiempo.** Un reporte validado hace 6 meses sigue marcado como tal aunque se haya solucionado. Aceptable por el alcance del MVP; si el equipo lo pide, agregar TTL en el trigger.
- **El trigger no es transaccional con el contador del usuario.** Si dos personas votan simultáneamente, el trigger recuenta correctamente al final (cada onWritten relee la subcolección entera), pero los displays intermedios pueden ver valores stale por ~200ms.
- **No hay tests de reglas Firestore.** Mismo patrón documentado en D-02..D-09. Validación queda como runtime check con emulador (§6).
- **Cliente no muestra quiénes votaron.** Solo el conteo. Decisión deliberada de privacidad: el `userId` de las reactions es legible (subcolección), pero la UI no lo expone para no llamar a "campaña" o "ataque colectivo".

## 6. Comandos de verificación

```bash
# Backend
cd functions && npx tsc --noEmit
# limpio

cd functions && npm test
# 110/110 passed (incluye 9 nuevos del aggregator)

# Cliente
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (154/154)
```

### Pruebas manuales con emulador

1. `firebase emulators:start --only firestore,functions,auth`.
2. Crear `vecino-1` (dueño), `vecino-2`, `vecino-3`, `vecino-4` (todos active).
3. Crear `incidents/inc-1` con `userId: 'vecino-1'`.
4. Como `vecino-2`, escribir `incidents/inc-1/reactions/vecino-2 = { type: 'confirm', by: 'vecino-2', at: now }`.
5. Verificar que `incidents/inc-1` se actualizó con `confirmsCount: 1`, `confirmationScore: 1.0`, `communityValidated: false` (todavía falta para min 3).
6. Como `vecino-3` y `vecino-4`, mandar `confirm` también.
7. Verificar `communityValidated: true` con score 1.0 y count 3.
8. Como `vecino-1` (dueño), intentar votar su propio reporte → debe rechazar con `permission-denied`.

### Deploy

```bash
firebase deploy --only firestore:rules
firebase deploy --only functions:aggregateReactionsOnWritten
```

## 7. Próximos pasos relacionados

- **Integrar `communityValidated` en `priorityCalculationFlow`**: cuando el motor NLP considere el flag, los reportes validados por la comunidad pueden subir un escalón de prioridad (calibrable desde T-NLP-06).
- **Jerarquía en el score combinado**: si en F-05/F-06 se diseña un score único de "este reporte es real", la verificación del referente (D-05) debe pesar más que `confirmationScore`. Contrato documentado, sin implementación.
- **Filtro por proximidad** en quién puede votar (mejora #1 de §5).
- **Tests de reglas Firestore en CI** (deuda compartida con D-02..D-09): agregar job con emulador. F-04 es buen candidato para cubrir por la complejidad del `get()` del padre.
- **F-05**: cuando se diseñe el cierre bilateral, la comunidad ya tiene voz vía F-04. F-05 cierra el ciclo con la voz del propio reportero.

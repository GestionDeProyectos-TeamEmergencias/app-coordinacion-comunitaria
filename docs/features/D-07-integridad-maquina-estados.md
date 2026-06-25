# D-07 — Integridad de la máquina de estados (un solo camino a `falso`)

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.7)
> **Tickets relacionados:** RF-ADM-02, O4 (definición de "done" del cierre)
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Codifica el grafo de transiciones válidas de `IncidentStatus` y restringe el dropdown del Administrador a transiciones autorizadas. Elimina el camino doble a `falso` (dropdown manual sin efectos + callable con decremento de reputación): tras D-07, `falso` queda exclusivamente vía `moderateFalseReport`. La validación se replica en reglas Firestore para que ningún cliente pueda saltarse el orden.

Antes de D-07, el dropdown exponía los 8 valores del enum como transición libre: se podía saltar `recibido → solucionado`, ir hacia atrás, y marcar `falso` desde el dropdown sin disparar `falseReportsCount++` ni el decremento de reputación (que vive en el callable). Era inconsistente con RF-ADM-02 y bloqueaba la mitigación de reportes falsos (Informe de Viabilidad).

## 2. Justificación

RF-ADM-02 define el ciclo `Recibido → Programado → En Reparación → Solucionado`. Un dropdown que ignora ese contrato vacía la documentación. Además, la observación **O4** del docente pidió "reglas claras de qué condiciones se deben cumplir para cerrar un reporte": el grafo es justamente esa definición operativa. D-07 también es **prerrequisito de F-05** (cierre bilateral): F-05 necesita una máquina de estados predecible para agregar el sub-estado de confirmación.

## 3. Decisiones de diseño

### 3.1 Grafo de transiciones

```
recibido       → {programado, enReparacion, solucionado}
programado     → {recibido, enReparacion, solucionado}
enReparacion   → {programado, solucionado}
solucionado    → {}   (terminal — F-05 abrirá disputa por campo ortogonal)

Estados marcadores del backend (terminales, no manuales):
  falso, rechazadoFueraDeCobertura, vitalRiskDetected, rechazadoAutorInactivo
```

Decisiones puntuales:

- **`recibido → solucionado` saltando pasos es válido.** Caso real: el admin recibe un reporte de algo que ya está resuelto en terreno, lo marca directamente. No exigir pasos intermedios artificiales.
- **`programado → recibido` (vuelta atrás) sí, `enReparacion → recibido` no.** "Anular planificación" antes de iniciar trabajo es un caso real; volver desde "ya en obra" a "recibido" perdería la traza de la reparación iniciada. Si se necesita esto, se hace marcando una acción (D-06) y manteniéndolo en `enReparacion`.
- **`solucionado` es terminal.** F-05 va a permitir disputa por el reportero, pero **con un campo ortogonal** `closureConfirmation`, no tocando `status` hacia atrás (decisión §5.2 de la devolución).
- **Estados marcadores no transitan a nada.** Son veredictos terminales del backend (`falso` por moderación, los rechazos por pipeline). Si un admin necesita re-evaluar, abre un nuevo reporte o levanta la sanción de cuenta (T-AUTH-07/D-08), no toca el incident.

### 3.2 `falso` con un solo camino: callable `moderateFalseReport`

- **Quitado del dropdown** (no figura en `allowedTransitions` de ningún estado).
- **Botón "Marcar como falso"** sigue siendo el único entry point. Solo se muestra cuando `status.canBeMarkedAsFalse == true` (estados activos: recibido, programado, en_reparacion).
- El callable corre con Admin SDK (`functions/src/moderation.ts`) → no cae bajo reglas, así que puede hacer la transición a `falso` aunque las reglas no la permitan al cliente.
- Esto **garantiza** que `falseReportsCount++` y el decremento de reputación (D-08) se ejecuten siempre que se marca un reporte como falso. Hoy el decremento no anda por el mismatch de campo (D-08), pero D-07 deja el camino preparado para que cuando D-08 cierre, todo funcione automáticamente.

### 3.3 Validación replicada en reglas Firestore

Codificamos el grafo en `firestore.rules` con la función `isValidStatusTransition(oldStatus, newStatus)`. La regla de update del admin la invoca cuando se está tocando `status`:

```
isAdmin() && (
  !affectedKeys().hasAny(['status']) ||           // no toca status → ok
  isValidStatusTransition(old.status, new.status)  // si toca, debe ser válida
)
```

Esto bloquea:

- Saltos arbitrarios (`solucionado → recibido`, `enReparacion → recibido`).
- Estados marcadores desde el dropdown (`falso`, `rechazado_*`, `vital_risk_detected`). Solo el backend con Admin SDK puede setearlos.

**Trade-off documentado**: el grafo está codificado en dos lugares (Dart y Firestore Rules). Mantener sincronizados los dos es manual. Es aceptable: las transiciones son pocas y estables; cualquier cambio futuro requiere PR en los dos archivos. Tests del lado cliente lo validan; tests de reglas (futuro D-NN o iteración) lo validarían del lado backend.

### 3.4 UX del dropdown: estado actual visible pero no seleccionable como "cambio"

El dropdown muestra el estado actual como primer item (etiqueta de partida) y luego las transiciones permitidas. Si el usuario "selecciona" el actual no pasa nada (la lógica de `_onChanged` retorna early). Si el estado es terminal, el dropdown se reemplaza por un mensaje `'El ciclo de vida ya está cerrado…'`.

### 3.5 Botón "Marcar como falso" condicional al estado

Antes de D-07, el botón se mostraba para todo `canVerify`, en cualquier estado. Ahora se condiciona a `status.canBeMarkedAsFalse`:

- **Activos** (recibido, programado, en_reparacion): visible.
- **Solucionado**: oculto. Reabrir como falso un incident ya solucionado tiene consecuencias serias para la reputación del autor; si hace falta hacerlo, hay que ir por flujo administrativo distinto.
- **Marcadores ya presentes** (`falso`, rechazados, vital risk): oculto. Ya está sancionado o descartado.

### 3.6 Backend del callable `moderateFalseReport` no se tocó

Para el alcance de D-07: el callable ya rechaza si el incident ya estaba moderado (`alreadyModerated == true`). No se agregó validación de "desde qué estados se puede marcar" porque el cliente ya filtra. **Mejora futura sugerida**: agregar `if (currentStatus !in ['recibido', 'programado', 'en_reparacion']) throw HttpsError('failed-precondition')` para evitar que un cliente desactualizado o un acceso directo a la callable haga la moderación desde un estado inválido. Queda para D-08 (que toca esa función) o un follow-up.

## 4. Archivos modificados / creados

### Modificados
- `lib/features/incidents/domain/entities/incident_event.dart` — agrega `allowedTransitions`, `canTransitionTo`, `canBeMarkedAsFalse` al enum `IncidentStatus`.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — `_StatusUpdater` filtra dropdown por `allowedTransitions` y muestra mensaje cuando es terminal. `_MarkAsFalseButton` solo aparece si `status.canBeMarkedAsFalse`.
- `firestore.rules` — agrega la función `isValidStatusTransition` y la integra en la regla de update del admin.

### Creados
- `test/unit/incidents/status_transitions_test.dart` — 10 tests del grafo (cada estado, identidad, saltos inválidos, `canBeMarkedAsFalse`).

### No modificados
- `functions/src/moderation.ts` (`moderateFalseReport`) — no se tocó. Sigue siendo el único camino a `falso`.
- `functions/src/index.ts` (pipeline) — sigue escribiendo los estados marcadores con Admin SDK, sin caer bajo reglas. Sin cambios.

## 5. Impacto

| Antes de D-07 | Después de D-07 |
| --- | --- |
| Dropdown exponía los 8 valores del enum, sin orden. | Solo transiciones válidas; estado terminal muestra mensaje en vez de dropdown. |
| `falso` se podía setear desde el dropdown **sin efectos** (no decrementaba reputación, no contaba el falso). | `falso` solo vía callable `moderateFalseReport`. Un único camino. |
| Saltos arbitrarios (`solucionado → recibido`, `enReparacion → recibido`). | Bloqueados en cliente y en reglas Firestore. |
| Estados marcadores (`falso`, `rechazado_*`, etc.) ponibles manualmente desde el dropdown. | Solo el backend con Admin SDK los escribe. |
| Reglas Firestore no validaban orden de transiciones. | `isValidStatusTransition` lo replica server-side. |
| Botón "Marcar como falso" visible en cualquier estado. | Solo en estados activos del ciclo (recibido, programado, en_reparacion). |

## 6. Limitaciones conocidas

- **Grafo duplicado en Dart y reglas Firestore.** Aceptable por simplicidad; cambios futuros requieren PR en los dos archivos. Una mejora futura sería generar la regla desde una fuente única (build step), pero por ahora no compensa el costo.
- **No hay tests automatizados de reglas Firestore.** Mismo trade-off documentado en D-02/D-04/D-05/D-06: validación queda como checklist runtime con emulador. Esta tarea es especialmente buena candidata para esos tests cuando se agreguen.
- **El callable `moderateFalseReport` no valida el estado del incident.** Si un cliente desactualizado (o un acceso vía SDK) invoca la callable desde un estado donde la UI ahora no la ofrece, igual va a marcar como falso. Sugerido para D-08 o seguimiento.
- **No hay transición "reabrir" para corregir un cierre prematuro.** F-05 introduce la disputa del reportero como camino oficial; si el admin necesita reabrir por su cuenta, hoy tiene que crear un incident nuevo. Aceptable: el principio es que el ciclo solo avanza, los retrocesos son excepciones documentadas.
- **Sin auditoría especial cuando la transición es válida pero "atípica"** (p. ej. `recibido → solucionado` saltando dos pasos). Si el equipo lo pide, se puede emitir una acción automática (D-06) en esos casos para dejar registro.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (131/131)
```

### Pruebas manuales

1. Login como **admin** → abrir incident en `recibido` → dropdown muestra solo `programado`, `enReparacion`, `solucionado` (y el actual deshabilitado). NO muestra `falso`, `rechazado_*`, `vital_risk_detected`.
2. Cambiar a `enReparacion` → el dropdown ahora muestra solo `programado` y `solucionado` (no `recibido`).
3. Cambiar a `solucionado` → el dropdown desaparece, se ve el mensaje "ciclo ya cerrado".
4. Volver al inicio con un incident en `solucionado` → el botón "Marcar como falso" **no** aparece.
5. Con un incident en `recibido`, marcar como falso → se invoca callable, `falseReportsCount` sube, status pasa a `falso`. (El decremento de reputación llega cuando D-08 esté merged.)
6. **(Reglas)** Como admin, intentar setear `status: 'falso'` desde SDK directo → debe rechazar con `permission-denied`.
7. **(Reglas)** Como admin, intentar `solucionado → recibido` desde SDK → debe rechazar.

## 8. Próximos pasos relacionados

- **D-08**: con D-07 cerrado, el único camino a `falso` es la callable. Cuando D-08 unifique el campo (`verifiedAsFalse` vs `moderatedAsFalse`), la reputación va a bajar automáticamente en cada marca de falso. D-07 prepara el terreno.
- **F-05** (cierre bilateral): va a agregar un campo **ortogonal** `closureConfirmation: { state, ... }` para que el reportero confirme/dispute. NO toca el grafo de `status` (el cierre sigue siendo "solucionado terminal").
- **Tests de reglas Firestore en CI**: candidato fuerte para acompañar D-07 / D-08 / D-09. Job de emulador + `@firebase/rules-unit-testing`.
- **Validación en `moderateFalseReport`**: agregar precondición de estado en el callable para defensa-en-profundidad (ya documentado como sugerencia en §3.6).

# D-06 — Admin: (re)asignar categoría + registrar acciones de resolución

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.6)
> **Tickets relacionados:** RF-ADM-03
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Completa RF-ADM-03: el Administrador puede (a) corregir la categoría que asignó el NLP y (b) registrar acciones/notas de resolución a lo largo del ciclo de vida del incidente. El feed de acciones es público al vecino dueño como rendición de cuentas.

Antes de D-06, el admin podía cambiar `status` y marcar incidents como falsos, pero **no** podía editar `category` (la última palabra la tenía el NLP, sin corrección humana posible) ni dejar registro de qué se hizo. El `IncidentEvent` no tenía ni `actions` ni auditoría de cambio de categoría.

## 2. Justificación

RF-ADM-03 es un **"deberá"** del SRS: el admin "deberá asignar cada incidente a una categoría… y **registrar las acciones tomadas para su resolución**". Las dos partes estaban sin cumplir. Es la base de la **"trazabilidad / rendición de cuentas"** que el Informe de Viabilidad nombra como uno de los cuatro pilares de la propuesta de valor. Deuda directa del MVP.

## 3. Decisiones de diseño

### 3.1 `actions` como array en el doc del incident, no subcolección

Se evaluaron tres opciones:

| Opción | Pros | Contras | Veredicto |
| --- | --- | --- | --- |
| **A. Array `actions[]` en el doc** (elegido) | Una sola lectura del incident trae todo (timeline, verificación, acciones). Atomicidad de lectura para la UI del detalle. Reglas Firestore simples. | Las arrays de Firestore tienen límite de tamaño (~1MB doc completo). | ✅ |
| B. Subcolección `incidents/{id}/actions/{actionId}` | Sin límite práctico. | Una lectura adicional por detalle. Reglas más complejas. Inconsistencia con cómo se modelan `statusHistory` y `referentVerificationHistory` (también arrays). | ❌ |
| C. Colección global `audit_log` filtrada por incident | Centraliza auditoría. | Mucho overhead para el alcance del MVP. | ❌ |

A es consistente con cómo el proyecto ya modela `statusHistory` y `referentVerificationHistory`. Cuando un incident llegue a límites de tamaño (muy improbable en este uso real), se migra a subcolección.

### 3.2 Auditoría del cambio de categoría: solo último (no histórico)

`categoryChangedBy` y `categoryChangedAt` guardan **el último cambio** de categoría, no un histórico. Razones:

- El valor de `category` es el operativo; saber **quién y cuándo** lo cambió por última vez es suficiente para rendición de cuentas básica.
- Si en el futuro se quiere histórico, se puede agregar una entrada al array `actions` automáticamente cuando cambia la categoría ("Categoría reasignada de X a Y").
- Mantenerlo simple ahora evita inflar el modelo con sub-historiales separados.

### 3.3 Reglas Firestore: allowlist del dueño (cambio importante)

Hasta D-06, la regla del **dueño** del incident usaba una **blacklist** (`!affectedKeys().hasAny(['status', 'priority', 'priorityScore', 'userId'])`). Eso permitía al dueño tocar **cualquier otro campo**, incluyendo `category` y `actions`. Eso vaciaba D-06 (un vecino podía sobrescribir la categoría del admin) y violaba RF-ADM-03 (un vecino podía meter acciones falsas en el feed).

La regla pasa a **allowlist** (`hasOnly(['description', 'photoUrl'])`): el dueño solo puede tocar esos dos campos mientras `status == recibido`. Es la intención original de T-REP-03, expresada de forma defensiva.

| Caller | Antes de D-06 | Después de D-06 |
| --- | --- | --- |
| Admin | Cualquier campo. | Sin cambios. |
| Referente | Solo `referentVerification`/`history` (D-05). | Sin cambios. |
| Dueño (en `recibido`) | Todo salvo `status`/`priority`/`priorityScore`/`userId`. **Podía tocar `category` y `actions`.** | Solo `description` y `photoUrl`. |

### 3.4 Categoría editable como `DropdownButtonFormField`, no `Dialog`

El dropdown está inline en el detalle (reemplaza el `_InfoRow` cuando el caller es admin). Eso minimiza fricción: un cambio de categoría es una operación frecuente y no merece un diálogo de confirmación. Si el equipo legal lo pide, se agrega confirmación.

### 3.5 Acciones siempre visibles al dueño

El bloque "Acciones tomadas" se renderiza para todos los usuarios cuando el incident tiene acciones. Es el corazón de la rendición de cuentas: el vecino debe ver qué hizo el admin con su reporte. Cuando no hay acciones todavía, el copy del dueño dice "El administrador aún no registró acciones sobre tu reporte"; el del admin dice "Todavía no se registraron acciones" (acción explícita).

### 3.6 `at` con `Timestamp.now()` del cliente, igual que D-05

`FieldValue.serverTimestamp()` no se permite **dentro** de un valor que va por `arrayUnion`. Para mantener el array, el `at` del Map se calcula en cliente. Suficiente para auditoría humana; el doc lleva además `createdAt: serverTimestamp` para casos más estrictos.

## 4. Archivos modificados / creados

### Creados
- `lib/features/incidents/data/services/incident_admin_service.dart` — `reassignCategory` y `addAction`.
- `lib/features/incidents/presentation/providers/incident_admin_provider.dart` — provider + notifier.
- `test/unit/incidents/incident_admin_service_test.dart` — 4 tests (categoría, una acción, varias acciones, nota vacía).

### Modificados
- `lib/features/incidents/domain/entities/incident_event.dart` — entity `ResolutionAction` y campos `actions`/`categoryChangedBy`/`categoryChangedAt` en `IncidentEvent`.
- `lib/features/incidents/data/models/incident_event_model.dart` — (de)serialización de los nuevos campos.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — widgets `_CategoryEditor` (reemplaza `_InfoRow` cuando el caller es admin) y `_ResolutionActionsSection` (lista + form para admin, solo lista para otros).
- `firestore.rules` — regla `incidents` update del dueño pasa de blacklist a allowlist (`hasOnly(['description', 'photoUrl'])`).

### No modificados
- El `_StatusUpdater` y la sección de moderación quedan iguales: D-06 solo agrega categoría editable y acciones, no toca el ciclo de estados.

## 5. Impacto

| Antes de D-06 | Después de D-06 |
| --- | --- |
| Admin no podía corregir la categoría del NLP — quedaba fija para siempre. | Dropdown editable inline en el detalle. |
| Sin registro de acciones del admin. RF-ADM-03 sin cobertura. | Feed cronológico con `note`, `by`, `byDisplayName`, `at`. |
| Vecino no veía nada de lo que hacía el admin con su reporte. | El bloque "Acciones tomadas" es visible al dueño como rendición de cuentas. |
| Regla del dueño con blacklist: dejaba al vecino sobrescribir `category` y `actions`. | Allowlist explícita: solo `description` y `photoUrl`. |
| `IncidentEvent` no modelaba acciones ni auditoría de categoría. | Entity y model con los campos serializados. |

## 6. Limitaciones conocidas

- **No hay edición / borrado de acciones registradas.** Una vez añadida, queda. Decisión deliberada: el feed de auditoría no debe ser "limpiable" por el mismo admin que registra. Si se necesita corregir, se agrega una acción nueva.
- **Sin notificación al vecino cuando se agrega una acción.** Aceptable por el alcance del MVP; cuando D-01 esté desplegado se puede agregar un push opt-in. Anotado para iteraciones futuras.
- **Sin historial de cambios de categoría.** Solo se guarda el último cambio (`categoryChangedBy`/`At`). Si el equipo pide histórico completo, se agrega una entrada automática a `actions` cuando cambia la categoría (rápido follow-up).
- **No hay tests de reglas Firestore.** Igual que D-02, D-04, D-05. Validación queda como runtime check con emulador (§11.13 punto 1 de la devolución).
- **Migración:** incidents existentes sin `actions` se tratan como lista vacía. Sin migración explícita (default seguro).
- **`_CategoryEditor` no muestra "Editado por X" en el detalle del dueño.** El timestamp y autor del cambio quedan en `categoryChangedBy/At` pero la UI actual no los renderiza. Mejora candidata si el equipo lo pide para reforzar transparencia.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (120/120)
```

### Pruebas manuales

1. Login como **admin** → abrir detalle de un incident → ver dropdown de categoría editable y la sección "Acciones tomadas" con form.
2. Cambiar categoría → verificar en Firestore que `category`, `categoryChangedBy`, `categoryChangedAt` se actualizaron.
3. Registrar una acción ("Derivado a Obras Públicas") → debe aparecer arriba del form con el nombre del admin y timestamp.
4. Registrar segunda acción → ambas se ven en orden cronológico inverso (más reciente primero).
5. Login como **vecino dueño** del incident → abrir detalle → ver las acciones (no la categoría editable, no el form).
6. Login como **referente** → ver acciones (no editor de categoría).
7. **(Reglas)** Como dueño activo, intentar cambiar `category` con SDK directo → debe rechazar con `permission-denied`.

## 8. Próximos pasos relacionados

- **D-07** (integridad de la máquina de estados): cuando se defina el grafo de transiciones válidas, considerar emitir una acción automática (`"Estado cambiado a X"`) cuando el admin avanza el ciclo. Eso unifica el feed con `statusHistory`.
- **F-05** (cierre bilateral): la confirmación/disputa del vecino debería agregarse al feed de acciones como entrada propia ("Cierre confirmado por reportero") para mantener una sola fuente de verdad cronológica.
- **Notificaciones**: cuando D-01 esté desplegado, pingear al dueño cuando el admin registre una acción nueva sobre su reporte. Cierra el loop de comunicación.
- **Histórico de categoría**: si el equipo pide, agregar entrada automática a `actions` cada vez que cambia `category`.

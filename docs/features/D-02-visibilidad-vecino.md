# D-02 — Visibilidad del vecino: mapa del barrio (reglas Firestore alineadas)

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.2)
> **Tickets relacionados:** SRS §3.1.1, RF-ADM-01
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Resuelve la contradicción entre el SRS §3.1.1 ("mapa de incidencias activas **del barrio**") y `firestore.rules:80-83`, que solo permitía al vecino leer **sus propios** incidents. Como las queries de `HomePage` y `MapPage` no filtraban por `userId`, las reglas rechazaban la consulta entera con `permission-denied` para cualquier vecino no-admin/no-referente.

La decisión de producto tomada (registrada en este documento) es **sostener la promesa del SRS**: el vecino activo ve el mapa del barrio. Para implementarlo, se amplió la regla de lectura a "cualquier usuario activo" y se alineó el stream del cliente para que excluya estados sancionados/descartados/resueltos (consistente con el panel del admin).

## 2. Justificación (deuda de MVP)

El SRS §3.1.1 y RF-ADM-01 ya prescribían el mapa del barrio. El MVP llegó con la **regla restrictiva** y la **query sin filtro**, dos decisiones incompatibles entre sí, dejando la feature **rota para vecinos** y funcional solo para los roles privilegiados (que no son la mayoría de usuarios). Es deuda pura del MVP, no una extensión: el plan ya prometía esto.

La tesis de "ciencia ciudadana / red de sensores" del Informe de Viabilidad **depende** de que el vecino vea reportes de otros — visibilizar es la mitad del valor del producto. Mantener la restricción equivaldría a descartar esa propuesta de valor.

## 3. Decisiones de diseño

### 3.1 Regla permisiva sin filtro por status

La opción inicial era ampliar la regla pero excluyendo en el server los estados `falso` y `rechazado_fuera_de_cobertura` (siguiendo la sugerencia de la devolución). Se descartó por dos razones:

1. **Consistencia con queries.** En Firestore, una regla de lectura que depende del valor de un campo del documento exige que la **query del cliente** incluya un filtro equivalente; si no, el server rechaza la query entera. Eso forzaba a usar `where('status', whereIn: [4 estados públicos])` con el orderBy por timestamp, lo que requiere un índice compuesto y se vuelve frágil cada vez que se agregue un estado al enum (D-03 va a agregar `vital_risk_detected` y `rechazado_autor_inactivo`).
2. **Defensa en profundidad real.** La sanitización útil contra exposición de identidad es **no mostrar `userId` al vecino en la UI**. Eso ya se cumple: ninguna pantalla del vecino (`MapPage`, `HomePage`, `IncidentDetailPage`) renderiza el `userId` del reportero. La regla de status no aporta privacidad extra: el `userId` igualmente viaja en el doc.

La regla final es simplemente `allow read: if isActive();`. El **cliente** filtra por estado en memoria para la vista pública (`watchActiveIncidents` excluye `solucionado`, `falso`, `rechazado_fuera_de_cobertura`).

### 3.2 Por qué el `userId` no es PII explotable

El `userId` que viaja en el doc de un incident es el UID de Firebase Auth. La regla `users/{uid}` sigue blindada a **dueño + admin**, por lo que un vecino no puede resolver `userId → email/nombre/comprobante`. Es un identificador opaco para terceros. La sanitización adicional (proyectar `userId` afuera del modelo de lectura, o usar colecciones espejo "públicas") quedó **fuera de scope** porque el riesgo concreto es bajo y agrega mantenimiento.

### 3.3 Home unificado al stream activo

Antes de D-02 había dos providers paralelos: `incidentsStreamProvider` (sin filtro) usado por `HomePage`, y `activeIncidentsStreamProvider` usado por `MapPage` y el panel de moderación. El de "sin filtro" era código muerto en la práctica para vecinos (la query fallaba) y, con la regla nueva, hubiera empezado a mostrar también `falso` y `solucionado` en Home — mal UX.

Se eliminó `incidentsStreamProvider` y se migró `HomePage` a `activeIncidentsStreamProvider`. Una sola fuente de verdad para la "vista pública del barrio".

Para "Mis reportes en cualquier estado" (incluido solucionados/falsos del propio reportero) ya quedó previsto **F-01** (pantalla dedicada). No se adelanta acá.

### 3.4 No se agregaron tests de reglas Firestore al pipeline

`firebase_rules_unit_testing` requiere un emulador y setup de Node aparte. Por costo/beneficio en esta iteración, **no se agregaron tests automatizados de reglas**. El test de aceptación queda como punto del checklist de runtime (`DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.13 punto 1). Recomendación a futuro: agregar un job de CI con emulador que cubra los 4 ejes (vecino dueño, vecino terceros, referente, admin) × (incidents, users).

## 4. Archivos modificados

- `firestore.rules` — regla `match /incidents/{incidentId}` de lectura ampliada a todo usuario activo, con comentario explicando el approach.
- `lib/features/incidents/presentation/providers/incidents_provider.dart` — eliminado `incidentsStreamProvider`; `activeIncidentsStreamProvider` documentado como la vista pública canónica.
- `lib/features/incidents/presentation/pages/home_page.dart` — pasa a `activeIncidentsStreamProvider`.
- `test/unit/incidents/watch_active_incidents_test.dart` — test nuevo que verifica que el filtro excluye `falso` y `rechazado_fuera_de_cobertura` (no solo `solucionado`).

### Verificado pero no modificado

- `MapPage` (`map_page.dart`) — ya usaba `activeIncidentsStreamProvider`.
- `IncidentModerationPage` (admin) — usa `activeIncidentsStreamProvider`; los admin/referente igual pueden leer cualquier estado por regla, pero su panel solo lista activos. Detalle de un incidente sancionado se sigue accediendo vía `watchIncidentById` (consulta puntual).
- `IncidentDetailPage` — solo renderiza `incident.userId` dentro del bloque `if (user?.role.canVerify == true)`. No expone PII al vecino. Tras D-02, un vecino puede abrir el detalle de un incidente ajeno; los datos visibles (descripción, foto, statusHistory, ubicación) fueron escritos para visibilizar el problema y son apropiados de mostrar.
- `firestore.indexes.json` — no requiere cambios (la query sigue siendo `orderBy('timestamp')` sin compuestos).

## 5. Impacto

| Antes de D-02 | Después de D-02 |
| --- | --- |
| Vecino activo abriendo `/home` o `/map` → query rechazada por `permission-denied` (síntoma: lista vacía o error). | Vecino activo ve incidents activos del barrio (`recibido`/`programado`/`en_reparacion`). |
| El "mapa del barrio" prometido por el SRS no se entregaba para la mayoría de usuarios. | Se cumple SRS §3.1.1 y RF-ADM-01 para el rol que más lo necesita. |
| Dos providers paralelos (`incidentsStreamProvider` sin filtro, `activeIncidentsStreamProvider`). | Un solo provider canónico para la vista pública. |
| Admin/Referente: sin cambios. | Admin/Referente: sin cambios (la regla los seguía dejando pasar). |

## 6. Limitaciones conocidas

- **`userId` legible vía SDK.** Cualquier usuario activo puede leer `userId` de cualquier incident vía Firebase SDK directo. Es un UID opaco (no se puede resolver a identidad por la regla de `users/{uid}`), pero **un atacante con tiempo podría correlacionar quién reportó qué**. Mitigación a futuro: campos espejo sin `userId` o sanitización vía Cloud Function. **No bloqueante** para el MVP.
- **No hay tests automatizados de reglas.** Validación queda como runtime check con emulador (§11.13 punto 1 del documento de devolución).
- **Sin paginación.** El stream actual trae todos los incidents activos en cada snapshot. Para una comunidad chica (Junín) es viable; con miles de incidents activos hace falta paginación + límite (out of scope D-02; sería una D-NN posterior si hace falta).
- **Solucionados invisibles también para el reportero en Home/Mapa.** El stream público filtra `solucionado` para todos, incluido el dueño. Para que el dueño vea sus reportes resueltos hace falta **F-01** (Mis reportes). Aceptable como interim — el detalle del incidente sigue accesible vía deeplink/notificación.
- **Vecinos pueden ver fotos e ubicaciones de incidents ajenos.** Eso *es la decisión de producto*; conviene reflejarlo en el disclaimer / T&C cuando se haga D-04.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (93/93)
```

### Validación manual con emulador (recomendada antes de desplegar)

1. `firebase emulators:start --only firestore,auth`.
2. Crear 3 usuarios: `vecino-activo`, `referente-activo`, `admin-activo`.
3. Crear 2 incidents: uno propiedad de `vecino-activo` (`recibido`), otro propiedad de otro user (`recibido`).
4. Como `vecino-activo`, hacer `db.collection('incidents').get()` → debe devolver ambos.
5. Como `vecino-activo`, hacer `db.collection('incidents').doc(id_ajeno).update({status: 'falso'})` → debe rechazar (la regla de update no cambió).
6. Como `vecino-pending` o `blocked`, hacer la lectura → debe rechazar (la regla exige `isActive()`).

## 8. Próximos pasos relacionados

- **F-01**: pantalla "Mis reportes" que sí incluya `solucionado`/`falso` propios (usando query con `where('userId', '==', uid)`).
- **D-03**: al agregar `vital_risk_detected` y `rechazado_autor_inactivo` al enum, decidir si esos estados son públicos o internos (probable: `vital_risk_detected` se muestra, `rechazado_autor_inactivo` no — actualizar el filtro de `watchActiveIncidents` en consecuencia).
- **D-04**: el disclaimer / T&C debe reflejar que los reportes son visibles a la comunidad.
- **Futuro**: tests de reglas Firestore en CI (job con emulador), paginación del stream público.

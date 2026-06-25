# F-01 — Sección "Mis reportes" con edición del reporte propio

> **Tipo:** `ajuste-feedback` (cierre de promesa SRS §3.1.1 + uso real O1)
> **Tickets relacionados:** SRS §3.1.1 ("historial de reportes propios"), RF-REP-01/03, T-REP-03 (reglas de edición existentes)
> **Fecha de implementación:** 2026-06-25
> **Estado:** completado

## 1. Qué es

Pantalla "Mis reportes" accesible desde Perfil que lista los incidents del usuario actual ordenados por fecha desc, sin filtro de status (incluye recibidos, programados, solucionados, falsos, rechazados). Cada tarjeta muestra estado + prioridad + fecha; tocarla abre el editor del reporte.

El editor se comporta de dos formas según el estado:

- **`status == recibido`** → todos los campos son editables (descripción, categoría, foto). Botón "Guardar cambios" persiste el patch en Firestore.
- **`status != recibido`** → todos los campos pasan a solo lectura con un badge "ya procesado". El usuario puede consultar pero no editar.

## 2. Por qué se hizo

El SRS §3.1.1 prometía explícitamente "historial de reportes propios y estado de resolución" para el vecino. El MVP llegó sin esa pantalla, y la observación **O1** del docente subrayó el problema desde la otra punta: el reporte rápido (RF-REP-01) toma ~3 segundos pero pierde valor porque no se enriquece después. F-01 cierra ambos gaps: completa la promesa SRS y permite enriquecer un reporte rápido con descripción/categoría/foto antes de que el pipeline NLP lo procese.

Categorización: **`ajuste-feedback`** — el SRS ya preveía la pantalla; F-01 la entrega + le suma edición.

## 3. Decisiones de diseño

### 3.1 Allowlist de campos editables incluye `category` (sobrescribe la regla D-06)

D-06 había restringido al dueño a `description` + `photoUrl` para proteger la categoría que asignaba el admin. F-01 amplía la allowlist a **`description`, `photoUrl`, `category`** únicamente mientras `status == recibido`. Justificación:

- En `recibido` el incident **aún no pasó por el pipeline NLP**. El reportero corrige la categoría que él mismo cargó en el form sin pisarle nada al admin.
- Apenas el incident sale de `recibido`, la regla del dueño deja de aplicar y la regla de D-06 (allowlist admin para `category`/`actions`) toma control. No hay solapamiento temporal.
- `actions`, `categoryChangedBy`, `categoryChangedAt`, `referentVerification*` y los demás campos siguen fuera del alcance del dueño.

### 3.2 Acceso desde Perfil, no bottom nav

El ticket dejaba la opción abierta. Elegí Perfil porque:

- El bottom nav ya tiene 4 tabs (Inicio, Reportar, Mapa, Perfil). Sumar una quinta cambia layout y reduce el target de cada item.
- "Mis reportes" es una vista de auditoría que el usuario abre con baja frecuencia (no diaria como el mapa). Vivir bajo Perfil refleja esa frecuencia y deja el bottom nav para flujos de uso continuo.

Si el equipo decide subirla al bottom nav después, es un cambio de una línea en `router.dart` y otra en `main_shell.dart`.

### 3.3 Hydratación una sola vez (no pisa edición en curso)

El editor escucha `incidentByIdProvider(id)`, que re-emite cada vez que el doc cambia en Firestore (p. ej. el admin avanza el status mientras el usuario está editando). Si re-poblamos el form en cada emit pisaríamos lo que el usuario está tipeando. Patrón: flag `_hydrated` que rellena los controllers solo en la primera emisión. Las emisiones posteriores actualizan `incident.status` para la lógica de "puede editar" pero respetan los campos en edición.

### 3.4 Botón "Guardar" no exige todos los campos (parcial allowed)

El use case `updateOwnIncidentDraft` solo persiste los campos no-null que recibe. El usuario puede guardar solo cambio de descripción, solo cambio de foto, etc. Validación mínima: si todo queda vacío (sin descripción ni categoría), bloqueamos con snackbar. Es razonable: un reporte sin descripción y sin categoría no aporta nada.

### 3.5 Foto: nueva vs. existente, sin borrar la vieja

Si el usuario cambia la foto, la nueva se sube y `photoUrl` se sobreescribe. **No** se borra el archivo viejo de Storage. Decisiones:

- El cliente no necesita permisos delete (más seguro).
- Las URLs sin referencia se purgarían en una limpieza periódica externa (sale del scope F-01).
- Para volumen de MVP es irrelevante.

### 3.6 `uploadPhoto` sube al `IncidentsRepository`

Antes era método privado del `IncidentsRemoteDataSource`. Lo elevé a la interfaz pública del repositorio porque ahora dos use cases lo necesitan (envío + edición). No introduce complejidad: es un wrapper directo.

### 3.7 Índice compuesto nuevo: `userId asc + timestamp desc`

Firestore requiere índice separado para `where + orderBy desc`. Agregué la entrada en `firestore.indexes.json`. **Deploy obligatorio antes de testear en remoto**: `firebase deploy --only firestore:indexes`. Sin esto, la query falla en runtime con un mensaje de "missing index" + link de creación automática.

## 4. Impacto en el sistema

### Modificados
- `firestore.rules` — allowlist del dueño extendida con `category`. **Requiere `firebase deploy --only firestore:rules`.**
- `firestore.indexes.json` — nuevo índice `userId asc + timestamp desc`. **Requiere `firebase deploy --only firestore:indexes`.**
- `lib/features/incidents/domain/repositories/incidents_repository.dart` — agrega `watchMyIncidents`, `updateOwnIncidentDraft`, `uploadPhoto` a la interfaz.
- `lib/features/incidents/data/datasources/incidents_remote_datasource.dart` — implementa `watchMyIncidents` y `updateOwnIncidentDraft`.
- `lib/features/incidents/data/repositories/incidents_repository_impl.dart` — pasa-through de los nuevos métodos.
- `lib/app/router.dart` — rutas `/my-reports` y `/my-reports/:id`.
- `lib/features/profile/presentation/pages/profile_page.dart` — ListTile "Mis reportes".
- `test/unit/incidents/update_status_notifier_test.dart` — el fake repo gana stubs para los nuevos métodos de la interfaz.

### Creados
- `lib/features/incidents/presentation/providers/my_incidents_provider.dart` — provider del stream + notifier de edición.
- `lib/features/incidents/presentation/pages/my_reports_page.dart` — listado.
- `lib/features/incidents/presentation/pages/my_report_edit_page.dart` — editor / visor.
- `test/unit/incidents/edit_own_incident_notifier_test.dart` — 3 tests del notifier (sin foto, con foto, error).
- `test/widget/incidents/my_reports_page_test.dart` — 4 widget tests (vacío, recibido editable, ya procesado lock, lista múltiple).

## 5. Limitaciones conocidas

- **Sin pull-to-refresh ni paginación.** Para usuarios con cientos de reportes la lista carga entero. Para volumen del MVP es trivial; cuando un user real pase los 50 reportes, agregar `limit + cursor`.
- **No hay edición de ubicación.** F-03 (en su propio ticket) va a permitir ajustar la ubicación al crear. Reutilizable en este editor cuando F-03 esté listo.
- **No notifica al admin cuando el dueño edita.** Si admin estaba mirando el incident, va a ver el cambio porque el stream emite, pero no recibe push. Quedará para cuando se integre D-01 con triggers más finos.
- **No elimina el archivo viejo de Storage al cambiar foto.** Documentado en §3.5; cleanup externo.
- **Sin "borrar mi reporte".** No estaba en el ticket; si el equipo lo pide, vale como F-NN o se agrega acá con confirmación.
- **El badge "ya procesado" es estático.** No explicita por qué (status programado vs solucionado vs falso). El status badge sí lo dice; el banner solo informa que está cerrado a edición.
- **No hay widget test del editor.** El editor depende de `image_picker`, `incidentByIdProvider` (que requiere Firestore mock) y el notifier — montar todo es overhead. El test del notifier cubre la lógica crítica.

## 6. Referencias

- Reglas Firestore: `firestore.rules` líneas que documentan la allowlist del dueño.
- Pantallas: `my_reports_page.dart`, `my_report_edit_page.dart`.
- Tests: `edit_own_incident_notifier_test.dart`, `my_reports_page_test.dart`.

### Deploy obligatorio antes de la demo

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (141/141)
```

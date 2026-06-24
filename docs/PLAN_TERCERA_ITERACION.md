# Plan de Tercera Iteración — Extensiones de Producto

> Documento de planificación generado tras la primera ronda de feedback de uso real de la app.
> Define el alcance, justificación y orden de implementación de funcionalidades que **exceden la planificación original** (Primera y Segunda Iteración) y responden a observaciones del usuario y del docente.

**Estado del documento:** propuesta — a validar con el equipo y el docente antes de comenzar la implementación.

---

## 1. Contexto y motivación

La Segunda Iteración cerró con todas las tareas del backlog implementadas y mergeadas a `develop`:
auth (T-AUTH-01..09), reporte/UI (T-REP-01..06), motor NLP (T-NLP-01..09) e infraestructura (T-INF-01..06).
La app es operativa end-to-end, pero el **uso real** y el feedback del docente expusieron limitaciones de producto que no se cubren con tareas pendientes del backlog original, sino con extensiones nuevas.

Estas extensiones se consideran **fuera del alcance original** (que estaba enmarcado en el SRS v1.1 y la Planificación v1.3) y se planifican aquí para ser implementadas como una **Tercera Iteración**.

> **Regla de oro de este documento:** cada vez que se complete una de las nuevas funcionalidades descriptas más abajo, se debe crear un archivo `.md` específico en `docs/features/` con:
> 1. **Descripción** de la funcionalidad.
> 2. **Justificación** (por qué se hizo, qué necesidad cubre, por qué excede el alcance original).
> 3. **Decisiones de diseño** tomadas y alternativas descartadas.
> 4. **Impacto** en módulos existentes (qué se rompió o cambió en otras features).
> 5. **Limitaciones conocidas** y futuras mejoras.

El docente nos exigirá la justificación al ver que el alcance se extendió, por eso es crítico no saltarse este paso.

---

## 2. Observaciones recogidas

Las observaciones que motivan esta iteración son:

| # | Observación | Origen |
|---|---|---|
| O1 | El reporte rápido no tiene categoría ni descripción, y el creador no puede editarlo después. No es útil así. Hace falta una sección "Mis reportes" con edición. | Uso real |
| O2 | No está claro el enfoque de la app ni el cliente objetivo. Falta una definición operativa que guíe decisiones de UX. | Docente |
| O3 | El reporte siempre usa GPS actual. Hay casos en que el vecino reporta cuando llega a su casa (no en el lugar del incidente). Tiene que poder ajustar la ubicación en el mapa. | Uso real |
| O4 | El flujo de cierre del reporte es opaco: no hay reglas claras sobre qué condiciones se deben cumplir para cerrarlo, ni un mecanismo para que la reputación del reporte mejore con interacciones de otros vecinos. | Docente |
| O5 | Falta validación bilateral al cerrar el reporte: hoy lo cierra el admin/referente unilateralmente. El docente sugirió notificar al reportero original para que dé el "visto bueno" o lo dispute. | Docente |
| O6 | Al cerrar el reporte (estado `solucionado`) debería poderse adjuntar evidencia opcional (foto de la reparación). | Uso real |
| O7 | El área de cobertura hoy es un círculo (centro + radio). No representa bien zonas urbanas reales (manzanas, barrios irregulares). Debería usarse un polígono. | Docente |

---

## 3. Análisis del estado actual por área

### 3.1 Reportes

**Hoy:**
- Tres modos de creación: rápido (solo GPS+timestamp), formulario (descripción + categoría + foto), voz (descripción transcripta).
- Estado inicial: `recibido`. Transiciones: `recibido → programado → enReparacion → solucionado`, más estados de rechazo (`rechazadoFueraDeCobertura`, `falso`, `rechazado_autor_inactivo`).
- Solo admin y referente pueden cambiar de estado (T-REP-06).
- Las reglas Firestore ya permiten al **dueño** editar `description` y `photoUrl` mientras el estado siga en `recibido` (ver `firestore.rules:82-88`). Esto **no se aprovecha en la UI** — no existe pantalla para hacerlo.

**Gap:** la edición de reporte propio existe a nivel reglas, pero la UI no la expone.

### 3.2 Reputación

**Hoy:**
- Existe `User.reputationScore` (T-AUTH-05): incrementa al pasar `recibido → programado` y decrementa cuando admin marca falso.
- **No existe** reputación a nivel reporte (no se puede confirmar/disputar por otros vecinos).

**Gap:** sistema de "votos" de la comunidad sobre la veracidad del reporte.

### 3.3 Cobertura geográfica

**Hoy:**
- `CoverageConfig`: `centerLat`, `centerLng`, `radiusMeters`.
- Validación con Haversine (`isWithinCoverage`).
- `T-AUTH-06` permite al admin configurar el centro y radio.

**Gap:** soporte de polígono — geometría más realista para zonas urbanas.

### 3.4 Identidad del producto

**Hoy:**
- El SRS describe el cliente como "organización vecinal adoptante (junta vecinal, sociedad de fomento, comisión de barrio privado, municipio pequeño)".
- No hay un documento de **buyer persona / journey** explícito que guíe decisiones de UX.

**Gap:** documentación de producto (no de código).

---

## 4. Plan de acción priorizado

Las features se ordenan por **valor agregado vs. esfuerzo**. Se proponen tres olas (waves) para entregar valor incrementalmente.

### 🌊 Wave 1 — Producto mínimo viable mejorado (alta prioridad, bajo esfuerzo)

#### **F-01: Sección "Mis reportes" con edición del reporte propio**

- **Cubre:** O1
- **Descripción:** nueva pantalla accesible desde el bottom nav o el perfil, que lista los incidentes del usuario actual (filtro `userId == currentUser.uid`). Cada card es tocable y abre un editor que permite modificar `description` y `category` mientras el estado siga en `recibido`. Si la foto está vacía, se ofrece subir una. Si el estado ya cambió, los campos son solo lectura.
- **Razón:** el reporte rápido toma 3 segundos hoy pero pierde valor porque no se enriquece. Permitir edición posterior convierte al "rápido" en un punto de entrada que se completa con contexto a posteriori.
- **Backend:** ninguno. Las reglas Firestore ya lo permiten.
- **Estimación:** 4 h.
- **Riesgo:** bajo.

#### **F-02: Definición operativa del cliente objetivo**

- **Cubre:** O2
- **Descripción:** documento `docs/PRODUCT_DEFINITION.md` con: buyer persona principal y secundaria, journey map del vecino y del admin, casos de uso primarios vs. fuera de alcance, principios de UX.
- **Razón:** sin esta definición, cada decisión de diseño se discute desde cero. Es entregable que pide el docente.
- **Backend:** ninguno (es documentación).
- **Estimación:** 3 h.
- **Riesgo:** bajo.

#### **F-03: Selector de ubicación interactivo en el formulario de reporte**

- **Cubre:** O3
- **Descripción:** en lugar de tomar el GPS automáticamente, mostrar un mini-mapa con un marker arrastrable (default = ubicación actual). El vecino puede tocar otro punto o arrastrar el marker para fijar la ubicación real del incidente. Se mantiene la validación de cobertura.
- **Razón:** caso de uso real frecuente (reportar al llegar a casa, reportar sobre algo cercano que ya pasó).
- **Backend:** ninguno. La validación de cobertura backend sigue funcionando con la lat/lng que recibe.
- **Estimación:** 5 h.
- **Riesgo:** medio (UX con Google Maps en Flutter Web suele tener detalles de plataforma).

### 🌊 Wave 2 — Validación social y bilateral (mediana prioridad)

#### **F-04: Sistema de "reacciones" de la comunidad para reputación del reporte**

- **Cubre:** O4 (parte 1)
- **Descripción:** otros vecinos activos pueden marcar un reporte como **"Confirmo"** o **"No es así"**. Se persisten en una subcolección `incidents/{id}/reactions/{userId}` con `{ type, at }`. El reporte calcula un `confirmationScore = confirms / (confirms + disputes)`. La UI muestra el contador y el score. Cuando el score supera un umbral configurable (ej. 70% con mínimo 3 confirmaciones), se marca como **"validado por la comunidad"** y el motor NLP puede usar ese flag para ajustar prioridad.
- **Reglas Firestore:** `incidents/{id}/reactions/{userId}` → `allow create, update if isActive() && userId == request.auth.uid && resource.data.userId != incidents.data.userId` (el dueño no puede votarse a sí mismo).
- **Razón:** descentraliza la verificación, reduce carga del admin y mejora confianza del sistema.
- **Estimación:** 6 h.
- **Riesgo:** medio. Hay que pensar el caso de abuso (sybil attacks): mitigado por el filtro `status: active` y por el sistema de reputación de usuario que ya existe.

#### **F-05: Validación bilateral al cerrar el reporte**

- **Cubre:** O5
- **Descripción:** cuando admin o referente cambia el estado a `solucionado`, el reporte queda en un sub-estado `solucionado_pendiente_confirmacion`. El reportero recibe una notificación push (vía FCM, infra ya lista por T-NLP-07) y al abrir su reporte ve dos botones: **"Confirmar solución"** → estado pasa a `solucionado_confirmado`; **"Disputar"** → vuelve a `enReparacion` con una nota obligatoria del reportero. Si no responde en X días (configurable, default 7), pasa automáticamente a `solucionado_confirmado`.
- **Backend:** Cloud Function programada (Cloud Scheduler) que cierra automáticamente los pendientes vencidos. O un check on-read en el cliente.
- **Razón:** evita que admins distraídos cierren reportes sin solución real. Empodera al reportero. Es exigencia del docente.
- **Estimación:** 8 h.
- **Riesgo:** medio (estados nuevos en el enum, migración de incidentes existentes).

#### **F-06: Evidencia opcional al cerrar el reporte**

- **Cubre:** O6
- **Descripción:** cuando admin/referente pasa el estado a `solucionado`, la UI ofrece subir una foto como evidencia (no obligatoria). Si se sube, se guarda en `resolutionEvidenceUrl` en el doc y se muestra en el detalle del incidente (tanto al reportero como a otros vecinos).
- **Razón:** cierre transparente y verificable. Mejora confianza.
- **Backend:** mismo flujo de Storage que ya usamos para `photoUrl` y `identityProofUrl`.
- **Estimación:** 3 h.
- **Riesgo:** bajo. Reutiliza patrones existentes.

### 🌊 Wave 3 — Cobertura geográfica avanzada (mayor esfuerzo)

#### **F-07: Área de cobertura como polígono**

- **Cubre:** O7
- **Descripción:** `CoverageConfig` pasa a tener un campo `polygonPoints: List<LatLng>` opcional. Si está presente, la validación de cobertura usa un algoritmo de **point-in-polygon** (`ray casting`) en lugar de Haversine. La pantalla del admin (`CoverageConfigPage`) gana un modo "Editar polígono" que permite tocar el mapa para agregar/mover/borrar vértices. Se mantiene retrocompatibilidad con el modo círculo (si no hay polígono, sigue usando centro+radio).
- **Backend:** `coverageValidation.ts` (Cloud Functions) implementa también `isWithinPolygon`. Misma lógica de retrocompatibilidad.
- **Razón:** representar zonas urbanas reales (manzanas, sociedades de fomento con jurisdicción irregular).
- **Estimación:** 10 h.
- **Riesgo:** medio-alto. Algoritmo point-in-polygon implementado correctamente (caso del borde, polígonos cóncavos). La UI de edición es no trivial.

---

## 5. Resumen de tareas nuevas

| ID | Nombre | Wave | Estimación | Depende de |
|---|---|---|---|---|
| F-01 | Mis reportes con edición | 1 | 4 h | — |
| F-02 | Definición de cliente objetivo | 1 | 3 h | — |
| F-03 | Selector de ubicación interactivo | 1 | 5 h | — |
| F-04 | Reacciones de la comunidad | 2 | 6 h | F-01 |
| F-05 | Validación bilateral del cierre | 2 | 8 h | T-NLP-07 (push) |
| F-06 | Evidencia opcional al cerrar | 2 | 3 h | T-REP-06 (status update) |
| F-07 | Polígono de cobertura | 3 | 10 h | T-AUTH-06 (coverage actual) |

**Total estimado:** 39 h.
**Recomendación de ejecución:** Wave 1 esta semana, Wave 2 la próxima, Wave 3 al final. Las tres olas son independientes entre sí (las dependencias son con tareas ya cerradas, no entre waves), así que se pueden paralelizar por equipo si conviene.

---

## 6. Convenciones para esta iteración

### 6.1 Branches y commits

Se mantiene el workflow de Segunda Iteración (`docs/WORKFLOW.md`):

- Branch: `feature/equipo-X/F-NN-descripcion-kebab`
- Commit: `feat: [F-NN] Descripción en español`

Ejemplo: `feature/equipo-b/F-01-mis-reportes-edicion` → `feat: [F-01] Sección Mis reportes con edición del reporte propio`.

### 6.2 Documentación obligatoria por feature

**Cada feature debe entregar dos documentos** además del PR:

1. **`docs/features/F-NN-nombre-corto.md`** — escrito al cerrar el PR. Estructura sugerida:

   ```markdown
   # F-NN — Nombre de la funcionalidad

   ## Qué es
   Descripción funcional de qué hace la feature, en lenguaje de producto (no técnico).

   ## Por qué se hizo
   Justificación del valor agregado. Explicar qué observación de los stakeholders cubre y
   por qué esta feature **excede el alcance original** de la Segunda Iteración (esto es
   crítico: el docente lo va a pedir).

   ## Decisiones de diseño
   Alternativas evaluadas y por qué se eligió esta. Tradeoffs aceptados.

   ## Impacto en el sistema
   Qué otros módulos cambian, qué migraciones de datos son necesarias, qué tests existentes
   se ajustan o se rompen.

   ## Limitaciones conocidas
   Cosas que esta versión NO cubre y que pueden ser futuras tareas.

   ## Referencias
   PR, commit, screenshots, video corto de demo si aplica.
   ```

2. **Actualización de `docs/PRODUCT_DEFINITION.md`** (si la feature cambia el journey del usuario o el caso de uso primario).

### 6.3 Tests

Se mantiene el criterio actual: **toda lógica de negocio nueva** debe tener tests unitarios. Los widget tests son recomendados pero no obligatorios (excepto si la feature cambia comportamiento visible al usuario en pantallas críticas como reporte o detalle).

### 6.4 CI/CD

Las features pasan por la misma CI existente (PR-checks). Si una feature requiere deploy de Cloud Functions o de reglas Firestore, debe documentarse en el `.md` de la feature con los comandos exactos.

---

## 7. Justificación del scope expansion (para el docente)

El SRS v1.1 y la Planificación v1.3 cubrieron el **MVP funcional** del sistema: que un vecino pudiera reportar un incidente, que el admin pudiera gestionarlo, y que el motor NLP priorizara los reportes. Ese alcance se cumplió en la Segunda Iteración.

Las features de esta Tercera Iteración **no son funcionalidades opcionales que se "se nos olvidaron"** — son extensiones identificadas durante el uso real que mejoran sustancialmente la utilidad de la app sin las cuales el producto, aunque técnicamente completo, no sirve bien para los casos reales (un reporte rápido sin descripción es casi inútil, un cierre unilateral del admin no inspira confianza, un círculo de cobertura no representa un barrio real).

La planificación original no las contempló porque dependían de **feedback de uso** que solo aparece después del MVP. Es un caso clásico de iteración ágil: cerramos el alcance comprometido, lo entregamos, observamos su uso, y de ese aprendizaje sale la siguiente ronda de prioridades.

---

## 8. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Subestimación de horas (sobre todo F-05 y F-07) | Media | Medio | Empezar por Wave 1 que es bajo riesgo; reajustar Wave 2-3 con datos reales de Wave 1. |
| Migración de incidentes existentes a nuevos sub-estados (F-05) | Media | Alto | Mantener retrocompatibilidad: los incidentes sin sub-estado se tratan como confirmados implícitamente. Migración lazy. |
| UI de polígono compleja en Flutter Web (F-07) | Alta | Bajo | MVP del polígono: ingreso manual por JSON pegado. Editor visual en una sub-tarea posterior si el tiempo lo permite. |
| Conflictos al mergear varias features que tocan el mismo archivo (ej. `incident_event.dart`) | Alta | Bajo | Coordinar orden de merge en el equipo. Wave 1 antes de Wave 2. |

---

## 9. Próximos pasos

1. **Validar este plan con el equipo y el docente** (esta semana).
2. **Crear las tareas en Jira** con IDs `F-01` a `F-07` y los detalles correspondientes.
3. **Arrancar Wave 1** en paralelo (las tres features son independientes).
4. **Documentar cada feature cerrada** según las convenciones de la sección 6.2.
5. **Demo final** al cerrar las tres waves, mostrando antes/después de cada observación.

---

**Última actualización:** 2026-06-22
**Responsable:** Grupo D, UNNOBA 2026

# Devolución — Plan de Tercera Iteración

> Análisis crítico del documento `docs/PLAN_TERCERA_ITERACION.md` contra el SRS v1.1, la
> Planificación de Segunda Iteración v1.3 y el Informe de Viabilidad ajustado V2.
> **Pregunta que responde:** con las siete features (`F-01`…`F-07`) terminadas, ¿la app tiene
> sentido como producto y cumple lo que prometen los documentos?
>
> **Autor:** análisis técnico-de-producto · **Fecha:** 2026-06-23

---

## 1. Veredicto en una línea

**Sí: con `F-01`…`F-07` terminadas, el producto cierra el circuito de valor que prometen los
documentos y deja de ser "técnicamente completo pero pobre en uso real".** El plan está bien
priorizado y bien justificado. Tiene, sin embargo, **tres imprecisiones de encuadre** y **cuatro
huecos técnicos** que conviene corregir antes de mostrarlo al docente y antes de codear.

> ⚠️ **Corrección importante (revisión sobre el código, no sobre los docs).** Las secciones 2-10
> de esta devolución analizaron el plan contra la documentación. Una **segunda pasada leyendo el
> código fuente** reveló que el MVP de la Segunda Iteración **no está realmente cerrado**: hay
> features marcadas como terminadas que están **a medias** (solo la mitad backend, sin cliente) o
> que **contradicen la propuesta de valor**. Esto **matiza el veredicto de arriba**: el producto
> *tiene sentido como diseño*, pero **hoy no es consistente como MVP funcional**. El detalle está
> en la nueva **sección 11**, que es la parte más importante de este documento. La fuente de
> verdad es el código, no `docs/BACKLOG.md` (que está desactualizado).

---

## 2. ¿El producto "tiene sentido" con estas tareas terminadas?

La propuesta de valor declarada en el Informe de Viabilidad descansa en cuatro pilares:
**ciencia ciudadana**, **priorización automática**, **geolocalización operativa** y **trazabilidad /
rendición de cuentas**. El MVP de la Segunda Iteración ya entregó los dos del medio (NLP +
mapa), pero dejó flojos el primero y el último. Las features de esta iteración atacan
exactamente esos dos:

| Pilar del producto (Viabilidad / SRS) | Estado tras Iteración 2 | Qué aporta la Iteración 3 |
|---|---|---|
| Ciencia ciudadana (el vecino como sensor activo) | Reporta, pero no participa después | **F-04** (validación comunitaria) y **F-01** (enriquecer su propio reporte) lo vuelven un actor sostenido, no de un solo toque |
| Priorización automática (NLP) | Completa | **F-04** puede alimentar el score (`confirmationScore` → RF-PRI-03) y darle señal social al motor |
| Geolocalización operativa | Círculo centro+radio | **F-03** (ubicación real del incidente) + **F-07** (polígono) elevan la calidad del dato geográfico |
| Trazabilidad / rendición de cuentas | Cierre unilateral y opaco | **F-05** (confirmación bilateral) + **F-06** (evidencia de resolución) hacen el cierre verificable |

**Conclusión:** ninguna de las siete features es "gold-plating". Cada una tapa un agujero real
entre lo que los documentos prometen y lo que el MVP entrega. El reporte rápido sin contexto
(O1), el cierre sin pruebas (O4/O5/O6) y el círculo de cobertura (O7) eran precisamente los
puntos donde la narrativa de "ciencia ciudadana con trazabilidad" se caía. Terminadas estas
tareas, **la app cumple su propósito declarado de forma coherente**, y de hecho de forma más
completa que el MVP académico exigido.

---

## 3. Dato de contexto positivo: el equipo ya sobre-cumplió el MVP

El SRS §1.4 declaró **fuera del MVP académico**: reporte por voz (RF-REP-02), reputación
(RF-MOD-01), calibración del algoritmo (RF-PRI-04), notificaciones push a la comunidad
(RF-ADM-04) y el rol de Referente Barrial (RF-ROL-02).

El `BACKLOG.md` muestra que **las cinco se implementaron igual** (KAN-52 voz, KAN-46 reputación,
KAN-64 calibración, KAN-67 masivas, KAN-45 referente, todas ✅). Es decir: el equipo ya entregó
por encima del piso comprometido. Esto es **munición a favor** frente al docente: la Tercera
Iteración no nace de un MVP incompleto, sino de uno que ya excedió su alcance y aun así detectó
mejoras de uso. Conviene decir esto explícitamente en la defensa.

---

## 4. Imprecisiones de encuadre (corregir antes de mostrarlo al docente)

El punto más delicado del plan es su **sección 7 ("Justificación del scope expansion")**, que
afirma que **todas** las features "exceden el alcance original". Eso **no es exacto** para cuatro
de las siete, y el docente —que va a tener el SRS a mano— puede detectarlo. Es mejor adelantarse.

### 4.1 `F-07` (polígono) **ya estaba en el SRS**, no lo excede
El SRS lo dice dos veces, literalmente:
- **RF-REP-01 (nota de cobertura):** "…un perímetro geográfico representado como **polígono o
  radio** sobre el mapa…".
- **RF-ADM-01** y la descripción del Panel de Administración asumen esa misma área.

El MVP **descopeó** el polígono a círculo (centro+radio, vía `T-AUTH-06`). Entonces `F-07` no es
alcance nuevo: es **completar un requisito especificado que se había recortado**. Encuadrarlo
como "extensión que excede el SRS" es un autogol; encuadrarlo como "cierre de deuda del MVP"
es más fuerte y más honesto.

### 4.2 `F-01` (Mis reportes) **traza al SRS §3.1.1**
La interfaz móvil del SRS incluye explícitamente "**historial de reportes propios** y estado de
resolución". La edición posterior sí es agregado, pero la pantalla en sí estaba prevista. Es
`ajuste-feedback`, no `extra`.

### 4.3 `F-02` y `F-03` ajustan cosas existentes
- `F-02` (cliente objetivo): el cliente **ya está definido** en el Informe de Viabilidad
  ("Municipios, Comunas, Sociedades de Fomento", caso Junín BA) y en el SRS §1.4 / §2.3. `F-02`
  no lo inventa: lo **operacionaliza** en persona/journey. Es documentación de afinamiento.
- `F-03` (selector de ubicación): ajusta el flujo de captura de `RF-REP-01`. Además, encaja con
  una mitigación ya escrita en el Informe de Viabilidad ("validación cruzada con dirección
  ingresada" para el riesgo de geolocalización). No es alcance nuevo.

**Las únicas tres que sí exceden el SRS son `F-04`, `F-05` y `F-06`** (reputación *por reporte*,
cierre bilateral y evidencia de resolución). Solo esas necesitan la justificación de scope.
Esta distinción ya quedó reflejada en la sección 6.5 del plan (labels `extra` /
`ajuste-feedback`); la sección 7 debería alinearse con ella en vez de meter las siete en la
misma bolsa.

> **Recomendación:** reescribir la primera frase de la sección 7 para distinguir
> "**completar alcance especificado pero descopeado**" (F-01, F-02, F-03, F-07) de
> "**ampliar el SRS**" (F-04, F-05, F-06). Es un cambio de una frase y blinda el documento.

---

## 5. Huecos técnicos (corregir antes de codear)

### 5.1 `F-05` necesita reglas Firestore nuevas — el plan dice "ninguno/Cloud Function" pero omite el permiso del reportero
Hoy, `firestore.rules:94-100` permite al **dueño** editar su incidente **solo mientras
`status == 'recibido'`** y le **prohíbe** tocar `status`, `priority`, `priorityScore`, `userId`.
`F-05` exige que el reportero, sobre un incidente ya en `solucionado_pendiente_confirmacion`
(es decir, `status != 'recibido'` **y** un campo de estado), pueda **confirmar o disputar**. Con
las reglas actuales eso queda **bloqueado**. Hace falta una regla nueva del estilo:

> el dueño puede actualizar **únicamente** el campo de confirmación (`closureConfirmation` o
> equivalente) cuando el incidente está en el sub-estado pendiente, sin tocar ningún otro campo.

Esto **no está mencionado** en F-05 (que solo habla de Cloud Function + enum). Es el cambio de
seguridad más sensible de la iteración y debe documentarse en el `.md` de la feature.

### 5.2 Modelar el sub-estado de cierre **fuera** del enum principal (SOLID / separación de responsabilidades)
F-05 propone agregar `solucionado_pendiente_confirmacion` y `solucionado_confirmado` al enum de
estados. Eso **contamina** la máquina de estados limpia que el SRS RF-ADM-02 expone al usuario
(Recibido → Programado → En Reparación → Solucionado) y obliga a migrar incidentes existentes.

Alternativa más limpia: mantener `status` con sus 4 valores y agregar un campo **ortogonal**
`closureConfirmation: { state: pendiente | confirmado | disputado, by, at, note }`. Ventajas:
- No rompe el enum documentado ni las pantallas que ya lo consumen (`T-REP-06`).
- Migración trivial: incidentes viejos = `closureConfirmation` ausente → se tratan como
  confirmados implícitos (la propia mitigación que el plan ya propone, pero sin tocar el enum).
- Es la separación de concerns correcta: "en qué etapa está la reparación" vs. "el reportero
  validó el cierre" son dos dimensiones distintas.

### 5.3 El snippet de regla de `F-04` no compila como está
El plan escribe:
`… && resource.data.userId != incidents.data.userId` (el dueño no puede votarse).
`incidents.data` **no es una referencia válida** dentro del match de la subcolección
`incidents/{id}/reactions/{userId}`. Hay que leer el doc padre con `get()`:
`get(/databases/$(database)/documents/incidents/$(id)).data.userId`. Además, como hoy hay un
**default-deny** al final de las reglas (`firestore.rules:128-130`), la subcolección `reactions`
**no existe a nivel reglas**: F-04 **sí** requiere un bloque `match` nuevo (el plan acierta al
decir que toca reglas, pero el sketch concreto está mal).

### 5.4 `F-04` vs. Referente Barrial: hay solapamiento de rol que conviene resolver en el diseño
El SRS RF-ROL-02 hace del **Referente Barrial** el que "confirma o descarta" incidentes en campo
(es su razón de ser). `F-04` reparte ese poder de confirmación a **todos los vecinos activos**.
Si no se articula, `F-04` **diluye** un rol que el SRS definió con cuidado. Encuadre sugerido:
- Vecinos (`F-04`) = **señal social blanda** (triage, "esto le pasa a más gente"), no autoritativa.
- Referente (RF-ROL-02) = **validación de campo autoritativa**, con peso distinto en el score.

Documentar esta jerarquía evita que el docente pregunte "¿y entonces para qué está el referente?".

---

## 6. Observaciones que el plan cubre solo parcialmente

- **O4 pide dos cosas:** (a) reglas claras de qué condiciones se deben cumplir para cerrar un
  reporte, y (b) que la reputación del reporte mejore con interacciones. El plan resuelve (b) con
  `F-04`, pero **(a) — el "definition of done" del cierre — queda sin dueño**. Sugerencia: definir
  criterios de cierre explícitos (p. ej. "no se puede pasar a `solucionado` sin evidencia `F-06`
  **o** sin N confirmaciones de comunidad") y dejarlo escrito, aunque la implementación sea
  mínima. Hoy `F-05` cubre el "quién valida", pero no el "bajo qué condiciones".

---

## 7. Riesgo de planificación: timeline

La Planificación v1.3 fijó **fecha límite 26/06/2026** (8 semanas, 224 h de equipo ya
presupuestadas y consumidas en la Iteración 2). El plan de Tercera Iteración propone **39 h
adicionales** repartidas en tres olas ("esta semana / la próxima / al final"). A la fecha de esta
devolución (**23/06/2026**) **restan ~3 días** del calendario original.

Esto **no invalida** el plan, pero exige **reconciliar fechas explícitamente**: o el docente
extendió el cronograma (lo cual habilita la Tercera Iteración y debería citarse), o estas 39 h
exceden la ventana comprometida y hay que re-priorizar. **Recomendación concreta:** si el tiempo
es real, ejecutar **solo Wave 1** (F-01/F-02/F-03, 12 h, bajo riesgo, alto valor visible para la
demo) y dejar Waves 2-3 como *backlog comprometido y documentado* pero no necesariamente
entregado. Es la jugada que mejor combina riesgo y narrativa.

---

## 8. Cosas que el plan hace bien (para no perderlas)

- **Priorización valor/esfuerzo correcta:** Wave 1 ataca lo barato y visible; deja el polígono
  (lo más caro y riesgoso) al final. Es el orden correcto.
- **Disciplina de documentación por feature** (`docs/features/F-NN-*.md`) y **TDD para lógica de
  negocio** (sección 6.3) — alineado con cómo veníamos trabajando. Las tres con lógica testeable
  de verdad son `F-04` (cálculo de `confirmationScore`), `F-05` (transiciones + auto-cierre) y
  `F-07` (point-in-polygon: testear borde, polígono cóncavo, vértice). El plan ya lo señala.
- **Retrocompatibilidad** pensada en F-05 y F-07 (lazy migration, fallback a círculo).
- **Trazabilidad** de cada feature a una observación (O1…O7). Es exactamente lo que el docente
  premia.

---

## 9. Recomendaciones priorizadas

1. **(Encuadre, 10 min)** Reescribir la sección 7 para separar "completar lo descopeado"
   (F-01/02/03/07) de "ampliar el SRS" (F-04/05/06). Citar RF-REP-01/RF-ADM-01 para el polígono y
   SRS §3.1.1 para "Mis reportes".
2. **(Defensa, 5 min)** Agregar el dato del §3 de esta devolución: el equipo ya superó el MVP
   académico; la Iteración 3 sale de un producto que ya excedió su piso.
3. **(Diseño F-05, antes de codear)** Adoptar el campo ortogonal `closureConfirmation` en vez de
   inflar el enum de `status`, y documentar la **nueva regla Firestore** que habilita al reportero
   a confirmar/disputar.
4. **(Diseño F-04, antes de codear)** Corregir el sketch de regla (usar `get()` del doc padre) y
   articular la jerarquía vecino-señal-blanda vs. referente-validación-autoritativa.
5. **(Alcance O4)** Definir y escribir el "definition of done" del cierre de un reporte
   (condiciones), no solo el quién valida.
6. **(Timeline)** Reconciliar las 39 h con la fecha 26/06; si el tiempo es real, comprometer solo
   Wave 1 como entregable y el resto como backlog documentado.

---

## 10. Resumen de la categorización (para los tickets de Jira)

Coincide con la sección 6.5 del plan. Solo F-04, F-05 y F-06 son alcance nuevo real.

| Ticket | Categoría | Origen | Traza a |
|---|---|---|---|
| F-01 | `ajuste-feedback` | Uso real (O1) | SRS §3.1.1 (historial propio) |
| F-02 | `ajuste-feedback` | Docente (O2) | Viabilidad + SRS §1.4/§2.3 (cliente ya definido) |
| F-03 | `ajuste-feedback` | Uso real (O3) | RF-REP-01 (captura de ubicación) |
| F-04 | `extra` | Docente (O4) | **Nuevo** (RF-MOD-01 es reputación por usuario, no por reporte) |
| F-05 | `extra` | Docente (O5) | **Nuevo** (RF-ADM-02 es cierre unilateral) |
| F-06 | `extra` | Uso real (O6) | **Nuevo** (evidencia de resolución no está en SRS) |
| F-07 | `ajuste-feedback` | Docente (O7) | RF-REP-01 / RF-ADM-01 ("polígono o radio") |

---

## 11. Gaps del MVP detectados en el código (verificados) — **lo más importante**

> Esta sección **no** sale de los documentos ni de `BACKLOG.md`. Sale de leer el código fuente
> (`lib/`, `functions/src/`, `firestore.rules`, `pubspec.yaml`). Cada hallazgo cita archivo y
> línea. Conclusión global: **varias funcionalidades marcadas como "terminadas" están a medias o
> son inconsistentes con la propuesta de valor.** Antes de extender el alcance (Iteración 3),
> esto es lo que falta para que el MVP planificado sea realmente consistente.

### 11.1 🔴 CRÍTICO — El sistema de alertas push está muerto de punta a punta

**Es el diferenciador #1 de todo el producto** (Informe de Viabilidad: "Sistema de alertas push…
notifica únicamente a los referentes barriales operativos en el radio del incidente",
"reducir la fatiga de alertas" es *la* ventaja competitiva headline). **No funciona.**

- El backend está completo: `functions/src/index.ts:294-321` busca referentes cercanos y manda
  push; `functions/src/pushNotifications.ts:46-96` filtra por `fcmTokens` + `coverageLat/Lng`.
- **Pero el cliente nunca registra un token FCM.** `firebase_messaging: ^15.1.3` está declarado en
  `pubspec.yaml:18` pero **no se importa ni se usa en ningún lugar de `lib/`** (sin
  `getToken()`, sin `requestPermission()`, sin `onMessage`/`onMessageOpenedApp`).
- El `UserModel` (`lib/features/auth/data/models/user_model.dart`) **no tiene campo `fcmTokens`**;
  nunca se escribe.
- **Segunda capa del mismo problema:** `findNearbyReferentes` también exige `coverageLat`/
  `coverageLng` por referente (`pushNotifications.ts:70-73`), y esos campos **tampoco se escriben
  nunca** (grep: `coverageLat`/`coverageLng` solo se leen/serializan en `user_model.dart`; ninguna
  pantalla los setea — `CoverageConfigPage` configura el doc **global** `config/coverage`, no la
  ubicación de cada referente). Así que aunque se arregle el token, el referente igual sería
  descartado por no tener ubicación. **D-01 debe incluir capturar y persistir la ubicación del
  referente.**
- Resultado: `findNearbyReferentes` descarta a todo referente sin `fcmTokens`
  (`pushNotifications.ts:66`) → `allTokens.length === 0` → "No FCM tokens found"
  (`pushNotifications.ts:112-114`) → **no se envía ninguna notificación, jamás.**
- Esto rompe **RF-SAL-01 / T-NLP-07** (alertas geolocalizadas al referente) **y RF-ADM-04 /
  T-NLP-09** (notificaciones masivas del admin): ambas dependen del mismo token inexistente.

**Diagnóstico:** T-NLP-07 se cerró con la mitad backend hecha y la mitad cliente sin hacer. El
push es invisible end-to-end. Sin esto, el referente barrial no se entera de nada y la tesis de
"ciencia ciudadana con alertas focalizadas" no se sostiene en la demo.

### 11.2 🔴 CRÍTICO — Contradicción: el vecino no puede ver el "mapa del barrio"

El SRS §3.1.1 promete al vecino un "**mapa de incidencias activas del barrio**" y toda la tesis de
ciencia ciudadana ("visibilizar", "red de sensores") depende de que el vecino vea reportes de
otros. **El código y las reglas dicen lo contrario.**

- El `MapPage` y el `HomePage` consumen `watchIncidents()`, que hace una query **sin filtro de
  `userId`** (`lib/features/incidents/data/datasources/incidents_remote_datasource.dart:65-68`;
  `watchActiveIncidents` solo filtra por estado en memoria, mismo origen sin filtro:
  `incidents_repository_impl.dart:21-28`).
- Las reglas Firestore solo dejan al vecino leer **sus propios** incidentes:
  `resource.data.userId == request.auth.uid || isAdminOrReferente()` (`firestore.rules:80-83`).
- En Firestore, **una query sin el `where('userId','==',uid)` que la regla exige se rechaza
  entera con `permission-denied`** (las reglas no filtran, validan). El `/map` no tiene guard de
  rol en el router (`lib/app/router.dart:153-158`): es para todos.
- **Por lo tanto, para un vecino base, el inicio y el mapa muy probablemente fallan con error de
  permisos.** El admin/referente no lo nota porque `isAdminOrReferente()` deja pasar la query.
  (Síntoma a confirmar ejecutando como vecino; la contradicción de diseño es segura.)

**La decisión de fondo que hay que tomar:** ¿el vecino ve el barrio (hay que **ampliar las reglas**
para que lea incidentes activos no rechazados, cuidando no exponer identidad del reportero) o el
vecino ve solo lo suyo (hay que **filtrar las queries por `userId`** y asumir que el "mapa del
barrio" del SRS **no se entrega**)? Hoy el producto está en una tierra de nadie donde la regla
dice una cosa y la UI intenta otra. Esto es central para "¿es consistente el producto?".

### 11.3 🔴 ALTO — La derivación a 911/107 (RF-PRI-05) no le llega al usuario + enum desalineado

RF-PRI-05 es un "**deberá**" y el Informe de Viabilidad §4 lo nombra *el principal riesgo*,
mitigado por "derivar automáticamente al 911/107". El backend lo detecta; el usuario nunca lo ve.

- El backend marca el incidente con `status: "vital_risk_detected"` (`functions/src/index.ts:183`)
  y corta el pipeline. **Ese valor no existe en el enum `IncidentStatus` de Flutter**
  (`lib/features/incidents/domain/entities/incident_event.dart:63-93`), cuyo `fromString` cae al
  default `recibido` (línea 82). → **Un incidente de riesgo vital se le muestra a todos como
  "Recibido"**, sin ninguna alerta.
- `VitalRiskDetectedException` (`lib/core/errors/app_exception.dart:22`) y los strings
  `vitalRiskTitle` / `emergencyCall911` / `emergencyCall107` (`lib/core/constants/app_strings.dart:69-75`)
  están **definidos pero nunca usados**. No hay diálogo de emergencia en ningún flujo de reporte.
- Mismo problema con `status: "rechazado_autor_inactivo"` (`index.ts:83`): tampoco está en el enum
  → se muestra como "Recibido".

**Diagnóstico:** el andamiaje de UX de riesgo vital se dejó preparado pero nunca se cableó, y el
contrato de estados backend↔cliente quedó desincronizado.

### 11.4 🟡 MEDIO — No hay disclaimer de seguridad ni Términos y Condiciones

No existe ninguna pantalla de aviso/consentimiento en `lib/` (búsqueda de
termin/consent/aviso/disclaimer sin resultados de UI). El Informe de Viabilidad mitiga el riesgo
"**Responsabilidad Civil**" con "Términos y condiciones claros" y nombra un "flujo de advertencia
obligatorio (disclaimer)". No implementado. Es barato y es escudo legal + claridad de propósito
(además ayuda a O2, la observación del docente sobre el enfoque del producto).

### 11.5 🟡 MEDIO — El Referente Barrial no puede confirmar/descartar in situ (RF-ROL-02b)

`lib/features/alerts/presentation/pages/referent_alerts_page.dart` es **solo lectura**: lista
alertas y abre el detalle. RF-ROL-02(b) exige "marcarlos como **'Confirmado' o 'Descartado'** con
evidencia fotográfica" — otro "deberá". El rol que el SRS define con cuidado quedó a mitad de
construir. **Ojo con F-04:** le da el poder de confirmación a *todos* los vecinos, pero al
referente —cuya razón de ser es exactamente esa— se lo dejó afuera. Hay que resolver la jerarquía
(ver §5.4) y completar la acción del referente.

### 11.6 🟡 MEDIO — RF-ADM-03 a medias: sin categoría manual ni registro de acciones

RF-ADM-03 dice que el admin "**deberá** asignar cada incidente a una categoría… y **registrar las
acciones tomadas para su resolución**". En el detalle (`lib/features/incidents/presentation/pages/incident_detail_page.dart`)
el admin puede cambiar estado y marcar falso, pero **no hay UI ni campo** para (re)asignar la
categoría (hoy solo la pone el NLP, sin corrección humana) ni para registrar acciones/notas de
resolución. El `IncidentEvent` no tiene `resolutionNotes`/`actions`. Es la base de la
"trazabilidad / rendición de cuentas" prometida.

### 11.7 🟢 BAJO/MEDIO — La máquina de estados no se valida; doble camino a "falso"

El dropdown de estado (`incident_detail_page.dart:169-174`) expone **todos** los
`IncidentStatus.values`, incluidos `falso` y `rechazadoFueraDeCobertura`, como transición manual
libre. Marcar `falso` por el dropdown **no** dispara el decremento de reputación (eso solo ocurre
por el callable `moderateFalseReport` / el botón "Marcar como falso"). Hay **dos caminos a 'falso'
con efectos distintos**, y no se valida el orden del ciclo (se puede saltar `recibido →
solucionado` o ir hacia atrás). Esto se conecta con **O4** (reglas claras de cierre) y con **F-05**:
conviene resolver la integridad del ciclo de estados cuando se toque el cierre.

### 11.9 🔴 ALTO — El decremento de reputación nunca se ejecuta (mismatch de campo)

RF-MOD-01/RF-MOD-03: "cada reporte marcado como falso **decrementa** la reputación". **No ocurre.**

- `reputationManager.ts:32` aplica el −15 solo cuando el campo **`verifiedAsFalse`** pasa a `true`.
- Pero `verifiedAsFalse` **no se escribe en ninguna parte** del código de producción (grep: solo
  aparece en `reputationManager.ts` y en su propio test). El flujo real de moderación
  (`moderation.ts:90-95`) escribe **`moderatedAsFalse`** y `status: "falso"` — **otro nombre de
  campo.**
- Consecuencia: marcar un reporte como falso incrementa `falseReportsCount` y puede bloquear al
  usuario, **pero la reputación nunca baja**. En la práctica la reputación es monótona creciente
  (+5 al pasar a programado/en_reparacion/solucionado). El sistema de reputación —mitigación #1
  del riesgo "reportes falsos" en el Informe de Viabilidad— está **a medias**.
- ⚠️ **Trampa de tests:** `reputationManager.test.ts` pasa en verde porque setea `verifiedAsFalse`
  a mano. Es un caso donde **los tests unitarios verdes esconden una integración rota**. Buen
  recordatorio de por qué "tests pasan" ≠ "el MVP es consistente".
- **Efecto dominó:** como la reputación nunca baja, **toda la superficie de moderación basada en
  reputación es decorativa**: el warning "Baja reputación (< 30)" y el filtro de baja reputación
  en `users_management_page.dart:567,202` nunca se activan en la práctica (ningún usuario llega a
  < 30 por reportes falsos). Arreglar D-08 "enciende" también esa UI.

### 11.10 🔴 ALTO (seguridad) — No hay `storage.rules`; comprobantes de identidad (PII) sin proteger en código

- `firebase.json` configura `firestore.rules`, índices y functions, pero **no tiene bloque
  `storage`**, y **no existe ningún archivo `storage.rules`** en el repo.
- Firebase Storage guarda fotos de incidentes (`incidents/{userId}/…`) y **comprobantes de
  servicio/domicilio** (`identityProofUrl`, T-AUTH-09) — esto último es **PII sensible**.
- Sin reglas de Storage versionadas, la protección de esos archivos queda librada a la
  configuración de consola (típicamente test-mode permisivo o expirado). El comentario en
  `user_model.dart:33-38` se preocupa por la sensibilidad del comprobante pero confía en reglas
  de **Firestore** — que **no gobiernan los binarios de Storage**.
- **Riesgo:** que cualquier usuario autenticado (o peor) pueda leer comprobantes de domicilio de
  otros vecinos. Es exactamente el tipo de exposición de PII que hay que cerrar antes de
  considerar el MVP "entregable". **Acción:** agregar `storage.rules` (comprobante visible solo
  para dueño + admin; fotos de incidente con la política que corresponda) y referenciarlo en
  `firebase.json`. *(Verificar también la config actual del bucket en consola.)*

### 11.11 🟢 BAJO — El reporte por voz se persiste como `form` (RF-REP-02)

En `report_form_page.dart:181-187` el modo voz transcribe al campo de texto y luego envía por
`_submit()` → `submitForm` (`sourceType: form`). El caso de uso dedicado `submitVoice` /
`SubmitVoiceReportUseCase` está cableado en el provider pero **nunca se invoca** desde la UI
(grep sin call-site). El reporte por voz funciona como *input*, pero se registra con el tipo
equivocado y el "Reporte Abreviado / voice" del SRS no se produce nunca. Divergencia menor del
contrato T-INF-04, pero contamina cualquier métrica/auditoría por `sourceType`.

> **Nota arquitectónica sobre D-03 (riesgo vital):** el reporte hoy es un *fire-and-forget* a
> Firestore (`report_form_page.dart:120-144` muestra "enviado con éxito" y navega a home **antes**
> de que el pipeline corra). Por eso la derivación a 911/107 **no puede** surgir del flujo actual:
> requiere decidir entre (a) convertir el envío en un **callable síncrono** que devuelva el
> veredicto de riesgo vital, o (b) un **listener** sobre el doc del incidente que abra el diálogo
> cuando aparezca `vital_risk_detected`. D-03 es, por esto, más que "cablear la excepción".

### 11.8 Tablero de tickets — Deuda de MVP (`deuda-mvp`)

> **Este es el backlog accionable de la pre-entrega.** Todos los tickets van bajo **una sola
> categoría: `deuda-mvp`**. No son `extra` ni `ajuste-feedback` de producto: son **deuda del MVP
> planificado** (funcionalidad ya especificada como "deberá" que quedó a medias). Se cierran
> **antes de la entrega**, idealmente antes o en paralelo a la Wave 1 de la Iteración 3.
>
> **Convención Jira** (igual que las features, ver `docs/PLAN_TERCERA_ITERACION.md` §6.5): proyecto
> `KAN`, tipo `Tarea`, summary `[D-NN] Nombre`, **épica nueva "Deuda de MVP"**, **label único
> `deuda-mvp`**. Branch/commit: `[D-NN]` igual que `[F-NN]`.
>
> **Cómo se actualiza este tablero** (para trabajarlo con Claude Code e ir commiteando el avance):
> cambiar el ícono de **Estado** según la leyenda — ⬜ Por hacer · 🔄 En curso · 🔍 En revisión ·
> ✅ Finalizado — y, al cerrar cada ticket, marcar como ✅ los **flujos de §12** que ya pasan.

| Estado | ID | Tarea | Sev | Cierra (RF/Doc) | Valida (flujo §12) |
|---|---|---|---|---|---|
| ⬜ | D-01 | Registrar token FCM + permisos + handlers de push en el cliente; persistir `fcmTokens` **y** `coverageLat/Lng` del referente | 🔴 Crítico | RF-SAL-01 / T-NLP-07 + RF-ADM-04 | R2, A10, P8, V13 |
| ⬜ | D-02 | Resolver visibilidad del vecino: alinear reglas Firestore con el "mapa del barrio" (o filtrar queries por `userId` y asumir el recorte) | 🔴 Crítico | SRS §3.1.1 + `firestore.rules:80-83` | V8, V11 |
| ⬜ | D-03 | Cablear derivación a 911/107 en el reporte + agregar `vital_risk_detected` y `rechazado_autor_inactivo` al enum | 🔴 Alto | RF-PRI-05 + Viab. §4 | V7, P2, P5 |
| ⬜ | D-04 | Disclaimer de seguridad + Términos y Condiciones en el onboarding | 🟡 Medio | Riesgo "Responsabilidad Civil" | (nueva pantalla de onboarding) |
| ⬜ | D-05 | Acción del Referente: confirmar/descartar in situ con foto | 🟡 Medio | RF-ROL-02(b) | R4 |
| ⬜ | D-06 | RF-ADM-03: (re)asignar categoría manual + registrar acciones/notas de resolución | 🟡 Medio | RF-ADM-03 | A7 |
| ⬜ | D-07 | Integridad de la máquina de estados (un solo camino a 'falso'; respetar el ciclo) | 🟢 Bajo | RF-ADM-02 / O4 | A5 |
| ⬜ | D-08 | Arreglar el decremento de reputación: unificar `verifiedAsFalse`/`moderatedAsFalse` (que moderación escriba el campo que lee reputación) | 🔴 Alto | RF-MOD-01 / RF-MOD-03 | A6, P9 |
| ⬜ | D-09 | Agregar `storage.rules` (comprobante solo dueño+admin; fotos según política) y referenciarlo en `firebase.json` | 🔴 Alto (seg) | RNF-SEG / T-AUTH-09 | V12 |
| ⬜ | D-10 | Persistir el reporte por voz con `sourceType: voice` (usar `submitVoice`) | 🟢 Bajo | RF-REP-02 | V5 |

La **evidencia** de cada ticket está en su subsección (§11.1–§11.11). El **criterio de aceptación**
de cada uno es que los flujos de la columna "Valida" pasen en la matriz de §12.

**Prioridad de cierre:** D-01, D-02, D-08 y D-09 primero (rompen la propuesta de valor, el rol
base, la reputación o la seguridad de PII). D-03 por su peso legal. D-04…D-07 y D-10 después.

> Nota: se omitió a propósito la tarea de testing que se había numerado en una iteración previa de
> este análisis — el `docs/BACKLOG.md` está desactualizado y no se quiso afirmar el estado de la
> suite sin verificarlo (queda como ítem 7 del checklist de runtime, §11.13).

### 11.12 Alcance de esta auditoría (qué cubrí y qué no)

Auditoría **estática** (lectura de código, sin ejecutar nada). Cubre prácticamente toda la
superficie relevante para la consistencia de producto.

**Auditado en detalle (Flutter):** flujo de reporte (rápido/formulario/voz + `voice_report_widget`),
home, mapa, detalle de incidente, moderación de incidentes, alertas de referente, router/RBAC,
gestión de usuarios (`users_management_page`), broadcast (`admin_broadcast_page`), config de
cobertura (`coverage_config_page`), `main.dart`, modelos y entidades de incidente y usuario
(`incident_event`, `user_model`, `app_user`), datasource de auth (`auth_remote_datasource`),
uploader de comprobante (`identity_proof_uploader`), providers de incidentes.

**Auditado en detalle (backend/infra):** pipeline `index.ts` completo, `pushNotifications.ts`,
`adminBroadcast.ts`, `coverageValidation.ts`, `reputationManager.ts`, `moderation.ts`,
`vitalRiskDetection.ts`, `firestore.rules`, `firebase.json`, `pubspec.yaml`.

**NO leído en detalle (riesgo bajo, no esperaría gaps de consistencia mayores):**
`algorithm_config_page` / `identity_verification_config_page` / `admin_dashboard_page` / `profile_page`
/ `splash` / `app.dart` / `main_shell` (UI de config/navegación), y los flows NLP internos
`semanticExtraction` / `priorityCalculation` / `incidentNormalization` / `incidentEnrichment` /
`incidentDuplicates` / `incidentPersistence` / `algorithmConfig` / `genkit` (su corrección
funcional se ve indirectamente en `index.ts`; lo que **no** es verificable estáticamente es su
**precisión**, que es justamente lo que miden los RNF).

**No verificable sin ejecutar (queda para runtime, ver §11.13):** RNF-PRE-02 (precisión ≥80%),
RNF-PRE-03 (≤10% falsos positivos), RNF-REN (tiempos), el `permission-denied` del rol vecino
(§11.2), y el **estado real de la suite de tests** (no la corrí; y como muestra §11.9, verde no
garantiza integración correcta).

**Conclusión sobre "¿queda todo consistente con estos cambios?":** cerrar `D-01…D-10` +
`F-01…F-07` resuelve **todos los gaps que encontré en la auditoría estática**, que ya cubre la
superficie relevante. Pero "consistente" exige además que cada arreglo se implemente bien **y se
valide end-to-end** — no solo con unit tests verdes. Por eso la respuesta honesta sigue siendo:
**con estos cambios el MVP queda consistente *en diseño*; la confirmación final depende de ejecutar
el checklist de §11.13.**

### 11.13 Checklist de verificación en runtime (para que lo ejecute otra persona)

> Ninguno de estos requiere cambios de código; son comprobaciones de ejecución que esta auditoría
> estática no puede hacer. Marcar resultado y fecha.

1. **Rol vecino (confirma §11.2):** crear/usar una cuenta `vecino_informante` *active* y abrir
   Home y Mapa. **Esperado si el bug existe:** error `permission-denied` (o lista vacía). Si carga
   bien, revisar si en realidad solo ve sus propios incidentes. Comando para mirar reglas vs.
   query: correr el emulador (`firebase emulators:start`) y observar la consola.
2. **Push de alerta (confirma §11.1):** con un referente con app abierta, crear un incidente
   urgente dentro de cobertura. **Esperado hoy:** no llega push; en logs de Functions aparece
   "No FCM tokens found for nearby referentes".
3. **Broadcast (confirma §11.1):** admin envía un broadcast. **Esperado hoy:** `successCount: 0`.
4. **Riesgo vital (confirma §11.3):** reportar por formulario un texto con término crítico
   (p. ej. "hay una persona electrocutada"). **Esperado hoy:** no aparece diálogo 911/107; el
   incidente queda con `status: vital_risk_detected` en Firestore pero se muestra como "Recibido".
5. **Decremento de reputación (confirma §11.9):** marcar un reporte como falso y mirar el
   `reputationScore` del autor en Firestore. **Esperado hoy:** **no baja** (solo sube
   `falseReportsCount`).
6. **Seguridad de Storage (confirma §11.10):** intentar abrir la URL de un `identity_proofs/{uid}`
   sin estar autenticado / con otra cuenta. **Esperado a verificar:** si abre, los comprobantes de
   domicilio (PII) están expuestos.
7. **Suite de tests:** correr `flutter test` y `npm --prefix functions test`. Registrar qué pasa,
   qué falla y la cobertura real. **Recordatorio:** el verde de `reputationManager.test.ts` no
   refleja el camino de producción (§11.9).
8. **RNF de IA:** preparar un set de ~20 incidentes etiquetados y medir precisión de prioridad
   (objetivo RNF-PRE-02 ≥ 80%) y falsos positivos de "Urgente" (RNF-PRE-03 ≤ 10%).

> **Para la demo / defensa:** si el tiempo apremia, una app que **deriva emergencias**, **muestra
> el mapa del barrio al vecino** y **manda push al referente** (D-01/D-02/D-03) es mucho más
> defendible que uno con F-04/F-05/F-06 nuevas sobre un MVP cuyo diferenciador headline no
> funciona. Cerrar la deuda del MVP **es** la prioridad de consistencia.

---

## 12. Flujos funcionales a probar (matriz de aceptación + caza de bugs)

> Esta es la lista de **recorridos end-to-end** que deben andar para que la app sea funcional y
> consistente con el SRS v1.1 / Informe de Viabilidad / Planificación v1.3. Sirve para **dos cosas**:
> (a) como **plan de aceptación** (¿la app hace lo que el documento promete?) y (b) como **guía de
> caza de bugs** (cada fila apunta a dónde se rompe hoy). Es el complemento dinámico de la auditoría
> estática: si alguien ejecuta esto, valida o refuta cada hallazgo de la §11.
>
> **Leyenda de "Estado hoy":** ✅ debería andar · ⚠️ anda parcial / con bug conocido · ❌ no
> implementado o roto end-to-end. Entre paréntesis, la tarea que lo arregla (`D-0X` deuda de MVP,
> `F-0X` Iteración 3).

### 12.1 Vecino Informante

| # | Flujo a probar | Valida (RF/Doc) | Resultado esperado | Estado hoy |
|---|---|---|---|---|
| V1 | Registro abierto → cuenta `pending` → pantalla "en revisión" | RF-ROL-01 / T-AUTH-01 | No accede a la app hasta ser aprobado | ✅ |
| V2 | Login, logout, reset de contraseña | RF-ROL-01 / T-AUTH-02 | Sesión persistente; mensajes de error claros | ✅ |
| V3 | Reporte rápido (botón GPS) dentro de cobertura | RF-REP-01 | Se crea incidente `recibido` y el pipeline lo prioriza | ✅ |
| V4 | Reporte por formulario con foto (mobile y web) | RF-REP-03 | Sube foto a Storage y persiste el incidente | ✅ |
| V5 | Reporte por voz (transcripción on-device) | RF-REP-02 | El reporte se guarda con `sourceType: voice` | ⚠️ se guarda como `form` (D-10) |
| V6 | Reporte fuera del área de cobertura | RF-MOD-02 / T-AUTH-06 | Se bloquea con mensaje "fuera de cobertura" | ✅ |
| V7 | Reporte con texto de riesgo vital (p. ej. "persona electrocutada") | RF-PRI-05 / Viab. §4 | Diálogo con botones 911/107; no genera alerta comunitaria | ❌ no se deriva en UI (D-03) |
| V8 | Ver el mapa de incidencias **del barrio** | RF-ADM-01 / SRS §3.1.1 | El vecino ve los incidentes activos de la zona | ❌ probable `permission-denied` (D-02) |
| V9 | Ver "Mis reportes" (historial propio) + estado | SRS §3.1.1 | Lista de los reportes propios con su estado | ❌ no existe pantalla (F-01) |
| V10 | Editar el reporte propio mientras está en `recibido` | (uso real O1) | Puede completar descripción/categoría/foto | ❌ no existe UI (F-01) |
| V11 | Seguir el estado de resolución de su reporte (detalle + timeline) | RF-ADM-02 / T-REP-06 | Ve la línea de tiempo de cambios de estado | ✅ el detalle anda; llegar desde Home/Mapa puede fallar (D-02) |
| V12 | Subir comprobante de domicilio | RF-ROL-01 / T-AUTH-09 | Se sube a Storage y el admin lo ve | ✅ funcional (pero seguridad de Storage sin reglas: D-09) |
| V13 | Recibir aviso cuando cambia el estado de su reporte | RF-ADM-02 (seguimiento) | Notificación push al vecino | ❌ sin FCM cliente (D-01); seguimiento es manual |

### 12.2 Referente Barrial

| # | Flujo a probar | Valida (RF/Doc) | Resultado esperado | Estado hoy |
|---|---|---|---|---|
| R1 | Ser promovido a referente por el admin | RF-ROL-02 / T-AUTH-04 | Gana acceso a la vista de alertas | ✅ |
| R2 | Recibir alerta push geolocalizada de incidente cercano | RF-SAL-01 / T-NLP-07 | Push con prioridad y ubicación | ❌ roto end-to-end (D-01: sin token ni ubicación de referente) |
| R3 | Ver la lista de alertas activas de su zona | RF-ROL-02 | Lista filtrada por prioridad/cobertura | ✅ (solo lectura) |
| R4 | Confirmar/Descartar un incidente in situ con foto | RF-ROL-02(b) | Marca verificación con evidencia | ❌ no existe (D-05) |

### 12.3 Administrador Vecinal

| # | Flujo a probar | Valida (RF/Doc) | Resultado esperado | Estado hoy |
|---|---|---|---|---|
| A1 | Login del admin bootstrap | Planif. §1.1 | Acceso al panel | ✅ (la cuenta se crea manualmente en consola) |
| A2 | Aprobar / rechazar cuentas pendientes (con gate de comprobante) | RF-ROL-01 / T-AUTH-01/09 | No deja aprobar sin comprobante si la modalidad lo exige | ✅ |
| A3 | Promover / degradar / bloquear / desbloquear usuarios | T-AUTH-04/07/08 | Cambios de rol/estado persistidos | ✅ |
| A4 | Mapa centralizado con filtros por prioridad/categoría | RF-ADM-01 | Ve todos los incidentes activos | ✅ |
| A5 | Avanzar el ciclo de vida: recibido→programado→en reparación→solucionado | RF-ADM-02 | Transiciones ordenadas y visibles | ⚠️ sin validar orden; doble camino a "falso" (D-07) |
| A6 | Marcar reporte como falso → baja reputación + bloqueo al umbral | RF-MOD-03 / RF-MOD-01 | `reputationScore` baja; bloqueo a los 3 falsos | ⚠️ bloqueo anda; **reputación no baja** (D-08) |
| A7 | (Re)asignar categoría manual + registrar acciones de resolución | RF-ADM-03 | Corrige categoría y deja registro de acciones | ❌ no existe (D-06) |
| A8 | Calibrar el algoritmo (diccionario/pesos) sin redeploy | RF-PRI-04 / T-NLP-06 | Cambios aplican en tiempo real | ✅ (callable existe; UI no auditada en detalle) |
| A9 | Configurar el área de cobertura (centro + radio) | T-AUTH-06 | Persiste `config/coverage`; el mapa lo refleja | ✅ (círculo; polígono = F-07) |
| A10 | Enviar notificación masiva (global o por zona) | RF-ADM-04 / T-NLP-09 | Push a la comunidad / zona | ❌ roto end-to-end (D-01: `successCount: 0`) |
| A11 | Configurar la modalidad de verificación de identidad | T-AUTH-09 | Cambia entre aprobación manual / comprobante | ✅ (no auditado en detalle) |

### 12.4 Pipeline / sistema (backend, sobre Firestore onCreate/onUpdate)

| # | Flujo a probar | Valida (RF/Doc) | Resultado esperado | Estado hoy |
|---|---|---|---|---|
| P1 | Pipeline completo al crear un incidente | RF-PRO-03 | normaliza→valida→enriquece→duplicados→riesgo vital→semántica→prioridad→persiste→push | ✅ (salvo el push, P8) |
| P2 | Rechazo de reportes de autor bloqueado/inactivo | T-AUTH-07 | `status: rechazado_autor_inactivo` | ⚠️ backend ok; el cliente lo muestra "Recibido" (D-03, enum) |
| P3 | Validación geográfica en backend | RF-MOD-02 | `status: rechazado_fuera_de_cobertura` | ✅ |
| P4 | Detección de incidentes duplicados cercanos | RF-PRO-02 | Marca/cuenta duplicados en ventana y radio | ✅ |
| P5 | Riesgo vital interrumpe el pipeline | RF-PRI-05 | No genera alerta comunitaria; marca el incidente | ✅ backend (no llega a UI: D-03) |
| P6 | Clasificación de prioridad + score | RF-PRI-02/03 | Prioridad {Urgente…Baja} con score | ✅ funcional; **precisión = runtime** (RNF-PRE-02/03) |
| P7 | Persistencia y auditoría del evento | RF-SAL-02 / T-NLP-08 | Registro con timestamps de cada etapa | ✅ |
| P8 | Despacho de push a referentes cercanos | RF-SAL-01 / T-NLP-07 | Multicast FCM a referentes en radio | ❌ roto (D-01) |
| P9 | Reputación: +5 al avanzar / −15 al falso | RF-MOD-01 | Score sube y baja según corresponde | ⚠️ sube ✅; **baja ❌** (D-08) |

### 12.5 Flujos de la Tercera Iteración (a probar cuando se implementen)

| # | Flujo | Tarea |
|---|---|---|
| I1 | Editar reporte propio desde "Mis reportes" | F-01 |
| I2 | Ajustar la ubicación del incidente en el mapa al reportar (hoy siempre es GPS actual) | F-03 |
| I3 | Reacciones "Confirmo / No es así" de la comunidad sobre un reporte | F-04 |
| I4 | Validación bilateral al cerrar (confirmar/disputar por el reportero) | F-05 |
| I5 | Adjuntar evidencia de resolución al cerrar | F-06 |
| I6 | Cobertura como polígono | F-07 |

### 12.6 Lectura rápida de la matriz

De los **13 + 4 + 11 + 9 = 37 flujos del MVP**, hoy fallan o están a medias **~11**, y todos
trazan a la deuda `D-01…D-10`. Los que más duelen para la consistencia con el documento son:
**V7/P5 (no se deriva emergencia), V8 (el vecino no ve el barrio), R2/A10/P8 (push muerto) y
A6/P9 (la reputación no modera)** — es decir, los cuatro pilares de la propuesta de valor
(ciencia ciudadana, alertas focalizadas, trazabilidad, anti-reportes-falsos) tienen al menos un
flujo roto. Por eso la conclusión de la §11 se sostiene: **cerrar la deuda de MVP es lo que
vuelve la app consistente con lo que prometen los documentos.**

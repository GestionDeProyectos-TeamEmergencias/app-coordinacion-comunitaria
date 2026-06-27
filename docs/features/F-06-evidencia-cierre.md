# F-06 — Evidencia opcional al cerrar el reporte

> **Tipo:** `extra` (extensión nueva sobre RF-ADM-02 — evidencia de resolución)
> **Tickets relacionados:** O6 (uso real), RF-ADM-02 (ciclo de vida), D-05/D-09 (patrón de Storage), F-05 (cierre bilateral)
> **Fecha de implementación:** 2026-06-27
> **Estado:** completado

## 1. Qué es

Cuando admin o referente pasa un incident a `solucionado`, la UI ofrece adjuntar una **foto opcional** como evidencia de la reparación. Si se sube, se guarda en `incidents/{id}/resolution/{uuid}.jpg` y su URL queda en el campo `resolutionEvidenceUrl` del incident. El detalle muestra esa foto debajo del status badge, visible a todos los usuarios como rendición de cuentas.

El cierre con foto viaja en el **mismo** update que ya dispara la validación bilateral (F-05): no hay un flujo nuevo de notificación, la foto es un campo más del cierre.

## 2. Por qué se hizo

La observación **O6** (uso real): el cierre actual es declarativo — el equipo marca "solucionado" sin una prueba visible de que la reparación ocurrió. Una foto de evidencia refuerza la trazabilidad y la rendición de cuentas que prometen los documentos (RF-ADM-02/RF-ADM-03), sin volverla obligatoria (no todos los cierres tienen una foto razonable).

Es alcance **`extra`**: la evidencia de resolución no figura en el SRS. Extiende RF-ADM-02 reutilizando el patrón de Storage ya probado en `photoUrl` (T-REP-03), `identityProofUrl` (T-AUTH-09) y la evidencia del referente (D-05).

## 3. Decisiones de diseño

### 3.1 Campo simple `resolutionEvidenceUrl`, no un sub-objeto

A diferencia de `referentVerification` (que necesita state/by/at/note + foto), la evidencia de cierre es **una sola URL opcional**. El "quién/cuándo" del cierre ya queda registrado en `statusHistory` y en `closureConfirmation.by/at` (F-05). Agregar un sub-objeto sería redundante. Un `String?` plano mantiene el modelo chico y la migración trivial: incidents legacy sin el campo → `null` → no se renderiza nada.

### 3.2 La foto viaja en el mismo update que el cierre (atómico)

`updateStatus` ya inicializaba `closureConfirmation` al pasar a `solucionado` (F-05). F-06 extiende ese método con un `resolutionEvidenceUrl` opcional que se agrega al mismo patch. Así el cambio de estado, el inicio del cierre bilateral y la evidencia se persisten en una sola escritura. La subida del binario a Storage ocurre **antes** (en el notifier) y solo si el usuario adjuntó algo; el patch lleva la URL ya resuelta.

### 3.3 El referente también puede cerrar — excepción documentada a D-07

El criterio de aceptación dice "admin **o** referente". Hasta F-06, D-07/D-05 dejaban el `status` exclusivamente bajo el admin: el referente solo escribía `referentVerification(History)`. F-06 introduce **una sola excepción** consciente, en el mismo espíritu que la excepción de F-05 (disputa):

- El referente puede transicionar **solo** a `solucionado` (validado por el grafo `isValidStatusTransition`), tocando **únicamente** los campos del cierre: `['status', 'statusHistory', 'resolutionEvidenceUrl', 'closureConfirmation']`.
- El admin conserva el control de todas las demás transiciones. El referente **no** puede ir a `programado`/`en_reparacion` ni tocar otros campos.

La regla vive en `firestore.rules` (`isReferenteResolvingIncident`), no en `isValidStatusTransition` — el grafo del cliente sigue siendo declarativo; la apertura es estrecha y server-side. En la UI, el dropdown del referente se filtra a la única transición `solucionado`.

> **Nota de alcance:** abrir el cierre al referente fue una decisión explícita del producto (no estaba en el diseño original D-05/D-07). Quedó acotada al mínimo para no contaminar la máquina de estados.

### 3.4 Picker dentro de `_StatusUpdater`, no un widget aparte

El flujo natural es: el operador elige "Solucionado" → aparece el picker de foto opcional + un botón "Confirmar cierre". Recién al confirmar se aplica el cambio. Para el resto de transiciones, el dropdown sigue aplicando el cambio de inmediato (comportamiento previo). Esto mantiene la acción de cierre en un solo lugar y reutiliza el patrón de `ImagePicker` (gallery, `imageQuality:70`, `maxWidth/Height:1024`) ya usado en `_ReferentVerificationActions`.

### 3.5 Storage: path dedicado y regla espejo de la verificación

La foto va a `incidents/{incidentId}/resolution/{uuid}.jpg` (paralelo a `incidents/{incidentId}/verifications/...` de D-05). La regla de Storage es idéntica: lectura para cualquier activo (evidencia pública del barrio, consistente con D-02), escritura para admin o referente activo. Default-deny global de D-09 sigue cubriendo todo lo demás.

### 3.6 Sin tests de reglas Firestore/Storage

Mismo trade-off costo/beneficio documentado desde D-02/D-09: la validación de reglas queda en el checklist manual con emulador (§6). El helper `isReferenteResolvingIncident` es candidato natural para los futuros tests de reglas en CI.

## 4. Impacto en el sistema

### Creados
- `docs/features/F-06-evidencia-cierre.md` — este documento.

### Modificados
- `lib/features/incidents/domain/entities/incident_event.dart` — campo `resolutionEvidenceUrl` + `copyWith` + `props`.
- `lib/features/incidents/data/models/incident_event_model.dart` — (de)serialización del campo (`fromFirestore`/`toFirestore`/`toDomain`/`fromDomain`).
- `lib/features/incidents/data/datasources/incidents_remote_datasource.dart` — `uploadResolutionEvidence(...)` + `updateStatus` extendido con `resolutionEvidenceUrl` opcional.
- `lib/features/incidents/domain/repositories/incidents_repository.dart` + `data/repositories/incidents_repository_impl.dart` — firma extendida + passthrough.
- `lib/features/incidents/presentation/providers/incidents_provider.dart` — `UpdateStatusNotifier.update` sube la evidencia (si hay) y propaga la URL.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — `_StatusUpdater` con picker opcional + confirmación; selector visible a admin **y** referente (referente limitado a cerrar); render de la evidencia debajo del status badge.
- `lib/core/constants/app_strings.dart` — strings de F-06.
- `storage.rules` — regla `incidents/{incidentId}/resolution/{fileName}`.
- `firestore.rules` — helper `isReferenteResolvingIncident()` + clausula en `allow update` de incidents.
- Tests: `test/unit/incidents/update_status_notifier_test.dart` (cierre con/sin foto), `test/unit/incidents/closure_confirmation_test.dart` (persistencia + upload), `test/widget/incidents/incident_detail_page_test.dart` (referente ahora ve el selector), `test/unit/incidents/edit_own_incident_notifier_test.dart` (stub a la nueva firma).

### No modificados (verificados)
- `functions/src/closureConfirmation.ts` — el trigger `notifyClosurePending` se dispara por `closureConfirmation.state → pendiente`, indiferente a la foto. La evidencia no cambia su comportamiento.
- F-05: el flujo de confirmación/disputa del reportero sigue igual; la foto es un campo extra del mismo cierre.

## 5. Limitaciones conocidas

- **La foto no se incluye en el push.** El `notifyClosurePending` notifica el cierre pendiente sin adjuntar la evidencia. Aceptable: el reportero la ve al abrir el detalle. Mejora futura si el cliente lo pide.
- **No se puede agregar evidencia después del cierre.** Solo se ofrece en la transición a `solucionado`. Si el operador cerró sin foto, no hay UI para sumarla luego. Candidato a iteración futura (un botón "agregar evidencia" en el detalle para admin/referente).
- **Una sola foto.** No hay galería de evidencias. Para el alcance del MVP alcanza; multi-foto es trabajo futuro.
- **Sin tests de reglas.** Igual que D-02..D-09. Validación manual con emulador.
- **Sin compresión server-side ni límite de tamaño.** Se confía en `imageQuality:70` + `maxWidth/Height:1024` del cliente; un SDK directo podría subir más grande. Las quotas de Storage del proyecto son el único límite.

## 6. Comandos de verificación

```bash
# Cliente
flutter analyze --no-pub
flutter test
```

### Pruebas manuales con emulador

1. `firebase emulators:start --only firestore,storage,functions,auth`.
2. Crear `vecino-1` (reportero), `admin-1` (administrador, active), `ref-1` (referente_barrial, active).
3. Crear `incidents/inc-1` con `userId: 'vecino-1'`, status `en_reparacion`.
4. Como `admin-1`, en el detalle pasar a "Solucionado" → aparece el picker. Confirmar **sin** foto → `status == solucionado`, `closureConfirmation.state == pendiente`, sin `resolutionEvidenceUrl`.
5. Crear `inc-2`. Como `admin-1`, cerrar **con** foto → verificar `resolutionEvidenceUrl` seteado y que la foto se ve en el detalle para `vecino-1` y para un tercero.
6. Como `ref-1` sobre `inc-3` (en `recibido`/`en_reparacion`): el selector solo ofrece "Solucionado"; cerrar con foto → permitido. Verificar que `ref-1` **no** puede otras transiciones.
7. Regla Storage: como `vecino-2`, intentar subir a `incidents/inc-2/resolution/x.jpg` → **debe rechazar**. Como `admin-1`/`ref-1` → debe permitir. Lectura de la evidencia por cualquier activo → permite.
8. Regla Firestore: como `ref-1`, intentar un update que toque `priority` junto al cierre → **debe rechazar** (allowlist estricta).

### Deploy obligatorio antes de demo

```bash
firebase deploy --only storage
firebase deploy --only firestore:rules
```

## 7. Próximos pasos relacionados

- **Evidencia post-cierre**: botón para sumar/editar la foto después de `solucionado` (admin/referente).
- **Multi-foto / antes-después**: galería de evidencia con par antes/después de la reparación.
- **Tests de reglas en CI**: `isReferenteResolvingIncident` y la regla de Storage de `resolution/` son buenos casos para el job futuro con `@firebase/rules-unit-testing`.
- **Push con miniatura**: incluir la evidencia en la notificación de cierre.

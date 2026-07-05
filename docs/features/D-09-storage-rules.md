# D-09 — Storage rules para fotos e identity_proofs (PII)

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.10)
> **Tickets relacionados:** RNF-SEG, T-AUTH-09
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Agrega `storage.rules` al repo y lo referencia desde `firebase.json`. Antes de D-09 el bucket de Firebase Storage quedaba con la configuración default de consola (típicamente test-mode permisivo), lo que dejaba **los comprobantes de domicilio expuestos** (PII sensible) y las fotos de incidentes sin política versionada.

Las reglas implementan tres ámbitos diferenciados:

| Path | Lectura | Escritura |
| --- | --- | --- |
| `identity_proofs/{userId}/{file}` (path nuevo) | dueño + admin | solo dueño |
| `identity_proofs/{fileName}` (legacy `{uid}.{ext}`) | dueño + admin (vía regex) | **denegada** (migración soft) |
| `incidents/{userId}/{file}` | cualquier activo (consistente con D-02) | solo dueño activo |
| `incidents/{incidentId}/verifications/{file}` | cualquier activo | admin o referente activo |
| `{allPaths=**}` | **denegado** | **denegado** |

## 2. Justificación

`firebase.json` no tenía bloque `storage` y no existía `storage.rules` en el repo. La protección quedaba librada a la configuración de consola — un riesgo de seguridad inaceptable cuando hay PII (comprobantes de domicilio) en juego. Es deuda directa de T-AUTH-09 (que implementó el upload sin las reglas).

El comentario en `lib/features/auth/data/models/user_model.dart:33-38` se preocupa explícitamente por la sensibilidad del comprobante pero **confía en reglas de Firestore**, que **no gobiernan los binarios de Storage**. D-09 cierra ese gap.

## 3. Decisiones de diseño

### 3.1 Migración del path de comprobantes a carpeta dedicada

El path legacy era `identity_proofs/{uid}.{ext}` — uid + extensión en el mismo segmento. Eso obligaba a usar `string.matches(regex)` en la regla para extraer el dueño. Lo cambié a `identity_proofs/{uid}/proof.{ext}`:

- **Match estándar por dueño**: la regla puede usar `request.auth.uid == userId` sin parseo.
- **Re-subida sobreescribe**: el nombre fijo `proof.{ext}` evita acumular comprobantes huérfanos cuando el usuario sube uno nuevo.
- **Compatibilidad legacy**: archivos viejos en `identity_proofs/{uid}.{ext}` siguen leyéndose por una regla específica que extrae el uid del filename (`fileName.matches(uid + '\\..*')`). La escritura nueva va al path nuevo; el legacy queda read-only.

Trade-off: hay dos reglas para el mismo tipo de archivo. Aceptable porque es transición unidireccional — los uploads nuevos no usan el path viejo y, eventualmente, todos los comprobantes vivos van a estar en el path nuevo. Si en una iteración futura se decide migrar los archivos viejos (script de copia), se puede eliminar la regla legacy.

### 3.2 Lectura de incidents públicos del barrio (consistencia con D-02)

Después de D-02, el "mapa del barrio" muestra incidents a cualquier usuario activo. Si las reglas de Storage solo permitieran lectura a dueño + admin, las fotos de los incidents **no se renderizarían** para vecinos no-dueños, rompiendo la UX. La regla de `incidents/{userId}/{file}` permite lectura a cualquier `isActive()`, alineado con la decisión de producto documentada en D-02.

La identidad del reportero ya viaja en `userId` (segmento del path), pero el cliente no la expone en UI a quien no sea dueño/admin/referente (verificado en D-02 §3). El path en URL no constituye filtración de identidad operable (el UID es opaco — `users/{uid}` sigue blindado por Firestore).

### 3.3 Verificación del referente como evidencia pública

Las fotos que sube el referente en D-05 viven en `incidents/{incidentId}/verifications/{uuid}.{ext}`. Son evidencia de campo: el SRS las quiere visibles al vecino dueño como rendición de cuentas (y al admin para auditoría). La regla replica lo mismo que la foto del reporte: lectura para cualquier activo, escritura para admin o referente activo. No se exige que el referente sea **dueño** del incident porque no hay tal cosa — el incident no le "pertenece" al referente.

### 3.4 Escritura de comprobante sin `isActive()`

El comprobante de identidad se sube **antes** de la aprobación de la cuenta (T-AUTH-09). En ese momento, `users/{uid}.status == 'pending'` y `isActive()` retornaría false. La regla de escritura usa `isAuthenticated() && request.auth.uid == userId`: solo se exige autenticación + dueño, no estado activo. Es la única ruta donde un user `pending` puede escribir.

### 3.5 Cross-service: `firestore.get` desde Storage rules

Los helpers `isActive`, `isAdmin`, `isReferente` usan `firestore.get(/databases/(default)/documents/users/$(uid))` para leer el rol/estado. Cada operación de Storage que cae bajo estos helpers ejecuta una lectura de Firestore extra. Costo aceptable para el volumen del MVP; si en producción escala (millones de lecturas), conviene cachear el rol con un token claim de Auth (Custom Claims) y leerlo desde `request.auth.token.role`.

### 3.6 `firebase.json` con bloque `storage` y emulador

Además de referenciar `storage.rules`, agregué el emulador en el puerto 9199 (`emulators.storage`) para que pruebas locales con `firebase emulators:start` carguen las reglas y permitan validación. El equipo va a necesitar esto para los tests manuales del checklist (§5 de este `.md`).

### 3.7 Sin tests automatizados de reglas

Igual que con `firestore.rules` (D-02, D-04, D-05, D-06, D-07), por costo/beneficio en esta iteración no se agregaron tests con `@firebase/rules-unit-testing`. Hay un job futuro (deuda futura, no MVP) para CI con emulador que cubra ambos rule sets juntos.

## 4. Archivos modificados / creados

### Creados
- `storage.rules` — reglas completas con default-deny.

### Modificados
- `firebase.json` — agrega bloque `"storage": { "rules": "storage.rules" }` y emulador `storage` en puerto 9199.
- `lib/features/auth/data/services/identity_proof_uploader.dart` — path del comprobante migrado de `identity_proofs/{uid}.{ext}` a `identity_proofs/{uid}/proof.{ext}`. Doc-comment explica el cambio y la compatibilidad legacy.

### No modificados
- `lib/features/incidents/data/datasources/incidents_remote_datasource.dart` — el path `incidents/{userId}/{uuid}.{ext}` ya es consistente con la regla nueva.
- `lib/features/incidents/data/services/referent_verification_service.dart` — el path `incidents/{incidentId}/verifications/{uuid}.{ext}` ya es consistente.

## 5. Impacto

| Antes de D-09 | Después de D-09 |
| --- | --- |
| Sin `storage.rules` en el repo. Bucket con regla default de consola (típicamente test-mode permisivo). | Reglas versionadas con default-deny + matches específicos por path. |
| Comprobantes de domicilio (PII) potencialmente accesibles a cualquier autenticado. | Solo dueño + admin pueden leer comprobantes. |
| Fotos de incidents y de verificación sin política versionada. | Política consistente con D-02 (públicas al barrio activo) y D-05 (evidencia pública). |
| `firebase deploy --only storage` no hacía nada (no había rules para subir). | Deploy explícito sube las reglas y queda en historial. |
| Sin emulador de Storage local. | Emulador disponible en `localhost:9199`. |

## 6. Limitaciones conocidas

- **Comprobantes legacy (`identity_proofs/{uid}.{ext}`) quedan en read-only.** Si el usuario quiere actualizar su comprobante, el path nuevo lo reemplaza pero el archivo viejo persiste en Storage hasta que se haga limpieza manual. Para alcance del MVP es aceptable; en producción conviene un script de limpieza o una Cloud Function que mueva los archivos viejos al nuevo formato.
- **Sin verificación automatizada de las reglas.** Validación manual con emulador queda como checklist (§7).
- **Reglas dependen de lecturas a Firestore.** Cada acceso a Storage que pasa por `isActive()`, `isAdmin()` o `isReferente()` cuesta una lectura de Firestore. Si esto se vuelve cuello de botella o de costo, mover el rol a Custom Claims de Auth (token-based, sin lectura). No es urgente para el MVP.
- **No hay rate-limiting de uploads.** Un user activo puede subir N fotos por segundo. Firebase Storage tiene quotas de proyecto, pero no hay per-user. Tarea futura si aparece abuso.
- **Sin política de retención.** Los archivos quedan indefinidamente. Para producción real (con costos a la vista) conviene una política de TTL por categoría (ej. fotos de incidents solucionados se purgan a los 90 días).

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (131/131)
```

### Deploy de las reglas

```bash
firebase deploy --only storage
# Sube `storage.rules` al bucket configurado en el proyecto.
```

**Importante**: después del deploy, verificar manualmente en la consola de Firebase Storage (`https://console.firebase.google.com/.../storage/rules`) que la regla activa es la nueva, no la default. Si el bucket sigue en test-mode permisivo, el deploy lo va a reemplazar.

### Validación manual con emulador (parte del checklist §11.13 de la devolución)

1. `firebase emulators:start --only firestore,storage,auth`.
2. Crear `vecino-1` (rol vecino, active), `vecino-2` (rol vecino, active), `admin-1` (rol administrador, active).
3. Como `vecino-1`, subir foto a `incidents/vecino-1/test.jpg` → debe permitir.
4. Como `vecino-2`, leer la foto anterior → debe permitir (mapa del barrio).
5. Como `vecino-2`, intentar subir foto a `incidents/vecino-1/otra.jpg` → debe rechazar.
6. Como `vecino-1` pending (status != active), subir comprobante a `identity_proofs/vecino-1/proof.jpg` → debe permitir.
7. Como `vecino-2`, intentar leer `identity_proofs/vecino-1/proof.jpg` → **debe rechazar** (criterio crítico del ticket).
8. Como `admin-1`, leer el mismo comprobante → debe permitir.
9. Como referente, subir foto a `incidents/inc-1/verifications/x.jpg` → debe permitir.
10. Como vecino, intentar lo mismo → debe rechazar.

## 8. Próximos pasos relacionados

- **Migración de archivos legacy**: script que recorra `identity_proofs/` y mueva `{uid}.{ext}` → `{uid}/proof.{ext}`, actualizando `users/{uid}.identityProofUrl`. Permitiría eliminar la regla legacy.
- **Custom Claims para rol**: mover `role` y `status` a token claims de Auth para evitar lecturas de Firestore desde Storage rules. Mejora performance y costos a escala.
- **Tests de reglas en CI**: job de GitHub Actions con `firebase emulators:exec` que cubra tanto `firestore.rules` como `storage.rules`. Es el siguiente paso natural cuando se aborde la deuda de "ningún test de reglas" acumulada desde D-02.
- **Política de retención y limpieza**: agregar lifecycle rules al bucket para purgar archivos viejos automáticamente. Configuración a nivel de proyecto GCP, fuera del scope de las reglas.
- **Audit log de accesos a comprobantes**: si la auditoría legal lo exige, instrumentar con Cloud Logging quién leyó qué comprobante y cuándo. Sale del alcance D-09.

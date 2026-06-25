# D-05 — Acción del Referente Barrial: confirmar/descartar con foto

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.5)
> **Tickets relacionados:** RF-ROL-02(b)
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Completa RF-ROL-02(b): el Referente Barrial puede marcar un incidente como **Confirmado** o **Descartado** desde el detalle, con foto obligatoria como evidencia y nota opcional. Antes de D-05, la pantalla del referente (`referent_alerts_page.dart`) era solo lectura: el rol que el SRS definió con cuidado quedó a mitad de construir.

La verificación se modela como **ortogonal** al `status` del incidente: el referente no entra a la máquina de estados operativa del admin (RF-ADM-02), sino que aporta una señal **autoritativa de campo** que se persiste en un campo aparte y queda visible para todos los usuarios.

## 2. Justificación

RF-ROL-02(b) es un "deberá" del SRS y la razón de ser del rol. La devolución (§11.5) lo describe como "el rol que el SRS define con cuidado quedó a medias". Sin esta acción, el referente solo recibe alertas y consulta — no puede aportar lo que el SRS le encarga. Deuda directa del MVP.

Además, anticipa la jerarquía que va a hacer falta cuando se implemente F-04 (señal social de la comunidad): el referente es **autoridad de campo**, los vecinos van a aportar **señal social blanda**. D-05 deja el primer pilar instalado.

## 3. Decisiones de diseño

### 3.1 Campo ortogonal, no inflar el enum `IncidentStatus`

Se evaluó agregar `confirmado_por_referente` y `descartado_por_referente` al enum `IncidentStatus`. Se descartó por las mismas razones que la devolución argumentó para F-05 (separación de concerns):

- **Contamina la máquina de estados** que el SRS expone al usuario en RF-ADM-02 (Recibido → Programado → En Reparación → Solucionado).
- **Confunde la autoría**: el ciclo de vida lo conduce el admin; la validación de campo la conduce el referente. Son dimensiones distintas.
- **Migración**: incidents existentes no necesitan tocarse.

El campo `referentVerification` (un Map) lleva el último estado autoritativo. `referentVerificationHistory` (Array) es el feed de auditoría con todas las verificaciones (incluye re-verificaciones).

### 3.2 Foto obligatoria

El RF dice "con evidencia fotográfica". El servicio rechaza la operación si `photoBytes` está vacío. La UI también valida antes de enviar (snackbar de error). Defensa en dos capas porque la evidencia es el corazón del valor del rol.

### 3.3 Reglas Firestore separan admin de referente

Hasta D-05, la regla de update de `incidents` permitía a admin y referente "actualizar cualquier campo" indistintamente. Eso era inconsistente con la jerarquía SRS. La nueva regla:

- **Admin** (`isAdmin()`): cualquier campo.
- **Referente** (`isReferente()`): solo `referentVerification` y `referentVerificationHistory`. No puede tocar `status`, `priority`, `description`, etc.
- **Vecino dueño**: como antes (descripción/foto mientras esté en `recibido`).

Esto cambia el comportamiento previo: hoy el referente **no** puede usar el dropdown de estado del detalle. La UI se actualizó para esconderlo (era para admin solo). La acción "marcar como falso" sigue disponible al referente vía el callable `moderateFalseReport` (que valida internamente que el caller sea admin o referente, no por reglas).

### 3.4 Subida de foto a path separado

Las fotos del reportero van a `incidents/{userId}/{uuid}.{ext}`. Las del referente van a `incidents/{incidentId}/verifications/{uuid}.{ext}`. Razones:

- **Auditoría**: separar evidencia de campo del referente facilita revisión por el admin.
- **D-09 (storage.rules)**: cuando se implemente, el path permite reglas distintas por carpeta (los `verifications/` deberían leerse por todos los activos, las del reportero según política).
- **Limpieza**: si el equipo decide después purgar evidencias de verificación antiguas, se puede hacer por prefijo.

### 3.5 Re-verificar sobrescribe `referentVerification` pero conserva historial

Si el mismo referente (u otro) verifica de nuevo, el campo "último estado" se sobrescribe pero el array `referentVerificationHistory` crece. Razones:

- La UI siempre muestra el último estado autoritativo (es la señal vigente).
- El admin puede consultar el feed completo para auditar cambios.

### 3.6 Visible a todos los usuarios cuando existe

El widget `_ReferentVerificationSummary` aparece a vecinos, referentes y admins por igual cuando el incident tiene verificación. Razones:

- Es información pública del estado del barrio (alineado con D-02, "mapa del barrio").
- Refuerza la jerarquía: cuando un vecino abre un incidente y ve "Confirmado por referente", sabe que tiene peso operativo.

### 3.7 `at` con `Timestamp.now()` del cliente, no server timestamp

`FieldValue.serverTimestamp()` no se permite **dentro** de un valor que va por `arrayUnion`. Para que el historial crezca, el `at` del Map se calcula en cliente. Es aceptable: la precisión sub-segundo del reloj del cliente alcanza para un feed de auditoría humano. El doc tiene `createdAt: serverTimestamp` para auditoría más estricta si hace falta.

## 4. Archivos modificados / creados

### Creados
- `lib/features/incidents/data/services/referent_verification_service.dart` — sube foto a Storage y actualiza el doc.
- `lib/features/incidents/presentation/providers/referent_verification_provider.dart` — provider + notifier.
- `test/unit/incidents/referent_verification_service_test.dart` — 4 tests (foto obligatoria, persistencia, historial, nota vacía).
- `test/unit/incidents/referent_verification_model_test.dart` — 3 tests de serialización (roundtrip, datos inválidos, vacío).

### Modificados
- `lib/features/incidents/domain/entities/incident_event.dart` — entity `ReferentVerification`, enum `ReferentVerificationState`, campos en `IncidentEvent`.
- `lib/features/incidents/data/models/incident_event_model.dart` — (de)serialización de los nuevos campos.
- `lib/features/incidents/presentation/pages/incident_detail_page.dart` — widgets `_ReferentVerificationSummary` (visible a todos) y `_ReferentVerificationActions` (solo referente). Dropdown de status restringido a admin.
- `firestore.rules` — regla `incidents` update separa admin (cualquier campo) y referente (solo verificación).
- `pubspec.yaml` — agrega `firebase_storage_mocks: ^0.7.0` como dev dependency.
- `test/widget/incidents/incident_detail_page_test.dart` — actualiza test que ahora exige rol `administrador` para el dropdown.

### No modificados
- `referent_alerts_page.dart` — la entrada al detalle desde la pantalla de alertas ya funcionaba. La acción del referente ocurre en el detalle, no en la lista.

## 5. Impacto

| Antes de D-05 | Después de D-05 |
| --- | --- |
| El Referente solo podía leer alertas. RF-ROL-02(b) sin cobertura. | El Referente confirma/descarta con foto desde el detalle. RF cumplido. |
| El Referente podía cambiar `status` del incidente (mismo dropdown que admin). | El Referente NO puede tocar status. Su intervención es ortogonal. |
| Sin distinción entre "ciclo de vida operativo" y "validación de campo". | Dimensiones separadas: status del admin / verification del referente. |
| Las reglas Firestore daban privilegios indistinguibles a admin y referente. | Regla refinada que respeta la jerarquía SRS. |
| Sin campo dedicado a evidencia del referente. | `referentVerification` + `referentVerificationHistory` (auditoría). |

## 6. Limitaciones conocidas

- **Sin storage.rules versionadas todavía.** Las fotos de evidencia van al bucket con la regla default de la consola (test-mode o equivalente). **D-09** va a cubrir esto agregando `storage.rules` con la política definitiva (la dependencia ya está documentada en el ticket).
- **Cualquier referente activo puede re-verificar lo que verificó otro referente.** No hay candado de autoría (solo último-gana). Aceptable para el MVP: si hay disputa entre referentes, el admin tiene el historial completo y decide.
- **El widget no marca como "ya verificado" en la lista de alertas.** Para una próxima iteración: agregar un badge en `_AlertCard` para que el referente sepa qué alertas ya tienen verificación.
- **Sin notificación al admin cuando se verifica.** Una mejora futura sería pingear al admin (push o solo badge) cuando un incident gana verificación de campo, especialmente si fue `dismissed`.
- **`_ReferentVerificationActions` no usa scroll-to-end gate ni confirmación.** Una operación errónea (descartar un incident real) es rápida. Si esto se vuelve un problema, agregar `AlertDialog` de confirmación antes del envío.
- **Reset post-envío:** después de verificar, el form se limpia (foto, nota). Si el referente quería re-verificar inmediatamente con la misma evidencia tiene que volver a cargarla. Decisión deliberada para forzar selección consciente de evidencia.
- **No hay tests de reglas Firestore.** Igual que D-02, D-04. Validación queda como runtime check con emulador.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (116/116)
```

### Pruebas manuales

1. Login como **referente activo** → abrir un incidente desde el feed de alertas → ver botones "Confirmar" / "Descartar" + campo de nota + adjuntar evidencia.
2. Tocar "Confirmar" sin foto → snackbar de error, no se envía.
3. Adjuntar foto + tocar "Confirmar" → snackbar de éxito, aparece el badge verde "Confirmado por referente" arriba.
4. Re-verificar como "Descartar" → el badge cambia a rojo, `referentVerificationHistory` tiene 2 entradas.
5. Login como **vecino activo** → abrir el mismo incidente → ve el badge "Confirmado/Descartado por referente" (lectura).
6. Login como **admin** → abrir el incidente → ve el badge + sigue teniendo el dropdown de status.
7. **(Reglas)** Como referente, intentar cambiar `status` con SDK directo → debe rechazar con `permission-denied`.

## 8. Próximos pasos relacionados

- **D-09**: agregar `storage.rules` con permiso adecuado para `incidents/{id}/verifications/*` (mínimo: lectura por activos, escritura por referente/admin).
- **F-04**: cuando se sumen "reacciones" de la comunidad, el `confirmationScore` debería ponderar más fuerte la señal del referente (`referentVerification.state`) que las señales de los vecinos.
- **D-06**: el admin debería poder agregar notas de resolución (RF-ADM-03). El histórico unificado de "qué pasó con este incident" debería mezclar `statusHistory`, `referentVerificationHistory` y `actions` futuras en un único timeline.
- **Notificaciones**: cuando D-01 esté desplegado, considerar pingear al reportero cuando su incident reciba verificación del referente — cierra el loop de "tu reporte fue visto en terreno".

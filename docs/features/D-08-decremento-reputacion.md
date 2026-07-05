# D-08 — Decremento de reputación: unificar campo de moderación

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.9)
> **Tickets relacionados:** RF-MOD-01, RF-MOD-03, T-AUTH-07
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Repara el bug que volvía monótona creciente la reputación de los usuarios: el callable `moderateFalseReport` (`functions/src/moderation.ts:90-95`) escribía el flag **`moderatedAsFalse`** en el incident, pero el trigger de reputación (`functions/src/reputationManager.ts:32`) leía **`verifiedAsFalse`** — otro nombre. El decremento de −15 puntos nunca se ejecutaba en producción aunque el callable corriera correctamente.

Tras D-08, ambos archivos usan **`moderatedAsFalse`** como única fuente de verdad. Marcar un reporte como falso decrementa efectivamente la reputación del autor.

## 2. Justificación

RF-MOD-01 / RF-MOD-03 prescriben que "cada reporte marcado como falso decrementa la reputación". Era la mitigación #1 del riesgo "reportes falsos" del Informe de Viabilidad. El sistema de reputación quedaba decorativo: ningún usuario llegaba a < 30 puntos por reportes falsos, lo que dejaba **toda la superficie de moderación basada en reputación inerte**:

- El warning "Baja reputación (< 30)" en `users_management_page.dart:567`.
- El filtro de baja reputación en `users_management_page.dart:202`.
- Cualquier downstream que mire reputación como señal anti-spam.

Es deuda directa del MVP de Iteración 2 (T-AUTH-05 cerró la mitad del trabajo).

## 3. Decisiones de diseño

### 3.1 Conservar `moderatedAsFalse`, no `verifiedAsFalse`

`moderation.ts` ya escribía un cluster coherente de campos:

```ts
status: "falso",
moderatedAsFalse: true,
moderatedAt: serverTimestamp(),
moderatedBy: callerId,
```

`moderatedAsFalse` es consistente con `moderatedAt`/`moderatedBy`. Cambiar `moderation.ts` para escribir `verifiedAsFalse` rompía esa coherencia y, encima, los tests de `moderation.test.ts` también referencian `moderatedAsFalse`. Renombrar el lado de `reputationManager.ts` es la operación más barata y la que deja el código más legible.

### 3.2 Renombrar también el campo del cache (`beforeData.moderatedAsFalse`)

`reputationManager.ts:17` tiene una optimización early-return: si ni el status ni el flag de moderación cambiaron, no hace nada. Se renombró también esta lectura para mantener simetría — sino el early-return seguiría mirando un campo siempre `undefined`.

### 3.3 Tests de integración que **no** setean el campo a mano

Los tests viejos hacían:

```ts
"incidents/incident2": { data: { verifiedAsFalse: true } },
// ...
await updateUserReputationLogic(firestore, "user2",
  { verifiedAsFalse: false },
  { verifiedAsFalse: true },
  "incident2"
);
```

Esto pasaba en verde porque el test mismo seteaba el campo que la función leía. Era exactamente la "trampa" que la devolución (§11.9) marcó como ejemplo de "tests verdes que esconden integración rota".

D-08 agrega un bloque `[D-08] integración con moderation.ts` con dos tests cuyo input es el **shape exacto** que produce `moderation.ts:90-95` (cluster `status: 'falso'` + `moderatedAsFalse: true` + `moderatedAt` + `moderatedBy`). Eso valida:

1. Que el contrato implícito entre los dos archivos se mantiene.
2. Que cualquier futuro cambio que rompa el contrato (renombrar un campo, eliminar otro) explote en CI antes de mergearse.

Es una forma barata de tener "tests de integración" sin levantar el emulador. Cuando se agreguen tests con `@firebase/rules-unit-testing` + emulador (deuda comprometida en §11.13 de la devolución), estos se complementan, no se reemplazan.

### 3.4 Sin cambios en el cliente

El cliente Flutter nunca leyó ni `verifiedAsFalse` ni `moderatedAsFalse`. El callable `moderateFalseReport` se invoca desde `moderation_remote_service.dart` y el resultado se proyecta como `{success, blocked, alreadyModerated}`. La UI no necesita conocer los nombres internos. Por eso D-08 es **100% backend**.

### 3.5 Sin migración de incidents existentes

Incidents que ya estaban marcados con `moderatedAsFalse: true` antes de D-08 quedaron sin disparar el decremento (no había trigger que los leyera correctamente). **No vamos a aplicar el −15 retroactivo** porque:

- El trigger `updateUserReputationOnValidation` se ejecuta `onDocumentUpdated`, no `onDocumentCreated`, así que no se va a re-disparar para docs viejos sin un update artificial.
- Forzar un update artificial sobre cada incident viejo es operativamente caro y arriesgado (puede activar otros triggers).
- En el contexto del MVP / demo académica, el dataset es nuevo: no hay corrida histórica relevante para corregir.

Si en un despliegue real hace falta corrección retroactiva, se hace un script administrativo aparte que recalcule `reputationScore` desde cero sumando todos los incidents del usuario y sus moderaciones.

## 4. Archivos modificados / creados

### Modificados
- `functions/src/reputationManager.ts` — 3 ocurrencias `verifiedAsFalse` → `moderatedAsFalse`. Comentario aclaratorio de por qué cambió.
- `functions/src/reputationManager.test.ts` — 6 ocurrencias renombradas en tests existentes + un nuevo bloque `describe('[D-08] integración con moderation.ts', ...)` con 2 tests que validan el shape exacto del callable.

### No modificados
- `functions/src/moderation.ts` — ya escribía `moderatedAsFalse` (era el lado correcto).
- `functions/src/moderation.test.ts` — sus tests usan `moderatedAsFalse` y siguen siendo válidos.
- `lib/features/auth/data/services/moderation_remote_service.dart` (cliente) — invoca el callable y consume `{success, blocked, alreadyModerated}`. No cambia.
- `firestore.rules` — los flags se escriben con Admin SDK desde el callable, no caen bajo reglas.

## 5. Impacto

| Antes de D-08 | Después de D-08 |
| --- | --- |
| Marcar un reporte como falso: `falseReportsCount++` ✅ pero **`reputationScore` no bajaba** ❌. | Marcar un reporte como falso: ambos efectos se aplican (−15 puntos + contador). |
| Reputación monótona creciente. Nadie llegaba a < 30. | Reputación bidireccional, refleja el comportamiento real del usuario. |
| Warning "Baja reputación" y filtro en `users_management_page.dart` decorativos. | Activos: identifican usuarios con historial de reportes falsos. |
| Tests verdes con campo seteado a mano (`verifiedAsFalse`) ocultaban el bug. | Tests `[D-08]` usan el shape real del callable. Cualquier futura ruptura del contrato explota en CI. |
| Mitigación #1 del riesgo "reportes falsos" del Informe de Viabilidad no operativa. | Mitigación operativa end-to-end. |

## 6. Limitaciones conocidas

- **No hay corrección retroactiva.** Incidents marcados como falsos antes de D-08 no van a disparar el decremento. Documentado en §3.5; si se necesita, requiere script ad-hoc.
- **Tests siguen siendo con mock de Firestore, no emulador.** El test `[D-08]` valida el shape pero no levanta un emulador real con triggers. Para validación full end-to-end (corrida real de la callable + trigger en cascada), queda como runtime check con `firebase emulators:start`.
- **El umbral de bloqueo (3 falsos) no se calibra desde T-NLP-06.** Sigue siendo constante hardcodeada en `MAX_FALSE_REPORTS_THRESHOLD`. No es alcance de D-08; podría sumarse a una iteración de calibración.
- **Sin auditoría de quién aplicó el decremento.** El trigger no graba `byCallerId` en `users/{uid}` cuando baja el score. Si la rendición de cuentas legal lo pide, sumarlo es trivial.
- **Sin notificación al usuario cuando le bajan la reputación.** El usuario ve su score cambiar al abrir Perfil, pero no recibe push. Cuando D-01 esté desplegado se puede agregar un opt-in.

## 7. Comandos de verificación

```bash
# Backend
cd functions && npx tsc --noEmit
# limpio

cd functions && npm test
# 101/101 passed (incluye 2 nuevos en reputationManager.test.ts)

# Cliente (sin cambios funcionales pero corro la suite por las dudas)
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (131/131)
```

### Pruebas manuales con emulador (recomendadas)

1. `firebase emulators:start --only firestore,functions,auth`.
2. Crear `admin-1` (rol `administrador`, status `active`) y `reporter-1` (rol `vecino_informante`, `status: active`, `reputationScore: 70`).
3. Crear `incidents/inc-X` con `userId: 'reporter-1'`, `status: 'recibido'`.
4. Invocar el callable `moderateFalseReport({incidentId: 'inc-X', userId: 'reporter-1'})` autenticado como `admin-1`.
5. Verificar en Firestore:
   - `incidents/inc-X`: `status: 'falso'`, `moderatedAsFalse: true`, `reputationApplied: true`.
   - `users/reporter-1`: `reputationScore: 55` (70 − 15), `falseReportsCount: 1`.
6. Invocar el callable de nuevo sobre el mismo incident → debe retornar `{alreadyModerated: true, blocked: false}` y NO bajar el score otra vez.
7. Repetir el flujo con dos incidents más del mismo reportero → al tercero, `users/reporter-1.status` pasa a `blocked` (umbral 3).

## 8. Próximos pasos relacionados

- **D-09**: agregar reglas de Storage es la otra deuda crítica de seguridad de la Wave 0.
- **Tests con emulador en CI**: candidato fuerte para acompañar D-08 / D-07. Job de GitHub Actions con `firebase-tools`, `firebase emulators:exec`.
- **Calibración del umbral de bloqueo**: agregar `falseReportsThreshold` a `config/algorithm` (T-NLP-06) para que el admin pueda ajustarlo sin redeploy.
- **F-04** (reacciones de la comunidad): si en el futuro se suma reputación por validación social, el `confirmationScore` puede modular el decremento (un reporte verificado por muchos vecinos y luego descartado por el admin podría costar menos puntos que un reporte que no convenció a nadie).
- **D-07** ya dejó preparado el único camino a `falso` (vía callable). Con D-08 cerrado, ese camino ahora dispara la cadena completa: status + contador + bloqueo + decremento. La trazabilidad del reporte falso es coherente end-to-end.

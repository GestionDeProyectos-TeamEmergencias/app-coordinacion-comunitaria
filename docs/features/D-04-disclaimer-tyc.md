# D-04 — Disclaimer de seguridad + Términos y Condiciones en onboarding

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.4)
> **Tickets relacionados:** Informe de Viabilidad §4 (riesgo "Responsabilidad Civil"), Observación O2 del docente
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Cierra el gap de disclaimer + Términos y Condiciones del MVP: agrega una pantalla de aviso obligatorio que el usuario debe aceptar antes de poder usar la app. La aceptación se persiste con versión, de modo que si el equipo modifica el documento legal se vuelve a pedir consentimiento. La pantalla queda accesible siempre desde Perfil en modo solo lectura.

## 2. Justificación

El Informe de Viabilidad §4 nombra "**Términos y condiciones claros**" y un "**flujo de advertencia obligatorio (disclaimer)**" como mitigaciones explícitas del riesgo **Responsabilidad Civil** (el principal riesgo de producto). El MVP llegó sin ninguna pantalla de consentimiento — la búsqueda en `lib/` no devuelve nada relacionado a *termin/consent/aviso/disclaimer*. Es deuda directa.

Además, la observación O2 del docente pedía mayor claridad sobre el alcance del producto: el disclaimer ayuda a hacerlo explícito ("no es para emergencias activas") y deja constancia legal.

## 3. Decisiones de diseño

### 3.1 Texto del documento en constante de cliente, no en Firestore

Se evaluó persistir el cuerpo de los T&C en `config/terms` (similar a `config/coverage`, `config/algorithm`) para permitir al Administrador modificar el texto sin redeploy. Se descartó por ahora:

- **Frecuencia de cambio:** un documento legal cambia muy rara vez (cada vez que se reescribe legal o se agregan obligaciones), no se calibra como un diccionario.
- **Riesgo de validación:** el texto legal lo escribe el equipo legal del cliente y debería **versionar como código** (PR, review, deploy controlado), no editarse en caliente desde una UI del admin.
- **Costo:** mover el texto a Firestore agrega lectura inicial, latencia y un punto de fallo más.

`lib/core/constants/terms_config.dart` contiene `currentVersion` y `body`. Cuando el equipo legal entregue el texto definitivo, el cambio es trivial: editar la constante y subir la versión.

### 3.2 Versión como `int`, no semver

Versionado simple. Un counter monótono creciente es suficiente: el único uso es la comparación `user.acceptedVersion < currentVersion → re-pedir`. Semver agregaría complejidad sin valor.

### 3.3 Gate en el router, no en cada pantalla

El check se hace una vez en `routerProvider.redirect`, después del setup de ubicación del referente y antes del RBAC. Esto centraliza la lógica de "qué usuarios están listos para entrar a la app" en un único lugar. Si en el futuro hay más gates (verificación de email, captcha, etc.) van todos juntos en esa cascada.

### 3.4 Modo dual (gate vs. reader) con query param

`/terms` es la URL del gate (obligatorio, no permite back). `/terms?mode=read` es el modo reader (accesible desde Perfil, permite back). El router omite el gate cuando ve `mode=read`, así un usuario que ya aceptó puede consultar los términos sin ser deslogueado o forzado a re-aceptar.

### 3.5 Botón "No acepto, cerrar sesión"

La única salida del gate es aceptar o cerrar sesión. No hay "aceptar después" porque el riesgo legal no se mitiga si el usuario puede esquivar el disclaimer. Esto es consistente con apps de banca y seguros.

### 3.6 Checkbox antes del botón "Acepto"

Patrón clásico de dark-pattern-evader: el botón "Acepto y continuar" solo se habilita si el usuario marcó explícitamente "Leí y acepto…". Reduce aceptaciones accidentales por tap rápido y deja evidencia más fuerte de consentimiento.

### 3.7 Disclaimer destacado arriba del cuerpo

Un banner rojo persistente al tope de la pantalla repite el mensaje fuerte ("NO reemplaza al 911"). Razón: aunque el usuario haga scroll rápido y se salte el cuerpo, ese mensaje queda visible. Es defensa en profundidad para el caso real de emergencia donde no hay tiempo de leer.

### 3.8 Sin tests de reglas de Firestore

`termsAcceptedAt` y `termsAcceptedVersion` no están en la blacklist de campos prohibidos del update de `users/{uid}` (firestore.rules:62-67 solo bloquea `role`, `status`, `reputationScore`, `falseReportsCount`), así que la regla actual ya permite el flujo. No se modificaron reglas y no se agregaron tests dedicados (consistente con la convención del proyecto, ver `D-02 §3.4`).

## 4. Archivos modificados / creados

### Creados
- `lib/core/constants/terms_config.dart` — versión y cuerpo del documento legal.
- `lib/features/terms/data/services/terms_acceptance_service.dart` — escribe `termsAcceptedAt` y `termsAcceptedVersion` en Firestore.
- `lib/features/terms/presentation/providers/terms_provider.dart` — provider del servicio, helper `hasAcceptedCurrentTerms`, notifier de aceptación.
- `lib/features/terms/presentation/pages/terms_page.dart` — pantalla dual (gate / reader).
- `test/unit/terms/terms_provider_test.dart` — 4 tests de `hasAcceptedCurrentTerms` (null, vieja, actual, superior).
- `test/unit/terms/terms_acceptance_service_test.dart` — 2 tests del servicio (persistencia, re-aceptación).

### Modificados
- `lib/features/auth/domain/entities/app_user.dart` — agrega `termsAcceptedVersion` y `termsAcceptedAt` (entity).
- `lib/features/auth/data/models/user_model.dart` — agrega los mismos campos al model + serialización.
- `lib/app/router.dart` — nueva ruta `/terms` + redirect gate antes del RBAC.
- `lib/features/profile/presentation/pages/profile_page.dart` — link a `/terms?mode=read`.

### No modificados (verificados pero ya correctos)
- `firestore.rules` — los nuevos campos no están en la blacklist del update del propio user, no requieren cambios.

## 5. Impacto

| Antes de D-04 | Después de D-04 |
| --- | --- |
| Sin pantalla de consentimiento ni disclaimer en ningún flujo de la app. | Gate obligatorio post-aprobación de cuenta. No se accede a Home / Reportar / Mapa hasta aceptar. |
| Riesgo "Responsabilidad Civil" mitigado solo en papel (Viab. §4). | Mitigación concreta: aceptación versionada y verificable en Firestore. |
| Sin recordatorio explícito de que la app no reemplaza al 911 / 107 al ingresar. | Banner rojo persistente al tope del gate + cláusula §2 dedicada en el cuerpo. |
| No se podía pedir reaceptación si cambiaban los términos. | Subir `TermsConfig.currentVersion` fuerza re-aceptación en el próximo login. |
| Sin acceso desde la app a los términos vigentes. | Acceso permanente desde Perfil en modo solo lectura, mostrando qué versión aceptó el usuario. |

## 6. Limitaciones conocidas

- **Texto provisto por el desarrollador, no por el equipo legal.** El cuerpo actual (`TermsConfig.body`) es un placeholder técnicamente funcional — cubre los puntos típicos (propósito, alcance, no-emergencias, responsabilidad del usuario, responsabilidad del admin, privacidad, push, limitación de responsabilidad, modificaciones). **Debe ser revisado y reemplazado por el equipo legal del cliente antes del despliegue a producción.** Cuando lo reemplacen, subir `currentVersion`.
- **Sin localización.** Si en el futuro la app soporta otros idiomas, hay que i18n-izar `TermsConfig.body` y el `disclaimerHighlight`.
- **No registramos IP ni device-id en la aceptación.** Solo guardamos uid (implícito en el path) + version + server timestamp. Si una eventual disputa requiriera prueba más fuerte (qué dispositivo, qué hora exacta del cliente), habría que extender el doc.
- **No bloqueamos al admin si no aceptó.** El gate se aplica a todos los roles activos. Esto es deliberado: incluso el admin debe aceptar para garantizar consistencia legal.
- **El gate no exige scroll completo.** Solo el checkbox. Si el equipo legal pide "scroll-to-end gate" (otro patrón común), es ~10 líneas de cambio.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (108/108)
```

### Pruebas manuales

1. Login con una cuenta activa que nunca aceptó T&C → debe redirigir al gate, no permitir back.
2. Tocar checkbox + "Acepto y continuar" → debe navegar a Home y registrar `termsAcceptedAt` + `termsAcceptedVersion: 1` en `users/{uid}`.
3. Logout + login con la misma cuenta → debe ir directo a Home (ya aceptó).
4. En `terms_config.dart`, subir `currentVersion` a `2`, hot-restart, login → debe volver a pedir aceptación.
5. Desde Perfil → "Términos y Condiciones" → debe abrir la pantalla en modo lectura, con botón "Cerrar" y mostrar qué versión aceptó el usuario.
6. En el gate, tocar "No acepto, cerrar sesión" → debe ejecutar logout y volver al login.

## 8. Próximos pasos relacionados

- **Texto final del equipo legal**: reemplazar `TermsConfig.body` cuando esté listo. Subir `currentVersion`.
- **Política de privacidad separada**: hoy el punto 5 del cuerpo cubre privacidad de manera resumida. Si el cliente requiere documento separado, agregar `PrivacyConfig` análoga y un segundo gate en cascada (o consolidar en un solo gate de 2 secciones).
- **Métricas**: trackear cuántos usuarios aceptan vs. cierran sesión en el gate para entender si el texto genera fricción inesperada.
- **Audit trail**: si cambia la legislación local, considerar agregar una subcolección `users/{uid}/termsAcceptances` con histórico de todas las versiones que aceptó el usuario, no solo la última.

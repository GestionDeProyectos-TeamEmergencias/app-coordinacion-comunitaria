# D-01 — Registro de token FCM en el cliente y captura de ubicación del referente

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.1)
> **Tickets relacionados / dependientes:** T-NLP-07 (push referentes), T-NLP-09 (broadcast del administrador)
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Se completa el ciclo de notificaciones push, que en el MVP quedó implementado únicamente del lado del backend (Cloud Functions ya hacían `messaging.sendEachForMulticast` sobre `users/{uid}.fcmTokens`), pero **sin nadie escribiendo ese array desde la app**. Esta tarea cierra el gap end-to-end:

1. **Cliente Flutter:** pide permisos de notificaciones, obtiene el token FCM del dispositivo y lo persiste en `users/{uid}.fcmTokens` (array, para soportar múltiples dispositivos por usuario). Renueva el token cuando rota (`onTokenRefresh`) y lo retira del array al cerrar sesión.
2. **Ubicación del Referente Barrial:** se agrega una pantalla bloqueante de setup que captura `coverageLat`/`coverageLng` mediante GPS. Sin estos valores, la function `findNearbyReferentes` (`functions/src/pushNotifications.ts:70-73`) descarta al referente aunque tenga el token registrado.

## 2. Justificación (por qué excede el alcance original)

El plan original del MVP asumía que la sola existencia del flujo backend ya proveía notificaciones operativas. La devolución (`DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.1) detectó que:

- `firebase_messaging: ^15.1.3` estaba declarado en `pubspec.yaml` pero **nunca importado ni invocado en ninguna parte de `lib/`**.
- `UserModel` no tenía el campo `fcmTokens` ⇒ aunque la app hubiese registrado tokens, el mapeo a/desde Firestore los hubiera perdido en cada `toFirestore`.
- Los referentes barriales nunca proveían su ubicación de cobertura ⇒ la función `findNearbyReferentes` siempre retornaba lista vacía.

En la práctica, **ningún push se entregaba aunque toda la lógica de servidor estuviera correcta**. Eso convierte a T-NLP-07/T-NLP-09 en features "verdes en el repo y rotas en producción". D-01 es el mínimo necesario para que el flujo de notificaciones del MVP sea verificable end-to-end.

## 3. Decisiones de diseño

### 3.1 Modelo multi-dispositivo (`fcmTokens` como array)

- Se usa `arrayUnion` / `arrayRemove` sobre `users/{uid}.fcmTokens` para soportar múltiples sesiones del mismo usuario (web + móvil, varios celulares).
- Es consistente con el backend que ya hace `flatMap` sobre `fcmTokens` (`pushNotifications.ts`, `adminBroadcast.ts`).
- El backend ya limpia tokens inválidos cuando FCM responde `registration-token-not-registered`, así que la rotación natural mantiene el array limpio sin trabajo adicional del cliente.

### 3.2 Idempotencia del servicio

`FcmService.registerForUser(uid)` corta tempranamente si ya se registró para ese mismo uid en esta instancia, evitando dobles llamadas innecesarias a `getToken()` y a Firestore. Esto importa porque el sync con auth corre en `fireImmediately: true` y puede dispararse en cada rebuild de `App`.

### 3.3 Limpieza del token en logout

El `unregisterCurrent` se llama **explícitamente desde `AuthNotifier.logout()` antes del `signOut`**, no solo desde el listener de `authStateProvider`. Razón: una vez ejecutado `signOut`, `request.auth` queda nulo y las reglas Firestore rechazan el `update` sobre el doc del propio user. El listener queda como red de seguridad para sesión expirada / app abierta sin user logueado.

### 3.4 Sincronización con auth vía `ref.listen`

Se usa un `Provider<void>` (`fcmAuthSyncProvider`) que escucha el `authStateProvider` y dispara register/unregister según transiciones. Esto evita que la lógica de FCM esté esparcida en pantallas y se ejecuta una sola vez, montada en `App` (raíz del árbol autenticado).

### 3.5 Pantalla bloqueante de ubicación

Para Referentes Barriales sin `coverageAreaCenter`, el `routerProvider` redirige a `/referent/setup-location` sin importar a qué intenten navegar. Decisión: **bloquear el acceso al resto de la app** hasta completar el setup. Sin ubicación, el referente es invisible al sistema de push y deja de cumplir su rol.

La pantalla pide permisos vía `Geolocator`, captura una sola muestra (`accuracy: medium`, `timeLimit: 8s`) y escribe `coverageLat`/`coverageLng`. El router observa el stream del doc y, al actualizarse, libera al user automáticamente.

### 3.6 División en dos archivos para evitar ciclo de imports

`fcmServiceProvider` quedó en su propio archivo (`fcm_service_provider.dart`) porque `auth_provider.dart` necesita importarlo (para `logout()`), y a su vez `fcm_provider.dart` importa `auth_provider.dart` (para `authStateProvider`). Sin esta división habría import circular.

### 3.7 Handler de background como top-level

`_fcmBackgroundHandler` está declarado top-level en `main.dart` y anotado `@pragma('vm:entry-point')`. Es requisito de `firebase_messaging`: el handler corre en un isolate separado spawn-eado por el SO, no comparte memoria con el isolate principal. Por ahora solo loggea — el sistema operativo muestra la notificación si el mensaje trae bloque `notification`.

## 4. Archivos modificados / creados

### Creados
- `lib/features/notifications/data/services/fcm_service.dart` — servicio FCM
- `lib/features/notifications/presentation/providers/fcm_service_provider.dart` — provider singleton
- `lib/features/notifications/presentation/providers/fcm_provider.dart` — sync con auth
- `lib/features/notifications/presentation/pages/referent_location_setup_page.dart` — pantalla de setup
- `test/unit/notifications/fcm_service_test.dart` — 7 tests del servicio

### Modificados
- `lib/features/auth/data/models/user_model.dart` — campo `fcmTokens`
- `lib/features/auth/domain/entities/app_user.dart` — campo `fcmTokens`
- `lib/features/auth/presentation/providers/auth_provider.dart` — `logout()` invoca `unregisterCurrent`
- `lib/app/app.dart` — monta `fcmAuthSyncProvider` en la raíz
- `lib/app/router.dart` — redirige referentes sin coverage a `/referent/setup-location`
- `lib/main.dart` — handler de background y registro de `onBackgroundMessage`

### No modificados (validados pero ya correctos)
- `firestore.rules` — el bloque de campos prohibidos en `users` (líneas 62-67) **no** incluye `fcmTokens`, `coverageLat`, `coverageLng`, por lo que el user ya podía actualizarlos sobre su propio doc.
- `functions/src/pushNotifications.ts` — el filtro por proximidad usa `coverageLat/Lng`, ahora finalmente poblados desde el cliente.
- `pubspec.yaml` — `firebase_messaging: ^15.1.3` y `geolocator: ^13.0.1` ya estaban declarados.

## 5. Impacto

| Antes de D-01 | Después de D-01 |
| --- | --- |
| El array `users/{uid}.fcmTokens` siempre estaba vacío (o ausente). | El cliente registra el token al loguearse y lo rota cuando cambia. |
| `findNearbyReferentes` retornaba `[]` siempre. | Los referentes con ubicación recibirán push de incidentes cercanos. |
| `messaging.sendEachForMulticast` recibía lista vacía → 0 deliveries. | El multicast efectivamente despacha a los dispositivos del referente. |
| El broadcast del Admin (T-NLP-09) caía al vacío para todos. | El broadcast es ahora la primera feature de comunicación operativa. |
| Cerrar sesión dejaba el token activo en el array. | El token se remueve antes del `signOut`. |

## 6. Limitaciones conocidas

- **Web `vapidKey`**: `getToken()` en Flutter Web requiere una `vapidKey` configurada en `lib/firebase_options.dart` (consola Firebase → Cloud Messaging → Web push certificates). Si falta, el servicio retorna `false` sin error y simplemente no se persiste el token. **No bloqueante para móvil**, pero debe completarse antes de habilitar push en web.
- **Permiso denegado**: si el user rechaza la notificación, el servicio retorna `false` y no se re-pregunta automáticamente. En iOS, el sistema **no** vuelve a mostrar el diálogo una vez denegado: el user debe ir a Ajustes manualmente. Hoy no hay UI que comunique esto (TODO: D-08 o futuro F-XX).
- **Ubicación una sola muestra**: la pantalla captura una sola lectura del GPS. Si el referente se muda, debe re-capturar manualmente desde el perfil (UI no implementada todavía — sale del scope de D-01 y se cubrirá en D-02 o un edit de perfil).
- **Token rotation cleanup**: cuando el token rota, el viejo queda en el array hasta que FCM lo reporte como inválido y el backend lo limpie en el próximo send. No hay limpieza proactiva del lado del cliente.
- **Handler de foreground mínimo**: hoy solo loggea. Una notificación recibida con la app abierta no muestra banner ni snackbar; el user solo la verá cuando vaya al feed de alertas. Mejora candidata para F-04 (notificación in-app).
- **Tests**: cubren la unidad `FcmService` con `FakeFirebaseFirestore`. No se testea la integración con el `AuthNotifier` ni el routing condicional — son pruebas de mayor superficie que aplican mejor en un futuro `integration_test/`.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (92/92)
```

## 8. Próximos pasos relacionados (no incluidos en D-01)

- **D-02**: límite de rate del broadcast del administrador (cuando ya hay tokens reales, sin cap esto se vuelve un foot-gun).
- **D-08**: surface de errores de notificaciones (qué pasa si el user denegó el permiso, cómo recuperarlo).
- **F-04**: UX de notificaciones in-app (snackbar/banner cuando llega un push en foreground).
- Edición de ubicación de cobertura desde el perfil del referente.

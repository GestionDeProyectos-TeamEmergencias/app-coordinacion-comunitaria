# F-03 — Selector de ubicación interactivo en el formulario de reporte

> **Tipo:** `ajuste-feedback` (RF-REP-01 ya prescribía captura de ubicación; F-03 mejora la UX)
> **Tickets relacionados:** RF-REP-01, Informe de Viabilidad §4 (validación cruzada con ubicación)
> **Fecha de implementación:** 2026-06-25
> **Estado:** completado

## 1. Qué es

Reemplaza la captura silenciosa de GPS al pulsar "Enviar" por un **mini-mapa interactivo** que aparece dentro del formulario de reporte (`ReportFormPage`). Comportamiento:

- Al abrir el formulario, el widget pide el GPS y centra el mapa en la ubicación actual con un marker fijo.
- El usuario puede **tocar** cualquier punto del mapa para mover el marker.
- El marker es **arrastrable** (long-press + drag).
- Botón **"Mi ubicación"** refresca el GPS y centra el mapa en él.
- Botón **"Volver al GPS"** resetea la selección a la última lectura del GPS sin re-pedir permisos.
- **Badge "Fuera de cobertura"** aparece debajo del mapa si la ubicación elegida cae fuera del radio configurado (preview de la validación que el backend igual aplica).
- El reporte rápido (`QuickReportButton`) sigue como hoy — captura GPS automática, sin selector. F-03 aplica al formulario / voz.

## 2. Por qué se hizo

La observación **O3** del uso real: un vecino que llega a su casa y se acuerda del bache no debería ser obligado a volver al lugar para reportar. F-03 le permite fijar manualmente la ubicación real del incidente.

El SRS RF-REP-01 ya prescribía "captura de ubicación", sin especificar si era automática o ajustable. El MVP había implementado solo la versión automática. F-03 completa la promesa con la versión más flexible.

Además, conecta con la mitigación "validación cruzada con dirección ingresada" del Informe de Viabilidad (§4): cuanto más control tiene el usuario sobre dónde reporta, menos falsos positivos por GPS impreciso.

Categorización: **`ajuste-feedback`** — afina el flujo de captura ya existente; no agrega alcance nuevo del SRS.

## 3. Decisiones de diseño

### 3.1 Selector inline en el formulario, no pantalla aparte

Alternativas evaluadas:

- **Inline en el form (elegida)**: el mini-mapa vive como una sección más del formulario, debajo de la descripción y antes de la categoría. El usuario lo ve y lo ajusta sin abandonar el flujo.
- Pantalla aparte ("Elegí la ubicación") con navegación: agregaría fricción (1 tap más) sin valor — el usuario igual va a verla siempre.
- Solo botón "Ajustar ubicación" + diálogo modal con mapa: similar al inline pero con peor visibilidad de qué se está reportando dónde.

El inline gana por simplicidad UX. El costo es que el formulario es más alto y el botón "Enviar" queda fuera del fold inicial en pantallas chicas — aceptable porque el scroll del form ya existía con foto/descripción.

### 3.2 GPS como adapter inyectable (`GpsFetcher`)

`Geolocator.getCurrentPosition` no se puede mockear en widget tests sin hacks. Para hacer el notifier testeable, el GPS está detrás de un `typedef GpsFetcher = Future<LatLng> Function()` con su propio provider (`gpsFetcherProvider`). En tests, override con un closure síncrono que devuelve coordenadas fijas. Lo mismo se hizo en D-10 con `vitalRiskCheckServiceProvider`.

### 3.3 Estado del picker: `selected` separado de `gpsCurrent`

El notifier mantiene dos coordenadas:

- `selected`: lo que el usuario fijó (default = GPS al cargar).
- `gpsCurrent`: la última lectura del GPS, para que "Volver al GPS" tenga referencia.

Esto deja al usuario libre de mover el marker varias veces sin perder la opción de volver al GPS original. Al pulsar "Mi ubicación", refrescamos `gpsCurrent` (puede haber caminado desde que abrió) y también seteamos `selected = gpsCurrent`.

### 3.4 Errores de GPS no bloquean el envío

Si el GPS falla (permiso denegado, timeout, sin conexión), el notifier no aborta. Muestra `gpsError` como texto debajo del mapa, pero permite al usuario fijar manualmente con tap-to-place. Es coherente con la filosofía del Informe de Viabilidad: la ubicación es un dato crítico, pero el sistema no debe quedar inutilizable si el GPS no responde.

### 3.5 Badge "Fuera de cobertura" como preview, no como bloqueo

El backend igual rechaza reportes fuera de cobertura (T-AUTH-06 / `OutOfCoverageException`). El badge solo avisa al usuario *antes* de enviar para evitar un round-trip frustrante. No deshabilita el botón "Enviar" — la decisión final del bloqueo la sigue tomando el server-side (`ReportNotifier.submitForm` ya valida con `coverageConfigProvider`). Razón: si en algún momento se relaja la regla (p. ej. permitir reportes "cerca del borde" con flag), no hay que tocar la UI.

### 3.6 `LocationPickerCard.disableMapForTests` (hack consciente)

`google_maps_flutter` usa platform views que no renderizan en widget tests (crashea con `RenderAndroidView._sizePlatformView`). Para que los widget tests del `ReportFormPage` sigan corriendo, agregué una variable estática `disableMapForTests` que reemplaza el `GoogleMap` por un placeholder vacío. Está anotada con `@visibleForTesting`. Es la solución estándar de la comunidad Flutter para platform views en tests. No afecta producción.

### 3.7 Reporte rápido sigue con GPS automático

`QuickReportButton` apunta a velocidad (RNF-REN-01: ≤3 segundos). Forzar un selector de ubicación lo rompería. Quien necesita ajustar ubicación usa formulario.

## 4. Impacto en el sistema

### Creados
- `lib/features/incidents/presentation/providers/location_picker_provider.dart` — estado + notifier + `gpsFetcherProvider` + `selectedLocationIsWithinCoverageProvider`.
- `lib/features/incidents/presentation/widgets/location_picker_card.dart` — widget del mini-mapa.
- `test/unit/incidents/location_picker_notifier_test.dart` — 8 tests (estado del notifier + helper de cobertura).

### Modificados
- `lib/features/incidents/presentation/pages/report_form_page.dart`:
  - Elimina `_getPosition()` (la lógica vive en el picker).
  - Inserta `LocationPickerCard` debajo de descripción.
  - `_submit()` lee la ubicación de `locationPickerProvider` en vez de pedir GPS.
  - Snackbar de error si no hay ubicación seleccionada.
- `test/widget/incidents/report_form_page_test.dart`:
  - `setUpAll` activa `LocationPickerCard.disableMapForTests = true`.
  - `_buildSubject` override `gpsFetcherProvider` con coordenadas fijas.
  - `pumpAndSettle()` reemplazado por `pump()` repetido (GoogleMap nunca settlea).
  - Pre-tap: `unfocus + ensureVisible + warnIfMissed: false` para acomodar el form más alto y el foco del TextField.

### No modificados
- `lib/features/incidents/presentation/widgets/quick_report_button.dart` — el reporte rápido mantiene el GPS automático (decisión §3.7).
- Backend — la validación de cobertura sigue corriendo (`ReportNotifier.submitForm` ya la invoca con la lat/lng que reciba).

## 5. Limitaciones conocidas

- **Drag del marker es flaky en Flutter Web** en algunas combinaciones de browser+touch device. El tap-to-place es siempre el fallback universal y funciona en todo. Documentado en el doc-comment del widget.
- **Sin reverse geocoding.** El picker no muestra "Av. Belgrano 1234" sino "−34.6037, −58.3816". Para usabilidad real, agregar `geocoding` package y mostrar la dirección debajo. Out of scope F-03 (mejora candidata).
- **Sin search box.** Tampoco "Buscar dirección…" para saltar al lugar. Misma razón.
- **Permiso de ubicación se pide en cada apertura del formulario.** Si el usuario lo deniega, queda fijo en denegado y debe ir a Ajustes. Mismo comportamiento que el flujo previo; no cambió en F-03.
- **No hay historial de "mis ubicaciones frecuentes".** Una mejora futura: ofrecer 3 chips con las últimas 3 ubicaciones donde el user reportó.
- **`pumpAndSettle` no funciona en widget tests del form** — hay que usar `pump()` explícito. Documentado en el test. Si el equipo agrega tests nuevos del formulario, deben seguir el mismo patrón.
- **No hay widget test del LocationPickerCard en aislamiento.** El mock de `GoogleMap` es non-trivial; los tests del notifier cubren la lógica de estado. Quedaría para integration tests.

## 6. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (149/149)
```

### Pruebas manuales

1. **Web (Chrome) + Android**: abrir el formulario → ver el mini-mapa centrarse en el GPS actual con marker visible.
2. Tocar otro punto dentro del radio → marker se mueve, badge de cobertura no aparece.
3. Tocar un punto fuera del radio → badge rojo "Fuera de cobertura" aparece debajo.
4. Long-press en el marker + arrastrar → marker se mueve al soltar (drag-end).
5. Tocar "Volver al GPS" → marker vuelve al centro original.
6. Tocar "Mi ubicación" → mapa anima al GPS actual (si caminaste, debería actualizar).
7. Negar permiso de ubicación → mensaje de error visible, tap-to-place sigue funcionando.
8. Completar form con ubicación válida + tap Enviar → reporte se persiste con las coords elegidas.

## 7. Referencias

- Widget: `lib/features/incidents/presentation/widgets/location_picker_card.dart`.
- Notifier: `lib/features/incidents/presentation/providers/location_picker_provider.dart`.
- Tests: `test/unit/incidents/location_picker_notifier_test.dart`.

### Coordinación con tickets vecinos

- **F-01** (Mis reportes): si en una iteración futura se permite editar la ubicación del reporte propio mientras `status == recibido`, este selector se puede reutilizar en el editor (`MyReportEditPage`) cambiando una línea: hoy F-01 no edita ubicación.
- **D-02** (mapa del barrio): el selector usa el mismo `CoverageConfig` que el mapa público para el círculo de preview. Si en el futuro F-07 implementa polígono, hay que cambiar el `Circle` por `Polygon`.

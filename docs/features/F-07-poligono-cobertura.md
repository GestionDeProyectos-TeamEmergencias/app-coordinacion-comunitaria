# F-07 — Área de cobertura como polígono

> **Tipo:** `ajuste-feedback` (cierre de deuda del MVP — RF-REP-01 / RF-ADM-01)
> **Tickets relacionados:** O7 (docente), RF-REP-01 ("polígono o radio"), RF-ADM-01, T-AUTH-06 (CoverageConfig actual)
> **Fecha de implementación:** 2026-06-27
> **Estado:** completado

## 1. Qué es

`CoverageConfig` gana un campo opcional `polygonPoints`. Si está presente y tiene al menos 3 vértices, la validación de cobertura usa **point-in-polygon (ray casting)** en lugar de la distancia de Haversine al centro del círculo. La misma lógica corre en cliente (`coverage_config.dart`) y backend (`coverageValidation.ts`). La `CoverageConfigPage` del admin suma un modo **"Editar polígono"**: tap para agregar vértices, drag para moverlos, long-press para borrar el más cercano, y "Limpiar polígono" para volver al círculo. Retrocompatibilidad total con el modo círculo.

## 2. Por qué se hizo — cierre de deuda, NO scope expansion

> **Importante para la defensa:** F-07 **no** es alcance nuevo. La devolución (§4.1) aclara que el polígono **ya estaba en el SRS**: RF-REP-01 define el perímetro como "**polígono o radio**" y RF-ADM-01 asume la misma definición de área. El MVP lo descopeó a círculo en T-AUTH-06 por simplicidad. F-07 completa el requisito especificado que se había recortado. Es `ajuste-feedback` (deuda del MVP), no una extensión de producto.

La observación **O7** del docente lo señaló: el área real de un barrio rara vez es un círculo perfecto; un polígono representa el perímetro con fidelidad.

## 3. Decisiones de diseño

### 3.1 Algoritmo: ray casting (paridad de cruces)

Se eligió **ray casting** (trazar una semirrecta horizontal desde el punto y contar cruces con los lados; impar = dentro) por ser el estándar para point-in-polygon de propósito general, O(n) sobre los vértices, sin dependencias y trivial de espejar en Dart y TypeScript. Alternativa descartada: winding number (más robusto para auto-intersecciones, pero innecesario para polígonos simples dibujados a mano y más caro de explicar/mantener).

### 3.2 Convención de borde: inclusiva

El círculo usa `distance <= radius` (borde **dentro**). Para mantener coherencia, el polígono también trata el borde como dentro: antes del conteo de cruces se chequea explícitamente si el punto coincide con un vértice o cae sobre un lado (colinealidad por producto cruzado ≈ 0 dentro del bounding box del segmento). Esto evita la ambigüedad clásica del ray casting en bordes/vértices y hace determinísticos los casos límite.

### 3.3 Plano lat/lng euclídeo

El ray casting trata (lng, lat) como un plano cartesiano (x = lng, y = lat). Para áreas barriales (pocos km) la distorsión por proyección es despreciable y no afecta la decisión dentro/fuera. No se proyecta a UTM ni se usa geometría esférica: sería sobre-ingeniería para el caso de uso. (El círculo sí usa Haversine porque ahí la distancia métrica importa.)

### 3.4 Dominio plugin-free: `polygonPoints` como records, no `LatLng`

La entidad `CoverageConfig` vive en `domain/` y hasta ahora no dependía de `google_maps_flutter`. Para no acoplar el dominio al plugin de mapas, el polígono se modela como `List<CoverageVertex>` donde `CoverageVertex = ({double lat, double lng})` (record puro de Dart 3, con value-equality nativa). La conversión `LatLng ↔ CoverageVertex` ocurre solo en la capa de UI (`CoverageConfigPage`) y de datos. `isWithinCoverage` sigue recibiendo primitivos (`double lat, double lng`), así que también queda libre del plugin.

### 3.5 Retrocompatibilidad y "dispatch" por presencia

`isWithinCoverage` despacha: si `polygonPoints != null && length >= 3` → polígono; si no → círculo. Un `polygonPoints` ausente, null o con `<3` vértices **siempre** cae al círculo. Así, configs viejas (sólo centro+radio) siguen funcionando sin migración. La serialización es tolerante: ignora vértices inválidos y descarta polígonos de menos de 3 puntos al leer.

### 3.6 Persistencia y "limpiar polígono"

En `config/coverage` el polígono se guarda como `polygonPoints: [{lat, lng}, ...]`. Al guardar en modo círculo (o tras "Limpiar polígono"), el datasource escribe `FieldValue.delete()` sobre `polygonPoints` (con `merge: true`), borrando el campo para que la lectura vuelva al círculo. Evita dejar un polígono fantasma en el doc.

### 3.7 Edición en el mapa: tap / drag / long-press

`google_maps_flutter` no expone long-press por marcador, así que el borrado de vértices se hace con el long-press **del mapa**, eliminando el vértice más cercano (distancia euclídea en grados, suficiente a escala barrial). Agregar = `onTap`; mover = `Marker` `draggable` con `onDragEnd`. El polígono se dibuja como overlay `Polygon` cuando hay ≥3 vértices. En modo polígono se oculta el círculo para no confundir cuál valida.

### 3.8 El área dibujada coincide con la que valida (en todas las pantallas)

La **edición** del polígono vive sólo en `CoverageConfigPage` (admin). La **visualización**, en cambio, se dibuja en todos los mapas para que lo mostrado coincida con lo que se valida y no confunda al usuario:

- `map_page.dart` (mapa de incidencias, visible a todos incl. admin).
- `location_picker_card.dart` (selector de ubicación al reportar, vecino).
- `coverage_config_page.dart` (panel admin).

Los tres usan el mismo dispatch: si `config.usesPolygon` → dibujan el `Polygon`; si no → el `Circle`. Así se evita el caso confuso de un reporte que cae *dentro* del círculo dibujado pero *fuera* del polígono real (más ajustado) y termina rechazado sin explicación visual.

> **Nota:** una versión previa de F-07 limitaba el dibujo del polígono al panel admin. Se extendió a los mapas compartidos para mantener coherencia entre lo dibujado y lo validado.

### 3.9 Sin tests de reglas

`config/coverage` ya estaba gobernado por la regla existente (lectura: activos; escritura: admin). F-07 no cambia reglas, así que no agrega deuda de tests de reglas.

## 4. Impacto en el sistema

### Creados
- `test/unit/admin/coverage_polygon_test.dart` — point-in-polygon (borde, cóncavo, vértice exacto, fuera, primer/último punto), dispatch círculo↔polígono y round-trip de serialización.
- `docs/features/F-07-poligono-cobertura.md` — este documento.

### Modificados
- `lib/features/admin/domain/entities/coverage_config.dart` — `CoverageVertex`, campo `polygonPoints`, `usesPolygon`, `pointInPolygon` (+ `_isOnSegment`) y dispatch en `isWithinCoverage`.
- `lib/features/admin/data/datasources/coverage_config_remote_datasource.dart` — (de)serialización del polígono + `FieldValue.delete()` al limpiar.
- `lib/features/admin/presentation/pages/coverage_config_page.dart` — modo "Editar polígono": estado, toggle, limpiar, tap/drag/long-press, overlay `Polygon`/`Marker`, validación pre-guardado (<3 vértices). En modo polígono se ocultan los campos centro/radio (respaldo inactivo) con nota aclaratoria.
- `lib/features/map/presentation/pages/map_page.dart` — dibuja el `Polygon` de cobertura (fallback a círculo) en el mapa de incidencias.
- `lib/features/incidents/presentation/widgets/location_picker_card.dart` — idem en el selector de ubicación del reporte.
- `lib/core/constants/app_strings.dart` — strings de F-07.
- `functions/src/coverageValidation.ts` — `PolygonVertex`, `polygonPoints` en la interfaz, `parsePolygon`, `pointInPolygon` (+ `isOnSegment`), dispatch en `isWithinCoverage` y lectura en `loadCoverageConfig`.
- `functions/src/coverageValidation.test.ts` — espejo de los casos de polígono + `loadCoverageConfig` con/sin polígono.

### No modificados (verificados, ya correctos)
- `lib/features/incidents/presentation/providers/location_picker_provider.dart` y `incidents_provider.dart` — llaman `config.isWithinCoverage`; el dispatch es transparente.
- `functions/src/index.ts` — el pipeline ya usa `isWithinCoverage`; sin cambios de llamada.

## 5. Limitaciones conocidas

- **Plano euclídeo.** A escalas grandes (decenas de km) la falta de proyección introduciría un error mínimo en bordes muy inclinados. Irrelevante para barrios; documentado por completitud.
- **Polígonos simples, sin auto-intersección.** El ray casting asume un polígono simple. La UI no impide que el admin cruce lados; el resultado sería ambiguo en esa región. Mejora futura: validar simplicidad o pasar a winding number.
- **Borrado por cercanía.** El long-press borra el vértice más próximo; con vértices muy juntos podría no ser el deseado. Aceptable para edición manual; un hit-test por marcador sería más preciso.
- **Sin "deshacer".** No hay undo de la última edición de vértice; se reconstruye manualmente o se limpia.

## 6. Comandos de verificación

```bash
# Cliente
flutter analyze --no-pub
flutter test

# Backend
cd functions && npx tsc --noEmit && npm test
```

### Pruebas manuales con emulador

1. `firebase emulators:start --only firestore,auth`.
2. Como admin, abrir "Área de cobertura" → "Editar polígono". Tocar el mapa para crear ≥3 vértices; arrastrar uno; long-press para borrar uno. Guardar.
3. Verificar en `config/coverage` que `polygonPoints` quedó persistido.
4. Como vecino, reportar **dentro** del polígono → aceptado; **fuera** (pero dentro del viejo círculo) → rechazado por cobertura. Confirma que valida por polígono.
5. "Limpiar polígono" → guardar → verificar que `polygonPoints` se borró y la validación vuelve al círculo (config previa sigue funcionando).

### Deploy obligatorio antes de demo

```bash
firebase deploy --only functions:processIncident   # o el nombre real del trigger del pipeline
```
(No requiere cambios de reglas: `config/coverage` ya estaba cubierto.)

## 7. Próximos pasos relacionados

- **Validación de simplicidad** del polígono en la UI (impedir auto-intersección) o migrar a winding number.
- **Undo / edición por marcador**: hit-test por vértice para mover/borrar con precisión y deshacer la última acción.
- **Multi-área**: soportar varios polígonos disjuntos (barrios separados) en una sola config.

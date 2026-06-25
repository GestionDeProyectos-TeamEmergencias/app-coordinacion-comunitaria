# D-10 — Reporte por voz: persistir con `sourceType: voice`

> **Tipo:** deuda-mvp (cierre de gap detectado en `DEVOLUCION_PLAN_TERCERA_ITERACION.md` §11.11)
> **Tickets relacionados:** RF-REP-02 (reporte por voz), T-INF-04 (contrato `IncidentEvent`)
> **Fecha de implementación:** 2026-06-24
> **Estado:** completado

## 1. Descripción

Cablea el flujo de reporte por voz para que invoque `SubmitVoiceReportUseCase` (que ya existía y estaba provider-cableado pero **nunca se llamaba** desde la UI) y el incidente se persista con `sourceType: voice` en lugar de `form`.

Antes de D-10, `report_form_page.dart` transcribía al campo de texto y luego ejecutaba siempre `submitForm()`, produciendo un incident con `sourceType: form` aunque el usuario hubiese reportado por voz. El "Reporte Abreviado / voice" del SRS nunca se producía y el use case dedicado era código muerto.

## 2. Justificación

RF-REP-02 establece tres modos de reporte distintos en `SourceType` (quick, form, voice). El contrato T-INF-04 obliga a que cada incident tenga un `sourceType` que refleje el método real de entrada. Antes de D-10, el dataset quedaba **falseado**: cualquier métrica o auditoría que filtrara por `sourceType` veía sobre-representación de form y cero voice. Es deuda menor pero ensucia análisis y deja muerto el use case ya implementado.

## 3. Decisiones de diseño

### 3.1 Flag de estado `_originatedFromVoice` que sobrevive a la edición

El criterio explícito del ticket: *"si el usuario edita la transcripción antes de enviar, sigue siendo voice — corregir transcripción no convierte el reporte en form"*. La forma natural de implementarlo es una variable de estado en la página (`_originatedFromVoice`) que se enciende cuando llega `onTranscription` del `VoiceReportWidget` y persiste hasta que el usuario:

- **Envía con éxito** → se resetea.
- **Cancela explícitamente** con el botón "X" del chip "Reporte por voz".

Editar el campo de descripción **no** apaga el flag. Esto coincide con el contrato del SRS: la transcripción puede tener errores y el usuario debe poder corregirla sin perder el origen del reporte.

### 3.2 Voz oculta categoría y foto, no las exige

El use case `SubmitVoiceReportUseCase` no acepta `category` ni `photoUrl` — solo `transcribedText`. El SRS T-INF-04 deja `category` opcional, y el pipeline NLP (`semanticExtraction`) la enriquece desde la descripción.

En modo voz:

- Se **ocultan** los inputs de categoría y foto (no se renderiza el dropdown ni el botón "Adjuntar").
- La validación del form **no exige** categoría.
- Si el usuario quiere agregar categoría/foto, cancela con el chip y entra al form normalmente.

Alternativa descartada: ampliar el use case voice para aceptar foto/categoría. Romperíamos la separación SRS entre "reporte abreviado" y "reporte detallado". Si en el futuro hace falta un híbrido, se diseña como modo nuevo.

### 3.3 Chip "Reporte por voz" con botón cancelar como afordancia visible

Sin marcador en la UI, el usuario que transcribió y editó podría dudar si su reporte va por el camino voice o form. El chip:

- Muestra el ícono de micrófono y el texto "Reporte por voz".
- Tiene una "X" que limpia el flag **y** vacía el campo de descripción (vuelta a estado inicial limpio).

### 3.4 Sin cambios al callable de vital risk

D-03 ya hace el chequeo de riesgo vital sobre `description` antes de enviar. El flag `_originatedFromVoice` no afecta esa lógica: el texto se evalúa igual, ya sea tipeado o transcripto. Mantener un único entry-point al chequeo evita olvidar el aviso 911/107 en el flujo de voz.

### 3.5 Sin cambios al `SubmitVoiceReportUseCase` ni al `ReportNotifier`

Ambos ya estaban implementados y testeados. La deuda era cliente-only: el form llamaba al método equivocado. D-10 es básicamente "conectar dos cables que ya existían".

## 4. Archivos modificados / creados

### Modificados
- `lib/features/incidents/presentation/pages/report_form_page.dart` — agrega `_originatedFromVoice`, lo enciende en `onTranscription`, condiciona la validación de categoría, oculta los inputs de categoría/foto en modo voz, agrega el chip cancelable, y bifurca `_submit()` para invocar `submitVoice` o `submitForm` según corresponda.

### Creados
- `test/unit/incidents/report_notifier_voice_test.dart` — tests del notifier que validan que (a) `submitVoice` invoca `SubmitVoiceReportUseCase` y **no** el form, y (b) la validación de cobertura sigue activa en el camino voice.

### No modificados (verificados pero ya correctos)
- `lib/features/incidents/domain/usecases/submit_voice_report_usecase.dart` — el use case ya construía `IncidentEvent(sourceType: SourceType.voice, ...)`. Sin cambios.
- `lib/features/incidents/presentation/providers/incidents_provider.dart` — `ReportNotifier.submitVoice` ya estaba implementado, solo no se llamaba. Sin cambios.
- `test/unit/incidents/submit_voice_report_usecase_test.dart` — tests pre-existentes del use case siguen verdes.

## 5. Impacto

| Antes de D-10 | Después de D-10 |
| --- | --- |
| Reporte por voz se persistía con `sourceType: form`. | Se persiste con `sourceType: voice`. |
| Métricas/auditoría por `sourceType` quedaban falseadas. | Reflejan el método real de entrada. |
| `SubmitVoiceReportUseCase` era código muerto invocado solo por tests. | Se invoca desde la UI cuando el usuario reporta por voz. |
| Modo voz exigía categoría (y la UI la mostraba). | Modo voz oculta categoría/foto; la categoría se enriquece por NLP en el pipeline backend. |
| Sin indicador visible del modo "voz" durante la edición. | Chip "Reporte por voz" con botón cancelar. |
| Editar la transcripción dejaba al reporte indistinguible de uno tipeado. | El flag `_originatedFromVoice` sobrevive a la edición. |

## 6. Limitaciones conocidas

- **Si el usuario edita el chip "X" después de transcribir queda con descripción vacía.** Decisión deliberada: limpiar el flag **y** la descripción es coherente con "cancelé el modo voz". Si el equipo prefiere conservar el texto, es un cambio de una línea.
- **Sin auditoría server-side de la transición voice → form.** Si el cliente miente sobre `sourceType` (vía SDK directo), el backend no lo valida. Aceptable: no hay incentivo a falsificar el campo; cuando la categoría se enriquece por NLP, el sistema queda consistente independientemente del `sourceType`.
- **El callable `checkVitalRiskCallable` se invoca igual en modo voz y form.** No se trackea separadamente cuántas detecciones de riesgo vital vienen por voz. Métrica útil si se quiere afinar el diccionario (T-NLP-06).
- **No hay widget test del flujo completo de voz.** Las dependencias (geolocator, image picker, vital risk callable, coverage config) hacen prohibitivo testear la página entera en widget test. Los tests del notifier validan el cableado clave (invoca el use case correcto). Si se agrega un emulador en CI, conviene un test E2E para cerrar el círculo.

## 7. Comandos de verificación

```bash
flutter analyze --no-pub
# No issues found!

flutter test
# All tests passed! (134/134)
```

### Pruebas manuales

1. Abrir `ReportFormPage` → tocar "Voz" en el segmented button → hablar → el widget transcribe al campo.
2. Verificar que aparece el chip "Reporte por voz" debajo del input y que los campos de categoría y foto **desaparecen**.
3. Editar el texto manualmente → el chip sigue ahí (no se borra por editar).
4. Tocar enviar → el incidente persistido en Firestore tiene `sourceType: 'voice'`.
5. Repetir el flujo pero tocando la "X" del chip antes de enviar → el chip desaparece, vuelven categoría/foto, el campo queda vacío.
6. Ingresar texto manualmente desde cero (sin haber usado voz) → reportar → el incidente persiste con `sourceType: 'form'`.

## 8. Próximos pasos relacionados

- **Métricas de adopción del modo voz**: instrumentar para validar si los usuarios efectivamente usan el modo voz cuando está disponible, o si lo descartan por la fricción del permiso de micrófono.
- **F-01 (Mis reportes)**: mostrar el `sourceType` como badge en la card del incident permite al usuario distinguir sus reportes rápidos/de formulario/de voz a simple vista. Trivial con `IncidentEvent.sourceType` ya bien populado.
- **Calibración del prompt de NLP**: con un dataset real que distingue voice vs. form, se puede entrenar/ajustar el `semanticExtraction` para que sea más robusto a transcripciones con errores (más errores típicos esperables en voice).
- **F-03 (selector de ubicación)**: el modo voz también podría beneficiarse del selector — un reporte por voz desde el sofá igual debería poder ajustar la ubicación.

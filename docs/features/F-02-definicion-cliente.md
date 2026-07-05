# F-02 — Definición operativa del cliente objetivo

> **Tipo:** `ajuste-feedback` (operacionaliza lo ya especificado — Informe de Viabilidad §1–2, SRS §1.4/§2.3)
> **Tickets relacionados:** O2 (docente), SRS §1.4/§1.5/§2.3, Informe de Viabilidad V2 §1–2
> **Fecha de implementación:** 2026-06-27
> **Estado:** completado

## 1. Qué es

Documentación de afinamiento que produce **`docs/PRODUCT_DEFINITION.md`**: la definición operativa del producto (buyer persona principal y secundaria, journey map del vecino y del admin, casos de uso primarios vs. fuera de alcance, y principios de UX). Es el entregable que pide el docente para cerrar la observación **O2**.

Como ampliación pedida durante la implementación, F-02 también incluye **`docs/AUDITORIA_TRAZABILIDAD.md`**: una auditoría "promesas vs. implementación" que verifica, contra el código real, que todo lo documentado en SRS/Informe esté efectivamente implementado.

## 2. Por qué se hizo — cierre de feedback, NO scope expansion

> **Importante para la defensa:** F-02 **no** es alcance nuevo. El cliente **ya estaba definido** en el Informe de Viabilidad ("Municipios, Comunas, Sociedades de Fomento", contexto Junín BA) y en el SRS §1.4 / §2.3. F-02 no lo inventa: lo **operacionaliza** en persona/journey (`docs/DEVOLUCION_PLAN_TERCERA_ITERACION.md` §4.2). Es documentación de afinamiento.

La observación **O2** del docente lo señaló: *"No está claro el enfoque de la app ni el cliente objetivo. Falta una definición operativa que guíe decisiones de UX."* Sin esta definición, cada decisión de diseño se discute desde cero.

## 3. Decisiones de diseño

### 3.1 Buyer persona principal = institución, no usuario masivo

El **Administrador Vecinal** (que representa a la institución adoptante: municipio/comuna/sociedad de fomento) es la persona **principal** porque es quien adopta y, eventualmente, paga la plataforma. El **Vecino Informante** es persona **secundaria**: no compra, pero su adopción masiva es condición de éxito (aporta el valor de red). El **Referente Barrial** es persona complementaria. Esta jerarquía evita diseñar "para el que más toca la app" en lugar de "para el que decide adoptarla".

### 3.2 Reutilizar terminología, no redefinirla

El glosario del `PRODUCT_DEFINITION` **referencia** las definiciones canónicas del SRS §1.5 en lugar de duplicarlas, para evitar divergencia. Los nombres de roles, estados y entidades coinciden con el código (`vecino_informante`, `referente_barrial`, `administrador`; estados `recibido → programado → en_reparacion → solucionado`).

### 3.3 Auditoría en documento separado

La verificación "promesas vs. implementación" vive en `AUDITORIA_TRAZABILIDAD.md`, no dentro del `PRODUCT_DEFINITION`. Razón: separar el **qué prometemos** (definición de producto, estable) del **qué entregamos** (auditoría, fechada y sujeta a cambios del código). Cada uno tiene una audiencia y un ciclo de vida distintos.

### 3.4 Auditoría basada en evidencia

Cada veredicto de la auditoría se respaldó leyendo el archivo/símbolo real (no resúmenes). En particular se confirmó el cierre de las 10 deudas D-01…D-10 de la última devolución (ver `AUDITORIA_TRAZABILIDAD.md` §3).

## 4. Impacto en el sistema

### Creados
- `docs/PRODUCT_DEFINITION.md` — definición operativa del producto (entregable de O2).
- `docs/AUDITORIA_TRAZABILIDAD.md` — auditoría promesas vs. implementación.
- `docs/features/F-02-definicion-cliente.md` — este documento.

### Modificados
- `docs/BACKLOG.md` — nueva sección "Épica 6 — Tercera Iteración" con F-01…F-07 y actualización del resumen por estado.

### No modificados
- Ningún archivo de código, reglas o tests. F-02 es **doc-only**. Los gaps detectados por la auditoría se proponen como tickets nuevos, no se corrigen aquí.

## 5. Limitaciones conocidas

- **Snapshot temporal.** El `PRODUCT_DEFINITION` refleja el alcance acordado; si el SRS cambia, debe actualizarse. La auditoría está fechada (2026-06-27) y refleja el estado del código a esa fecha.
- **RNF no auditables estáticamente.** Rendimiento, disponibilidad y precisión del NLP requieren medición/test de carga; la auditoría los marca como recomendación, no como veredicto.

## 6. Comandos de verificación

Doc-only: la verificación es revisión de contenido. Opcionalmente, para respaldar la auditoría, confirmar que el código auditado está verde:

```bash
flutter test
cd functions && npm test
```

Revisión manual: abrir el preview markdown de `PRODUCT_DEFINITION.md` y `AUDITORIA_TRAZABILIDAD.md` en VS Code y comprobar que las referencias internas a SRS/Informe y a archivos de código resuelven.

## 7. Próximos pasos relacionados

- Atender los gaps remanentes de la auditoría (`AUDITORIA_TRAZABILIDAD.md` §4): push web (vapidKey), tests de integración e2e, ponderación de la verificación del referente en el score.
- Completar las claves `KAN-NN` reales de la Épica 6 en `docs/BACKLOG.md`.

# Definición de Producto — App de Coordinación Comunitaria

> **Feature:** F-02 (`ajuste-feedback`) · **Cubre:** observación O2 del docente
> **Fecha:** 2026-06-27 · **Estado:** completado
> **Fuentes que operacionaliza:** `Informe de viabilidad ajustado V2.md` §1–2, `SRS_GestionUrbanaParticipativa_v1.1.md` §1.4/§1.5/§2.3

## 1. Propósito y trazabilidad

Este documento es la **definición operativa del producto**: traduce el cliente y los usuarios —ya descritos de forma dispersa en el Informe de Viabilidad y el SRS— a artefactos accionables (buyer personas, journey maps, casos de uso y principios de UX) que guían cada decisión de diseño.

Responde a la observación **O2** del docente (`docs/PLAN_TERCERA_ITERACION.md` §2): *"No está claro el enfoque de la app ni el cliente objetivo. Falta una definición operativa que guíe decisiones de UX."*

> **Para la defensa:** F-02 es `ajuste-feedback`, **no scope nuevo**. El cliente ya estaba definido (Informe de Viabilidad: "Municipios, Comunas, Sociedades de Fomento", caso Junín BA; SRS §1.4/§2.3). Este doc lo **operacionaliza** en persona/journey; no inventa producto (ver `docs/DEVOLUCION_PLAN_TERCERA_ITERACION.md` §4.2).

La verificación de que lo aquí prometido está efectivamente implementado vive en un documento separado: **`docs/AUDITORIA_TRAZABILIDAD.md`**.

## 2. Cliente objetivo

**Cliente institucional (quien adopta y, eventualmente, paga):** **Municipios locales, Comunas y Asociaciones Vecinales / Sociedades de Fomento** (Informe §1.3, §2). El contexto inicial de referencia es la ciudad de **Junín, Buenos Aires**.

**Contexto de aplicación:** **localidades medianas y barrios en desarrollo** (SRS §1.4), donde el volumen de incidentes urbanos justifica una herramienta estructurada pero la escala no amerita las plataformas corporativas caras del mercado.

**Qué adquiere el cliente:** un canal estructurado, auditable y asistido por IA para recibir, priorizar y resolver reportes de incidentes urbanos **no críticos para la vida**, apoyado en la propia comunidad como red de sensores.

## 3. Problema que resuelve

Los vecinos **carecen de un canal estructurado** para reportar y dar seguimiento a problemas del espacio público (Informe §2). Los mecanismos actuales son informales y deficientes:

- **Llamados telefónicos** al municipio que frecuentemente **no se registran**.
- **Grupos de WhatsApp** sin estructura, donde el reporte compite con comunicaciones de todo tipo y se pierde.
- **Resignación** ante problemas que quedan sin atención.

El resultado es que no hay **distinción de urgencia** (un cable eléctrico expuesto compite con un bache menor), ni **trazabilidad**, ni **rendición de cuentas**.

**Incidentes en alcance:** baches, luminarias defectuosas, cables colgando, caída de ramas, micro-basurales, calles anegadas y similares (Informe §1, SRS §1.4).

**Qué NO es (límite explícito):** el producto **no reemplaza a los servicios de emergencia oficiales** (911, 107, Policía, Bomberos, Ambulancias) — Informe §"Límites del alcance", SRS §1.4/§1.5. Tampoco provee hardware ni conectividad a los usuarios.

## 4. Buyer personas

### 4.1 Persona principal — Administrador Vecinal (institución adoptante)

Representa a la institución que decide adoptar la plataforma y la opera día a día. Es **el decisor de compra/adopción**.

- **Perfil:** personal de junta vecinal, comuna o sociedad de fomento. Nivel técnico **intermedio-avanzado** (SRS §2.3).
- **Objetivos:** recibir reportes en un solo lugar, priorizarlos por urgencia real, coordinar la resolución y poder **rendir cuentas** de lo gestionado.
- **Frustraciones (estado actual):** reportes dispersos y sin registro; imposible saber qué es urgente; ningún historial auditable; reportes falsos o malintencionados que consumen tiempo.
- **Necesidades clave:** panel centralizado con mapa, filtros (prioridad/categoría/estado), gestión del ciclo de vida del incidente, notificaciones masivas, herramientas de moderación y calibración del motor de priorización.
- **Cómo el producto lo sirve:** Panel de Administración (mapa + lista filtrable), máquina de estados `recibido → programado → en reparación → solucionado`, moderación de reportes falsos con efecto en la reputación, broadcast por zona y calibración del algoritmo sin redeploy.

### 4.2 Persona secundaria — Vecino Informante (usuario final masivo)

Es quien aporta el **valor de red**: sin reportes de vecinos no hay producto. No "compra", pero su adopción masiva es condición de éxito.

- **Perfil:** ciudadano general, rango etario amplio, **potencialmente en movimiento** al reportar. Nivel técnico **básico** (SRS §2.3).
- **Objetivos:** reportar un problema rápido y sin fricción, y **enterarse de que se está resolviendo**.
- **Frustraciones (estado actual):** "reporté y no pasó nada"; no sabe a quién dirigirse; los canales informales no dan seguimiento.
- **Necesidades clave:** interfaz simple, **máximo 2 interacciones** para emitir un reporte, opción de **voz** para manos libres, y visibilidad del estado de su reporte.
- **Cómo el producto lo sirve:** reporte rápido (1 toque), formulario detallado y reporte por voz; "Mis reportes" con edición posterior (F-01); mapa del barrio; confirmación bilateral del cierre (F-05).

### 4.3 Persona complementaria — Referente Barrial (moderador de campo)

Usuario verificado que actúa como **brazo de verificación in situ** del Administrador. No es buyer, pero es pieza clave del modelo de ciencia ciudadana.

- **Perfil:** vecino verificado con conducta colaborativa sostenida, que conoce el barrio. Nivel técnico **intermedio** (SRS §2.3).
- **Objetivos:** enterarse rápido de incidentes cercanos y confirmarlos/descartarlos en el lugar.
- **Necesidades clave:** **alertas push geolocalizadas** (solo lo cercano, sin fatiga), capacidad de verificar con evidencia fotográfica.
- **Cómo el producto lo sirve:** alertas focalizadas por cercanía; verificación de campo con foto; cierre con evidencia (F-06).

## 5. Journey map del Vecino Informante

| Etapa | Qué hace el vecino | Fricción a evitar | Cómo lo resuelve el producto |
|---|---|---|---|
| **Descubrir** | Conoce la app por difusión del municipio/barrio | "Otra app más que no sé usar" | Onboarding simple; propósito claro (TyC + disclaimer de seguridad) |
| **Registrarse** | Crea cuenta y **acredita domicilio** (código de invitación o comprobante) | Trámite engorroso; subir documentación sensible | Carga de comprobante protegida (PII); estado `pending` hasta aprobación |
| **Reportar** | Emite el reporte: rápido (1 toque), formulario o **voz** | Trámite largo estando en la calle | ≤2 interacciones; GPS automático; selector de ubicación ajustable (F-03); voz manos libres |
| **Ser derivado (si aplica)** | Si describe un riesgo vital, se lo redirige a emergencias | Creer que la app atenderá una emergencia | Detección de riesgo vital → diálogo de derivación a **911/107**; el reporte no genera alerta comunitaria |
| **Seguir** | Ve el estado de su reporte evolucionar | "Reporté y nunca supe nada" | Estado visible (`recibido → … → solucionado`); historial; acciones del admin visibles |
| **Validar el cierre** | Confirma o disputa que el problema fue resuelto | Cierre unilateral opaco | Validación bilateral (F-05): confirma, o disputa con nota → reabre |
| **Participar** | Reacciona a reportes de otros ("Confirmo"/"No es así") | No sentirse parte | Reacciones de comunidad (F-04); reputación por buen comportamiento |

## 6. Journey map del Administrador Vecinal

| Etapa | Qué hace el admin | Necesidad | Cómo lo resuelve el producto |
|---|---|---|---|
| **Recibir** | Ve entrar reportes en el panel y el mapa | Todo en un solo lugar | Mapa centralizado + lista filtrable (RF-ADM-01) |
| **Priorizar** | Atiende primero lo urgente | Distinguir urgencia real | Score de prioridad por NLP (palabras clave + ubicación + duplicados + reputación) → {Urgente, Alta, Media, Baja} |
| **Moderar** | Filtra reportes falsos o fuera de cobertura | Proteger la señal del sistema | Validación geográfica automática; marcar `falso` → decremento de reputación → bloqueo al umbral |
| **Coordinar** | Mueve el incidente por el ciclo de vida | Estados claros y ordenados | Máquina de estados validada (`recibido → programado → en reparación → solucionado`); (re)asignar categoría y registrar acciones |
| **Resolver** | Cierra el incidente, opcionalmente con evidencia | Probar la resolución | Cierre con foto de evidencia (F-06); dispara confirmación del vecino |
| **Comunicar** | Avisa a la comunidad o a una zona | Difusión focalizada | Notificaciones masivas (global o por zona) |
| **Rendir cuentas** | Audita lo actuado | Trazabilidad | Historial de estados + acciones por incidente; auditoría persistida |

## 7. Casos de uso

### 7.1 Primarios — en alcance (MVP académico, SRS §1.4)

1. **Reporte de incidentes** por botón rápido (RF-REP-01) y formulario detallado con foto (RF-REP-03).
2. **Procesamiento con NLP**: normalización, clasificación de categoría/intención y **score de prioridad** (RF-PRO-*, RF-PRI-01/02/03).
3. **Detección de riesgo vital** y derivación a servicios oficiales (RF-PRI-05).
4. **Gestión de roles** vecino informante y administrador vecinal (RF-ROL-01, RF-ROL-03).
5. **Panel de administración** con mapa y **ciclo de vida** del incidente (RF-ADM-01, RF-ADM-02).
6. **Validación geográfica** de reportes — área de cobertura (RF-MOD-02).
7. **Persistencia auditable** de todos los eventos (RF-SAL-02).

### 7.2 Extensiones entregadas más allá del MVP

Funcionalidades especificadas como fuera del MVP académico que el equipo **sí** implementó (reporte por voz RF-REP-02, reputación RF-MOD-01, calibración RF-PRI-04, broadcast RF-ADM-04, rol referente RF-ROL-02) y las features `extra` de iteraciones posteriores (reacciones de comunidad F-04, validación bilateral F-05, evidencia de cierre F-06). El estado real de cada una se detalla en `docs/AUDITORIA_TRAZABILIDAD.md`.

### 7.3 Fuera de alcance (no exigible al producto)

- **Atención de emergencias críticas para la vida** — se deriva a 911/107 (Informe §"Límites del alcance", SRS §1.4).
- **Provisión de hardware** (dispositivos) o **planes de conectividad** a los usuarios (Informe §"Límites del alcance").
- Integraciones con sistemas municipales de terceros, facturación de obra y gestión de cuadrillas (no especificados).

## 8. Principios de UX

Derivados del Informe (§"Ventajas Competitivas", §"Conclusión de Viabilidad") y de los RNF de usabilidad del SRS:

1. **Mínima fricción para reportar.** Máximo **2 interacciones** para emitir un reporte (RNF-USA-01); el reporte rápido es de un toque. El reporte debe poder hacerse *sin interrumpir la actividad* del vecino.
2. **Interfaz híbrida y accesible.** Voz para personas en movimiento, conduciendo, con manos ocupadas o **movilidad reducida**. La voz elimina la fricción de la interacción manual.
3. **Alertas focalizadas, sin fatiga.** A diferencia de WhatsApp, se notifica **solo a los referentes cercanos** al incidente, evitando la fatiga de alertas que lleva a ignorarlas.
4. **Priorización automática y transparente.** El sistema asigna urgencia por análisis de la descripción, para atender primero lo más grave; el vecino ve en qué estado está su reporte.
5. **Transparencia y rendición de cuentas.** El estado del incidente y las acciones del admin son visibles; el cierre es **bilateral** (el vecino confirma o disputa).
6. **Ciencia ciudadana.** La comunidad colabora como **red de sensores urbanos**; el diseño refuerza la participación (reacciones, reputación) sin convertir la app en una red social.
7. **Seguridad y privacidad por defecto.** No exponer datos personales de un vecino a otros (la identidad del reportero queda opaca para terceros); los comprobantes de domicilio (PII) se protegen estrictamente.

## 9. Glosario / lenguaje ubicuo

Términos canónicos del dominio (definiciones completas en `SRS_GestionUrbanaParticipativa_v1.1.md` §1.5). Usar **siempre** estos nombres en UI, código y documentación.

| Término | Significado breve |
|---|---|
| **Incidente Urbano** | Problema no crítico para la vida detectado en el espacio público |
| **Reporte** | Registro estructurado de un incidente generado por un vecino |
| **Vecino Informante** | Usuario base que reporta incidentes (`vecino_informante`) |
| **Referente Barrial** | Usuario verificado, moderador de campo (`referente_barrial`) |
| **Administrador Vecinal** | Usuario de gestión de la plataforma (`administrador`) |
| **Score de Prioridad** | Valor numérico de urgencia calculado por el motor de priorización |
| **Motor de Priorización** | Algoritmo que clasifica la urgencia por palabras clave y reglas configurables |
| **Ciencia Ciudadana** | Modelo donde los ciudadanos actúan como sensores activos del entorno |
| **Estados del incidente** | `recibido → programado → en reparación → solucionado` (+ estados marcadores del backend) |

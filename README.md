# App de Coordinación Comunitaria

![Flutter Version](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter) ![Firebase](https://img.shields.io/badge/Firebase-Genkit%20%7C%20Functions%20%7C%20Firestore-FFCA28?logo=firebase) ![Gemini](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-8E75B2?logo=google) ![License](https://img.shields.io/badge/License-MIT-blue.svg)

Plataforma de ciencia ciudadana para el reporte de incidentes urbanos no críticos (baches, luminarias rotas, basura, cables sueltos). Actúa como puente entre los vecinos y la administración municipal/vecinal de forma eficiente y geo-referenciada.

> Proyecto académico — Grupo D, UNNOBA 2026.

---

## Descripción y Características Principales

El sistema permite a los vecinos reportar incidentes urbanos mediante texto, foto o voz. Un motor de NLP (Firebase Genkit + Gemini) procesa los reportes asíncronamente, los clasifica por categoría y prioridad, y notifica automáticamente a los referentes barriales correspondientes.

- **Speech-to-Text Offline**: Transcripción de voz a texto 100% *on-device* garantizando accesibilidad y privacidad sin costos de API externa.
- **GenAI Classification**: Motor de procesamiento de lenguaje natural utilizando Gemini 2.5 para asignar prioridades y clasificar la naturaleza del incidente en milisegundos.
- **Geolocalización In-App**: Renderizado nativo con Google Maps SDK y captura de coordenadas exactas del incidente.
- **Sistema de Reputación**: Scoring dinámico por usuario para mitigar reportes falsos y trolls.
- **Notificaciones Push**: Arquitectura orientada a eventos vía FCM para movilizar referentes barriales.

**Restricción Core:** el sistema **NO** es para emergencias de riesgo vital (incendios, crímenes, problemas de salud graves). Cualquier indicio de riesgo vital detectado por el motor NLP interrumpe el flujo y emite una alerta bloqueante sugiriendo el contacto inmediato al 911/107.

---

## Roles

| Rol | Descripción |
|---|---|
| **Vecino Informante** | Reporta incidentes urbanos |
| **Referente Barrial** | Verifica incidentes en campo, recibe alertas push |
| **Administrador Vecinal** | Modera reportes, gestiona estados y usuarios |

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Frontend Mobile | Flutter (Dart) |
| Backend | Cloud Functions (Node.js/TypeScript) |
| IA / NLP | Firebase Genkit + Gemini 2.5 Flash-Lite |
| Base de datos | Cloud Firestore |
| Autenticación | Firebase Auth |
| Almacenamiento | Firebase Storage |
| Notificaciones | Firebase Cloud Messaging (FCM) |
| Reconocimiento de voz | `speech_to_text` (on-device, sin API externa) |
| Geolocalización | Google Maps SDK for Flutter |

---

## Equipos

| Equipo | Responsabilidad |
|---|---|
| **Equipo A** | Autenticación, roles y seguridad |
| **Equipo B** | Interfaz de usuario y captura de incidentes |
| **Equipo C** | NLP, lógica backend y notificaciones |

---

## Documentación

| Documento | Descripción |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Diagramas de secuencia y flujos críticos de la plataforma |
| [docs/RUNBOOK.md](docs/RUNBOOK.md) | Manual operativo, métricas (SLIs) y troubleshooting (Playbooks) |
| [docs/DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md) | Plan de contingencia, RPO/RTO y backups |
| [docs/adrs/](docs/adrs/) | Registros de Decisiones Arquitectónicas (ADRs) |
| [docs/setup.md](docs/setup.md) | Guía de instalación y configuración del entorno |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | Flujo de desarrollo y ciclo de vida de una tarea |
| [docs/BACKLOG.md](docs/BACKLOG.md) | Backlog sincronizado con Jira |
| [SECURITY.md](SECURITY.md) | Política de vulnerabilidades y modelo de seguridad |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Convenciones de branches, commits y PRs |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes de IA |

---

## Arquitectura del Sistema

El sistema sigue una arquitectura serverless y event-driven basada en Firebase y Genkit:

```mermaid
graph TD
    classDef person fill:#08427b,stroke:#073b6f,color:#fff,rx:5,ry:5
    classDef container fill:#43B02A,stroke:#3C9D25,color:#fff,rx:5,ry:5
    classDef db fill:#F68212,stroke:#C96A0E,color:#fff,rx:5,ry:5
    classDef backend fill:#F68212,stroke:#C96A0E,color:#fff,rx:5,ry:5
    classDef external fill:#999999,stroke:#666666,color:#fff,rx:5,ry:5
    classDef ext_ai fill:#8E75B2,stroke:#6B5B95,color:#fff,rx:5,ry:5
    
    Vecino("Vecino Informante<br/><br/>[Person]"):::person
    Referente("Referente Barrial<br/><br/>[Person]"):::person
    Admin("Administrador Vecinal<br/><br/>[Person]"):::person
    
    subgraph App ["Plataforma de Coordinación Comunitaria"]
        direction TB
        Mobile("App Móvil (Flutter)<br/><br/>[Container: Dart]"):::container
        Auth("Firebase Auth<br/><br/>[Container: BaaS]"):::backend
        Firestore[("Cloud Firestore<br/><br/>[Container: NoSQL]")]:::db
        Storage("Firebase Storage<br/><br/>[Container: Blob]"):::backend
        Functions("Cloud Functions<br/><br/>[Container: Node.js]"):::backend
        FCM("Firebase Cloud Messaging<br/><br/>[Container: BaaS]"):::backend
    end
    
    Gemini("Gemini 2.5 Flash-Lite<br/><br/>[Software System]"):::ext_ai
    Maps("Google Maps API<br/><br/>[Software System]"):::external
    
    Vecino -- "Envía reportes" --> Mobile
    Referente -- "Verifica reportes" --> Mobile
    Admin -- "Modera sistema" --> Mobile
    
    Mobile -- "Autentica usuarios" --> Auth
    Mobile -- "Carga mapas" --> Maps
    Mobile -- "Sube fotos" --> Storage
    Mobile -- "Lee/Escribe datos" --> Firestore
    
    Firestore -- "Trigger async" --> Functions
    Functions -- "Actualiza estado" --> Firestore
    
    Functions -- "Evalúa NLP" --> Gemini
    Functions -- "Envía alerta" --> FCM
    FCM -- "Notifica" --> Mobile
```

### Ciclo de Vida del Incidente (Máquina de Estados)

Para entender cómo muta el estado de un reporte en la base de datos (según las reglas definidas en `docs/incident-event-schema.json`), se expone el siguiente diagrama de estados:

```mermaid
stateDiagram-v2
    [*] --> Recibido : Vecino envía reporte
    
    state "Procesamiento NLP (Genkit)" as Procesamiento {
        [*] --> Analizando
        Analizando --> Riesgo_Vital_Detectado : Prioridad Crítica
        Analizando --> Validado : Incidente Normal
    }
    
    Recibido --> Procesamiento : Trigger Cloud Function
    Riesgo_Vital_Detectado --> [*] : Rechazado (Alerta 911)
    
    Validado --> Programado : Referente agenda reparación
    Programado --> En_Reparacion : Cuadrilla en zona
    En_Reparacion --> Solucionado : Tarea finalizada
    Solucionado --> [*]
```

### Modelo de Datos (NoSQL Firestore)

Esquema central de colecciones y documentos persistidos en la base de datos, estructurado a partir del `EventoDeIncidente`:

```mermaid
erDiagram
    USERS ||--o{ INCIDENTS : "reporta (1:N)"
    USERS {
        string uid PK "Firebase Auth UID"
        string role "vecino | referente | admin"
        number reputation_score "Dinámico (evita trolls)"
    }
    INCIDENTS ||--o| NLP_ANALYSIS : "integra (1:1)"
    INCIDENTS {
        string eventId PK "UUID v4"
        string userId FK "Indexado"
        geopoint location "Google Maps SDK"
        string status "Ciclo de vida"
    }
    NLP_ANALYSIS {
        string category "Clasificación Genkit"
        string priority "Nivel de urgencia"
        boolean life_threatening "Flag de bloqueo"
    }
```

### Pipeline de Integración Continua (CI/CD)

Flujo de entrega desde el commit local hasta el despliegue en producción, aplicable a los tres equipos del proyecto:

```mermaid
graph LR
    classDef action fill:#2D6A4F,stroke:#1B4332,color:#fff
    classDef check fill:#E76F51,stroke:#C1472E,color:#fff
    classDef deploy fill:#264653,stroke:#1D3640,color:#fff

    A("Push a Feature Branch"):::action
    B("Pull Request a develop"):::action
    C{"flutter analyze"}:::check
    D{"flutter test"}:::check
    E("Code Review por Pares"):::action
    F("Merge a develop"):::action
    G{"npm run test (Functions)"}:::check
    H("flutter build apk"):::deploy
    I("firebase deploy --only functions,firestore:rules"):::deploy
    J("Distribución via Firebase App Distribution"):::deploy

    A --> B --> C
    C -- "Pasa" --> D
    C -- "Falla" --> A
    D -- "Pasa" --> E
    D -- "Falla" --> A
    E -- "Aprobado" --> F
    F --> G
    G -- "Pasa" --> H
    G -- "Falla" --> A
    H --> I --> J
```

## Variables de Entorno

Para ejecutar correctamente el sistema en un entorno local o de CI/CD, se requiere configurar las siguientes variables de entorno (generalmente en un `.env` dentro de `functions/` o a nivel de sistema):

| Variable | Descripción | Entorno |
|---|---|---|
| `GEMINI_API_KEY` | Clave API de Google AI Studio para que Genkit procese NLP | Backend / Cloud Functions |
| `GOOGLE_MAPS_API_KEY` | Clave de Google Cloud Console habilitada para Maps SDK | Frontend (AndroidManifest.xml / AppDelegate.swift) |
| `FIREBASE_PROJECT_ID` | Identificador del proyecto en Firebase Console | Backend / CLI |

## Configuración (Setup) Paso a Paso

A continuación se detalla la configuración inicial mínima requerida. Para una guía exhaustiva (incluyendo resolución de problemas y herramientas), consulte [docs/setup.md](docs/setup.md).

1. **Clonar e instalar dependencias base**
   ```powershell
   git clone <repo-url>
   cd app-coordinacion-comunitaria
   flutter pub get
   ```

2. **Configuración de Firebase y Autenticación**
   Requiere Node.js y Flutter SDK.
   ```powershell
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<id-del-proyecto-firebase>
   ```

3. **Configuración de Google Maps**
   Insertar la `GOOGLE_MAPS_API_KEY` en `android/app/src/main/AndroidManifest.xml` (metadata `com.google.android.geo.API_KEY`).

4. **Generación de Código (Freezed / Riverpod / JSON)**
   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Ejecución de la Aplicación Móvil**
   Asegurarse de tener un emulador en ejecución y correr:
   ```powershell
   flutter run -d emulator-5554 --no-enable-impeller
   ```

6. **Despliegue Local del Backend (Opcional pero recomendado)**
   Para probar el motor NLP y funciones asociadas de manera local:
   ```powershell
   cd functions
   npm install
   npm run build
   firebase emulators:start
   ```

---

## Testing y Calidad de Código

El proyecto exige el cumplimiento riguroso de pruebas automáticas (Requisito `[T-TEST-06]`).

```powershell
# Ejecutar Linter (Reglas definidas en analysis_options.yaml)
flutter analyze

# Ejecutar Suite de Pruebas Unitarias y de Widgets
flutter test

# Pruebas de Backend (Cloud Functions)
cd functions
npm run test
```

> **Nota Arquitectónica**: Las pruebas de UI y de lógica de dominio (NLP) están desacopladas siguiendo principios de Clean Architecture y SOLID.

---

## CI/CD

| Evento | Acción |
|---|---|
| PR abierto hacia `main` o `develop` | Valida título, corre `flutter analyze` y `flutter test` |
| Merge a `main` | Build del APK de release + deploy de Firestore rules si cambiaron |
| Cualquier PR | Auto-labeling según archivos modificados |

---

## Estructura del proyecto (Monorepo Lógico)

```
app-coordinacion-comunitaria/
├── lib/
│   ├── app/                  # GoRouter y Provider Scope (Configuración global)
│   ├── core/                 # Constantes, errores, temas y widgets compartidos
│   └── features/             # Feature-first architecture
│       ├── auth/             # Autenticación y roles (Equipo A)
│       ├── incidents/        # Creación y tracking de reportes (Equipo B)
│       ├── map/              # Mapa interactivo de incidencias (Equipo B)
│       └── admin/            # Dashboard de moderación vecinal (Equipo A)
├── functions/                # Backend Node.js / TypeScript (Cloud Functions y Genkit)
├── docs/                     # Documentación arquitectónica, ADRs y Runbooks
├── .github/workflows/        # Pipelines CI/CD con GitHub Actions
└── firestore.rules           # Reglas declarativas de seguridad de BD
```

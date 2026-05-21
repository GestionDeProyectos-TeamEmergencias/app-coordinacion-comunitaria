# App de Coordinación Comunitaria

Plataforma de ciencia ciudadana para el reporte de incidentes urbanos no críticos (baches, luminarias rotas, basura, cables sueltos). Actúa como puente entre los vecinos y la administración municipal/vecinal.

> Proyecto académico — Grupo D, UNNOBA 2026.

---

## Descripción

El sistema permite a los vecinos reportar incidentes urbanos mediante texto, foto o voz. Un motor de NLP (Firebase Genkit + Gemini) procesa los reportes, los clasifica por categoría y prioridad, y notifica automáticamente a los referentes barriales correspondientes.

**Restricción core:** el sistema NO es para emergencias de riesgo vital (incendios, crímenes, salud). Cualquier indicio de riesgo vital interrumpe el flujo y sugiere llamar al 911/107.

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
| [docs/setup.md](docs/setup.md) | Guía de instalación y configuración del entorno |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | Flujo de desarrollo y ciclo de vida de una tarea |
| [docs/BACKLOG.md](docs/BACKLOG.md) | Backlog sincronizado con Jira |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Convenciones de branches, commits y PRs |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes de IA |

---

## Quickstart

```powershell
# 1. Clonar el repositorio
git clone <repo-url>
cd app-coordinacion-comunitaria

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase (ver docs/setup.md sección 5)
flutterfire configure --project=<firebase-project-id>

# 4. Generar código
dart run build_runner build --delete-conflicting-outputs

# 5. Correr la app
flutter run -d emulator-5554 --no-enable-impeller
```

Para la guía completa ver [docs/setup.md](docs/setup.md).

---

## CI/CD

| Evento | Acción |
|---|---|
| PR abierto hacia `main` o `develop` | Valida título, corre `flutter analyze` y `flutter test` |
| Merge a `main` | Build del APK de release + deploy de Firestore rules si cambiaron |
| Cualquier PR | Auto-labeling según archivos modificados |

---

## Estructura del proyecto

```
lib/
├── app/                  # Router y configuración de la app
├── core/                 # Constantes, errores, widgets compartidos
└── features/
    ├── auth/             # Autenticación y roles (Equipo A)
    ├── incidents/        # Reportes de incidentes (Equipo B)
    ├── map/              # Mapa de incidencias (Equipo B)
    └── admin/            # Panel de administración (Equipo A)
docs/                     # Documentación del proyecto
.github/workflows/        # CI/CD con GitHub Actions
firestore.rules           # Reglas de seguridad de Firestore
```

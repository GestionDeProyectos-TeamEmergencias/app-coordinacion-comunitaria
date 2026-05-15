# AGENTS.md — lib/ (Flutter Frontend)

> Complementa el AGENTS.md raíz. Aplica solo al directorio `lib/` y `test/`.

## Arquitectura: Feature-First + Clean Architecture

Cada feature sigue la misma estructura de 3 capas:

```
features/<nombre>/
├── data/
│   ├── datasources/   # Acceso a Firebase (Firestore, Storage, Auth)
│   ├── models/        # DTOs con fromFirestore() / toFirestore()
│   └── repositories/  # Implementación de la interfaz de dominio
├── domain/
│   ├── entities/      # Clases puras de Dart (sin imports de Flutter/Firebase)
│   ├── repositories/  # Interfaces (abstract interface class)
│   └── usecases/      # Un use case = una operación de negocio
└── presentation/
    ├── providers/     # Riverpod providers (StateNotifier, Stream, Future)
    ├── pages/         # Pantallas completas (Scaffold)
    └── widgets/       # Widgets reutilizables del feature
```

## Reglas de dependencia

- `domain/` NO puede importar nada de `data/` ni de `presentation/`.
- `data/` puede importar `domain/` pero NO `presentation/`.
- `presentation/` puede importar `domain/` y acceder a `data/` solo via providers de Riverpod.
- `core/` es compartido por todos los features; no importa nada de `features/`.

## Convenciones de nombres

| Tipo | Sufijo | Ejemplo |
|------|--------|---------|
| Entidad de dominio | (ninguno) | `AppUser`, `IncidentEvent` |
| DTO de datos | `Model` | `UserModel`, `IncidentEventModel` |
| Interfaz de repositorio | `Repository` | `AuthRepository` |
| Implementación | `RepositoryImpl` | `AuthRepositoryImpl` |
| Caso de uso | `UseCase` | `LoginUseCase` |
| Página | `Page` | `LoginPage` |
| StateNotifier | `Notifier` | `AuthNotifier` |

## Contrato T-INF-04: "Evento de Incidente"

El objeto central de la app es `IncidentEvent` (`lib/features/incidents/domain/entities/incident_event.dart`).
Cualquier flujo de reporte (quick, form, voice) DEBE construir un `IncidentEvent` y enviarlo via `IncidentsRepository.submitIncident()`.
Nunca enviar datos crudos a Firestore desde la capa de presentación.

## Estado con Riverpod

- Usar `StateNotifierProvider` para operaciones con estado mutable (login, envío de reporte).
- Usar `StreamProvider` para datos en tiempo real de Firestore.
- Usar `FutureProvider.family` para datos por ID.
- Todos los providers de infraestructura (Firebase) están en el archivo `providers/` del feature correspondiente.

## Código generado

Los archivos `*.g.dart` y `*.freezed.dart` son generados por `build_runner`. NO editar manualmente.
Regenerar con: `dart run build_runner build --delete-conflicting-outputs`

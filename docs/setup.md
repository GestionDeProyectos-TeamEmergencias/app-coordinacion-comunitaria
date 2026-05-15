# Guía de Setup — App de Coordinación Comunitaria

## Prerrequisitos

| Herramienta | Versión mínima | Instalación |
|---|---|---|
| Flutter SDK | 3.22+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.3+ | Incluido con Flutter |
| Android Studio / Xcode | Última | Para emuladores |
| Firebase CLI | 13+ | `npm install -g firebase-tools` |
| FlutterFire CLI | Última | `dart pub global activate flutterfire_cli` |
| Node.js | 20 LTS | Para Cloud Functions |

---

## 1. Clonar el repositorio

```bash
git clone <repo-url>
cd app-coordinacion-comunitaria
```

## 2. Instalar dependencias de Flutter

```bash
flutter pub get
```

## 3. Configurar Firebase (T-INF-02)

### 3.1. Crear el proyecto Firebase
1. Ir a https://console.firebase.google.com
2. Crear nuevo proyecto: `app-coordinacion-comunitaria`
3. Habilitar **Blaze Plan** (necesario para Cloud Functions y Storage)
4. Habilitar en Firebase Console:
   - Authentication → Email/Password
   - Firestore Database → crear en modo producción
   - Storage → crear bucket
   - Cloud Functions → habilitar
   - Cloud Messaging → habilitado automáticamente

### 3.2. Conectar Flutter con Firebase (FlutterFire CLI)

```bash
# Instalar FlutterFire CLI (solo primera vez)
dart pub global activate flutterfire_cli

# Conectar el proyecto (genera lib/firebase_options.dart)
flutterfire configure --project=<tu-project-id-de-firebase>
```

Esto reemplazará el `lib/firebase_options.dart` placeholder con las credenciales reales.

### 3.3. Configurar Google Maps (T-REP-05)

1. Ir a https://console.cloud.google.com → APIs & Services → Credentials
2. Crear una API Key y habilitar **Maps SDK for Android** y **Maps SDK for iOS**
3. Agregar la API key:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

---

## 4. Setup del entorno de desarrollo Flutter (T-INF-03)

```bash
# Verificar que todo está correcto
flutter doctor

# Levantar en Android
flutter run -d android

# Levantar en iOS
flutter run -d ios

# Levantar en dispositivo específico
flutter devices
flutter run -d <device-id>
```

---

## 5. Backend: Cloud Functions (Equipo C)

```bash
cd functions

# Instalar dependencias
npm install

# Compilar TypeScript
npm run build

# Levantar emuladores locales (incluye Firestore y Functions)
firebase emulators:start
```

---

## 6. Código generado (build_runner)

Los modelos anotados con `@JsonSerializable` o `@freezed` requieren generación de código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Cuándo ejecutar:** cada vez que se modifiquen entidades/modelos anotados.

---

## 7. Reglas de Firestore (T-RNF-01)

Las reglas de seguridad se encuentran en `firestore.rules` (a crear en T-RNF-01).
Para deployar:

```bash
firebase deploy --only firestore:rules
```

---

## 8. Verificación del setup

```bash
# Análisis estático (debe pasar sin errores)
flutter analyze

# Tests unitarios y de widgets
flutter test

# Build de producción Android
flutter build apk --release

# Build de producción iOS
flutter build ipa
```

---

## 9. Branches y flujo de trabajo

| Branch | Propósito |
|---|---|
| `main` | Producción estable |
| `develop` | Integración continua |
| `feature/equipo-a/*` | Features Equipo A (Auth, Roles) |
| `feature/equipo-b/*` | Features Equipo B (UI, Reporte) |
| `feature/equipo-c/*` | Features Equipo C (NLP, Notificaciones) |

Commits: `feat: [T-AUTH-01] Implementar registro de vecinos`

---

## 10. Variables de entorno

No hay `.env` en el frontend (Flutter no lo usa). Las API keys de Google Maps se configuran directamente en los manifests de cada plataforma (ver Sección 3.3).

Las credenciales de Firebase están en `lib/firebase_options.dart` (generado por FlutterFire CLI, no commitear si contiene datos sensibles de producción — está en `.gitignore`).

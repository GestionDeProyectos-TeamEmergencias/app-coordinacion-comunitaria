# Guía de Setup — App de Coordinación Comunitaria

> Guía paso a paso para desarrolladores que se incorporan al proyecto.
> Se centra en **Windows** (plataforma principal del equipo) con una sección adicional para Linux.
> Tiempo estimado: 45–90 minutos (dependiendo de la velocidad de descarga).

---

## Índice

1. [Herramientas necesarias](#1-herramientas-necesarias)
2. [Instalación en Windows](#2-instalación-en-windows-plataforma-principal)
3. [Instalación en Linux](#3-instalación-en-linux)
4. [Clonar el repositorio](#4-clonar-el-repositorio)
5. [Configurar Firebase](#5-configurar-firebase)
6. [Instalar dependencias del proyecto](#6-instalar-dependencias-del-proyecto)
7. [Configurar el emulador Android](#7-configurar-el-emulador-android)
8. [Correr la aplicación](#8-correr-la-aplicación)
9. [Crear usuario de prueba](#9-crear-usuario-de-prueba)
10. [Configurar Google Maps](#10-configurar-google-maps-cuando-llegues-a-t-rep-05)
11. [Backend: Cloud Functions](#11-backend-cloud-functions)
12. [Flujo de trabajo diario](#12-flujo-de-trabajo-diario)
13. [Problemas frecuentes](#13-problemas-frecuentes)

---

## 1. Herramientas necesarias

| Herramienta | Versión mínima | Notas |
|---|---|---|
| Flutter SDK | 3.22+ | Incluye Dart |
| Android Studio | Última | Solo para el SDK y el emulador, no para escribir código |
| VS Code | Última | Editor principal |
| Node.js | 20 LTS | Para Firebase CLI y Cloud Functions |
| Firebase CLI | 13+ | Se instala con npm |
| FlutterFire CLI | Última | Se instala con dart |

> **¿Necesito OpenJDK?** No. Android Studio ya incluye su propio JDK internamente.
>
> **¿Necesito Visual Studio (el de C++)?** No. Eso es solo para apps de escritorio Windows, este proyecto apunta a Android.
>
> **¿Puedo usar solo VS Code sin Android Studio?** No. Android Studio es necesario para instalar el Android SDK y manejar los emuladores, aunque no lo uses para escribir código.

---

## 2. Instalación en Windows (Plataforma Principal)

### 2.1. Instalar Flutter SDK

1. Ir a [flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) → elegir **Windows** → **Android**
2. Descargar el `.zip` y extraerlo en `C:\dev\flutter`
   - Evitá rutas con espacios como `C:\Program Files\`
3. Agregar Flutter al PATH:
   - Buscar **"Variables de entorno"** en el menú inicio
   - En *Variables de usuario* → seleccionar `Path` → **Editar**
   - Click en **Nuevo** → agregar `C:\dev\flutter\bin`
   - Aceptar todo y cerrar
4. Abrir una terminal **nueva** y verificar:
   ```powershell
   flutter --version
   ```
   Deberías ver algo como `Flutter 3.x.x`.

### 2.2. Habilitar Developer Mode en Windows

Flutter necesita permisos de symlinks en Windows. Sin esto `flutter pub get` va a tirar una advertencia y los plugins no van a funcionar bien.

1. Abrir PowerShell y correr:
   ```powershell
   start ms-settings:developers
   ```
2. Activar **Modo de desarrollador** y confirmar el mensaje de advertencia.

### 2.3. Instalar Android Studio

1. Descargar desde [developer.android.com/studio](https://developer.android.com/studio)
2. Durante la instalación, dejar todas las opciones por defecto marcadas (incluye Android SDK y AVD)
3. Al abrir por primera vez, completar el **Setup Wizard** — esto descarga el Android SDK automáticamente
4. Una vez terminado, instalar el **SDK Command-line Tools** (necesario para aceptar licencias):
   - Ir a **Settings** → **Languages & Frameworks** → **Android SDK**
   - Click en la pestaña **SDK Tools**
   - Tildar **Android SDK Command-line Tools (latest)**
   - Click en **Apply** y esperar la descarga
5. Aceptar las licencias de Android desde la terminal:
   ```powershell
   flutter doctor --android-licenses
   ```
   Escribir `y` y Enter en cada pregunta hasta que diga `All SDK package licenses accepted`.

### 2.4. Instalar Node.js

1. Descargar el instalador LTS desde [nodejs.org](https://nodejs.org)
2. Instalar con las opciones por defecto
3. Verificar en una terminal nueva:
   ```powershell
   node --version
   npm --version
   ```

### 2.5. Instalar Firebase CLI

```powershell
npm install -g firebase-tools
firebase login
```

El comando `firebase login` abre el navegador para autenticarse con tu cuenta de Google. Usá la cuenta que tiene acceso al proyecto Firebase del equipo.

### 2.6. Instalar FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Luego agregar el directorio de binarios de Dart al PATH (igual que hiciste con Flutter):
- Agregar esta ruta a las Variables de entorno → Path:
  ```
  C:\Users\<TuUsuario>\AppData\Local\Pub\Cache\bin
  ```
- Reemplazar `<TuUsuario>` con tu nombre de usuario de Windows.

### 2.7. Instalar extensiones de VS Code

Abrir VS Code e instalar estas extensiones desde el Marketplace:
- **Flutter** (by Dart Code) — instala Dart automáticamente también
- **Dart** (by Dart Code)

### 2.8. Verificar todo con flutter doctor

```powershell
flutter doctor
```

El resultado esperado para este proyecto (sin iOS ni Windows Desktop):

```
[✓] Flutter
[✓] Windows Version
[✓] Android toolchain
[✓] Chrome
[✗] Visual Studio  ← ignorar, no es necesario
[✓] Connected device
[✓] Network resources
```

---

## 3. Instalación en Linux

### 3.1. Instalar dependencias del sistema

```bash
sudo apt update
sudo apt install clang cmake ninja-build libgtk-3-dev pkg-config curl git unzip
```

### 3.2. Instalar Flutter SDK

```bash
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz
tar xf flutter_linux_*.tar.xz
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter --version
```

> Reemplazar `3.x.x` con la versión estable más reciente desde flutter.dev.

### 3.3. Instalar Android Studio

Descargar desde [developer.android.com/studio](https://developer.android.com/studio), extraer y correr el instalador:

```bash
tar xzf android-studio-*.tar.gz -C /opt
/opt/android-studio/bin/studio.sh
```

Completar el Setup Wizard igual que en Windows. Luego:

```bash
flutter doctor --android-licenses
```

### 3.4. Instalar Node.js, Firebase CLI y FlutterFire CLI

```bash
# Node.js via nvm (recomendado)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Firebase CLI
npm install -g firebase-tools
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

---

## 4. Clonar el repositorio

```powershell
git clone <repo-url>
cd app-coordinacion-comunitaria
```

Abrir la carpeta en VS Code:
```powershell
code .
```

---

## 5. Configurar Firebase

### 5.1. Crear el proyecto Firebase (solo la primera persona del equipo)

Si el proyecto Firebase ya existe, saltar al paso 5.2.

1. Ir a [console.firebase.google.com](https://console.firebase.google.com)
2. Click en **Agregar proyecto** → nombre: `app-coordinacion-comunitaria`
3. Una vez creado, habilitar estos servicios desde el menú lateral:
   - **Authentication** → Sign-in method → **Email/Password** → Habilitar
   - **Firestore Database** → Crear base de datos → Modo producción → Elegir región
   - **Storage** → Comenzar
   - **Cloud Functions** → requiere plan Blaze (pago por uso)
   - **Cloud Messaging** → se habilita automáticamente

### 5.2. Conectar el proyecto Flutter con Firebase

Desde la raíz del repositorio:

```powershell
flutterfire configure --project=<id-del-proyecto-firebase>
```

El ID del proyecto se encuentra en Firebase Console → ícono de engranaje → **Configuración del proyecto**.

Este comando genera automáticamente el archivo `lib/firebase_options.dart` con las credenciales para todas las plataformas. **No commitearlo si tiene credenciales de producción** (ya está en `.gitignore`).

### 5.3. Agregar la huella digital SHA-1 para Firebase Auth en Android

Firebase Auth en Android requiere que registres el certificado de tu máquina. Sin esto el login tira `DEVELOPER_ERROR`.

**Paso 1 — Obtener tu SHA-1:**

En Windows:
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

En Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copiar el valor de la línea `SHA1:`.

**Paso 2 — Registrarla en Firebase Console:**

1. Firebase Console → ícono de engranaje → **Configuración del proyecto**
2. Bajar hasta la sección **Tus apps** → app de Android
3. Click en **Agregar huella digital**
4. Pegar el SHA-1 y guardar

**Paso 3 — Regenerar la configuración:**

```powershell
flutterfire configure --project=<id-del-proyecto-firebase>
```

> Cada desarrollador del equipo debe hacer este paso con su propia máquina. El SHA-1 de debug es único por máquina.

---

## 6. Instalar dependencias del proyecto

Desde la raíz del repositorio:

```powershell
# Instalar paquetes de Flutter
flutter pub get

# Generar código (modelos Freezed, Riverpod, JSON serialization)
dart run build_runner build --delete-conflicting-outputs
```

> Correr `build_runner` nuevamente cada vez que modifiques un archivo anotado con `@freezed`, `@riverpod`, o `@JsonSerializable`.

---

## 7. Configurar el emulador Android

### 7.1. Crear un dispositivo virtual

1. Abrir Android Studio
2. En la pantalla de bienvenida: **More Actions** → **Virtual Device Manager**
   (Si tenés un proyecto abierto: menú **Tools** → **Device Manager**)
3. Click en el ícono **+** para crear un dispositivo nuevo
4. Elegir **Pixel 8** → Next
5. Elegir sistema operativo **API 35 (Android 15)** — si aparece un link de descarga, hacer click y esperar
6. Next → Finish

### 7.2. Configurar la aceleración gráfica

Antes de iniciar el emulador, editar el dispositivo recién creado:
- En Device Manager → click en el ícono de lápiz (editar)
- Buscar la opción de **Graphics** o **Aceleración gráfica**
- Cambiar a **Hardware**
- Guardar

### 7.3. Iniciar el emulador

Click en el botón ▶ en Device Manager. El primer arranque tarda 2–3 minutos.

Verificar que Flutter lo detecta:
```powershell
flutter devices
```

Deberías ver el emulador listado con un ID como `emulator-5554`.

---

## 8. Correr la aplicación

```powershell
flutter run -d emulator-5554 --no-enable-impeller
```

> El flag `--no-enable-impeller` es necesario en el emulador para evitar crashes de renderizado con OpenGL. En dispositivos físicos no hace falta.

Si no recordás el ID del emulador, corré `flutter devices` primero.

**Comandos útiles mientras la app está corriendo:**

| Tecla | Acción |
|---|---|
| `r` | Hot reload (recarga cambios de UI instantáneamente) |
| `R` | Hot restart (reinicia el estado de la app) |
| `q` | Salir |
| `h` | Ver todos los comandos disponibles |

---

## 9. Crear usuario de prueba

Para poder navegar la app durante el desarrollo necesitás un usuario de prueba. El sistema requiere que exista tanto en **Firebase Auth** como en **Firestore**.

### 9.1. Crear usuario en Firebase Auth

1. Firebase Console → **Authentication** → **Users** → **Agregar usuario**
2. Ingresar email y contraseña → crear
3. Copiar el **User UID** que aparece en la tabla

### 9.2. Crear el documento en Firestore

1. Firebase Console → **Firestore Database** → **Iniciar colección**
2. ID de colección: `users`
3. ID del documento: pegar el **User UID** copiado en el paso anterior
4. Agregar los siguientes campos:

| Campo | Tipo | Valor |
|---|---|---|
| `email` | string | el email del usuario |
| `displayName` | string | Tu Nombre |
| `role` | string | `vecino_informante` |
| `status` | string | `active` |
| `reputationScore` | number | `100` |

> **¿Por qué necesito hacer esto?** El app, después de autenticar con Firebase Auth, busca el documento del usuario en Firestore para leer su rol y estado. Si el documento no existe, la app crashea con `Null check operator used on a null value`.

---

## 10. Configurar Google Maps (cuando llegues a T-REP-05)

Esta configuración solo es necesaria cuando vayas a trabajar en la pantalla del mapa. Si todavía no llegaste a esa tarea, podés saltear esta sección.

1. Ir a [console.cloud.google.com](https://console.cloud.google.com) → **APIs & Services** → **Credentials**
2. Crear una API Key y habilitar **Maps SDK for Android**
3. Agregar la key en [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) dentro del tag `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

---

## 11. Backend: Cloud Functions

El backend en Node.js/TypeScript todavía está en desarrollo (T-NLP-01 en adelante). Cuando esté disponible:

```powershell
cd functions
npm install
npm run build

# Levantar emuladores locales (Firestore + Functions)
firebase emulators:start
```

---

## 12. Flujo de trabajo diario

Una vez que tenés todo configurado, el día a día es:

```powershell
# 1. Asegurarse de estar en la rama correcta
git checkout feature/equipo-x/nombre-tarea

# 2. Levantar el emulador desde Android Studio (si no está corriendo)

# 3. Correr la app
flutter run -d emulator-5554 --no-enable-impeller

# 4. Si modificaste modelos anotados, regenerar código
dart run build_runner build --delete-conflicting-outputs

# 5. Antes de hacer commit, verificar que no hay errores
flutter analyze
flutter test
```

**Convención de commits:**
```
feat: [T-AUTH-01] Implementar registro de vecinos informantes
fix: [T-REP-02] Corregir captura de GPS en segundo plano
```

---

## 13. Problemas frecuentes

### "flutter: command not found" o "flutter no reconocido"
Flutter no está en el PATH. Verificar que `C:\dev\flutter\bin` está agregado correctamente en las Variables de entorno y abrir una terminal nueva.

### "Building with plugins requires symlink support"
El Modo de desarrollador de Windows no está activado. Ver sección 2.2.

### DEVELOPER_ERROR al intentar loguear
Falta la huella digital SHA-1 en Firebase. Ver sección 5.3. Cada dev necesita agregar la suya propia.

### "Null check operator used on a null value" después del login
El usuario existe en Firebase Auth pero no tiene documento en Firestore. Ver sección 9.2 para crear el documento manualmente.

### La app crashea al iniciar en el emulador (Lost connection to device)
Problema de renderizado con Impeller. Siempre usar el flag `--no-enable-impeller` con el emulador. Además verificar que la aceleración gráfica del emulador esté en **Hardware** (ver sección 7.2).

### "Android sdkmanager not found"
Las Command-line Tools del Android SDK no están instaladas. Ver sección 2.3, paso 4.

### El emulador no aparece en `flutter devices`
El emulador no está iniciado. Abrirlo desde Android Studio → Device Manager → ▶.

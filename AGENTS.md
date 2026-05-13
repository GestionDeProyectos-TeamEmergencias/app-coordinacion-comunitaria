# 🤖 Guía para Agentes de IA (AGENTS.md)

¡Hola, agente! Este archivo contiene las instrucciones principales para trabajar en la **"App de Coordinación Comunitaria para la Gestión Urbana Participativa"**. Lee detenidamente estas directrices antes de escribir, modificar o refactorizar código.

---

## 🏙️ 1. Project Overview (Visión General del Proyecto)

El sistema es una plataforma de **ciencia ciudadana** para el reporte de **incidentes urbanos no críticos** (baches, luminarias rotas, basura, cables sueltos). Actúa como puente entre los vecinos y la administración municipal/vecinal.

*   **Restricción Core:** El sistema **NO** es para emergencias de riesgo vital (incendios, crímenes, salud). Cualquier indicio de riesgo vital en el texto (NLP) debe interrumpir el flujo y sugerir llamar al 911/107.
*   **Roles:** 
    1. *Vecino Informante* (reporta).
    2. *Referente Barrial* (verifica en campo, recibe alertas push).
    3. *Administrador Vecinal* (modera, gestiona estados, configura el sistema).

---

## 🛠️ 2. Tech Stack & Architecture

*   **Frontend Mobile:** Flutter (Dart).
*   **Backend & IA:** Cloud Functions (Node.js/TypeScript) + Firebase Genkit + Gemini 2.5 Flash-Lite.
*   **Base de Datos & Auth:** Cloud Firestore, Firebase Storage, Firebase Auth.
*   **Reconocimiento de voz:** Paquete `speech_to_text` (procesamiento 100% *on-device*, no usar APIs cloud).
*   **Geolocalización:** Google Maps SDK for Flutter.
*   **Notificaciones:** Firebase Cloud Messaging (FCM) + APNs.

**Regla de Arquitectura:** El frontend (cualquiera de los 3 métodos de reporte) siempre debe enviar un objeto JSON homogéneo llamado `"Evento de Incidente"` hacia las Cloud Functions para su procesamiento.

---

## 🚀 3. Build and Test Commands (Comandos de Construcción y Pruebas)

### Frontend (Flutter)
*   **Generar código (build_runner):** `dart run build_runner build --delete-conflicting-outputs` (Obligatorio si se modifican modelos serializables).
*   **Ejecutar app:** `flutter run`
*   **Ejecutar linter:** `flutter analyze`
*   **Ejecutar tests:** `flutter test`

### Backend (Firebase Cloud Functions)
*   **Instalar dependencias:** `cd functions && npm install`
*   **Compilar TypeScript:** `npm run build`
*   **Ejecutar emuladores locales:** `firebase emulators:start`
*   **Ejecutar tests:** `npm run test`

---

## 💅 4. Code Style Guidelines (Guías de Estilo de Código)

*   **Dart/Flutter:** 
    *   Usa **SOLID** y prioriza la **composición sobre la herencia**.
    *   Mantén los widgets inmutables. Usa constructores `const` siempre que sea posible.
    *   Sigue las reglas del paquete `flutter_lints`. Usa `dart format` antes de hacer commit.
*   **Node.js/TypeScript (Backend):**
    *   Usa tipado estricto. Evita usar `any`.
    *   Diseña las Cloud Functions para que sean **idempotentes**.
    *   Estructura el código de Genkit para que la IA (Gemini) siempre devuelva respuestas en formato JSON tipado.

---

## 🧪 5. Testing Instructions (Instrucciones de Testing)

*   Todo nuevo feature debe incluir sus respectivas pruebas.
*   **Tests Unitarios:** Obligatorios para la lógica de dominio (NLP, priorización, cálculo de reputación).
*   **Tests de Widgets:** Obligatorios para los flujos principales de UI (ej. presionar botón de reporte rápido).
*   La SRS exige que el tiempo de procesamiento completo (Frontend -> Backend NLP -> Alerta) sea **menor a 10 segundos**. Tenlo en cuenta al escribir tests de rendimiento o mocks.

---

## 🔒 6. Security Considerations (Consideraciones de Seguridad)

*   **Frontend es Inseguro:** El backend (Cloud Functions/Firestore) SIEMPRE debe revalidar roles, coordenadas GPS y datos enviados por el usuario.
*   **Firestore Rules:** Configura `firestore.rules` meticulosamente. Los vecinos NO deben poder leer los datos personales de otros vecinos.
*   **Datos Sensibles:** Nunca hagas console.log de PII (Personally Identifiable Information) como emails, contraseñas o ubicaciones exactas en los logs de Firebase.
*   **Protección contra Trolls:** El sistema incluye un mecanismo de reputación. Asegúrate de que las funciones de bloqueo se ejecuten si un usuario cae por debajo del umbral configurado por el admin.

---

## 📦 7. Extra Instructions: Commits, PRs & Deployment

*   **Commits:** Sigue convenciones semánticas y **siempre incluye el ID de la tarea de Jira** al inicio del commit.
    *   *Ejemplo:* `feat: [T-AUTH-03] Implementar middleware de roles en Firebase`
*   **Pull Requests:** Antes de solicitar un merge a `develop`, debes asegurar que `flutter analyze` y `flutter test` pasan sin errores.
*   **Deployment:** 
    *   Para backend: `firebase deploy --only functions,firestore:rules`
    *   Para frontend: Usa los canales de distribución definidos (ej. Fastlane o Firebase App Distribution) tras buildear con `flutter build apk` o `flutter build ipa`.

---

## 📁 8. Nested AGENTS.md (Estrategia de Monorepo)

Si el proyecto crece y se divide en paquetes independientes o microservicios (ej. un package local para la lógica compartida de Flutter y otro para las funciones de Node), se deberán crear archivos `AGENTS.md` anidados dentro de esas subcarpetas.
*Nota para el agente:* Siempre dale prioridad a las reglas del archivo `AGENTS.md` más cercano al directorio donde estás modificando código.

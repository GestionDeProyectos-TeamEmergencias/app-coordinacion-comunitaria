# Runbook Operativo y Troubleshooting

Este documento está dirigido a los administradores del sistema, DevOps y SRE. Define los procedimientos operativos para mantener la plataforma saludable, monitorear su rendimiento y resolver incidencias críticas en los entornos productivos.

---

## 1. Monitoreo y Observabilidad

### 1.1. Herramientas Clave
- **Google Cloud Logging (Log Explorer)**: Única fuente de verdad para los registros de backend de las Cloud Functions. Todo `console.error` u observabilidad inyectada por Genkit se visualizará aquí.
- **Firebase Crashlytics**: Monitoreo de estabilidad de la aplicación móvil Flutter.
- **Firebase Performance Monitoring**: Seguimiento de latencia en peticiones HTTP y tiempos de arranque de la app.

### 1.2. Métricas Críticas (SLIs)
- **Latencia del Flujo de NLP**: El tiempo entre la escritura en Firestore y el envío del payload a FCM debe ser **< 10 segundos**.
- **Tasa de Errores de API Gemini**: Monitorear HTTP 429 (Too Many Requests) o HTTP 500.

---

## 2. Playbooks de Resolución (Troubleshooting)

### Playbook A: Latencia elevada en el procesamiento (> 10s)
*Síntoma*: Los reportes tardan más de 10 segundos en notificar a los referentes barriales.
*Posibles causas y mitigaciones*:
1. **Cold Start de Cloud Functions**: 
   - *Acción*: Configurar al menos 1 instancia mínima (`minInstances: 1`) en la configuración de la función para el horario diurno de alto tráfico.
2. **Concurrencia saturada**:
   - *Acción*: Incrementar la memoria asignada a la función (ej. 512MB a 1GB) para permitir que Gen 2 maneje más peticiones concurrentes por contenedor.
3. **Degradación de Gemini API**:
   - *Acción*: Verificar el dashboard de estado de Google Cloud. Si hay una caída global, el sistema se degradará automáticamente a revisión manual.

### Playbook B: Errores 429 - "Quota Exceeded" en Gemini/Genkit
*Síntoma*: En Cloud Logging se observan ráfagas de errores `429 Too Many Requests` provenientes de Genkit.
*Posibles causas y mitigaciones*:
1. **Límite del Tier Gratuito/Básico**: La adopción barrial ha excedido las RPM (Requests Per Minute) permitidas.
   - *Acción Inmediata*: Solicitar al equipo de Finanzas un aumento de cuota en Google Cloud Console para la API de Vertex AI / Gemini.
   - *Acción Secundaria*: Si se detecta un ataque de spam o trolling, ubicar el UID del atacante y banear su cuenta manipulando la colección de `users` en Firestore.

### Playbook C: Dispositivos no reciben alertas Push
*Síntoma*: Firebase Cloud Messaging retorna "Success", pero los referentes barriales afirman no recibir alertas.
*Posibles causas y mitigaciones*:
1. **Certificados APNs (iOS) caducados**:
   - *Acción*: Validar que el archivo `.p8` de Apple no haya sido revocado en el Developer Portal de Apple. Renovar y resubir a Firebase Console > Cloud Messaging.
2. **Tokens FCM expirados**:
   - *Acción*: La app móvil tiene una lógica que actualiza el token FCM en Firestore cada vez que inicia la app. Pedir a los referentes que abran la aplicación para forzar la actualización del token.

---

## 3. Disaster Recovery y Operaciones Manuales

### 3.1. Re-despliegue de Reglas de Seguridad (Emergencia)
Si ocurre una brecha o las reglas de seguridad introducen un bug bloqueante en producción, forzar el despliegue de las reglas desde la máquina local:
```bash
firebase deploy --only firestore:rules
```

### 3.2. Rollback de Cloud Functions
Para deshacer un despliegue fallido que introdujo regresiones en la lógica NLP:
1. Usar Git para volver al último commit estable (`git checkout <commit-hash>`).
2. Re-desplegar forzosamente:
```bash
cd functions
npm run build
firebase deploy --only functions
```

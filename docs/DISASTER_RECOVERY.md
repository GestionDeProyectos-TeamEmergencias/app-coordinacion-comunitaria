# Plan de Recuperación ante Desastres (Disaster Recovery Plan - DRP)

Este documento establece las políticas y procedimientos técnicos operativos destinados a recuperar la infraestructura de datos y los servicios críticos de la *App de Coordinación Comunitaria* en caso de un evento catastrófico (corrupción de base de datos, borrado accidental por administrador, fallo regional de GCP).

## 1. Objetivos de Recuperación (SLAs)

Dada la naturaleza ciudadana pero no crítica (no-vital) de la aplicación, se establecen los siguientes umbrales:
*   **RPO (Recovery Point Objective):** 24 Horas. Es la máxima cantidad de pérdida de datos aceptable. Los backups se tomarán diariamente.
*   **RTO (Recovery Time Objective):** 4 Horas. Es el tiempo máximo para restaurar el servicio a un estado operativo tras la declaración del desastre.

## 2. Estrategias de Respaldo (Backups)

### 2.1. Cloud Firestore
Se requiere habilitar los backups programados (Scheduled Backups) nativos de GCP (Google Cloud Platform) o utilizar Cloud Scheduler + Cloud Functions para exportar la base de datos a un bucket de Google Cloud Storage.
*   **Frecuencia:** Diaria a las 03:00 AM (Hora Local).
*   **Retención:** 30 Días.
*   **Destino:** `gs://<FIREBASE_PROJECT_ID>-firestore-backups` (Clase de almacenamiento Coldline).

### 2.2. Firebase Storage (Archivos Multimedia)
Para prevenir el borrado accidental o sobrescritura de evidencias fotográficas, el bucket primario de Firebase Storage debe contar con Object Versioning activado.
*   **Política de Ciclo de Vida:** Mantener versiones no actuales por 15 días, luego aplicar borrado definitivo.

## 3. Procedimiento de Restauración (Playbook)

### Escenario A: Corrupción de Datos en Firestore
Si la base de datos Firestore es comprometida:
1. Aislar el entorno: Bloquear temporalmente el acceso de escritura desde la App Móvil modificando `firestore.rules` (forzar `allow write: if false;`).
2. Identificar el punto de restauración válido más reciente (PITR o Snapshot diario).
3. Ejecutar la importación de datos desde Cloud Shell:
   ```bash
   gcloud firestore import gs://<FIREBASE_PROJECT_ID>-firestore-backups/<TIMESTAMP> --async
   ```
4. Validar la integridad referencial de los reportes.
5. Restaurar `firestore.rules` al estado original.

### Escenario B: Interrupción Regional de Firebase (Caída Total)
Al utilizar una arquitectura "Serverless" administrada por Google, una caída total de región (e.g. `us-central1`) está fuera de nuestra matriz de control directo.
1. Activar el Banner de Mantenimiento en la aplicación vía Firebase Remote Config (o DNS Failover si se utiliza un backend edge).
2. Notificar a los Referentes Barriales por vías alternativas (Email/WhatsApp) que la gestión de incidentes en curso está pausada.
3. Esperar el reporte de mitigación de la página oficial de Google Cloud Status.

## 4. Simulacros (Drills)
El equipo de ingeniería deberá realizar un simulacro de recuperación (Tabletop Exercise) semestralmente, restaurando un snapshot de producción en un entorno de Firebase Emulator local, verificando que el RTO de 4 horas sea realista.

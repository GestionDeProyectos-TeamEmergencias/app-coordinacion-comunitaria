import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { FieldValue } from "firebase-admin/firestore";

import { NormalizedIncidentEvent } from "./incidentNormalization";
import { EnrichmentResult } from "./incidentEnrichment";
import { DuplicateCheckResult } from "./incidentDuplicates";
import { SemanticExtractionResult } from "./semanticExtraction";
import { PriorityResult } from "./priorityCalculation";

// ── Contrato T-NLP-08: Schema persistido del documento de incidente ──────────
// Esta interfaz documenta los campos obligatorios que debe tener un documento
// `incidents/{id}` una vez que el pipeline NLP terminó correctamente, según
// RF-SAL-02. La validación se hace en `assertIncidentCompleteness()`.

// Estado inicial del incidente procesado. ACOPLADO al enum del cliente Flutter:
// `IncidentStatus.recibido.firestoreValue` en
// `lib/features/incidents/domain/entities/incident_event.dart`. Cualquier cambio
// acá debe sincronizarse con el frontend para que el `fromString` no caiga al
// default y desaparezcan los incidentes del listado activo.
export const INITIAL_STATUS = "recibido" as const;

/**
 * Etapas del pipeline NLP que se registran en `incidents/{id}/audit/`. Útil
 * para reconstruir el orden y la duración de cada etapa cuando un incidente
 * se investiga después de procesado.
 */
export type IncidentPipelineStage =
  | "received"
  | "normalized"
  | "author_validated"
  | "coverage_validated"
  | "coverage_rejected"
  | "author_inactive_rejected"
  | "enrichment_built"
  | "duplicate_check_done"
  | "vital_risk_evaluated"
  | "vital_risk_interrupted"
  | "semantic_extracted"
  | "semantic_extraction_failed"
  | "priority_calculated"
  | "priority_calculation_failed"
  | "persisted"
  | "alerts_dispatched"
  | "pipeline_failed";

export interface PersistedIncidentDocument {
  // Datos del evento normalizados (incluye userID, timestamp original, location, descripción, categoría).
  normalizedEvent: NormalizedIncidentEvent;
  normalizationWarnings: string[];
  // Contexto de enriquecimiento y deduplicación que alimenta la priorización.
  enrichment: EnrichmentResult;
  duplicateCheck: DuplicateCheckResult;
  // Salidas del NLP — opcionales si los flows fallan, pero requeridas en el happy path.
  semanticExtraction?: SemanticExtractionResult & { extractedAt: string };
  priorityCalculation?: PriorityResult & { calculatedAt: string };
  // Atajos para queries eficientes desde el cliente: priority y priorityScore
  // se duplican en el nivel superior, además de quedar dentro de priorityCalculation.
  priority?: PriorityResult["priority"];
  priorityScore?: PriorityResult["priorityScore"];
  // Estado inicial requerido por T-NLP-08 / RF-SAL-02.
  status: typeof INITIAL_STATUS;
  // Marcadores temporales de la auditoría.
  normalizedAt: admin.firestore.FieldValue | Date;
}

interface PersistProcessedIncidentArgs {
  firestore: admin.firestore.Firestore;
  incidentId: string;
  normalizedEvent: NormalizedIncidentEvent;
  warnings: string[];
  enrichment: EnrichmentResult;
  duplicateCheck: DuplicateCheckResult;
  semanticExtraction:
    | (SemanticExtractionResult & { extractedAt: string })
    | null;
  priorityCalculation: (PriorityResult & { calculatedAt: string }) | null;
}

export interface PersistResult {
  // True si la transacción seteó `status: "recibido"` (false si el cliente o
  // un admin ya había escrito otro valor entre la creación y el procesamiento).
  statusSet: boolean;
  // Issues detectados en los datos que se persistieron (campos faltantes según
  // RF-SAL-02). Validación in-memory para no agregar un GET adicional.
  issues: string[];
}

/**
 * Escribe el documento final del incidente procesado garantizando que todos
 * los campos exigidos por T-NLP-08 estén presentes y que el `status` inicial
 * sea "recibido". Idempotente y atómico: usa runTransaction para evitar pisar
 * cambios concurrentes entre el read del status y el update.
 *
 * Retorna issues detectados sobre los datos que se acaban de persistir
 * (in-memory, sin hacer un GET extra) para que el caller decida cómo loggear.
 */
export async function persistProcessedIncident(
  args: PersistProcessedIncidentArgs,
): Promise<PersistResult> {
  const {
    firestore,
    incidentId,
    normalizedEvent,
    warnings,
    enrichment,
    duplicateCheck,
    semanticExtraction,
    priorityCalculation,
  } = args;

  const incidentRef = firestore.collection("incidents").doc(incidentId);

  const statusSet = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(incidentRef);
    const currentStatus = snap.data()?.status;
    // Solo seteamos "recibido" si el cliente no escribió otro status o ya
    // era "recibido". Esto evita pisar cambios manuales del admin entre la
    // creación y el final del pipeline (caso raro pero posible con cargas
    // pesadas del LLM).
    const shouldSetStatus = !currentStatus || currentStatus === INITIAL_STATUS;

    tx.update(incidentRef, {
      normalizedEvent,
      normalizationWarnings: warnings,
      enrichment,
      duplicateCheck,
      ...(semanticExtraction ? { semanticExtraction } : {}),
      ...(priorityCalculation
        ? {
            priority: priorityCalculation.priority,
            priorityScore: priorityCalculation.priorityScore,
            priorityCalculation,
          }
        : {}),
      ...(shouldSetStatus ? { status: INITIAL_STATUS } : {}),
      normalizedAt: FieldValue.serverTimestamp(),
    });

    return shouldSetStatus;
  });

  // Validamos in-memory los datos que recién persistimos en lugar de hacer un
  // GET adicional a Firestore (1 read menos por incidente).
  const issues = validateInMemoryCompleteness({
    normalizedEvent,
    semanticExtraction,
    priorityCalculation,
    statusSet,
  });

  return { statusSet, issues };
}

interface InMemoryValidationArgs {
  normalizedEvent: NormalizedIncidentEvent;
  semanticExtraction:
    | (SemanticExtractionResult & { extractedAt: string })
    | null;
  priorityCalculation: (PriorityResult & { calculatedAt: string }) | null;
  statusSet: boolean;
}

function validateInMemoryCompleteness(args: InMemoryValidationArgs): string[] {
  const issues: string[] = [];
  if (!args.normalizedEvent.userId) issues.push("missing normalizedEvent.userId");
  if (!args.normalizedEvent.timestamp) {
    issues.push("missing normalizedEvent.timestamp (timestamp de creación)");
  }
  if (!args.normalizedEvent.location) {
    issues.push("missing normalizedEvent.location");
  }
  if (args.normalizedEvent.category === undefined) {
    issues.push("missing normalizedEvent.category");
  }
  if (!args.priorityCalculation) {
    issues.push("missing priorityCalculation (priority + score)");
  }
  if (!args.statusSet) {
    // No es un error si el admin ya cambió el estado entremedio, pero conviene
    // dejarlo registrado para auditoría.
    issues.push(
      "status not set to recibido (probablemente otro proceso lo cambió antes)",
    );
  }
  return issues;
}

/**
 * Registra una entrada de auditoría en la subcolección `incidents/{id}/audit`.
 * Cada entrada queda con un `stage`, su timestamp del servidor y detalles
 * opcionales. Los errores se loggean pero no rompen el pipeline — la auditoría
 * es best-effort.
 */
export async function appendAuditEntry(
  firestore: admin.firestore.Firestore,
  incidentId: string,
  stage: IncidentPipelineStage,
  details?: Record<string, unknown>,
): Promise<void> {
  try {
    await firestore
      .collection("incidents")
      .doc(incidentId)
      .collection("audit")
      .add({
        stage,
        at: FieldValue.serverTimestamp(),
        ...(details ? { details } : {}),
      });
  } catch (error) {
    logger.warn("Failed to append audit entry", { incidentId, stage, error });
  }
}

/**
 * Verifica en runtime que un documento de incidente cumple los criterios
 * de T-NLP-08 / RF-SAL-02. Loggea warnings por cada campo faltante. Retorna
 * la lista de issues encontrados para que el caller decida cómo tratarlos.
 */
export function assertIncidentCompleteness(
  data: FirebaseFirestore.DocumentData | undefined,
): string[] {
  const issues: string[] = [];
  if (!data) {
    return ["document is missing or empty"];
  }
  const normalizedEvent = data.normalizedEvent;
  if (!normalizedEvent) {
    issues.push("missing normalizedEvent (datos del evento)");
  } else {
    if (!normalizedEvent.userId) issues.push("missing normalizedEvent.userId");
    if (!normalizedEvent.timestamp) {
      issues.push("missing normalizedEvent.timestamp (timestamp de creación)");
    }
    if (!normalizedEvent.location) issues.push("missing normalizedEvent.location");
    if (normalizedEvent.category === undefined) {
      issues.push("missing normalizedEvent.category");
    }
  }
  if (!data.normalizedAt) {
    issues.push("missing normalizedAt (timestamp de procesamiento NLP)");
  }
  if (!data.priority) issues.push("missing priority");
  if (data.priorityScore === undefined) issues.push("missing priorityScore");
  if (!data.status) issues.push("missing status");
  return issues;
}

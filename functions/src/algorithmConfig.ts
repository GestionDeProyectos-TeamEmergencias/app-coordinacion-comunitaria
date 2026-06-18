import { z } from "genkit";
import * as logger from "firebase-functions/logger";
import type { firestore as FirestoreAdmin } from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

// ── Schema (T-NLP-06) ────────────────────────────────────────────────────────
// Configuración persistida en Firestore (config/algorithm). Cualquier campo
// ausente se completa con DEFAULT_ALGORITHM_CONFIG. Los Cloud Functions
// no necesitan redeploy cuando el administrador actualiza estos valores.

const RiskCategoryShape = {
  medico: z.array(z.string().min(1)),
  seguridad: z.array(z.string().min(1)),
  desastre: z.array(z.string().min(1)),
};

export const AlgorithmConfigSchema = z.object({
  vitalRiskTerms: z.object(RiskCategoryShape),
  emergencyNumbers: z.object(RiskCategoryShape),
  categoryBaseScores: z.object({
    alumbrado_electrico: z.number().min(0).max(100),
    infraestructura_vial: z.number().min(0).max(100),
    pavimentacion: z.number().min(0).max(100),
    saneamiento: z.number().min(0).max(100),
    espacios_verdes: z.number().min(0).max(100),
    otro: z.number().min(0).max(100),
  }),
  priorityWeights: z.object({
    semanticTermsLimit: z.number().int().min(0).max(10),
    semanticTermPointsMultiplier: z.number().min(0).max(50),
    duplicateNearbyPoints: z.number().min(0).max(50),
    duplicateMaxPoints: z.number().min(0).max(50),
    reputationLowThreshold: z.number().min(0).max(100),
    reputationHighThreshold: z.number().min(0).max(100),
    reputationAdjustment: z.number().min(0).max(50),
  }),
  priorityThresholds: z.object({
    urgente: z.number().int().min(0).max(100),
    alta: z.number().int().min(0).max(100),
    media: z.number().int().min(0).max(100),
  }),
});

export type AlgorithmConfig = z.infer<typeof AlgorithmConfigSchema>;

// Versión parcial usada por updateAlgorithmConfig — todos los campos opcionales,
// pero los presentes deben respetar el schema.
export const AlgorithmConfigPatchSchema = AlgorithmConfigSchema.deepPartial();
export type AlgorithmConfigPatch = z.infer<typeof AlgorithmConfigPatchSchema>;

// ── Defaults ─────────────────────────────────────────────────────────────────

export const DEFAULT_ALGORITHM_CONFIG: AlgorithmConfig = {
  vitalRiskTerms: {
    medico: [
      "infarto", "infartando", "convulsion", "convulsionando",
      "inconsciente", "desmayado", "paro cardiaco", "no respira",
      "hemorragia", "desangrando", "sobredosis", "ahogando",
      "electrocutado", "electrocucion", "intoxicacion",
    ],
    seguridad: [
      "tiroteo", "disparos", "disparo", "baleado",
      "apunalado", "acuchillado", "navajazo",
      "asalto armado", "secuestro", "rehen", "rehenes",
      "amenaza de bomba", "explosion", "arma de fuego",
      "robo a mano armada",
    ],
    desastre: [
      "incendio", "se prende fuego", "prendio fuego",
      "derrumbe", "colapso", "edificio colapsado",
      "inundacion grave", "atrapado", "persona atrapada",
      "personas atrapadas", "derrumbe de edificio",
    ],
  },
  emergencyNumbers: {
    medico: ["107", "911"],
    seguridad: ["911"],
    desastre: ["911", "100"],
  },
  categoryBaseScores: {
    alumbrado_electrico: 40,
    infraestructura_vial: 40,
    pavimentacion: 30,
    saneamiento: 30,
    espacios_verdes: 20,
    otro: 10,
  },
  priorityWeights: {
    semanticTermsLimit: 3,
    semanticTermPointsMultiplier: 10,
    duplicateNearbyPoints: 5,
    duplicateMaxPoints: 20,
    reputationLowThreshold: 30,
    reputationHighThreshold: 80,
    reputationAdjustment: 10,
  },
  priorityThresholds: {
    urgente: 80,
    alta: 60,
    media: 30,
  },
};

// ── Caché in-memory ──────────────────────────────────────────────────────────

export const CONFIG_DOC_PATH = "config/algorithm";
const CACHE_TTL_MS = 60_000;

interface CacheEntry {
  config: AlgorithmConfig;
  expiresAt: number;
}

let cache: CacheEntry | null = null;

export function invalidateAlgorithmConfigCache(): void {
  cache = null;
}

// ── Funciones de carga / lectura / persistencia ──────────────────────────────

/**
 * Carga la config aplicando caché de 60s. Pensada para uso en el pipeline de
 * normalización donde se invoca por cada incidente: la latencia adicional debe
 * ser despreciable y la frescura de 1 minuto es suficiente.
 */
export async function loadAlgorithmConfig(
  firestore: FirestoreAdmin.Firestore
): Promise<AlgorithmConfig> {
  const now = Date.now();
  if (cache && cache.expiresAt > now) {
    return cache.config;
  }
  const fresh = await getAlgorithmConfig(firestore);
  cache = { config: fresh, expiresAt: now + CACHE_TTL_MS };
  return fresh;
}

/**
 * Lee la config directo de Firestore sin caché. Usada por el endpoint GET
 * del panel del administrador para que siempre obtenga el último valor.
 */
export async function getAlgorithmConfig(
  firestore: FirestoreAdmin.Firestore
): Promise<AlgorithmConfig> {
  const snap = await firestore.doc(CONFIG_DOC_PATH).get();
  if (!snap.exists) {
    return DEFAULT_ALGORITHM_CONFIG;
  }
  return mergeWithDefaults(snap.data() ?? {});
}

/**
 * Persiste un patch parcial mergeado con la config actual. Usa una transacción
 * para evitar race conditions cuando varios admins editan simultáneamente.
 * Valida el resultado contra el schema completo antes de escribir e invalida
 * el caché para que el próximo `loadAlgorithmConfig` lea el valor nuevo.
 */
export async function saveAlgorithmConfig(
  firestore: FirestoreAdmin.Firestore,
  patch: AlgorithmConfigPatch,
  updatedBy: string
): Promise<AlgorithmConfig> {
  // Validar el patch antes de tocar Firestore.
  AlgorithmConfigPatchSchema.parse(patch);

  const docRef = firestore.doc(CONFIG_DOC_PATH);
  const validated = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    const current = snap.exists
      ? mergeWithDefaults(snap.data() ?? {})
      : DEFAULT_ALGORITHM_CONFIG;
    const merged = mergeConfig(current, patch);
    const result = AlgorithmConfigSchema.parse(merged);
    tx.set(
      docRef,
      {
        ...result,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy,
      },
      { merge: true }
    );
    return result;
  });

  invalidateAlgorithmConfigCache();
  return validated;
}

// ── Merge helpers ────────────────────────────────────────────────────────────

function mergeWithDefaults(raw: Record<string, unknown>): AlgorithmConfig {
  const merged = mergeConfig(DEFAULT_ALGORITHM_CONFIG, raw as AlgorithmConfigPatch);
  const parsed = AlgorithmConfigSchema.safeParse(merged);
  if (!parsed.success) {
    // Si Firestore tiene datos inválidos, caemos a defaults sin romper el pipeline.
    logger.warn("Algorithm config in Firestore is invalid, falling back to defaults", {
      issues: parsed.error.flatten(),
    });
    return DEFAULT_ALGORITHM_CONFIG;
  }
  return parsed.data;
}

function mergeConfig(
  base: AlgorithmConfig,
  patch: AlgorithmConfigPatch
): AlgorithmConfig {
  return {
    vitalRiskTerms: {
      ...base.vitalRiskTerms,
      ...(patch.vitalRiskTerms ?? {}),
    } as AlgorithmConfig["vitalRiskTerms"],
    emergencyNumbers: {
      ...base.emergencyNumbers,
      ...(patch.emergencyNumbers ?? {}),
    } as AlgorithmConfig["emergencyNumbers"],
    categoryBaseScores: {
      ...base.categoryBaseScores,
      ...(patch.categoryBaseScores ?? {}),
    },
    priorityWeights: {
      ...base.priorityWeights,
      ...(patch.priorityWeights ?? {}),
    },
    priorityThresholds: {
      ...base.priorityThresholds,
      ...(patch.priorityThresholds ?? {}),
    },
  };
}

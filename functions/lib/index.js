"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizeIncident = exports.classifyIncident = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_2 = require("firebase-admin/firestore");
const genkit_1 = require("genkit");
const google_genai_1 = require("@genkit-ai/google-genai");
const incidentNormalization_1 = require("./incidentNormalization");
const incidentEnrichment_1 = require("./incidentEnrichment");
const incidentDuplicates_1 = require("./incidentDuplicates");
admin.initializeApp();
// Inicializacion de Genkit con el plugin de Google Gen AI
const ai = (0, genkit_1.genkit)({
    plugins: [(0, google_genai_1.googleAI)()],
});
// Definición del esquema tipado esperado para la clasificación
const IncidentClassificationSchema = genkit_1.z.object({
    category: genkit_1.z.enum(["Vandalismo", "Infraestructura", "Seguridad", "Otro"]),
    priority: genkit_1.z.enum(["Baja", "Media", "Alta"]),
    reasoning: genkit_1.z.string().describe("Breve justificación de la clasificación"),
});
exports.classifyIncident = (0, https_1.onRequest)(async (req, res) => {
    try {
        const description = req.body.description || req.query.description || "Hubo un corte de luz en la calle principal";
        // Generación de contenido con esquema tipado usando Gemini 2.5 Flash-Lite
        const response = await ai.generate({
            model: google_genai_1.googleAI.model('gemini-2.5-flash-lite'),
            prompt: `Actúa como un asistente para un sistema de coordinación comunitaria. 
      Analiza el siguiente reporte de incidente vecinal y clasifícalo.
      Reporte: "${description}"`,
            output: {
                schema: IncidentClassificationSchema
            }
        });
        res.status(200).json({
            success: true,
            report: description,
            classification: response.output
        });
    }
    catch (error) {
        logger.error("Error al procesar el incidente con Genkit", error);
        res.status(500).json({ success: false, error: error.message });
    }
});
exports.normalizeIncident = (0, firestore_1.onDocumentCreated)("incidents/{incidentId}", async (event) => {
    const incidentId = event.params.incidentId;
    const snapshot = event.data;
    if (!snapshot) {
        logger.warn("Missing incident snapshot", { incidentId });
        return;
    }
    const data = snapshot.data();
    if (data.normalizedAt || data.normalizedEvent) {
        return;
    }
    const firestore = admin.firestore();
    try {
        const { normalizedEvent, warnings } = (0, incidentNormalization_1.normalizeIncidentEvent)(incidentId, data);
        const now = new Date();
        const enrichment = await (0, incidentEnrichment_1.buildEnrichment)(firestore, normalizedEvent.userId, now);
        const duplicateCheck = await (0, incidentDuplicates_1.detectDuplicateIncidents)(firestore, {
            incidentId,
            latitude: normalizedEvent.location.latitude,
            longitude: normalizedEvent.location.longitude,
            timestamp: new Date(normalizedEvent.timestamp),
            radiusMeters: getDuplicateRadiusMeters(),
            windowHours: getDuplicateWindowHours(),
        });
        await firestore.collection("incidents").doc(incidentId).update({
            normalizedEvent,
            normalizationWarnings: warnings,
            enrichment,
            duplicateCheck,
            normalizedAt: firestore_2.FieldValue.serverTimestamp(),
        });
    }
    catch (error) {
        logger.error("Normalization failed", { incidentId, error });
        await firestore.collection("incidents").doc(incidentId).update({
            normalizationError: {
                message: error instanceof Error ? error.message : "Unknown error",
                at: firestore_2.FieldValue.serverTimestamp(),
            },
        });
    }
});
function getDuplicateRadiusMeters() {
    var _a;
    const value = Number((_a = process.env.DUPLICATE_RADIUS_METERS) !== null && _a !== void 0 ? _a : "100");
    return Number.isFinite(value) && value > 0 ? value : 100;
}
function getDuplicateWindowHours() {
    var _a;
    const value = Number((_a = process.env.DUPLICATE_WINDOW_HOURS) !== null && _a !== void 0 ? _a : "24");
    return Number.isFinite(value) && value > 0 ? value : 24;
}
//# sourceMappingURL=index.js.map
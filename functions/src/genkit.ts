import { genkit } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

// Inicialización de la instancia compartida de Genkit con el plugin de Google Gen AI
export const ai = genkit({
  plugins: [googleAI()],
});

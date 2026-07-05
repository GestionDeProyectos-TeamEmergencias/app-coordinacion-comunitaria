# ADR 0001: Uso de Firebase Genkit con Gemini 2.5 Flash-Lite para Motor de NLP

## Estado
Aceptado

## Contexto
El núcleo de valor de la plataforma de Coordinación Comunitaria radica en clasificar automáticamente los reportes ciudadanos (texto y voz transcrita) para determinar la categoría del incidente, asignar un nivel de urgencia, y detectar inmediatamente escenarios de "riesgo vital" (emergencias puras) que deben ser derivados al 911/107. Necesitamos un marco de trabajo (framework) de Inteligencia Artificial que procese estas tareas de forma escalable en nuestro backend (Cloud Functions).

## Alternativas Consideradas
1. **LangChain (Node.js)**: Framework agnóstico y maduro para orquestación de LLMs.
2. **Llamadas HTTP directas a Google AI Studio**: Usar la API REST nativa de Gemini.
3. **Firebase Genkit**: Framework nativo de Google/Firebase para integrar LLMs en TypeScript/Go con fuerte soporte de flujos y telemetría.

## Decisión
Se ha decidido adoptar **Firebase Genkit** interactuando exclusivamente con el modelo **Gemini 2.5 Flash-Lite**.

## Justificación
1. **Ecosistema Nativo**: Genkit está diseñado específicamente para correr en Firebase Cloud Functions de manera fluida, lo cual es nuestro entorno de backend.
2. **Tipado Estricto (Structured Output)**: Genkit permite definir esquemas (Zod) para forzar al modelo a devolver siempre un objeto JSON estandarizado (`EventoDeIncidente`), eliminando el frágil análisis de texto libre en respuestas.
3. **Telemetría**: Integra automáticamente `Firebase Genkit Developer UI` para depurar flujos y trazar cada petición al modelo.
4. **Costo y Velocidad**: El modelo *Gemini 2.5 Flash-Lite* ofrece el mejor balance latencia/costo para tareas de clasificación rápida, asegurando que el ciclo completo (Frontend -> Backend -> Genkit -> Alerta) demore menos de 10 segundos, según lo exigido por el SRS.

## Consecuencias
*   **Positivas**: Tiempos de desarrollo acelerados, integración nativa con Cloud Functions, tipado fuerte y validación automática de respuestas.
*   **Negativas (Riesgos)**: Mayor grado de *vendor lock-in* (dependencia directa de librerías de Google y modelos fundacionales Gemini), en comparación con frameworks agnósticos como LangChain que permiten intercambiar modelos (OpenAI, Anthropic) más fácilmente.

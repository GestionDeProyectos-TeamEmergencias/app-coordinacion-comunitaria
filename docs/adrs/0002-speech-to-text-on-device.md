# ADR 0002: Transcripción de Voz (Speech-to-Text) On-Device

## Estado
Aceptado

## Contexto
Para garantizar accesibilidad e inclusión, la aplicación permite a los Vecinos Informantes reportar incidentes dictando audios con su voz. Las Cloud Functions que evalúan el incidente (mediante Gemini) requieren texto plano (`string`) para poder extraer la prioridad y categoría con mayor certidumbre semántica. Debemos decidir dónde y cómo transcribir el audio a texto.

## Alternativas Consideradas
1. **Google Cloud Speech-to-Text API**: Enviar el audio capturado al backend y consumir la API oficial de GCP.
2. **OpenAI Whisper (API)**: Consumir el modelo de transcripción Whisper remoto.
3. **Procesamiento On-Device (Paquete `speech_to_text` en Flutter)**: Utilizar los motores de transcripción nativos incorporados en iOS (Siri/Apple Speech) y Android (Google Assistant Speech Services).

## Decisión
Se ha optado por implementar el **Procesamiento On-Device** utilizando el framework nativo del teléfono a través del plugin de Flutter `speech_to_text`. El teléfono del usuario realiza la transcripción localmente y solo envía la cadena de texto resultante hacia Firebase.

## Justificación
1. **Costos Cero (Economía de Escala)**: Al evitar invocar APIs de transcripción en la nube, el costo variable asociado al reporte por voz desciende a $0, esencial para un proyecto municipal/comunitario con presupuesto restringido.
2. **Latencia**: La transcripción local es considerablemente más rápida al no requerir codificación del audio, subida al Storage, disparo de trigger, y llamada a una API externa. El usuario ve la transcripción en tiempo real antes de presionar "Enviar".
3. **Privacidad**: El archivo de audio (que contiene la voz biométrica del usuario) nunca abandona el dispositivo. Sólo se transfiere el texto final a Firestore, reduciendo radicalmente el riesgo frente a la PII.
4. **Acuerdo con Requisitos**: El documento `AGENTS.md` subraya la necesidad de procesamiento de voz 100% *on-device*.

## Consecuencias
*   **Positivas**: Cero costos operativos por transcripción, UI en tiempo real, latencia mínima y mitigación de problemas de privacidad.
*   **Negativas (Riesgos)**: Dependemos enteramente de la capacidad de procesamiento de la CPU del usuario y de la calidad del modelo nativo de su OS (que varía notablemente entre un teléfono Android de gama baja y un iOS reciente). Esto puede inyectar errores tipográficos menores al modelo de Genkit.

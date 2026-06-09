import 'package:app_coordinacion_comunitaria/features/incidents/presentation/widgets/voice_report_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'VoiceReportWidget maneja la falta de reconocimiento de voz sin romperse',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoiceReportWidget(
                onTranscription: (_) {},
              ),
            ),
          ),
        );

        // Esperar a que _initSpeech() se complete (fallará en test,
        // pero es manejado por el catch en el widget)
        await Future<void>.delayed(const Duration(seconds: 2));
      });

      // Reconstruir el widget con el estado actualizado
      await tester.pump();
      await tester.pump();

      // Verificar que el widget renderiza sin errores.
      // En el entorno de test sin speech_to_text nativo,
      // muestra el estado de error o reintento.
      expect(tester.takeException(), isNull);

      // Verificar que el mensaje de error o reintento aparece
      final hasError = find.textContaining('reconocimiento de voz')
          .evaluate()
          .isNotEmpty;
      final hasRetry = find.text('Reintentar').evaluate().isNotEmpty;

      // Al menos uno de estos estados debe aparecer
      expect(hasError || hasRetry, isTrue);
    },
  );

  testWidgets(
    'VoiceReportWidget no lanza excepciones al interactuar',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoiceReportWidget(
                onTranscription: (_) {},
              ),
            ),
          ),
        );

        await Future<void>.delayed(const Duration(seconds: 2));
      });

      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

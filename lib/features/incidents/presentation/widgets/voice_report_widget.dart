import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// RF-REP-02: transcripción on-device usando speech_to_text.
/// Procesamiento 100% on-device.
/// Llama a onTranscription cuando la transcripción finaliza.
class VoiceReportWidget extends StatefulWidget {
  const VoiceReportWidget({
    super.key,
    required this.onTranscription,
  });

  final void Function(String text) onTranscription;

  @override
  State<VoiceReportWidget> createState() => _VoiceReportWidgetState();
}

class _VoiceReportWidgetState extends State<VoiceReportWidget> {
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  bool _available = false;
  bool _initializing = true;

  String? _errorMessage;
  String _text = '';

  bool _transcriptionSent = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    if (!mounted) return;

    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    try {
      final available = await _speech.initialize(
        debugLogging: false,
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });

            if (!_transcriptionSent && _text.trim().isNotEmpty) {
              _transcriptionSent = true;
              widget.onTranscription(_text.trim());
            }
          }
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _isListening = false;
            _errorMessage = 'Error en el reconocimiento de voz.\n'
                'Verificá permisos y micrófono.';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _available = available;
        _initializing = false;

        if (!available) {
          _errorMessage = 'Reconocimiento de voz no disponible.\n'
              'Verificá permisos del micrófono.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _available = false;
        _initializing = false;
        _errorMessage = 'No se pudo inicializar el reconocimiento de voz.';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_initializing || !_available) return;

    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      return;
    }

    _transcriptionSent = false;

    setState(() {
      _isListening = true;
      _text = '';
      _errorMessage = null;
    });

    await _speech.listen(
      localeId: 'es_AR',
      listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation),
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;

        setState(() {
          _text = result.recognizedWords;
        });

        /// Cuando el reconocimiento es final
        if (result.finalResult &&
            !_transcriptionSent &&
            result.recognizedWords.trim().isNotEmpty) {
          _transcriptionSent = true;

          widget.onTranscription(
            result.recognizedWords.trim(),
          );
        }
      },
    );
  }

  Future<void> _retry() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _available = false;
      _initializing = true;
    });

    await _initSpeech();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isListening
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening ? Colors.red : Colors.grey,
            ),
          ),
          child: _buildContent(context),
        ),
        const SizedBox(height: 16),
        if (_initializing)
          const CircularProgressIndicator()
        else if (_available)
          FloatingActionButton.extended(
            onPressed: _toggleListening,
            backgroundColor: _isListening ? Colors.red : null,
            icon: Icon(
              _isListening ? Icons.stop : Icons.mic,
            ),
            label: Text(
              _isListening ? 'Detener' : 'Hablar',
            ),
          )
        else ...[
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initializing) {
      return const Text(
        'Inicializando micrófono...',
        textAlign: TextAlign.center,
      );
    }

    if (!_available && _errorMessage != null) {
      return Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    if (_text.isEmpty) {
      return Text(
        _isListening ? 'Escuchando...' : 'Presioná el botón para hablar',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Text(
      _text,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

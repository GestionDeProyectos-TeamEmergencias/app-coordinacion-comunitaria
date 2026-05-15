import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// RF-REP-02: transcripción on-device usando speech_to_text.
// Llama a onTranscription con el texto final cuando el usuario termina.
class VoiceReportWidget extends StatefulWidget {
  const VoiceReportWidget({super.key, required this.onTranscription});

  final void Function(String text) onTranscription;

  @override
  State<VoiceReportWidget> createState() => _VoiceReportWidgetState();
}

class _VoiceReportWidgetState extends State<VoiceReportWidget> {
  final _speech = SpeechToText();
  bool _isListening = false;
  bool _available = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          if (_text.isNotEmpty) widget.onTranscription(_text);
        }
      },
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_available) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _text = '';
      });
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() => _text = result.recognizedWords);
        },
        localeId: 'es_AR',
      );
    }
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
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening ? Colors.red : Colors.grey,
            ),
          ),
          child: Text(
            _text.isEmpty
                ? (_isListening ? 'Escuchando...' : 'Presioná para hablar')
                : _text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: _available ? _toggleListening : null,
          backgroundColor: _isListening ? Colors.red : null,
          icon: Icon(_isListening ? Icons.stop : Icons.mic),
          label: Text(_isListening ? 'Detener' : 'Hablar'),
        ),
      ],
    );
  }
}

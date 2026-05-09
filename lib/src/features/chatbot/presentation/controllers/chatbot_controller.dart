import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/chatbot_service.dart';
import '../../domain/chat_message.dart';

class ChatbotController extends ChangeNotifier {
  ChatbotController({ChatbotService? service}) : _service = service ?? ChatbotService();

  final ChatbotService _service;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final List<ChatMessage> messages = <ChatMessage>[
    ChatMessage(
      text:
          'Hola, soy PetBot. Puedo ayudarte a agendar, reprogramar y cancelar citas. '
          'Tambien puedes escribirme o compartir tu ubicacion para citas a domicilio.',
      isBot: true,
    ),
  ];

  Map<String, dynamic>? _chatContext;
  String? _sharedAddress;
  bool isLoading = false;
  bool isListening = false;
  bool isSpeaking = false;
  String? speakingText;
  String? errorMessage;
  String _lastVoiceText = '';
  String? _lastOutgoingMessage;
  DateTime? _lastOutgoingAt;
  bool _lastOutgoingWasLocation = false;
  bool _isFinishingVoiceInput = false;
  bool _ttsConfigured = false;
  bool _isDisposed = false;

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || isLoading) return;

    await _sendOutgoingMessage(message);
  }

  Future<void> sharePickedLocation(String coordinates) async {
    final address = coordinates.trim();
    if (address.isEmpty || isLoading) return;

    _sharedAddress = address;
    await _sendOutgoingMessage(address, isLocation: true);
  }

  Future<void> toggleVoiceMessage() async {
    if (isLoading) return;

    if (isListening) {
      await _finishVoiceInput();
      return;
    }

    errorMessage = null;
    _lastVoiceText = '';
    _isFinishingVoiceInput = false;
    await _tts.stop();
    isSpeaking = false;
    speakingText = null;
    notifyListeners();

    final available = await _speech.initialize(
      onStatus: _handleSpeechStatus,
      onError: (error) {
        isListening = false;
        errorMessage = error.errorMsg;
        notifyListeners();
      },
    );

    if (!available) {
      errorMessage = 'No se pudo activar el reconocimiento de voz.';
      notifyListeners();
      return;
    }

    isListening = true;
    notifyListeners();

    await _speech.listen(
      localeId: 'es_ES',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
      onResult: _handleSpeechResult,
    );
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isNotEmpty) {
      _lastVoiceText = words;
    }

    if (result.finalResult && _lastVoiceText.isNotEmpty) {
      _finishVoiceInput();
    }
  }

  void _handleSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') && isListening) {
      _finishVoiceInput();
    }
  }

  Future<void> _finishVoiceInput() async {
    if (_isFinishingVoiceInput) return;
    _isFinishingVoiceInput = true;

    if (isListening) {
      isListening = false;
      await _speech.stop();
      notifyListeners();
    }

    final voiceText = _lastVoiceText.trim();
    _lastVoiceText = '';

    if (voiceText.isEmpty) {
      _isFinishingVoiceInput = false;
      return;
    }

    await sendMessage(voiceText);
    _isFinishingVoiceInput = false;
  }

  Future<void> _sendOutgoingMessage(
    String message, {
    bool isLocation = false,
  }) async {
    final now = DateTime.now();
    if (_lastOutgoingMessage == message &&
        _lastOutgoingWasLocation == isLocation &&
        _lastOutgoingAt != null &&
        now.difference(_lastOutgoingAt!) < const Duration(milliseconds: 1200)) {
      return;
    }

    _lastOutgoingMessage = message;
    _lastOutgoingWasLocation = isLocation;
    _lastOutgoingAt = now;
    isLoading = true;
    errorMessage = null;
    messages.add(
      ChatMessage(
        text: message,
        isBot: false,
        isLocation: isLocation,
      ),
    );
    notifyListeners();

    try {
      final response = await _service.sendMessage(
        message: message,
        context: _buildContext(),
      );

      _chatContext = response.context;
      final botMessage = response.message.isEmpty
          ? 'No recibi una respuesta valida del bot.'
          : response.message;
      messages.add(ChatMessage(text: botMessage, isBot: true));
    } catch (error) {
      errorMessage = error.toString();
      messages.add(
        ChatMessage(
          text: 'No pude conectar con el chatbot en este momento.',
          isBot: true,
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _buildContext() {
    final context = <String, dynamic>{...?_chatContext};
    if (_sharedAddress != null) {
      context['direccion_cita_compartida'] = _sharedAddress;
    }
    return context;
  }

  bool isSpeakingMessage(String text) => isSpeaking && speakingText == text;

  Future<void> _configureTts() async {
    if (_ttsConfigured) return;

    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _selectPleasantSpanishVoice();

    _tts.setStartHandler(() {
      isSpeaking = true;
      _notifySafely();
    });
    _tts.setCompletionHandler(() {
      isSpeaking = false;
      speakingText = null;
      _notifySafely();
    });
    _tts.setCancelHandler(() {
      isSpeaking = false;
      speakingText = null;
      _notifySafely();
    });
    _tts.setErrorHandler((_) {
      isSpeaking = false;
      speakingText = null;
      _notifySafely();
    });

    _ttsConfigured = true;
  }

  Future<void> _selectPleasantSpanishVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;

    final spanishVoices = voices.whereType<Map>().where((voice) {
      final locale = (voice['locale'] ?? '').toString().toLowerCase();
      return locale.startsWith('es');
    }).toList();

    if (spanishVoices.isEmpty) return;

    int scoreVoice(Map voice) {
      final name = (voice['name'] ?? '').toString().toLowerCase();
      final locale = (voice['locale'] ?? '').toString().toLowerCase();
      var score = 0;

      if (name.contains('natural') || name.contains('neural')) score += 60;
      if (name.contains('online')) score += 20;
      if (name.contains('premium') || name.contains('enhanced')) score += 15;

      const preferredFemaleNames = <String>[
        'dalia',
        'elvira',
        'sabina',
        'monica',
        'paulina',
        'maria',
        'lucia',
        'luciana',
        'helena',
        'sofia',
        'laura',
        'catalina',
        'paloma',
      ];

      if (preferredFemaleNames.any(name.contains)) score += 50;
      if (name.contains('female') || name.contains('mujer')) score += 40;

      if (locale == 'es-bo') score += 8;
      if (locale == 'es-mx' || locale == 'es-us') score += 6;
      if (locale == 'es-es') score += 4;

      return score;
    }

    spanishVoices.sort((a, b) => scoreVoice(b).compareTo(scoreVoice(a)));
    final selected = spanishVoices.first;

    await _tts.setVoice({
      'name': selected['name'].toString(),
      'locale': selected['locale'].toString(),
    });
  }

  Future<void> speakMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    await _configureTts();

    if (isSpeaking && speakingText == cleanText) {
      await _tts.stop();
      isSpeaking = false;
      speakingText = null;
      notifyListeners();
      return;
    }

    await _tts.stop();
    speakingText = cleanText;
    isSpeaking = true;
    notifyListeners();
    await _tts.speak(cleanText);
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

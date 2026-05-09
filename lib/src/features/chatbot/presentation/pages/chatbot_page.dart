import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/location_coordinate_picker.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingMessage = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _shareLocation(ChatbotController chatbot) async {
    if (chatbot.isLoading) return;

    var selectedCoordinates = '';
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compartir ubicacion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    LocationCoordinatePicker(
                      initialCoordinates: selectedCoordinates,
                      buttonLabel: 'Usar mi ubicacion actual',
                      onChanged: (value) {
                        setSheetState(() => selectedCoordinates = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: selectedCoordinates.trim().isEmpty
                          ? null
                          : () => Navigator.of(sheetContext).pop(true),
                      child: const Text('Enviar ubicacion'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (sent == true && mounted) {
      await chatbot.sharePickedLocation(selectedCoordinates);
    }
  }

  Future<void> _handleSend(ChatbotController chatbot) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSendingMessage || chatbot.isLoading) return;

    setState(() => _isSendingMessage = true);
    _controller.clear();
    try {
      await chatbot.sendMessage(text);
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F2FA),
        appBar: AppBar(
          title: const Text('Chatbot PetBot'),
          backgroundColor: Colors.white,
        ),
        body: Consumer<ChatbotController>(
          builder: (_, chatbot, _) {
            _scrollToBottom();

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatbot.messages.length,
                    itemBuilder: (_, index) {
                      final msg = chatbot.messages[index];
                      return MessageBubble(
                        text: msg.text,
                        isBot: msg.isBot,
                        isLocation: msg.isLocation,
                        isSpeaking: chatbot.isSpeakingMessage(msg.text),
                        onSpeak: msg.isBot
                            ? () => chatbot.speakMessage(msg.text)
                            : null,
                      );
                    },
                  ),
                ),
                if (chatbot.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      chatbot.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (chatbot.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: CircularProgressIndicator(),
                  ),
                if (chatbot.isListening)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Escuchando...',
                      style: TextStyle(
                        color: Color(0xFF6A11CB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ChatInput(
                  controller: _controller,
                  isLoading: chatbot.isLoading || _isSendingMessage,
                  isListening: chatbot.isListening,
                  onShareLocation: () => _shareLocation(chatbot),
                  onVoice: chatbot.toggleVoiceMessage,
                  onSend: () => _handleSend(chatbot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

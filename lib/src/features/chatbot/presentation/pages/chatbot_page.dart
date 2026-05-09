import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  isLoading: chatbot.isLoading,
                  isListening: chatbot.isListening,
                  onShareLocation: chatbot.shareLocation,
                  onVoice: chatbot.toggleVoiceMessage,
                  onSend: () async {
                    final text = _controller.text;
                    _controller.clear();
                    await chatbot.sendMessage(text);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

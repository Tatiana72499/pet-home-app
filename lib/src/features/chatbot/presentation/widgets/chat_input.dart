import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onShareLocation,
    required this.onVoice,
    required this.isLoading,
    required this.isListening,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onShareLocation;
  final VoidCallback onVoice;
  final bool isLoading;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        color: const Color(0xFFF7F2FA),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje para el bot',
                  filled: true,
                  fillColor: Colors.white,
                  enabled: !isLoading,
                  prefixIcon: IconButton(
                    onPressed: isLoading ? null : onShareLocation,
                    icon: const Icon(Icons.location_on_outlined),
                    tooltip: 'Enviar coordenadas como direccion',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              width: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : onVoice,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isListening ? Colors.redAccent : const Color(0xFF6A11CB),
                  side: BorderSide(
                    color:
                        isListening ? Colors.redAccent : const Color(0xFF6A11CB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              width: 52,
              child: FilledButton(
                onPressed: isLoading ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE17116),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

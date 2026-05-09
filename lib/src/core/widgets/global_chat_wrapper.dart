import 'package:flutter/material.dart';

import '../../features/chatbot/presentation/widgets/chat_fab.dart';

class GlobalChatWrapper extends StatelessWidget {
  const GlobalChatWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          bottom: 20,
          right: 20,
          child: ChatFab(),
        ),
      ],
    );
  }
}

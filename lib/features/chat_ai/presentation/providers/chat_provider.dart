import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hi! I'm your AI financial assistant. Tell me what you spent today.", isUser: false, timestamp: DateTime.now()),
  ];

  List<ChatMessage> get messages => _messages;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    // User message
    _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    notifyListeners();

    // AI Simulated response
    _simulateAIResponse(text);
  }

  void _simulateAIResponse(String userText) {
    Future.delayed(const Duration(seconds: 1), () {
      _messages.add(ChatMessage(
        text: 'Got it! Added to your expenses.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      // Need a way to parse "Added 500 for food" and add to dashboard provider...
      // For phase 1 we'll keep it simple UI simulation.
    });
  }
}

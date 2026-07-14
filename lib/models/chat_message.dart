// lib/models/chat_message.dart

class ChatMessage {
  final String role; // 'user' atau 'model'
  final String text;
  final DateTime time;

  ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });
}
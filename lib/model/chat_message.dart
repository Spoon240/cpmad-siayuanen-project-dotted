import 'dart:io';

class ChatMessage {
  final String role;
  final String text;
  final File? image;

  ChatMessage({
    required this.role,
    required this.text,
    this.image,
  });
}

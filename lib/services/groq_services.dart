// in lib/services/groq_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class GroqService {
  static const String _apiKey = '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';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';
  String? _cachedUsername;

  static const String _system = '''
  You are a macro-tracking coach in a mobile app. Be concise and actionable.
  Use grams and kcal. You are a helpful assistance that can help to estimate calories for users using an image they sent.
  You are to give useful advice but not to wordy or lengthy. You are not too strict to the users, make them feel like your friend.
  You will perform what the user ask even if it is not related to fitness
  ''';


  Future<String?> _getUsername() async {
    if (_cachedUsername != null) return _cachedUsername;
    final name = await FirestoreService().fetchCurrentUsername();
    _cachedUsername = name;
    return name;
  }

  Future<String> sendMessage({required String chatId, required String messageText, String? contextBlock, File? imageFile}) async {
    final username = await _getUsername();

    // Build user content: text only OR text + image
    final List<Map<String, dynamic>> userContent = [];
    final txt = messageText.trim();
    if (txt.isNotEmpty) {
      userContent.add({"type": "text", "text": txt});
    }
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mime = (ext == 'png') ? 'png' : 'jpeg';
      userContent.add({
        "type": "image_url",
        "image_url": {"url": "data:image/$mime;base64,$b64"},
      });
    }

    final recent = await FirestoreService().fetchRecentMessages(chatId, limit: 30);
    final recentAsChat = recent
      .where((msg) => (msg['text'] ?? '').toString().trim().isNotEmpty)
      .map<Map<String, dynamic>>((msg) => {
            'role': (msg['role'] == 'assistant') ? 'assistant' : 'user',
            'content': msg['text'],
          }).toList();

      // debugPrint(recentAsChat.toString());
      // debugPrint(contextBlock.toString());


    final messages = <Map<String, dynamic>>[
      {
        'role': 'system', 
        'content': _system
      },

      if (username != null && username.trim().isNotEmpty)
        {
          'role': 'system', 
          'content': 'User name: ${username.trim()}.'
        },

      if (contextBlock != null && contextBlock.trim().isNotEmpty)
        {
          'role': 'system', 'content': 'App context:\n${contextBlock.trim()}'
        },
      
      ...recentAsChat,
      {
        'role': 'user', 'content': imageFile == null ? txt : userContent
      },
    ];

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'stream': false,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Groq error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final reply = data['choices'][0]['message']['content'] ?? '';
    final trimmed = reply.toString().trim();
    return trimmed.isEmpty ? '<empty>' : trimmed;
  }





}

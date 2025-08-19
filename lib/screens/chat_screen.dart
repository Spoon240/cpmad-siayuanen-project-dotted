import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/common_bot_nav.dart';
import '../widgets/stylesheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/groq_services.dart';
import '../services/firestore_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String context;
  const ChatPage({super.key, required this.chatId, required this.chatName, required this.context});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _api = GroqService(); 
  final _fs = FirestoreService();  
  final _scroll = ScrollController();

  bool _sending = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if ((text.isEmpty && _selectedImage == null) || _sending) return;

    setState(() => _sending = true);

    final File? imgForModel = _selectedImage;

    // Store USER message with image upload
    await _fs.addMessage(
      widget.chatId,
      role: 'user',
      text: text,
      imageFile: _selectedImage,
    );

    // Clear UI input
    _textController.clear();
    setState(() => _selectedImage = null);

    try {
      //Ask AI send message and text
      final reply = await _api.sendMessage(
        chatId: widget.chatId,  
        messageText: text,
        contextBlock: widget.context,
        imageFile: imgForModel,
      );

      // Store ASSISTANT message
      await _fs.addMessage(
        widget.chatId,
        role: 'assistant',
        text: reply,
      );
    } 
    catch (e) {
      await _fs.addMessage(
        widget.chatId,
        role: 'assistant',
        text: 'Error: $e',
      );
    }

    if (!mounted) return;
    setState(() => _sending = false);

    // light auto-scroll
    await Future.delayed(const Duration(milliseconds: 60));
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = _fs.messagesStream(widget.chatId);

    return Scaffold(
      appBar: buildCreateFoodAppBar('Dotted AI - ${widget.chatName}'),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;

                return ListView.builder(
                  controller: _scroll,
                  reverse: true, 
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                    itemBuilder: (context , i) {

                      // if (_sending && i == 0) {
                      //   return const TypingBubble();
                      // }
                      
                      final d = docs[i].data();
                      final role = (d['role'] ?? 'assistant') as String;
                      final text = (d['text'] ?? '') as String;
                      final imageUrl = d['imageUrl'] as String?;

                      return ChatBubble(
                        role: role,
                        text: text,
                        imageUrl: imageUrl,
                        maxWidth: 320,
                      );
                    },
                );
              },
            ),
          ),

          // Local preview before sending (not saved until _send)
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 120),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Input row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[400], // background for the whole input area
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Image button inside the "bubble"
                    IconButton(
                      icon: const Icon(Icons.image, color: const Color.fromARGB(255, 41, 87, 49)),
                      onPressed: _sending ? null : _pickImage,
                    ),

                    // Expanding text field
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 5,
                        style: AppTextStyles.bodyH_NotBold,
                        decoration: const InputDecoration(
                          hintText: 'Type your message…',
                          hintStyle: AppTextStyles.bodyH_NotBold,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (c) => _send(),
                      ),
                    ),

                    // Send button inside the same bubble
                    IconButton(
                      icon: Icon(
                        Icons.arrow_circle_left,
                        color: _sending ? Colors.grey : const Color.fromARGB(255, 41, 87, 49),
                      ),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}



class ChatBubble extends StatelessWidget {
  final String role;
  final String text;
  final String? imageUrl;
  final double maxWidth;

  const ChatBubble({
    super.key,
    required this.role,
    required this.text,
    this.imageUrl,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),

        decoration: BoxDecoration(
          color: isUser ? Color.fromARGB(255, 9, 99, 59) : Color.fromARGB(255, 142, 142, 142),
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (text.isNotEmpty)
            isUser
              ? Text(text, style: AppTextStyles.messagesText)
              : MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: AppTextStyles.messagesP,
                    strong: AppTextStyles.messagesStrong,
                    em: AppTextStyles.messagesEm,
                    code: AppTextStyles.messagesCode,
                  ),
                )
          ],
        ),
      ),
    );
  }
}


// class TypingBubble extends StatefulWidget {
//   const TypingBubble({super.key});

//   @override
//   State<TypingBubble> createState() => _TypingBubbleState();
// }

// class _TypingBubbleState extends State<TypingBubble> {
//   String _dots = '';
//   Timer? _t;

//   @override
//   void initState() {
//     super.initState();
//     _t = Timer.periodic(const Duration(milliseconds: 400), (_) {
//       setState(() => _dots = _dots.length == 3 ? '' : '$_dots.');
//     });
//   }

//   @override
//   void dispose() {
//     _t?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // match your assistant bubble style
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 142, 142, 142),
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Text('Typing$_dots', style: const TextStyle(color: Colors.white)),
//       ),
//     );
//   }
// }
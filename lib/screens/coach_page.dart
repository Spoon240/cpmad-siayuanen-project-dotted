import 'package:flutter/material.dart';
import '../widgets/stylesheet.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class CoachPage extends StatelessWidget {
  const CoachPage({super.key});

  Future<void> _createChatFlow(BuildContext context) async {
    final nameController = TextEditingController();
    final contextController  = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter chat name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contextController,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Optional: context (e.g. I want you to be...)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    final contextAI  = contextController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }

    try {
      final chatId = await FirestoreService().createChat(name, contextAI);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(chatId: chatId, chatName: name, context: contextAI),
          ),
        );
      }
    } 
    catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String chatId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete chat'),
        content: Text('Delete "$name"? This will remove all its messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirestoreService().deleteChat(chatId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted')));
      }
    }
  }


  Future<void> _editChatFlow(BuildContext context, {required String chatId, required String currentName, required String currentContext,}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentName);
    final ctxCtrl  = TextEditingController(text: currentContext);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Chat'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctxCtrl,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Context'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirestoreService().updateChat(
      chatId,
      name: nameCtrl.text.trim(),
      context: ctxCtrl.text.trim(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat updated')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirestoreService().chatsStream(), // live fetch
        builder: (context, AsyncSnapshot<dynamic> snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading chats'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs as List;
          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet. Tap Add to start.', style: AppTextStyles.body,));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: docs.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final chatId = d.id as String;
              final name = (data['name'] ?? 'Untitled') as String;
              final contextAI = (data['context'] ?? '') as String;


              return Material(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(name, style: AppTextStyles.body,),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editChatFlow(
                          context,
                          chatId: chatId,
                          currentName: name,
                          currentContext: contextAI,
                        ),
                      ),

                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, chatId, name),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(chatId: chatId, chatName: name, context: contextAI),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createChatFlow(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add", style: AppTextStyles.buttonText),
        backgroundColor: const Color(0xFF6B7E7A),
      ),
    );
  }
}





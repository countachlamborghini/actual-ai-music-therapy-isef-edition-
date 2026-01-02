import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class TherapistChat extends ConsumerStatefulWidget {
  const TherapistChat({super.key});

  @override
  ConsumerState<TherapistChat> createState() => _TherapistChatState();
}

class _TherapistChatState extends ConsumerState<TherapistChat> {
  final _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool _sending = false;

  void _addMessage(String role, String text) {
    setState(() {
      messages.add({'role': role, 'text': text});
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addMessage('user', text);
    _controller.clear();

    setState(() => _sending = true);
    final deepSeek = ref.read(deepSeekTherapistProvider);
    final currentEmotion = ref.read(stableEmotionProvider);
    final response = await deepSeek.getTherapeuticResponse(text, currentEmotion);
    _addMessage('assistant', response);

    // Look for frequency suggestion like '432 Hz' or a number + 'Hz'
    final freqMatch = RegExp(r"(\d{2,4})\s*Hz", caseSensitive: false).firstMatch(response);
    if (freqMatch != null) {
      final freq = double.tryParse(freqMatch.group(1)!);
      if (freq != null) {
        ref.read(aiSuggestedFrequencyProvider.notifier).state = freq;
      }
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Therapist Chat'),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                      decoration: BoxDecoration(
                        color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m['text'] ?? '',
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message the therapist...'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

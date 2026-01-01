import 'package:flutter/material.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _controller = TextEditingController();
  String _response = '';

  void _analyze() {
    final text = _controller.text.toLowerCase();
    if (text.contains('sad') || text.contains('bad') || text.contains('stressed')) {
      _response = 'I understand. Let\'s use a calming frequency to help you relax.';
    } else if (text.contains('happy') || text.contains('good')) {
      _response = 'Great! Let\'s enhance that positive feeling with a harmonious frequency.';
    } else {
      _response = 'Thank you for sharing. We\'ll select a balanced frequency for you.';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Guide Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('How are you feeling right now?', style: TextStyle(fontSize: 18)),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Share your thoughts...'),
            ),
            ElevatedButton(onPressed: _analyze, child: const Text('Submit')),
            if (_response.isNotEmpty) ...[
              Text(_response, style: const TextStyle(fontSize: 16)),
              ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/emotion'), child: const Text('Next')),
            ],
          ],
        ),
      ),
    );
  }
}
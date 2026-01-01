import 'package:flutter/material.dart';

class EmotionDetectionScreen extends StatefulWidget {
  const EmotionDetectionScreen({super.key});

  @override
  State<EmotionDetectionScreen> createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen> {
  String emotion = 'Detecting...';

  @override
  void initState() {
    super.initState();
    _detectEmotion();
  }

  Future<void> _detectEmotion() async {
    // Mock emotion detection
    await Future.delayed(const Duration(seconds: 2));
    emotion = 'neutral'; // Mock
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Detection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Detected Emotion:', style: TextStyle(fontSize: 20)),
            Text(emotion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/frequency'), child: const Text('Proceed to Session')),
          ],
        ),
      ),
    );
  }
}
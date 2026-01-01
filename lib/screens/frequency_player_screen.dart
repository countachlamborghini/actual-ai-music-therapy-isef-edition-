import 'package:flutter/material.dart';

class FrequencyPlayerScreen extends StatefulWidget {
  const FrequencyPlayerScreen({super.key});

  @override
  State<FrequencyPlayerScreen> createState() => _FrequencyPlayerScreenState();
}

class _FrequencyPlayerScreenState extends State<FrequencyPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Play frequency (mock)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequency Session')),
      body: const Center(
        child: Text('Playing solfeggio frequency...\nRelax and enjoy.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/game'),
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
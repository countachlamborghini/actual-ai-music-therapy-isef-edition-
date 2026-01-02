import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/top_nav_bar.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    const level = 1;
    const xp = 10;
    const streak = 1;
    return Scaffold(
      appBar: const TopNavBar(title: 'Progress'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Level: $level'),
            Text('Total XP: $xp'),
            Text('Current Streak: $streak'),
            const Text('Unlocked: Basic Session'),
            ElevatedButton(onPressed: () => context.go('/checkin'), child: const Text('Start New Session')),
          ],
        ),
      ),
    );
  }
}
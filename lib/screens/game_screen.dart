import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int level = 1;
  int xp = 0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    xp += 10;
    streak++;
    if (xp >= level * 100) {
      level++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Session')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Level: $level', style: const TextStyle(fontSize: 20)),
            Text('XP: $xp', style: const TextStyle(fontSize: 20)),
            Text('Streak: $streak', style: const TextStyle(fontSize: 20)),
            const Text('Session completed!'),
            ElevatedButton(onPressed: () => context.go('/progress'), child: const Text('View Progress')),
          ],
        ),
      ),
    );
  }
}
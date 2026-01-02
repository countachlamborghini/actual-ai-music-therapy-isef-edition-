import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/top_nav_bar.dart';

// Repurposed: Game screen removed in favor of rewards/Xp system. Redirect users to Rewards screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Games have been replaced by a Rewards system.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.go('/rewards'), child: const Text('Go to Rewards')),
          ],
        ),
      ),
    );
  }
}
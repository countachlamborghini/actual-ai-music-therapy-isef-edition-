import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/top_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: 'Home'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _HomeTile(
                  title: 'AI Music Therapy',
                  icon: Icons.music_note,
                  onTap: () => context.go('/frequency'),
                ),
                _HomeTile(
                  title: 'Therapist',
                  icon: Icons.psychology,
                  onTap: () => context.go('/therapist'),
                ),
                _HomeTile(
                  title: 'Rewards & XP',
                  icon: Icons.stars,
                  onTap: () => context.go('/rewards'),
                ),
                _HomeTile(
                  title: 'Settings',
                  icon: Icons.settings,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Learn with short, entertaining lessons — coming soon!', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('We will add Khan Academy-like short modules to learn about music therapy concepts, how frequencies affect mood, and self-care tips.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const TopNavBar({super.key, this.title = 'AI Music Therapy', this.extraActions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home, color: Colors.white),
          label: const Text('Home', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => context.go('/therapist'),
          icon: const Icon(Icons.psychology, color: Colors.white),
          label: const Text('Therapist', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.music_note, color: Colors.white),
          label: const Text('AI Music Therapy', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings, color: Colors.white),
          label: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
        if (extraActions != null) ...extraActions!,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/top_nav_bar.dart';
import '../providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider);
    final unlocked = ref.watch(unlockedRewardsProvider);

    return Scaffold(
      appBar: const TopNavBar(title: 'Rewards & XP'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total XP: ${xp.total}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('Tier: ${xp.tierName}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            const Text('Unlocked Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: unlocked.isEmpty
                  ? const Text('No rewards unlocked yet. Keep doing sessions to earn XP!')
                  : ListView.builder(
                      itemCount: unlocked.length,
                      itemBuilder: (context, index) {
                        final r = unlocked[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard),
                            title: Text(r['title'] ?? ''),
                            subtitle: Text(r['description'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

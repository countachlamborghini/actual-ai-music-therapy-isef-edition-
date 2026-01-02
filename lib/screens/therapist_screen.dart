import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/therapist_chat.dart';
import '../widgets/top_nav_bar.dart';

class TherapistScreen extends ConsumerWidget {
  const TherapistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const TopNavBar(title: 'Therapist'),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: TherapistChat(),
      ),
    );
  }
}

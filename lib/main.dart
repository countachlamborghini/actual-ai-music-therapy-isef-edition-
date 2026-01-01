import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/onboarding_screen.dart';
import 'screens/check_in_screen.dart';
import 'screens/emotion_detection_screen.dart';
import 'screens/frequency_player_screen.dart';
import 'screens/game_screen.dart';
import 'screens/progress_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Music Therapy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/emotion': (context) => const EmotionDetectionScreen(),
        '/frequency': (context) => const FrequencyPlayerScreen(),
        '/game': (context) => const GameScreen(),
        '/progress': (context) => const ProgressScreen(),
      },
    );
  }
}
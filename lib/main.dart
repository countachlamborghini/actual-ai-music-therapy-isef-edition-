import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
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
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/checkin', builder: (context, state) => const CheckInScreen()),
        GoRoute(path: '/emotion', builder: (context, state) => const EmotionDetectionScreen()),
        GoRoute(path: '/frequency', builder: (context, state) => const FrequencyPlayerScreen()),
        GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
        GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'AI Music Therapy - ISEF Edition',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2), // Professional blue
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
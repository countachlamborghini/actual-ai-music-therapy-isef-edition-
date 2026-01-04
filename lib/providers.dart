import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final emotionProvider = StateProvider<String>((ref) => 'neutral');
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) => {});
final chatHistoryProvider =
    StateProvider<List<Map<String, String>>>((ref) => []);
final detectedEmotionProvider = StateProvider<String>((ref) => 'neutral');
final recommendedFrequencyProvider =
    StateProvider<String>((ref) => 'Universal Healing');

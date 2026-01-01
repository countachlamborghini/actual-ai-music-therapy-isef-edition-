import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final emotionProvider = StateProvider<String>((ref) => 'neutral');
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) => {});
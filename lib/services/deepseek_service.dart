import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepseekService {
  // Get API key from environment variable - with debugging
  static String getApiKey() {
    final key = dotenv.env['DEEPSEEK_API_KEY'];
    if (key == null || key.isEmpty) {
      print('⚠️ WARNING: DEEPSEEK_API_KEY not found in environment variables');
      print('Available env vars: ${dotenv.env.keys}');
      // Return the key directly as fallback (OpenRouter key)
      return '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';
    }
    return key;
  }

  static const String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Detect emotion from user's text input using DeepSeek
  static Future<Map<String, dynamic>> detectEmotionFromText(
      String userText) async {
    try {
      final apiKey = getApiKey();
      print('🔑 Using API key: ${apiKey.substring(0, 20)}...');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek/deepseek-chat',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are an emotion detection expert. Analyze the user's text and determine their primary emotion.
              
Respond ONLY with a JSON object in this format:
{
  "primary_emotion": "emotion_name",
  "confidence": 0.0-1.0,
  "emotions": {
    "happy": 0.0-1.0,
    "sad": 0.0-1.0,
    "angry": 0.0-1.0,
    "anxious": 0.0-1.0,
    "neutral": 0.0-1.0,
    "surprised": 0.0-1.0,
    "disgusted": 0.0-1.0,
    "fearful": 0.0-1.0
  }
}

All emotion scores should sum to approximately 1.0. Be accurate and precise.'''
                },
                {
                  'role': 'user',
                  'content': 'Analyze my emotional state: $userText'
                }
              ],
              'temperature': 0.7,
              'max_tokens': 200,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Emotion detection request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var content = data['choices'][0]['message']['content'];

        // Strip markdown code blocks if present
        if (content.contains('```json')) {
          content = content
              .replaceAll(RegExp(r'```json\n?'), '')
              .replaceAll(RegExp(r'\n?```'), '');
        } else if (content.contains('```')) {
          content = content
              .replaceAll(RegExp(r'```\n?'), '')
              .replaceAll(RegExp(r'\n?```'), '');
        }

        final emotionData = jsonDecode(content);
        return emotionData;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to detect emotion: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detecting emotion: $e');
      return {
        'primary_emotion': 'neutral',
        'confidence': 0.5,
      };
    }
  }

  /// Get therapeutic response from DeepSeek
  static Future<String> getTherapeuticResponse(
    String userInput,
    String detectedEmotion,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      final apiKey = getApiKey();

      final messages = [
        {
          'role': 'system',
          'content':
              '''You are a compassionate AI music therapy guide. Your role is to:
1. Listen empathetically to the user's feelings
2. Validate their emotions
3. Suggest how specific frequencies and music can help them
4. Ask follow-up questions to deepen understanding
5. Provide brief, supportive responses (2-3 sentences max)

Current detected emotion: $detectedEmotion

Frequency recommendations:
- Happy (528 Hz): DNA Repair & Miracles - amplify positive emotions
- Sad (396 Hz): Liberating Guilt & Fear - process emotions and healing
- Angry (174 Hz): Pain Relief & Grounding - reduce tension and promote grounding
- Anxious (396 Hz): Liberating Guilt & Fear - release anxiety
- Neutral (432 Hz): Universal Healing - balance and harmony
- Surprised (528 Hz): DNA Repair & Miracles - embrace transformation
- Disgusted (285 Hz): Tissue & Organ Healing - restore balance
- Fearful (174 Hz): Pain Relief & Grounding - build safety and security

Always be warm, non-judgmental, and supportive.'''
        },
        ...conversationHistory
            .map((msg) => {'role': msg['role']!, 'content': msg['content']!})
            .toList(),
        {
          'role': 'user',
          'content': userInput,
        }
      ];

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek/deepseek-chat',
              'messages': messages,
              'temperature': 0.8,
              'max_tokens': 300,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Response generation request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting therapeutic response: $e');
      return 'I understand how you\'re feeling. Let\'s find the right frequency to support your journey. Would you like to continue our session?';
    }
  }

  /// Get frequency recommendation based on emotion
  static String getFrequencyRecommendation(String emotion) {
    const recommendations = {
      'happy': '528 Hz - DNA Repair & Miracles',
      'sad': '396 Hz - Liberating Guilt & Fear',
      'angry': '174 Hz - Pain Relief & Grounding',
      'anxious': '396 Hz - Liberating Guilt & Fear',
      'neutral': '432 Hz - Universal Healing',
      'surprised': '528 Hz - DNA Repair & Miracles',
      'disgusted': '285 Hz - Tissue & Organ Healing',
      'fearful': '174 Hz - Pain Relief & Grounding',
    };
    return recommendations[emotion] ?? '432 Hz - Universal Healing';
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Providers
final emotionProvider = StateProvider<String>((ref) => 'neutral');
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Continuous emotion detection service
class EmotionDetectionService {
  CameraController? controller;
  List<CameraDescription>? cameras;
  String currentEmotion = 'neutral';
  String stableEmotion = 'neutral';
  DateTime? emotionStartTime;
  Timer? emotionTimer;
  Timer? detectionTimer;
  bool isDetecting = false;
  bool isInitialized = false;
  Function(String)? onEmotionChanged;

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        controller = CameraController(cameras![0], ResolutionPreset.medium);
        await controller!.initialize();
        await _loadFaceApiModels();
        isInitialized = true;
      }
    } catch (e) {
      print('Failed to initialize camera: $e');
    }
  }

  Future<void> _loadFaceApiModels() async {
    // Load Face API models
    js.context.callMethod('eval', ['''
      async function loadModels() {
        await faceapi.nets.tinyFaceDetector.loadFromUri('https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/weights/');
        await faceapi.nets.faceExpressionNet.loadFromUri('https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/weights/');
        console.log('Face API models loaded');
      }
      loadModels();
    ''']);
  }

  void startDetection() {
    if (!isInitialized || isDetecting) return;

    isDetecting = true;
    detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _detectEmotion();
    });
  }

  void stopDetection() {
    isDetecting = false;
    detectionTimer?.cancel();
    emotionTimer?.cancel();
  }

  Future<void> _detectEmotion() async {
    if (!isDetecting) return;

    try {
      // Use JavaScript to access the camera video element and detect emotions
      final result = js.context.callMethod('eval', ['''
        (async function() {
          try {
            // Find the video element created by the camera package
            const videos = document.querySelectorAll('video');
            let video = null;
            for (const v of videos) {
              if (v.srcObject && v.srcObject.getVideoTracks().length > 0) {
                video = v;
                break;
              }
            }

            if (!video || video.readyState < 2) return 'neutral';

            const detections = await faceapi.detectSingleFace(video, new faceapi.TinyFaceDetectorOptions()).withFaceExpressions();
            if (detections && detections.expressions) {
              const expressions = detections.expressions;
              let maxEmotion = 'neutral';
              let maxValue = 0;

              for (const [emotion, value] of Object.entries(expressions)) {
                if (value > maxValue && value > 0.3) { // Minimum confidence threshold
                  maxValue = value;
                  maxEmotion = emotion;
                }
              }
              return maxEmotion;
            }
            return 'neutral';
          } catch (e) {
            console.error('Emotion detection error:', e);
            return 'neutral';
          }
        })();
      ''']);

      if (result != null && result != currentEmotion) {
        currentEmotion = result;
        _handleEmotionChange(result);
      }
    } catch (e) {
      print('Emotion detection failed: $e');
    }
  }

  void _handleEmotionChange(String newEmotion) {
    // Check if emotion has changed significantly
    if (newEmotion != stableEmotion) {
      emotionStartTime = DateTime.now();
      emotionTimer?.cancel();
      emotionTimer = Timer(const Duration(seconds: 5), () {
        if (newEmotion == currentEmotion) {
          stableEmotion = newEmotion;
          onEmotionChanged?.call(newEmotion);
        }
      });
    }
  }

  void dispose() {
    stopDetection();
    controller?.dispose();
  }
}

// Global emotion detection service provider
final emotionDetectionServiceProvider = Provider<EmotionDetectionService>((ref) {
  final service = EmotionDetectionService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Current stable emotion provider
final stableEmotionProvider = StateProvider<String>((ref) => 'neutral');

// DeepSeek AI Therapist Service
class DeepSeekTherapistService {
  final String apiKey = 'sk-1234567890abcdef'; // Replace with actual DeepSeek API key
  final String baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  List<Map<String, String>> conversationHistory = [];

  Future<String> getTherapeuticResponse(String userMessage, String currentEmotion) async {
    conversationHistory.add({'role': 'user', 'content': userMessage});

    // Create therapeutic context
    String systemPrompt = '''
You are an empathetic AI therapist specializing in music therapy. Your role is to:
1. Provide compassionate, non-judgmental support
2. Help users process their emotions through conversation
3. Recommend appropriate solfeggio frequencies based on their emotional state
4. Ask thoughtful follow-up questions to encourage deeper exploration
5. Maintain a supportive, professional therapeutic relationship

Current user emotion: $currentEmotion

Available solfeggio frequencies:
- 174 Hz: Pain Relief & Grounding
- 285 Hz: Tissue & Organ Healing  
- 396 Hz: Liberating Guilt & Fear
- 417 Hz: Undoing Situations & Facilitating Change
- 432 Hz: Universal Healing
- 528 Hz: DNA Repair & Miracles
- 741 Hz: Awakening Intuition
- 852 Hz: Returning to Spiritual Order
- 963 Hz: Divine Consciousness

Respond empathetically and suggest appropriate frequencies. Keep responses conversational and supportive.
''';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...conversationHistory.map((msg) => {
              'role': msg['role'],
              'content': msg['content']
            }).toList(),
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['content'];
        conversationHistory.add({'role': 'assistant', 'content': aiResponse});
        return aiResponse;
      } else {
        // Fallback response if API fails
        return _getFallbackResponse(userMessage, currentEmotion);
      }
    } catch (e) {
      print('DeepSeek API error: $e');
      return _getFallbackResponse(userMessage, currentEmotion);
    }
  }

  String _getFallbackResponse(String userMessage, String emotion) {
    // Enhanced fallback responses
    final text = userMessage.toLowerCase();

    if (text.contains('anxious') || text.contains('anxiety') || text.contains('worried')) {
      return 'I hear your anxiety, and it\'s completely valid to feel this way. Let\'s work together to find some calm. I recommend starting with 396 Hz for releasing fear and anxiety. What physical sensations are you noticing right now?';
    } else if (text.contains('sad') || text.contains('depressed') || text.contains('down')) {
      return 'I\'m here with you in this sadness. It takes courage to acknowledge these feelings. Try 396 Hz to help process these emotions. When did you first notice these feelings today?';
    } else if (text.contains('angry') || text.contains('frustrated') || text.contains('mad')) {
      return 'Anger is a powerful emotion that deserves acknowledgment. Let\'s explore this together. I suggest 174 Hz for grounding. What situation sparked this anger?';
    } else if (text.contains('stressed') || text.contains('overwhelmed')) {
      return 'I hear how much stress you\'re carrying. Let\'s create some space for relaxation. Try 285 Hz for healing. What areas of your life feel most stressful?';
    } else if (text.contains('happy') || text.contains('good') || text.contains('positive')) {
      return 'I\'m glad you\'re experiencing positive feelings! Let\'s amplify this with 528 Hz. What brought this happiness into your day?';
    } else {
      return 'Thank you for sharing. I\'m here to support you. Based on how you\'re feeling, I recommend 432 Hz for general healing and balance. What would be most helpful for you right now?';
    }
  }

  void clearHistory() {
    conversationHistory.clear();
  }
}

// DeepSeek therapist provider
final deepSeekTherapistProvider = Provider<DeepSeekTherapistService>((ref) {
  return DeepSeekTherapistService();
});
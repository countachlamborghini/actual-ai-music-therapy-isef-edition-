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
    // Load Face API models with CDN fallback and include landmarks for richer heuristics
    js.context.callMethod('eval', ['''
      async function loadModels() {
        const bases = [
          'https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/weights/',
          'https://justadudewhohacks.github.io/face-api.js/models/',
          'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/'
        ];

        for (const base of bases) {
          try {
            await faceapi.nets.tinyFaceDetector.loadFromUri(base);
            await faceapi.nets.faceExpressionNet.loadFromUri(base);
            await faceapi.nets.faceLandmark68Net.loadFromUri(base);
            console.log('Face API models loaded from', base);
            window.faceApiModelsBase = base;
            window.faceApiModelsLoaded = true;
            return;
          } catch (e) {
            console.warn('Failed to load face-api models from', base, e);
          }
        }

        console.error('Failed to load Face API models from all known URLs. Please host weights in your assets and load from there or verify network/CORS settings.');
        window.faceApiModelsLoaded = false;
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
      // Use JavaScript to access the camera video element and detect emotions with landmarks and heuristics
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

            const detections = await faceapi.detectSingleFace(video, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceExpressions();
            if (detections && detections.expressions) {
              const expressions = detections.expressions;

              // Landmarks-based features (if available)
              const lm = detections.landmarks;
              let mouthOpen = 0;
              let eyeOpen = 0;
              if (lm) {
                try {
                  const mouth = lm.getMouth();
                  const leftEye = lm.getLeftEye();
                  const rightEye = lm.getRightEye();
                  function dist(a,b){const dx=a.x-b.x;const dy=a.y-b.y;return Math.hypot(dx,dy);} 
                  // approximate vertical mouth opening
                  mouthOpen = dist(mouth[14], mouth[18]);
                  const eyeOpenL = dist(leftEye[1], leftEye[5]);
                  const eyeOpenR = dist(rightEye[1], rightEye[5]);
                  eyeOpen = (eyeOpenL + eyeOpenR) / 2;
                } catch (e) {
                  // ignore landmark errors
                }
              }

              // Audio signal features (if analyser present)
              let audioAvg = 0;
              if (window.analyser) {
                try {
                  const bufferLength = window.analyser.frequencyBinCount;
                  const dataArray = new Uint8Array(bufferLength);
                  window.analyser.getByteFrequencyData(dataArray);
                  let sum = 0;
                  for (let i = 0; i < bufferLength; i++) sum += dataArray[i];
                  audioAvg = sum / bufferLength;
                } catch (e) {
                  // ignore audio errors
                }
              }

              // Determine primary expression and attempt derived emotion heuristics
              let maxEmotion = 'neutral';
              let maxValue = 0;
              for (const [emotion, value] of Object.entries(expressions)) {
                if (value > maxValue) { maxValue = value; maxEmotion = emotion; }
              }

              // Heuristic-derived emotions (additional to face-api's base set)
              // Order matters: check more specific states first
              if ((expressions.fear && expressions.fear > 0.35) || (expressions.sad && expressions.sad > 0.35 && expressions.fear > 0.2)) {
                return 'anxious';
              } else if ((expressions.angry && expressions.angry > 0.3) && (expressions.fear && expressions.fear > 0.2)) {
                return 'stressed';
              } else if ((expressions.surprised && expressions.surprised > 0.25) && (expressions.sad && expressions.sad > 0.15)) {
                return 'confused';
              } else if (eyeOpen < 2.5 && mouthOpen < 2.5) {
                return 'tired';
              } else if (maxValue < 0.2 && audioAvg < 20) {
                return 'bored';
              } else if (expressions.happy && expressions.happy > 0.45 && audioAvg > 40) {
                return 'excited';
              } else if (expressions.happy && expressions.happy > 0.25 && (expressions.surprised && expressions.surprised < 0.2)) {
                return 'grateful';
              } else if (expressions.sad && expressions.sad > 0.5 && expressions.happy < 0.1) {
                return 'lonely';
              } else if (maxEmotion === 'neutral' && audioAvg < 25 && eyeOpen > 2.5) {
                return 'calm';
              } else if ((maxEmotion === 'neutral' || maxEmotion === 'surprised') && mouthOpen > 3 && audioAvg > 35) {
                return 'contemplative';
              }

              // Fallback to base emotion detection if no derived state matched
              // Apply a minimal confidence threshold to avoid noisy small values
              if (maxValue > 0.3) return maxEmotion;
              return 'neutral';
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

// Companion therapist (alternative persona) reusing DeepSeek calling code with a different system prompt
class CompanionTherapistService extends DeepSeekTherapistService {
  @override
  Future<String> getTherapeuticResponse(String userMessage, String currentEmotion) async {
    // Slightly different system prompt for a companion-style response
    conversationHistory.add({'role': 'user', 'content': userMessage});

    String systemPrompt = '''
You are a warm, friendly companion who listens empathetically and offers gentle, practical support. Encourage small steps, validate feelings, and suggest simple music-based exercises and frequencies that can help in the moment.
Current user emotion: $currentEmotion
Respond with short, conversational guidance and, if appropriate, suggest a solfeggio frequency (e.g., "Try 432 Hz").
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
          'max_tokens': 400,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['content'];
        conversationHistory.add({'role': 'assistant', 'content': aiResponse});
        return aiResponse;
      } else {
        return _getFallbackResponse(userMessage, currentEmotion);
      }
    } catch (e) {
      print('Companion API error: $e');
      return _getFallbackResponse(userMessage, currentEmotion);
    }
  }
}

// Companion provider
final companionTherapistProvider = Provider<CompanionTherapistService>((ref) {
  return CompanionTherapistService();
});

// Provider for AI-suggested frequency (Hz) set by therapist suggestions
final aiSuggestedFrequencyProvider = StateProvider<double?>((ref) => null);

// XP and rewards system
class XP {
  final int total;
  final int level;
  final String tierName;

  XP({required this.total, required this.level, required this.tierName});
}

class XPNotifier extends StateNotifier<XP> {
  XPNotifier(): super(XP(total: 0, level: 1, tierName: 'Beginner'));

  void addXp(int amount, WidgetRef? ref) {
    final newTotal = state.total + amount;
    final newLevel = (newTotal ~/ 100) + 1; // every 100 XP is a level
    final tier = _tierForXp(newTotal);
    state = XP(total: newTotal, level: newLevel, tierName: tier);

    // Check for rewards unlock
    if (ref != null) {
      final rewardService = ref.read(_rewardsServiceProvider);
      rewardService.checkUnlocks(newTotal);
    }
  }

  String _tierForXp(int xp) {
    if (xp >= 1000) return 'Master';
    if (xp >= 500) return 'Advanced';
    if (xp >= 200) return 'Intermediate';
    return 'Beginner';
  }
}

final xpProvider = StateNotifierProvider<XPNotifier, XP>((ref) {
  return XPNotifier();
});

// Simple rewards service using provider state
class RewardsService {
  final List<Map<String, String>> _unlocked = [];

  List<Map<String, String>> get unlocked => List.unmodifiable(_unlocked);

  void checkUnlocks(int xp) {
    // Example thresholds
    if (xp >= 50 && !_has('Calm Theme')) _unlock({'title':'Calm Theme','description':'Unlock a calming theme for your sessions'});
    if (xp >= 150 && !_has('Focus Theme')) _unlock({'title':'Focus Theme','description':'Unlock a focus theme for reflective sessions'});
    if (xp >= 300 && !_has('Guided Session')) _unlock({'title':'Guided Session','description':'Unlock a premium guided mini-session'});
    if (xp >= 600 && !_has('Exclusive Sound Pack')) _unlock({'title':'Exclusive Sound Pack','description':'Unlock an extra set of therapeutic tones'});
    if (xp >= 1200 && !_has('Achievement Badge')) _unlock({'title':'Achievement Badge','description':'Earn the Master badge'});
  }

  bool _has(String title) => _unlocked.any((r) => r['title'] == title);
  void _unlock(Map<String, String> reward) {
    _unlocked.add(reward);
  }
}

final _rewardsServiceProvider = Provider<RewardsService>((ref) => RewardsService());
final unlockedRewardsProvider = Provider<List<Map<String, String>>>((ref) => ref.read(_rewardsServiceProvider).unlocked);

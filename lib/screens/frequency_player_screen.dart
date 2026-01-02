import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../providers.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/therapist_chat.dart';

class FrequencyPlayerScreen extends ConsumerStatefulWidget {
  const FrequencyPlayerScreen({super.key});

  @override
  ConsumerState<FrequencyPlayerScreen> createState() => _FrequencyPlayerScreenState();
}

class _FrequencyPlayerScreenState extends ConsumerState<FrequencyPlayerScreen> {
  final player = AudioPlayer();
  String currentFrequency = '432 Hz';
  String currentEmotion = 'neutral';
  String description = 'Universal healing frequency';
  bool isPlaying = false;
  Timer? emotionCheckTimer;
  Timer? audioMonitoringTimer;

  // Audio monitoring using JavaScript
  bool audioMonitoringActive = false;

  @override
  void initState() {
    super.initState();
    _initializeEmotionDetection();
    _startEmotionMonitoring();
    _initializeAudioMonitoring();

    // Listen for AI-suggested frequency changes from the therapist
    ref.listen<double?>(aiSuggestedFrequencyProvider, (previous, next) {
      if (next != null) {
        _applySuggestedFrequency(next);
        // clear suggestion after applying
        ref.read(aiSuggestedFrequencyProvider.notifier).state = null;
      }
    });
  }

  Future<void> _initializeEmotionDetection() async {
    final emotionService = ref.read(emotionDetectionServiceProvider);
    await emotionService.initialize();
    emotionService.onEmotionChanged = _onEmotionChanged;
    emotionService.startDetection();

    final initialEmotion = ref.read(stableEmotionProvider);
    await _playBasedOnEmotion(initialEmotion);
  }

  void _onEmotionChanged(String emotion) {
    if (mounted) {
      _playBasedOnEmotion(emotion);
      setState(() {});
    }
  }

  void _startEmotionMonitoring() {
    emotionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final newEmotion = ref.read(stableEmotionProvider);
      if (newEmotion != currentEmotion && newEmotion.isNotEmpty) {
        currentEmotion = newEmotion;
        _playBasedOnEmotion(newEmotion);
        setState(() {});
      }
    });
  }

  Future<void> _initializeAudioMonitoring() async {
    try {
      // Initialize audio monitoring using JavaScript
      js.context.callMethod('eval', ['''
        window.audioMonitoringActive = false;
        window.audioContext = null;
        window.analyser = null;
        window.microphoneStream = null;
        window.audioMonitoringInterval = null;

        window.startAudioMonitoring = async function() {
          try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            window.microphoneStream = stream;
            window.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            window.analyser = window.audioContext.createAnalyser();
            window.analyser.fftSize = 256;

            const source = window.audioContext.createMediaStreamSource(stream);
            source.connect(window.analyser);

            window.audioMonitoringActive = true;

            window.audioMonitoringInterval = setInterval(() => {
              if (!window.audioMonitoringActive) return;

              const bufferLength = window.analyser.frequencyBinCount;
              const dataArray = new Uint8Array(bufferLength);
              window.analyser.getByteFrequencyData(dataArray);

              let sum = 0;
              for (let i = 0; i < bufferLength; i++) {
                sum += dataArray[i];
              }
              const average = sum / bufferLength;

              // Check for abnormal noises
              if (average > 150) {
                window.handleAbnormalNoise();
              }
            }, 500);
          } catch (e) {
            console.error('Audio monitoring initialization failed:', e);
          }
        };

        window.stopAudioMonitoring = function() {
          window.audioMonitoringActive = false;
          if (window.audioMonitoringInterval) {
            clearInterval(window.audioMonitoringInterval);
          }
          if (window.microphoneStream) {
            window.microphoneStream.getTracks().forEach(track => track.stop());
          }
          if (window.audioContext) {
            window.audioContext.close();
          }
        };

        window.handleAbnormalNoise = function() {
          // Call Dart method when abnormal noise is detected
          if (window.handleAbnormalNoiseCallback) {
            window.handleAbnormalNoiseCallback();
          }
        };
      ''']);

      // Start audio monitoring
      js.context.callMethod('startAudioMonitoring', []);
      audioMonitoringActive = true;

      // Set up callback for abnormal noise detection
      js.context['handleAbnormalNoiseCallback'] = js.allowInterop(() {
        _handleAbnormalNoise();
      });
    } catch (e) {
      print('Audio monitoring initialization failed: $e');
    }
  }

  void _handleAbnormalNoise() {
    // Pause the session and show warning
    player.pause();
    setState(() {
      isPlaying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abnormal noise detected. Session paused for safety.'),
        duration: Duration(seconds: 3),
      ),
    );

    // Resume after 5 seconds if no further issues
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !isPlaying) {
        player.play();
        setState(() {
          isPlaying = true;
        });
      }
    });
  }

  Future<void> _playBasedOnEmotion(String emotion) async {
    final frequency = _getFrequencyValue(emotion);
    currentFrequency = _getFrequency(emotion);
    description = _getDescription(emotion);

    try {
      // Use Web Audio API to generate frequency
      js.context.callMethod('eval', ['''
        if (window.currentOscillator) {
          window.currentOscillator.stop();
        }

        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);

        oscillator.frequency.setValueAtTime($frequency, audioContext.currentTime);
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime); // Low volume for comfort

        oscillator.start();
        window.currentOscillator = oscillator;
        window.currentGainNode = gainNode;
        window.currentAudioContext = audioContext;
      ''']);

      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      print('Audio generation error: $e');
    }
  }

  void _stopAudio() {
    js.context.callMethod('eval', ['''
      if (window.currentOscillator) {
        window.currentOscillator.stop();
        window.currentOscillator = null;
      }
    ''']);
    setState(() {
      isPlaying = false;
    });
  }

  double _getFrequencyValue(String emotion) {
    const map = {
      'happy': 528.0,
      'sad': 396.0,
      'angry': 174.0,
      'anxious': 396.0,
      'neutral': 432.0,
      'surprised': 528.0,
      'disgusted': 285.0,
      'fearful': 174.0,
      'stressed': 285.0,
      'confused': 432.0,
      'lonely': 528.0,
      'grateful': 528.0,
    };
    return map[emotion] ?? 432.0;
  }

  String _getFrequency(String emotion) {
    const map = {
      'happy': '528 Hz',
      'sad': '396 Hz',
      'angry': '174 Hz',
      'anxious': '396 Hz',
      'neutral': '432 Hz',
      'surprised': '528 Hz',
      'disgusted': '285 Hz',
      'fearful': '174 Hz',
    };
    return map[emotion] ?? '432 Hz';
  }

  String _getDescription(String emotion) {
    const map = {
      'happy': 'DNA Repair & Transformation',
      'sad': 'Liberating Guilt & Fear',
      'angry': 'Pain Relief & Grounding',
      'anxious': 'Liberating Guilt & Fear',
      'neutral': 'Universal Healing',
      'surprised': 'DNA Repair & Miracles',
      'disgusted': 'Tissue & Organ Healing',
      'fearful': 'Pain Relief & Grounding',
    };
    return map[emotion] ?? 'Universal Healing';
  }

  void _togglePlayback() {
    if (isPlaying) {
      _stopAudio();
    } else {
      // Resume with current emotion
      _playBasedOnEmotion(currentEmotion);
    }
  }

  void _applySuggestedFrequency(double frequency) {
    try {
      js.context.callMethod('eval', ["""
        if (window.currentOscillator && window.currentAudioContext) {
          window.currentOscillator.frequency.setValueAtTime($frequency, window.currentAudioContext.currentTime);
        }
      """]);

      // Update labels
      currentFrequency = '${frequency.toStringAsFixed(0)} Hz';
      description = _getDescriptionForFrequency(frequency);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Therapist suggested frequency applied: ${currentFrequency}')),
      );
    } catch (e) {
      print('Failed to apply suggested frequency: $e');
    }
  }

  String _getDescriptionForFrequency(double frequency) {
    final map = {
      174.0: 'Pain Relief & Grounding',
      285.0: 'Tissue & Organ Healing',
      396.0: 'Liberating Guilt & Fear',
      417.0: 'Undoing Situations & Facilitating Change',
      432.0: 'Universal Healing',
      528.0: 'DNA Repair & Miracles',
      741.0: 'Awakening Intuition',
      852.0: 'Returning to Spiritual Order',
      963.0: 'Divine Consciousness',
    };
    return map[frequency] ?? 'Suggested Frequency';
  }

  @override
  void dispose() {
    emotionCheckTimer?.cancel();
    audioMonitoringTimer?.cancel();

    // Stop Web Audio API oscillator
    _stopAudio();

    // Stop JavaScript audio monitoring
    if (audioMonitoringActive) {
      js.context.callMethod('stopAudioMonitoring', []);
    }

    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        title: 'Adaptive Frequency Session',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Open Therapist Chat',
          ),
        ],
      ),
      endDrawer: const TherapistChat(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'AI Music Therapy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Check In'),
              onTap: () => context.go('/checkin'),
            ),
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('Emotion Detection'),
              onTap: () => context.go('/emotion'),
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Frequency Player'),
              onTap: () => context.go('/frequency'),
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Games'),
              onTap: () => context.go('/game'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Progress'),
              onTap: () => context.go('/progress'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Frequency: $currentFrequency',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Emotion: $currentEmotion',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          iconSize: 48,
                          onPressed: _togglePlayback,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          iconSize: 48,
                          onPressed: _stopAudio,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Session Monitoring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.videocam,
                              color: ref.read(emotionDetectionServiceProvider).isInitialized ? Colors.green : Colors.red,
                            ),
                            const SizedBox(height: 4),
                            Text(ref.read(emotionDetectionServiceProvider).isInitialized ? 'Camera active' : 'Camera inactive'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.mic,
                              color: audioMonitoringActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(height: 4),
                            Text(audioMonitoringActive ? 'Mic active' : 'Mic inactive'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.auto_fix_high, color: Colors.blue),
                            const SizedBox(height: 4),
                            const Text('Auto frequency adjustment'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Real-time emotion detection active\n• Audio monitoring for safety\n• Automatic frequency adjustment\n• Session adapts to your emotional state',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.go('/game'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Continue to Games'),
            ),
          ],
        ),
      ),
    );
  }
}
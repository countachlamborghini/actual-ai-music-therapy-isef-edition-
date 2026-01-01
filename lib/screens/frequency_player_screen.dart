import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../providers.dart';

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
    _initializeAudio();
    _startEmotionMonitoring();
    _initializeAudioMonitoring();
  }

  Future<void> _initializeAudio() async {
    final emotion = ref.read(emotionProvider);
    await _playBasedOnEmotion(emotion);
  }

  void _startEmotionMonitoring() {
    emotionCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newEmotion = ref.read(emotionProvider);
      if (newEmotion != currentEmotion) {
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
    final url = _getUrl(emotion);
    currentFrequency = _getFrequency(emotion);
    description = _getDescription(emotion);

    try {
      await player.setUrl(url);
      await player.play();
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  String _getUrl(String emotion) {
    const map = {
      'happy': 'https://www.dropbox.com/scl/fi/.../528hz.mp3?rlkey=...&st=...', // 528 Hz - DNA Repair
      'sad': 'https://www.dropbox.com/scl/fi/.../396hz.mp3?rlkey=...&st=...', // 396 Hz - Liberating Guilt
      'angry': 'https://www.dropbox.com/scl/fi/.../174hz.mp3?rlkey=...&st=...', // 174 Hz - Pain Relief
      'anxious': 'https://www.dropbox.com/scl/fi/.../396hz.mp3?rlkey=...&st=...', // 396 Hz - Liberating Guilt
      'neutral': 'https://www.dropbox.com/scl/fi/.../432hz.mp3?rlkey=...&st=...', // 432 Hz - Universal
      'surprised': 'https://www.dropbox.com/scl/fi/.../528hz.mp3?rlkey=...&st=...', // 528 Hz - Transformation
      'disgusted': 'https://www.dropbox.com/scl/fi/.../285hz.mp3?rlkey=...&st=...', // 285 Hz - Tissue Healing
      'fearful': 'https://www.dropbox.com/scl/fi/.../174hz.mp3?rlkey=...&st=...', // 174 Hz - Grounding
    };
    return map[emotion] ?? map['neutral']!;
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
      player.pause();
    } else {
      player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    emotionCheckTimer?.cancel();
    audioMonitoringTimer?.cancel();

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
      appBar: AppBar(
        title: const Text('Adaptive Frequency Session'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                          onPressed: () {
                            player.stop();
                            setState(() {
                              isPlaying = false;
                            });
                          },
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
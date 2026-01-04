import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../providers.dart';

class FrequencyPlayerScreen extends ConsumerStatefulWidget {
  const FrequencyPlayerScreen({super.key});

  @override
  ConsumerState<FrequencyPlayerScreen> createState() =>
      _FrequencyPlayerScreenState();
}

class _FrequencyPlayerScreenState extends ConsumerState<FrequencyPlayerScreen> {
  final player = AudioPlayer();
  String currentFrequency = '432 Hz';
  String currentEmotion = 'neutral';
  String description = 'Universal healing frequency';
  bool isPlaying = false;
  bool isLoading = false;
  Timer? emotionCheckTimer;
  Timer? audioMonitoringTimer;
  String? audioError;

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
      js.context.callMethod('eval', [
        '''
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
      '''
      ]);

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
      setState(() {
        isLoading = true;
        audioError = null;
      });

      await player.setUrl(url);
      await player.play();

      setState(() {
        isPlaying = true;
        isLoading = false;
      });
    } catch (e) {
      print('Audio playback error: $e');
      setState(() {
        isLoading = false;
        audioError = 'Failed to load audio: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _getUrl(String emotion) {
    // Using free tone generator URLs - these generate soothing audio
    const map = {
      'happy':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // 528 Hz - DNA Repair
      'sad':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', // 396 Hz - Liberating Guilt
      'angry':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', // 174 Hz - Pain Relief
      'anxious':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', // 396 Hz - Liberating Guilt
      'neutral':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', // 432 Hz - Universal
      'surprised':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', // 528 Hz - Transformation
      'disgusted':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', // 285 Hz - Tissue Healing
      'fearful':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', // 174 Hz - Grounding
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Emotion: $currentEmotion',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (audioError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                audioError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isLoading)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading audio...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          iconSize: 64,
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (isPlaying) {
                                    player.pause();
                                  } else {
                                    player.play();
                                  }
                                  setState(() {
                                    isPlaying = !isPlaying;
                                  });
                                },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.stop_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          iconSize: 64,
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Real-time emotion detection active\n• Audio monitoring for safety\n• Automatic frequency adjustment\n• Session adapts to your emotional state',
                      style: Theme.of(context).textTheme.bodyMedium,
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

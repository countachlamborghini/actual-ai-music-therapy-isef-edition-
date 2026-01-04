import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';

class AdaptiveFrequencySessionScreen extends ConsumerStatefulWidget {
  const AdaptiveFrequencySessionScreen({super.key});

  @override
  ConsumerState<AdaptiveFrequencySessionScreen> createState() =>
      _AdaptiveFrequencySessionScreenState();
}

class _AdaptiveFrequencySessionScreenState
    extends ConsumerState<AdaptiveFrequencySessionScreen> {
  // Audio - using Web Audio API for solfeggio frequencies
  String currentFrequency = '432 Hz';
  int currentFrequencyHz = 432;
  String currentEmotion = 'neutral';
  String frequencyDescription = 'Universal healing frequency';
  bool isPlaying = false;
  bool isLoading = false;
  String? audioError;
  bool audioContextInitialized = false;

  // Camera & Emotion Detection
  CameraController? controller;
  List<CameraDescription>? cameras;
  String detectedEmotion = 'neutral';
  String stableEmotion = 'neutral';
  DateTime? emotionStartTime;
  String videoElementId = 'adaptive-emotion-video';
  String? cameraError;
  bool isInitializingCamera = true;
  int emotionConfidenceCount = 0;
  final int emotionStabilityThreshold = 3; // Need 3 consecutive detections

  // Face detection status
  bool faceDetected = false;
  String faceDetectionStatus = 'Initializing Face API...';
  bool faceApiReady = false;

  // Timers
  Timer? emotionDetectionTimer;
  Timer? emotionStabilityTimer;

  // Solfeggio frequency mapping (13 emotions) - actual Hz values
  final emotionFrequencyMap = {
    'happy': (528, '528 Hz', 'DNA Repair & Love - amplify positive emotions'),
    'angry': (174, '174 Hz', 'Pain Relief & Grounding - reduce tension'),
    'sad': (396, '396 Hz', 'Liberating Guilt & Fear - process emotions'),
    'tired': (285, '285 Hz', 'Tissue & Organ Healing - restore energy'),
    'disgusted': (285, '285 Hz', 'Tissue & Organ Healing - restore balance'),
    'anxious': (396, '396 Hz', 'Liberating Guilt & Fear - release anxiety'),
    'surprised': (528, '528 Hz', 'DNA Repair & Love - embrace transformation'),
    'fearful': (174, '174 Hz', 'Pain Relief & Grounding - build safety'),
    'stressed': (174, '174 Hz', 'Pain Relief & Grounding - reduce stress'),
    'overwhelmed': (396, '396 Hz', 'Liberating Guilt & Fear - restore calm'),
    'peaceful': (432, '432 Hz', 'Universal Healing - deepen peace'),
    'energized': (639, '639 Hz', 'Connecting & Relationships - amplify energy'),
    'neutral': (432, '432 Hz', 'Universal Healing - balance and harmony'),
  };

  final emotionColors = {
    'happy': Color(0xFFFFD700),
    'angry': Color(0xFFDC143C),
    'sad': Color(0xFF4169E1),
    'tired': Color(0xFF696969),
    'disgusted': Color(0xFF228B22),
    'anxious': Color(0xFFFFA500),
    'surprised': Color(0xFFFF69B4),
    'fearful': Color(0xFF8B008B),
    'stressed': Color(0xFFFF6347),
    'overwhelmed': Color(0xFF9932CC),
    'peaceful': Color(0xFF87CEEB),
    'energized': Color(0xFFFFFF00),
    'neutral': Color(0xFF808080),
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadFaceApiModels();
    _initializeAudio();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        controller = CameraController(cameras![0], ResolutionPreset.medium);
        await controller!.initialize();
        if (mounted) {
          setState(() {
            isInitializingCamera = false;
          });
          _startEmotionDetection();
        }
      } else {
        if (mounted) {
          setState(() {
            cameraError =
                'No camera found. Starting without real-time emotion detection.';
            isInitializingCamera = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cameraError =
              'Camera unavailable. Using check-in emotion instead: $e';
          isInitializingCamera = false;
        });
      }
      print('Camera initialization error: $e');
    }
  }

  Future<void> _loadFaceApiModels() async {
    try {
      // Wait for Face API script to load
      int retries = 0;
      while (retries < 50) {
        try {
          final faceApiAvailable = js.context['faceapi'] != null;
          if (faceApiAvailable) {
            print('Face API detected, loading models...');

            // Load models asynchronously
            await _executeAsyncJs('''
              async function loadModels() {
                try {
                  const modelUrl = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.13/model/';
                  console.log('Loading Face API models from:', modelUrl);
                  await faceapi.nets.tinyFaceDetector.loadFromUri(modelUrl);
                  await faceapi.nets.faceExpressionNet.loadFromUri(modelUrl);
                  window.faceApiReady = true;
                  console.log('✓ Face API models loaded successfully');
                  return 'ready';
                } catch (e) {
                  console.error('✗ Face API models loading failed:', e);
                  window.faceApiReady = false;
                  return 'failed';
                }
              }
              await loadModels();
            ''');

            if (mounted) {
              setState(() {
                faceApiReady = true;
                faceDetectionStatus = 'Face API Ready';
              });
            }
            break;
          }
          retries++;
          if (retries % 10 == 0) {
            print('Waiting for Face API... (attempt $retries)');
          }
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Face API load retry error: $e');
          retries++;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (retries >= 50) {
        print('✗ Face API failed to load after 50 retries');
        if (mounted) {
          setState(() {
            faceDetectionStatus = 'Face API Failed to Load';
            faceApiReady = false;
          });
        }
      }
    } catch (e) {
      print('Face API initialization error: $e');
      if (mounted) {
        setState(() {
          faceDetectionStatus = 'Face API Error: $e';
          faceApiReady = false;
        });
      }
    }
  }

  Future<void> _executeAsyncJs(String code) async {
    try {
      js.context.callMethod('eval', ['(async () => { $code })()']);
      // Give it time to execute
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('JS execution error: $e');
    }
  }

  void _startEmotionDetection() {
    // Set up the detection function that uses callbacks
    try {
      js.context.callMethod('eval', [
        '''
        window.detectFacesFromVideo = async function(callback) {
          try {
            const video = document.querySelectorAll('video')[0];
            if (!video) {
              callback(null);
              return;
            }
            
            const options = new faceapi.TinyFaceDetectorOptions({ inputSize: 416, scoreThreshold: 0.5 });
            const detections = await faceapi.detectAllFaces(video, options).withFaceExpressions();
            console.log('Detections returned:', detections, 'Length:', detections ? detections.length : 0);
            callback(detections);
          } catch (e) {
            console.error('Face detection failed:', e);
            callback(null);
          }
        };
        '''
      ]);
    } catch (e) {
      print('Error setting up detection function: $e');
    }

    emotionDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted ||
          controller == null ||
          !controller!.value.isInitialized ||
          !faceApiReady) {
        if (faceDetected) {
          setState(() {
            faceDetected = false;
            faceDetectionStatus = 'Waiting for face...';
          });
        }
        return;
      }

      try {
        // Check if Face API is available
        final faceApiAvailable = js.context['faceapi'] != null;
        if (!faceApiAvailable) {
          setState(() {
            faceDetectionStatus = 'Face API not available';
            faceDetected = false;
          });
          return;
        }

        // Get the first video element on the page (created by CameraPreview)
        final videoElement = js.context.callMethod('eval', [
          '''(function() {
            const videos = document.querySelectorAll('video');
            console.log('Found ' + videos.length + ' video element(s)');
            if (videos.length > 0) {
              console.log('Using video element 0, dimensions:', videos[0].videoWidth, 'x', videos[0].videoHeight);
              return videos[0];
            }
            return null;
          })()'''
        ]);

        if (videoElement == null) {
          setState(() {
            faceDetectionStatus = 'Video element not found';
            faceDetected = false;
          });
          return;
        }

        try {
          // Call the detection function with a Dart callback
          final dartCallback = js.allowInterop((dynamic detections) {
            _handleDetections(detections);
          });

          js.context.callMethod('detectFacesFromVideo', [dartCallback]);
        } catch (detectionError) {
          print('Face detection error: $detectionError');
          setState(() {
            faceDetectionStatus = 'Detection error: $detectionError';
            faceDetected = false;
          });
        }
      } catch (e) {
        print('Emotion detection setup error: $e');
        setState(() {
          faceDetectionStatus = 'Setup error: $e';
          faceDetected = false;
        });
      }
    });
  }

  void _handleDetections(dynamic detections) {
    if (!mounted) return;

    if (detections == null) {
      setState(() {
        faceDetected = false;
        faceDetectionStatus = 'No face detected';
      });
      return;
    }

    // Convert JS array to Dart list
    final List detectionsList;
    try {
      detectionsList = List.from(detections as List);
      print(
          'Successfully converted detections to list, count: ${detectionsList.length}');
    } catch (e) {
      print('Error converting detections to list: $e');
      setState(() {
        faceDetected = false;
        faceDetectionStatus = 'Detection parsing error';
      });
      return;
    }

    if (detectionsList.isEmpty) {
      if (faceDetected) {
        setState(() {
          faceDetected = false;
          faceDetectionStatus = 'Face lost';
        });
      }
      return;
    }

    // Face detected!
    if (!faceDetected) {
      setState(() {
        faceDetected = true;
        faceDetectionStatus = '✓ Face detected';
      });
    }

    final detection = detectionsList[0];
    if (detection == null) return;

    // Get expressions
    final expressions = detection['expressions'];
    if (expressions == null) {
      setState(() {
        faceDetectionStatus = '✓ Face detected (no expressions)';
      });
      return;
    }

    // Map expressions to emotions
    String detectedEmotion = _mapExpressionsToEmotion(expressions);

    if (detectedEmotion != this.detectedEmotion) {
      setState(() {
        this.detectedEmotion = detectedEmotion;
        emotionConfidenceCount = 0;
        faceDetectionStatus = '✓ Face detected - $detectedEmotion';
      });
      print('Emotion changed to: $detectedEmotion');
    } else {
      emotionConfidenceCount++;
      if (emotionConfidenceCount >= emotionStabilityThreshold) {
        if (stableEmotion != detectedEmotion) {
          setState(() {
            stableEmotion = detectedEmotion;
            faceDetectionStatus = '✓ Face detected - $detectedEmotion (stable)';
          });
          _switchFrequencyForEmotion(detectedEmotion);
          print(
              'Emotion stabilized: $detectedEmotion (confidence: $emotionConfidenceCount)');
        }
      }
    }
  }

  String _mapExpressionsToEmotion(dynamic expressions) {
    try {
      // Face API expression values (0-1 scale)
      double happy = (expressions['happy'] ?? 0.0) as double;
      double angry = (expressions['angry'] ?? 0.0) as double;
      double sad = (expressions['sad'] ?? 0.0) as double;
      double fearful = (expressions['fearful'] ?? 0.0) as double;
      double disgusted = (expressions['disgusted'] ?? 0.0) as double;
      double surprised = (expressions['surprised'] ?? 0.0) as double;
      double neutral = (expressions['neutral'] ?? 0.0) as double;

      print(
          'Expressions - Happy: $happy, Angry: $angry, Sad: $sad, Fearful: $fearful, Disgusted: $disgusted, Surprised: $surprised, Neutral: $neutral');

      // Map to our emotion set
      final emotionScores = {
        'happy': happy,
        'angry': angry,
        'sad': sad * 1.2, // Boost sad detection
        'tired': (sad * 0.6 + neutral * 0.4), // Tired = sad + neutral
        'disgusted': disgusted,
        'anxious': fearful * 1.1,
        'surprised': surprised,
        'fearful': fearful,
        'stressed': (angry * 0.7 + fearful * 0.3),
        'overwhelmed': (sad * 0.5 + fearful * 0.5),
        'peaceful': neutral * 0.8,
        'energized': happy * 0.6,
        'neutral': neutral,
      };

      // Find dominant emotion
      String maxEmotion = 'neutral';
      double maxScore = 0.0;

      emotionScores.forEach((emotion, score) {
        if (score > maxScore) {
          maxScore = score;
          maxEmotion = emotion;
        }
      });

      print('Detected emotion: $maxEmotion (score: $maxScore)');
      return maxEmotion;
    } catch (e) {
      print('Error mapping expressions: $e');
      return 'neutral';
    }
  }

  Future<void> _initializeAudio() async {
    // Initialize Web Audio API for solfeggio frequencies
    _initializeSolfeggioAudio();

    final checkInEmotion = ref.read(emotionProvider);
    currentEmotion = checkInEmotion.isNotEmpty ? checkInEmotion : 'neutral';
    stableEmotion = currentEmotion;
    detectedEmotion = currentEmotion;

    // Set initial frequency based on emotion
    final freq = emotionFrequencyMap[currentEmotion];
    if (freq != null) {
      currentFrequencyHz = freq.$1 as int;
      currentFrequency = freq.$2 as String;
      frequencyDescription = freq.$3 as String;
    }

    // Auto-start playing
    await Future.delayed(const Duration(milliseconds: 500));
    await _playBasedOnEmotion(currentEmotion);
  }

  void _switchFrequencyForEmotion(String emotion) {
    final freq = emotionFrequencyMap[emotion];
    if (freq != null) {
      final newHz = freq.$1 as int;
      // Only switch if frequency actually changed
      if (newHz != currentFrequencyHz) {
        print(
            'Switching frequency from ${currentFrequencyHz}Hz to ${newHz}Hz for emotion: $emotion');
        setState(() {
          currentFrequencyHz = newHz;
          currentFrequency = freq.$2 as String;
          frequencyDescription = freq.$3 as String;
          currentEmotion = emotion;
        });
        if (isPlaying) {
          _updateFrequency(newHz);
        }
      }
    }
  }

  void _initializeSolfeggioAudio() {
    // Initialize Web Audio API for solfeggio frequency generation
    try {
      js.context.callMethod('eval', [
        '''
        window.solfeggioAudio = {
          audioContext: null,
          oscillator: null,
          gainNode: null,
          isPlaying: false,
          
          init: function() {
            if (!this.audioContext) {
              this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
              this.gainNode = this.audioContext.createGain();
              this.gainNode.connect(this.audioContext.destination);
              this.gainNode.gain.value = 0.3; // Lower volume for comfort
            }
            return true;
          },
          
          play: function(frequency) {
            this.init();
            if (this.audioContext.state === 'suspended') {
              this.audioContext.resume();
            }
            
            // Stop existing oscillator
            if (this.oscillator) {
              this.oscillator.stop();
              this.oscillator.disconnect();
            }
            
            // Create new oscillator with solfeggio frequency
            this.oscillator = this.audioContext.createOscillator();
            this.oscillator.type = 'sine'; // Pure sine wave for healing frequencies
            this.oscillator.frequency.setValueAtTime(frequency, this.audioContext.currentTime);
            this.oscillator.connect(this.gainNode);
            this.oscillator.start();
            this.isPlaying = true;
            console.log('Playing solfeggio frequency:', frequency, 'Hz');
          },
          
          updateFrequency: function(frequency) {
            if (this.oscillator && this.isPlaying) {
              // Smooth transition to new frequency over 0.5 seconds
              this.oscillator.frequency.linearRampToValueAtTime(
                frequency,
                this.audioContext.currentTime + 0.5
              );
              console.log('Transitioning to frequency:', frequency, 'Hz');
            } else {
              this.play(frequency);
            }
          },
          
          pause: function() {
            if (this.oscillator) {
              this.oscillator.stop();
              this.oscillator.disconnect();
              this.oscillator = null;
            }
            this.isPlaying = false;
            console.log('Solfeggio frequency paused');
          },
          
          stop: function() {
            this.pause();
            if (this.audioContext) {
              this.audioContext.close();
              this.audioContext = null;
            }
            console.log('Solfeggio audio stopped');
          },
          
          setVolume: function(volume) {
            if (this.gainNode) {
              this.gainNode.gain.value = volume;
            }
          }
        };
        window.solfeggioAudio.init();
        console.log('✓ Solfeggio Audio initialized');
        '''
      ]);
      setState(() {
        audioContextInitialized = true;
      });
    } catch (e) {
      print('Error initializing solfeggio audio: $e');
      setState(() {
        audioError = 'Failed to initialize audio: $e';
      });
    }
  }

  void _playSolfeggioFrequency(int frequencyHz) {
    try {
      js.context
          .callMethod('eval', ['window.solfeggioAudio.play($frequencyHz);']);
      setState(() {
        isPlaying = true;
        audioError = null;
      });
    } catch (e) {
      print('Error playing solfeggio frequency: $e');
      setState(() {
        audioError = 'Error playing frequency: $e';
      });
    }
  }

  void _updateFrequency(int frequencyHz) {
    try {
      js.context.callMethod(
          'eval', ['window.solfeggioAudio.updateFrequency($frequencyHz);']);
    } catch (e) {
      print('Error updating frequency: $e');
    }
  }

  void _pauseSolfeggioFrequency() {
    try {
      js.context.callMethod('eval', ['window.solfeggioAudio.pause();']);
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error pausing solfeggio frequency: $e');
    }
  }

  void _stopSolfeggioFrequency() {
    try {
      js.context.callMethod('eval', ['window.solfeggioAudio.stop();']);
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error stopping solfeggio frequency: $e');
    }
  }

  Future<void> _playBasedOnEmotion(String emotion) async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        audioError = null;
      });

      final freq = emotionFrequencyMap[emotion];
      if (freq != null) {
        setState(() {
          currentFrequencyHz = freq.$1 as int;
          currentFrequency = freq.$2 as String;
          frequencyDescription = freq.$3 as String;
        });

        _playSolfeggioFrequency(currentFrequencyHz);
      }

      setState(() {
        isPlaying = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        audioError = 'Error loading audio: $e';
        isLoading = false;
      });
      print('Audio playback error: $e');
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (isPlaying) {
        _pauseSolfeggioFrequency();
      } else {
        _playSolfeggioFrequency(currentFrequencyHz);
      }
    } catch (e) {
      print('Playback toggle error: $e');
    }
  }

  Future<void> _stopSession() async {
    _stopSolfeggioFrequency();
    emotionDetectionTimer?.cancel();
    emotionStabilityTimer?.cancel();
    controller?.dispose();
    if (mounted) {
      context.go('/progress');
    }
  }

  @override
  void dispose() {
    emotionDetectionTimer?.cancel();
    emotionStabilityTimer?.cancel();
    _stopSolfeggioFrequency();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              emotionColors[stableEmotion] ?? Colors.blue,
              (emotionColors[stableEmotion] ?? Colors.blue).withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: isInitializingCamera
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Initializing Adaptive Frequency Session...',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Camera preview (if available)
                    if (controller != null &&
                        controller!.value.isInitialized &&
                        cameraError == null)
                      Container(
                        height: 150,
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Stack(
                          children: [
                            CameraPreview(controller!),
                            // Face detection status
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: faceDetected
                                      ? Colors.green.withOpacity(0.8)
                                      : Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  faceDetectionStatus,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // Real-time emotion
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Detected: $detectedEmotion',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (cameraError != null)
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white70),
                        ),
                        child: Text(
                          cameraError!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Main content
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Emotion status
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white30),
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                  'Current Emotion',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  stableEmotion.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                if (detectedEmotion != stableEmotion)
                                  Text(
                                    'Detected: $detectedEmotion '
                                    '($emotionConfidenceCount/$emotionStabilityThreshold)',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          // Frequency display
                          Text(
                            currentFrequency,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            frequencyDescription,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),
                          // Play/Pause button
                          FloatingActionButton(
                            onPressed: _togglePlayback,
                            backgroundColor: Colors.white,
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color:
                                  emotionColors[stableEmotion] ?? Colors.blue,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Error message
                    if (audioError != null)
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          audioError!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Controls
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: _stopSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white38),
                          ),
                        ),
                        child: Text(
                          'End Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

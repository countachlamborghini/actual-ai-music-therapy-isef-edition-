import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:js' as js;
import '../providers.dart';

class EmotionDetectionScreen extends ConsumerStatefulWidget {
  const EmotionDetectionScreen({super.key});

  @override
  ConsumerState<EmotionDetectionScreen> createState() =>
      _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState
    extends ConsumerState<EmotionDetectionScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  String currentEmotion = 'neutral';
  String stableEmotion = 'neutral';
  DateTime? emotionStartTime;
  Timer? emotionTimer;
  Timer? detectionTimer;
  bool isDetecting = false;
  String videoElementId = 'emotion-video';
  String? cameraError;
  bool isInitializingCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadFaceApiModels();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        controller = CameraController(cameras![0], ResolutionPreset.medium);
        await controller!.initialize();
        setState(() {
          isInitializingCamera = false;
        });
        _startDetection();
      } else {
        setState(() {
          cameraError = 'No camera found on this device';
          isInitializingCamera = false;
        });
      }
    } catch (e) {
      setState(() {
        cameraError = 'Camera permission denied or camera unavailable: $e';
        isInitializingCamera = false;
      });
      print('Camera initialization error: $e');
    }
  }

  Future<void> _loadFaceApiModels() async {
    // Wait for Face API to be loaded - gracefully handle if unavailable
    try {
      int retries = 0;
      while (retries < 30) {
        try {
          final faceApiAvailable = js.context['faceapi'] != null;
          if (faceApiAvailable) {
            // Load Face API models with error handling
            js.context.callMethod('eval', [
              '''
              async function loadModels() {
                try {
                  const modelUrl = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.13/model/';
                  await faceapi.nets.tinyFaceDetector.loadFromUri(modelUrl);
                  await faceapi.nets.faceExpressionNet.loadFromUri(modelUrl);
                  console.log('Face API models loaded successfully');
                } catch (e) {
                  console.warn('Face API models loading failed - emotion detection disabled:', e);
                  window.faceApiLoaded = false;
                }
              }
              loadModels();
              window.faceApiLoaded = true;
            '''
            ]);
            break;
          }
          retries++;
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          retries++;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (retries >= 30) {
        print(
            'Warning: Face API library not loaded after retries - emotion detection will be unavailable');
      }
    } catch (e) {
      print('Error loading Face API models: $e');
    }
  }

  void _startDetection() {
    if (controller == null || !controller!.value.isInitialized) return;

    isDetecting = true;
    detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _detectEmotion();
    });
  }

  Future<void> _detectEmotion() async {
    if (!isDetecting) return;

    try {
      // Use JavaScript to access the camera video element and detect emotions
      final result = js.context.callMethod('eval', [
        '''
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
            console.error('Face detection error:', e);
            return 'neutral';
          }
        })()
      '''
      ]);

      if (result != null && result is String && result != 'neutral') {
        _handleEmotionChange(result);
      }
    } catch (e) {
      print('Emotion detection error: $e');
    }
  }

  void _handleEmotionChange(String newEmotion) {
    if (newEmotion == currentEmotion) {
      // Same emotion, check if stable
      if (emotionStartTime == null) {
        emotionStartTime = DateTime.now();
      } else {
        final duration = DateTime.now().difference(emotionStartTime!);
        if (duration.inSeconds >= 5 &&
            duration.inSeconds <= 7.5 &&
            stableEmotion != newEmotion) {
          setState(() {
            stableEmotion = newEmotion;
          });
          ref.read(emotionProvider.notifier).state = newEmotion;
          _showEmotionChangeSnackBar(newEmotion);
        }
      }
    } else {
      // Different emotion, reset timer
      currentEmotion = newEmotion;
      emotionStartTime = DateTime.now();
      setState(() {});
    }
  }

  void _showEmotionChangeSnackBar(String emotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emotion changed to: $emotion. Adjusting frequency...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    isDetecting = false;
    detectionTimer?.cancel();
    emotionTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Detection'),
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
                    const Text(
                      'Continuous Emotion Detection',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your emotions are being monitored in real-time. The frequency will automatically adjust based on your emotional state.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (cameraError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera Error',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cameraError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isInitializingCamera)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Initializing camera...'),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: controller != null &&
                                controller!.value.isInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CameraPreview(controller!),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Emotion: $currentEmotion',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Stable Emotion: $stableEmotion',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (cameraError == null)
              ElevatedButton(
                onPressed: () => context.go('/frequency'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Start Frequency Session'),
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cameraError = null;
                        isInitializingCamera = true;
                      });
                      _initializeCamera();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Retry Camera'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/frequency'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Skip to Frequency Session'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../widgets/top_nav_bar.dart';

class EmotionDetectionScreen extends ConsumerStatefulWidget {
  const EmotionDetectionScreen({super.key});

  @override
  ConsumerState<EmotionDetectionScreen> createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends ConsumerState<EmotionDetectionScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  String currentEmotion = 'neutral';
  String stableEmotion = 'neutral';
  DateTime? emotionStartTime;
  Timer? emotionTimer;
  Timer? detectionTimer;
  bool isDetecting = false;
  String videoElementId = 'emotion-video';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadFaceApiModels();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![0], ResolutionPreset.medium);
      await controller!.initialize();
      setState(() {});
      _startDetection();
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
            console.error('Face detection error:', e);
            return 'neutral';
          }
        })()
      ''']);

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
        if (duration.inSeconds >= 5 && duration.inSeconds <= 7.5 && stableEmotion != newEmotion) {
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
      appBar: const TopNavBar(title: 'Emotion Detection'),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your emotions are being monitored in real-time. The frequency will automatically adjust based on your emotional state.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: controller != null && controller!.value.isInitialized
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CameraPreview(controller!),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Emotion: $currentEmotion',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            ElevatedButton(
              onPressed: () => context.go('/frequency'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Start Frequency Session'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _controller = TextEditingController();
  String _response = '';
  String _recommendedFrequency = '';
  String _frequencyDescription = '';
  bool _isAnalyzing = false;

  void _analyze() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _response = '';
      _recommendedFrequency = '';
      _frequencyDescription = '';
    });

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 1));

    final text = _controller.text.toLowerCase();
    String response;
    String frequency;
    String description;

    if (text.contains('anxious') ||
        text.contains('anxiety') ||
        text.contains('worried') ||
        text.contains('nervous')) {
      response =
          'I hear that you\'re feeling anxious. That\'s completely understandable, and we\'re here to help you find some calm.';
      frequency = '396 Hz';
      description =
          'Liberating Guilt & Fear - This frequency helps release deep-seated anxiety and promotes emotional balance.';
    } else if (text.contains('sad') ||
        text.contains('depressed') ||
        text.contains('down') ||
        text.contains('unhappy')) {
      response =
          'I\'m sorry you\'re feeling this way. It\'s brave of you to reach out, and music therapy can be very supportive during difficult times.';
      frequency = '396 Hz';
      description =
          'Liberating Guilt & Fear - This frequency helps process emotions and supports emotional healing.';
    } else if (text.contains('angry') ||
        text.contains('frustrated') ||
        text.contains('irritated') ||
        text.contains('mad')) {
      response =
          'Anger can be intense and overwhelming. Let\'s work together to help you find some inner peace and clarity.';
      frequency = '174 Hz';
      description =
          'Pain Relief & Grounding - This frequency helps reduce tension and promotes emotional grounding.';
    } else if (text.contains('stressed') ||
        text.contains('overwhelmed') ||
        text.contains('tired') ||
        text.contains('exhausted')) {
      response =
          'Stress can take a toll on our well-being. Let\'s create a peaceful space for you to relax and recharge.';
      frequency = '285 Hz';
      description =
          'Tissue & Organ Healing - This frequency supports overall relaxation and helps restore balance to your system.';
    } else if (text.contains('happy') ||
        text.contains('good') ||
        text.contains('great') ||
        text.contains('positive')) {
      response =
          'I\'m glad you\'re feeling positive! Let\'s enhance and maintain that wonderful energy.';
      frequency = '528 Hz';
      description =
          'DNA Repair & Miracles - This frequency amplifies positive emotions and supports overall well-being.';
    } else if (text.contains('confused') ||
        text.contains('unclear') ||
        text.contains('lost') ||
        text.contains('direction')) {
      response =
          'Feeling uncertain can be challenging. Let\'s help you find some clarity and inner guidance.';
      frequency = '432 Hz';
      description =
          'Universal Healing - This frequency promotes mental clarity and helps restore harmony.';
    } else if (text.contains('lonely') ||
        text.contains('alone') ||
        text.contains('isolated')) {
      response =
          'Feeling lonely is difficult, but you\'re not alone in this moment. Let\'s create a supportive, healing space for you.';
      frequency = '528 Hz';
      description =
          'DNA Repair & Miracles - This frequency helps foster connection and emotional healing.';
    } else {
      response =
          'Thank you for sharing how you\'re feeling. Every emotion is valid, and we\'re here to support your journey toward well-being.';
      frequency = '432 Hz';
      description =
          'Universal Healing - This balanced frequency provides gentle support for overall emotional harmony.';
    }

    setState(() {
      _isAnalyzing = false;
      _response = response;
      _recommendedFrequency = frequency;
      _frequencyDescription = description;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your AI Guide',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            Text(
                              'Let\'s check in together',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Check-in prompt
                  Card(
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'How are you feeling right now?',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Take a moment to share what\'s on your mind. Your feelings are safe here, and this helps us create the most supportive experience for you.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input area
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share your thoughts',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'I\'m feeling...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAnalyzing ? null : _analyze,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isAnalyzing
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                            'Analyzing your feelings...'),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('Share with my AI Guide'),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.send,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AI Response
                  if (_response.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Your AI Guide says:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _response,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Recommended: $_recommendedFrequency',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _frequencyDescription,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Continue button
                  if (_response.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed: () => context.go('/emotion'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Emotion Detection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

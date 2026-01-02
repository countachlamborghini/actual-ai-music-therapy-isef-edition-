import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../widgets/top_nav_bar.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _controller = TextEditingController();
  String _response = '';
  String _recommendedFrequency = '';
  String _frequencyDescription = '';
  String _followUpQuestion = '';
  bool _isAnalyzing = false;
  List<String> _conversationHistory = [];

  void _analyze() async {
    if (_controller.text.trim().isEmpty) return;

    final userInput = _controller.text.trim();
    final currentEmotion = ref.read(stableEmotionProvider);
    final deepSeekService = ref.read(deepSeekTherapistProvider);

    setState(() {
      _isAnalyzing = true;
      _response = '';
      _recommendedFrequency = '';
      _frequencyDescription = '';
      _followUpQuestion = '';
    });

    try {
      final aiResponse = await deepSeekService.getTherapeuticResponse(userInput, currentEmotion);

      // Parse the response to extract frequency recommendation
      final frequencyMatch = RegExp(r'(\d+)\s*Hz').firstMatch(aiResponse);
      if (frequencyMatch != null) {
        final frequency = '${frequencyMatch.group(1)} Hz';
        _recommendedFrequency = frequency;
        _frequencyDescription = _getFrequencyDescription(frequency);
      } else {
        _recommendedFrequency = '432 Hz';
        _frequencyDescription = 'Universal Healing - This balanced frequency provides gentle support for overall emotional harmony.';
      }

      // Extract follow-up question if present
      final questionMatch = RegExp(r'[?\.]\s*([^?.]*\?)').firstMatch(aiResponse);
      if (questionMatch != null) {
        _followUpQuestion = questionMatch.group(1)?.trim() ?? '';
      }

      setState(() {
        _isAnalyzing = false;
        _response = aiResponse;
      });
    } catch (e) {
      // Fallback to basic response
      setState(() {
        _isAnalyzing = false;
        _response = 'Thank you for sharing. I\'m here to support you. Let\'s continue our conversation.';
        _recommendedFrequency = '432 Hz';
        _frequencyDescription = 'Universal Healing - This balanced frequency provides gentle support.';
      });
    }
  }

  String _getFrequencyDescription(String frequency) {
    switch (frequency) {
      case '174 Hz':
        return 'Pain Relief & Grounding - This frequency helps reduce tension and promotes emotional grounding.';
      case '285 Hz':
        return 'Tissue & Organ Healing - This frequency supports overall relaxation and helps restore balance.';
      case '396 Hz':
        return 'Liberating Guilt & Fear - This frequency helps release deep-seated anxiety and promotes emotional balance.';
      case '417 Hz':
        return 'Undoing Situations & Facilitating Change - This frequency helps release limiting patterns and beliefs.';
      case '432 Hz':
        return 'Universal Healing - This frequency promotes mental clarity and helps restore harmony.';
      case '528 Hz':
        return 'DNA Repair & Miracles - This frequency amplifies positive emotions and supports overall well-being.';
      case '741 Hz':
        return 'Awakening Intuition - This frequency helps develop intuition and spiritual awareness.';
      case '852 Hz':
        return 'Returning to Spiritual Order - This frequency helps restore spiritual balance and order.';
      case '963 Hz':
        return 'Divine Consciousness - This frequency connects to divine consciousness and spiritual awakening.';
      default:
        return 'Universal Healing - This balanced frequency provides gentle support for overall emotional harmony.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        title: 'Check In',
        extraActions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Let\'s check in together',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/settings'),
                      icon: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Check-in prompt
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Take a moment to share what\'s on your mind. Your feelings are safe here, and this helps us create the most supportive experience for you.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isAnalyzing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Analyzing your feelings...'),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Share with my AI Guide'),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.send,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.onPrimary,
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _response,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recommended: $_recommendedFrequency',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _frequencyDescription,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_followUpQuestion.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.question_answer,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'A gentle question to explore deeper:',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _followUpQuestion,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
              ],
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
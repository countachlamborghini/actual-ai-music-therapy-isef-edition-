import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingContent(ref: ref);
  }
}

class OnboardingContent extends StatefulWidget {
  const OnboardingContent({super.key, required this.ref});
  final WidgetRef ref;

  @override
  State<OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<OnboardingContent> {
  int _ageRange = 0;
  String _style = 'action';
  bool _cameraComfort = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                      Icons.spa,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'AI Music Therapy',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Welcome message
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Personal Music Therapy Journey',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Experience adaptive solfeggio frequencies that respond to your emotions in real-time. Our AI-powered system creates a personalized therapeutic experience.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Setup steps
                Expanded(
                  child: ListView(
                    children: [
                      // Age Range
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Age Range',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<int>(
                                  value: _ageRange,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 0, child: Text('Under 18')),
                                    DropdownMenuItem(value: 1, child: Text('18-30')),
                                    DropdownMenuItem(value: 2, child: Text('31-50')),
                                    DropdownMenuItem(value: 3, child: Text('Over 50')),
                                  ],
                                  onChanged: (value) => setState(() => _ageRange = value!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Style Preference
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.palette,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Preferred Experience',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    RadioListTile<String>(
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.sports_esports,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text('Interactive & Game-like'),
                                          ),
                                        ],
                                      ),
                                      subtitle: const Text('Engaging activities with progress tracking'),
                                      value: 'action',
                                      groupValue: _style,
                                      onChanged: (value) => setState(() => _style = value!),
                                    ),
                                    const Divider(height: 1),
                                    RadioListTile<String>(
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.self_improvement,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text('Calm & Meditative'),
                                          ),
                                        ],
                                      ),
                                      subtitle: const Text('Peaceful experience with gentle guidance'),
                                      value: 'calm',
                                      groupValue: _style,
                                      onChanged: (value) => setState(() => _style = value!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Camera Consent
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Camera Access',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Real-time Emotion Detection',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Our AI analyzes your facial expressions to adapt the music therapy experience. All processing happens locally on your device - your privacy is protected.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CheckboxListTile(
                                  title: const Text('I agree to camera access for emotion detection'),
                                  subtitle: const Text('Required for personalized therapy experience'),
                                  value: _cameraComfort,
                                  onChanged: (value) => setState(() => _cameraComfort = value!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Continue button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: _cameraComfort ? () {
                      final profile = {
                        'ageRange': _ageRange,
                        'style': _style,
                        'cameraComfort': _cameraComfort,
                      };
                      widget.ref.read(userProfileProvider.notifier).state = profile;
                      context.go('/checkin');
                    } : null,
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
                          'Begin My Journey',
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
}
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  int _ageRange = 0;
  String _style = 'action';
  bool _cameraComfort = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // Save profile (for now, just navigate)
            Navigator.pushNamed(context, '/checkin');
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Age Range'),
            content: DropdownButton<int>(
              value: _ageRange,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Under 18')),
                DropdownMenuItem(value: 1, child: Text('18-30')),
                DropdownMenuItem(value: 2, child: Text('31-50')),
                DropdownMenuItem(value: 3, child: Text('Over 50')),
              ],
              onChanged: (value) => setState(() => _ageRange = value!),
            ),
          ),
          Step(
            title: const Text('Interaction Style'),
            content: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Action / Game-like'),
                  value: 'action',
                  groupValue: _style,
                  onChanged: (value) => setState(() => _style = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Calm / Visual / Story-based'),
                  value: 'calm',
                  groupValue: _style,
                  onChanged: (value) => setState(() => _style = value!),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Camera Comfort'),
            content: Column(
              children: [
                const Text('This app uses facial emotion detection for music therapy. This is not medical therapy.'),
                CheckboxListTile(
                  title: const Text('I am comfortable using the camera'),
                  value: _cameraComfort,
                  onChanged: (value) => setState(() => _cameraComfort = value!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
# actual-ai-music-therapy-isef-edition-

This project is an AI-assisted music therapy web app.

## Recent changes (Jan 2026)
- Added a top navigation bar with Home, Therapist, AI Music Therapy, and Settings across main screens. ✅
- Implemented a Therapist chat (DeepSeek) accessible as a page and as a sidebar during the adaptive frequency session. The therapist can suggest frequencies which are applied live. ✅
- Replaced the game with a Rewards & XP system: sessions grant XP over time and unlocking rewards/skins/badges like a Duolingo-style progression. ✅

- Adaptive Frequency Session improvements: continuous camera (emotion) + microphone monitoring, live oscillator-based frequency playback via Web Audio API, and UI indicators for camera/mic state. ✅

## DeepSeek configuration
Edit `lib/providers.dart` and replace the `apiKey` placeholder in `DeepSeekTherapistService` with your DeepSeek API key, or update the service to pull the key from secure config or environment variables.

## Notes
- The web build uses browser APIs (Web Audio, mediaDevices, face-api.js). Ensure the build is served over HTTPS for camera/microphone permissions.

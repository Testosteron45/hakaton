class AppConstants {
  AppConstants._();

  static const firestoreUserProfiles = 'user_profiles';
  static const firestoreSwipeSessions = 'swipe_sessions';

  // Groq (OpenAI-compatible API)
  static const groqApiBaseUrl = 'https://api.groq.com/openai/v1';
  static const groqDefaultModel = 'llama-3.1-8b-instant';
  static const groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
}

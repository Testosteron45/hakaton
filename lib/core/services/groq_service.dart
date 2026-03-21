import 'dart:convert';

import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class GroqService {
  GroqService({
    required this.apiKey,
    this.baseUrl = AppConstants.groqApiBaseUrl,
    this.defaultModel = AppConstants.groqDefaultModel,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String defaultModel;
  final http.Client _client;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> generateText({
    required String userPrompt,
    String? systemPrompt,
    String? model,
    double temperature = 0.6,
    int maxTokens = 400,
  }) async {
    if (!isConfigured) {
      throw const GroqException(
        'Groq API key is not configured. Pass --dart-define=GROQ_API_KEY=...',
      );
    }

    final uri = Uri.parse('$baseUrl/chat/completions');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model ?? defaultModel,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'messages': [
          if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
            {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroqException(
        'Groq request failed: ${response.statusCode} ${response.body}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = map['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) {
      throw const GroqException('Groq returned empty choices list');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>? ?? const {};
    final content = (message['content'] as String?)?.trim() ?? '';
    if (content.isEmpty) {
      throw const GroqException('Groq returned empty message content');
    }

    return content;
  }

  Future<bool> checkAvailability() async {
    if (!isConfigured) return false;

    final uri = Uri.parse('$baseUrl/models');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  void dispose() {
    _client.close();
  }
}

class GroqException implements Exception {
  const GroqException(this.message);

  final String message;

  @override
  String toString() => 'GroqException: $message';
}

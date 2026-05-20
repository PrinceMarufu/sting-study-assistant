import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  /// Ordered list of models to try. We fall through to the next if one is
  /// unavailable (503) or rate-limited (429 with free-tier limit: 0).
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
  ];

  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Core method: tries each model in order with up to 3 retries per model
  /// using exponential back-off for transient 503 errors.
  Future<String> _callGemini(String prompt) async {
    final apiKey = Constants.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final bodyMap = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
      },
    };

    Exception? lastException;

    for (final model in _models) {
      final url = Uri.parse('$_apiBase/$model:generateContent?key=$apiKey');
      debugPrint('Trying model: $model');

      // Retry up to 3 times for transient errors on this model
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyMap),
          );

          debugPrint('[$model] attempt $attempt → status ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] as String;
              }
            }
            throw Exception('No content returned from Gemini ($model).');
          } else if (response.statusCode == 503) {
            // Transient high-demand — wait and retry
            debugPrint('[$model] 503 high demand, retrying in ${attempt * 2}s...');
            lastException = Exception('Service temporarily unavailable ($model).');
            if (attempt < 3) {
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
            // Give up on this model, try next
            break;
          } else if (response.statusCode == 429) {
            // Quota exceeded — no point retrying this model
            debugPrint('[$model] 429 quota exceeded, trying next model...');
            lastException = Exception('Rate limit reached ($model).');
            break;
          } else if (response.statusCode == 404) {
            // Model not available on this key — skip
            debugPrint('[$model] 404 not found, trying next model...');
            lastException = Exception('Model not available ($model).');
            break;
          } else {
            debugPrint('[$model] Unexpected error: ${response.body}');
            lastException = Exception('API error (${response.statusCode}) on $model.');
            break;
          }
        } catch (e) {
          debugPrint('[$model] Exception: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }
    }

    // All models exhausted
    throw lastException ??
        Exception('All Gemini models are currently unavailable. Please try again in a moment.');
  }

  /// Strips markdown code-block wrappers (```json ... ``` or ``` ... ```) from
  /// Gemini responses to ensure clean JSON parsing.
  String _stripMarkdownWrapper(String text) {
    String cleaned = text.trim();
    // Remove ```json or ``` prefix
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    // Remove trailing ```
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  // ---------------------------------------------------------------
  // 1. General Chat
  // ---------------------------------------------------------------
  Future<String> sendMessage(String message) async {
    final prompt = '''You are SSA (Sting Study Assistant), a friendly, knowledgeable, and encouraging AI tutor designed to help university students study effectively.

Rules:
- Be concise but thorough.
- Use clear structure: bullet points, numbered lists, or short paragraphs.
- If the student asks about a topic, explain it clearly with examples.
- Always be encouraging and supportive.

Student's message: $message''';

    return await _callGemini(prompt);
  }

  // ---------------------------------------------------------------
  // 2. PDF Summarizer
  // ---------------------------------------------------------------
  Future<String> summarizeText(String text) async {
    // Truncate to 15,000 chars for optimal performance
    final truncated = text.length > 15000 ? text.substring(0, 15000) : text;

    final prompt = '''You are an expert academic summarizer. Analyze the following text extracted from a student's PDF document and produce a structured, high-quality study summary.

Format your summary as follows:
📌 OVERVIEW
A 2-3 sentence overview of the entire document.

📝 KEY CONCEPTS
- Concept 1: Explanation
- Concept 2: Explanation
(list all important concepts)

🔑 IMPORTANT DEFINITIONS
- Term: Definition
(list key terms)

💡 KEY TAKEAWAYS
1. First takeaway
2. Second takeaway
(numbered list of actionable takeaways)

---
Extracted Text:
$truncated''';

    return await _callGemini(prompt);
  }

  // ---------------------------------------------------------------
  // 3. Quiz Generator
  // ---------------------------------------------------------------
  /// Returns a JSON array of 5 quiz questions based on the provided notes.
  /// Each element: { "question": "...", "options": ["A","B","C","D"], "correctIndex": 0-3 }
  Future<List<Map<String, dynamic>>> generateQuiz(String notesText) async {
    final truncated =
        notesText.length > 12000 ? notesText.substring(0, 12000) : notesText;

    final prompt = '''You are an AI quiz generator for a university study assistant app.

Based on the following student notes, generate exactly 5 multiple-choice questions. Each question must have exactly 4 answer options with one correct answer.

IMPORTANT: Respond ONLY with a raw JSON array. Do NOT include any markdown formatting, code blocks, or explanation. Just the JSON array.

The JSON format must be:
[
  {
    "question": "What is ...?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0
  }
]

Student Notes:
$truncated''';

    final raw = await _callGemini(prompt);
    final cleaned = _stripMarkdownWrapper(raw);

    try {
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed
          .map<Map<String, dynamic>>((e) => {
                'question': e['question'] as String,
                'options': List<String>.from(e['options'] as List),
                'correctIndex': e['correctIndex'] as int,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to parse quiz JSON from Gemini: $e');
    }
  }

  // ---------------------------------------------------------------
  // 4. Study Task Planner
  // ---------------------------------------------------------------
  /// Returns a JSON array of 3-5 study tasks based on the provided notes.
  /// Each element: { "title": "...", "description": "..." }
  Future<List<Map<String, String>>> generateStudyTasks(
      String notesText) async {
    final truncated =
        notesText.length > 10000 ? notesText.substring(0, 10000) : notesText;

    final prompt = '''You are an AI study planner for a university study assistant app.

Based on the following student notes, generate between 3 and 5 actionable study tasks that would help the student master the material. Each task should have a clear title and a brief description.

IMPORTANT: Respond ONLY with a raw JSON array. Do NOT include any markdown formatting, code blocks, or explanation. Just the JSON array.

The JSON format must be:
[
  {
    "title": "Task Title",
    "description": "Brief description of what to study and how"
  }
]

Student Notes:
$truncated''';

    final raw = await _callGemini(prompt);
    final cleaned = _stripMarkdownWrapper(raw);

    try {
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed
          .map<Map<String, String>>((e) => {
                'title': e['title'] as String,
                'description': e['description'] as String,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to parse study tasks JSON from Gemini: $e');
    }
  }
}

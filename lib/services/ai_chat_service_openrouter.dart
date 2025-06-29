
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  final String _apiKey = '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'; // Actual API Key
  final String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String _model = 'mistralai/mistral-7b-instruct';

  Future<String> sendMessage(String message) async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      // IMPORTANT: Replace with a real referer URL. Must be a domain you own or control.
      'HTTP-Referer': 'https://github.com/nrathirazmn',
      'X-Title': 'TravelBuddy AI'
    };

    final body = jsonEncode({
      "model": _model,
      "messages": [ 
        {"role": "user", "content": message}
      ]
    });

    try {
      final response = await http.post(Uri.parse(_baseUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('OpenRouter Error: ${response.statusCode} - ${response.body}');
        return 'AI error ${response.statusCode}: ${jsonDecode(response.body)['error']['message'] ?? 'Unknown error'}';
      }
    } catch (e) {
      print('Network or parse error: $e');
      return 'Network error or bad API response. Please try again.';
    }
  }
}

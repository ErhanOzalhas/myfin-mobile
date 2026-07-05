import 'ai_provider.dart';

class OpenAIProvider extends AIProvider {
  
   OpenAIProvider();

  @override
  Future<String> ask({
    required String context,
    required String question,
  }) async {
    // OpenAI bağlantısı bir sonraki sprintte eklenecek.
    return '''
AI Provider hazır.

Context:

$context

User Question:

$question
''';
  }
}
import 'package:cloud_functions/cloud_functions.dart';

import 'ai_service.dart';

/// Secure OpenAI provider backed by a Firebase callable function.
///
/// The OpenAI API key is held by Firebase Secret Manager and is never shipped
/// inside the Flutter application.
class OpenAIProvider implements AIProvider {
  OpenAIProvider({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<AIResponse> complete(AIPrompt prompt) async {
    try {
      final webSearch = prompt.userMessage.contains(
        '=== ENABLE_WEB_SEARCH ===',
      );
      final callable = _functions.httpsCallable(
        'myFinAi',
        options: HttpsCallableOptions(
          timeout: Duration(seconds: webSearch ? 45 : 30),
        ),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'instructions': _buildInstructions(prompt.systemPrompt),
        'input': prompt.fullPrompt,
        'webSearch': webSearch,
      });

      final data = result.data;
      final content = (data['text'] ?? '').toString().trim();
      final model = (data['model'] ?? 'openai').toString().trim();

      if (content.isEmpty) {
        throw const OpenAIProviderException(
          message: 'Firebase AI function returned an empty response.',
          userMessage: 'AI boş yanıt döndürdü. Lütfen tekrar deneyin.',
        );
      }

      return AIResponse.success(
        content,
        providerName: 'openai:$model',
        prompt: prompt,
      );
    } on FirebaseFunctionsException catch (error) {
      throw OpenAIProviderException(
        message: 'Firebase AI function failed: ${error.code}',
        userMessage: _userMessageFor(error),
      );
    }
  }

  @override
  Stream<String> stream(AIPrompt prompt) async* {
    final response = await complete(prompt);
    yield response.content;
  }

  String _userMessageFor(FirebaseFunctionsException error) {
    final serverMessage = error.message?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    return switch (error.code) {
      'unauthenticated' =>
        'AI özelliğini kullanmak için yeniden oturum açmalısınız.',
      'resource-exhausted' =>
        'AI kullanım limiti doldu. Lütfen biraz sonra tekrar deneyin.',
      'deadline-exceeded' || 'unavailable' =>
        'AI servisine şu anda ulaşılamıyor. Lütfen tekrar deneyin.',
      _ => 'AI yanıtı oluşturulamadı. Lütfen biraz sonra tekrar deneyin.',
    };
  }
}

String _buildInstructions(String systemPrompt) {
  return '''
$systemPrompt

Role: MyFin AI, kullanıcının kişisel finans ve portföy asistanı.

Goal: Kullanıcının sorusunu mevcut portföy bağlamına dayanarak doğrudan,
anlaşılır ve aksiyon odaklı biçimde yanıtla.

Constraints:
- Kullanıcı açıkça başka bir dil istemedikçe Türkçe yanıt ver.
- Portföy bağlamını doğruluk kaynağı kabul et; verilmemiş değer, fiyat veya
  performans bilgisi üretme.
- Belirsizliği açıkça belirt ve yatırım sonuçlarını garanti etme.
- Bağlamda bulunan portföy bilgisini kullanıcıdan tekrar isteme.

Output:
- Sonuçla başla; profesyonel, sıcak ve sade bir ton kullan.
- Normalde 80–150 kelimeyi ve en fazla 3 maddeyi hedefle.
- Gerekliyse tek bir isteğe bağlı sonraki adımla bitir.
'''
      .trim();
}

class OpenAIProviderException implements Exception {
  const OpenAIProviderException({
    required this.message,
    required this.userMessage,
  });

  final String message;
  final String userMessage;

  @override
  String toString() => 'OpenAIProviderException: $message';
}

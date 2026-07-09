import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:myfin_mobile/services/ai/ai_service.dart';

/// OpenAI implementation of the MyFin AI provider layer.
///
/// Place this file at:
/// lib/services/ai/openai_provider.dart
///
/// Required .env value:
/// OPENAI_API_KEY=...
///
/// Optional .env values:
/// OPENAI_MODEL=gpt-5-mini
/// OPENAI_RESPONSES_ENDPOINT=https://api.openai.com/v1/responses
class OpenAIProvider implements AIProvider {
  OpenAIProvider({
    http.Client? client,
    String? apiKey,
    String? model,
    Uri? endpoint,
    Duration timeout = const Duration(seconds: 45),
    int maxRetries = 2,
  })  : _client = client ?? http.Client(),
        _apiKeyOverride = apiKey,
        _modelOverride = model,
        _endpointOverride = endpoint,
        _timeout = timeout,
        _maxRetries = maxRetries < 0 ? 0 : maxRetries;

  static const String _defaultEndpoint = 'https://api.openai.com/v1/responses';
  static const String _defaultModel = 'gpt-5-mini';

  final http.Client _client;
  final String? _apiKeyOverride;
  final String? _modelOverride;
  final Uri? _endpointOverride;
  final Duration _timeout;
  final int _maxRetries;

  String get _apiKey =>
      (_apiKeyOverride ?? dotenv.env['OPENAI_API_KEY'] ?? '').trim();

  String get _model =>
      (_modelOverride ?? dotenv.env['OPENAI_MODEL'] ?? _defaultModel).trim();

  Uri get _endpoint => _endpointOverride ??
      Uri.parse(
        (dotenv.env['OPENAI_RESPONSES_ENDPOINT'] ?? _defaultEndpoint).trim(),
      );

  @override
  Future<AIResponse> complete(AIPrompt prompt) async {
    _validateConfiguration();

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': _model,
      'instructions': _buildInstructions(prompt.systemPrompt),
      'input': prompt.fullPrompt,
    };

    final http.Response response = await _sendWithRetry(payload);
    final String content = _extractText(response.body).trim();

    if (content.isEmpty) {
      throw const OpenAIProviderException(
        message: 'OpenAI empty response.',
        userMessage:
            'AI boş yanıt döndürdü. Soruyu tekrar göndermeyi deneyebilirsin.',
      );
    }

    return AIResponse.success(
      content,
      providerName: 'openai:$_model',
      prompt: prompt,
    );
  }


  @override
  Stream<String> stream(AIPrompt prompt) async* {
    _validateConfiguration();

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': _model,
      'instructions': _buildInstructions(prompt.systemPrompt),
      'input': prompt.fullPrompt,
      'stream': true,
    };

    final http.Request request = http.Request('POST', _endpoint)
      ..headers.addAll(<String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $_apiKey',
        HttpHeaders.acceptHeader: 'text/event-stream',
      })
      ..body = jsonEncode(payload);

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_timeout);
    } on TimeoutException catch (error) {
      throw OpenAIProviderException(
        message: 'OpenAI stream request timed out: $error',
        userMessage:
            'AI servisine bağlanırken zaman aşımı oluştu. Lütfen tekrar dene.',
      );
    } on SocketException catch (error) {
      throw OpenAIProviderException(
        message: 'OpenAI stream socket error: $error',
        userMessage:
            'AI servisine bağlanırken ağ sorunu oluştu. İnternet bağlantını kontrol edebilirsin.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String body = await response.stream.bytesToString();
      throw _mapHttpError(
        http.Response(
          body,
          response.statusCode,
          headers: response.headers,
          request: request,
        ),
      );
    }

    await for (final String line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
      if (!trimmed.startsWith('data:')) continue;

      final String data = trimmed.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;

      final String delta = _extractStreamDelta(data);
     if (delta.isNotEmpty) {
  debugPrint('OPENAI STREAM CHUNK: "$delta"');
  yield delta;
} 
    }
  }

  Future<http.Response> _sendWithRetry(Map<String, dynamic> payload) async {
    Object? lastError;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final http.Response response = await _client
            .post(
              _endpoint,
              headers: <String, String>{
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: 'Bearer $_apiKey',
              },
              body: jsonEncode(payload),
            )
            .timeout(_timeout);

        _debugResponse(response, attempt);

        if (_isRetryableStatus(response.statusCode) && attempt < _maxRetries) {
          await _backoff(attempt);
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw _mapHttpError(response);
        }

        return response;
      } on TimeoutException catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) break;
        await _backoff(attempt);
      } on SocketException catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) break;
        await _backoff(attempt);
      } on OpenAIProviderException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) break;
        await _backoff(attempt);
      }
    }

    throw OpenAIProviderException(
      message: 'OpenAI request failed: $lastError',
      userMessage:
          'AI servisine bağlanırken sorun oluştu. İnternet bağlantısı veya servis ayarlarını kontrol edebilirsin.',
    );
  }

String _buildInstructions(String systemPrompt) {
  return '''
$systemPrompt

You are MyFin AI, the user's personal finance assistant.

Always respond in Turkish unless the user clearly asks for another language.

Be concise, practical, warm, and professional.

Keep responses short by default.

Target length: 80–150 words.

Start with a direct answer.

Use at most 3 bullet points.

End with one optional follow-up suggestion.

Do not repeat information already mentioned in previous answers.

Avoid long educational explanations unless the user explicitly asks for them.

When portfolio context is provided, treat it as the source of truth.
Never ask the user to provide portfolio information that is already available in the context.

Do not fabricate portfolio values, prices, performance, or market data.

If context is missing, briefly explain what is missing.
If some portfolio fields are missing but you can still answer the user's question, answer first.
Only mention missing information if it materially changes the recommendation.
Do not present investment ideas as guaranteed outcomes.

Sound like a premium finance coach rather than a textbook.
'''
      .trim();
}


  String _extractStreamDelta(String data) {
    try {
      final dynamic decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return '';

      final dynamic type = decoded['type'];
      if (type is String &&
          type != 'response.output_text.delta' &&
          type != 'response.refusal.delta' &&
          type != 'response.message.delta') {
        return '';
      }

      final dynamic delta = decoded['delta'];
      if (delta is String) return delta;

      final dynamic text = decoded['text'];
      if (text is String) return text;

      final dynamic outputText = decoded['output_text'];
      if (outputText is String) return outputText;

      final dynamic content = decoded['content'];
      if (content is String) return content;

      return '';
    } catch (_) {
      return '';
    }
  }

  String _extractText(String responseBody) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response root is not a JSON object.');
      }

      final dynamic outputText = decoded['output_text'];
      if (outputText is String && outputText.trim().isNotEmpty) {
        return outputText;
      }

      final dynamic output = decoded['output'];
      if (output is List) {
        final StringBuffer buffer = StringBuffer();

        for (final dynamic item in output) {
          if (item is! Map<String, dynamic>) continue;

          final dynamic content = item['content'];
          if (content is! List) continue;

          for (final dynamic contentItem in content) {
            if (contentItem is! Map<String, dynamic>) continue;

            final dynamic text = contentItem['text'];
            if (text is String && text.trim().isNotEmpty) {
              buffer.writeln(text.trim());
              continue;
            }

            final dynamic nestedText = contentItem['output_text'];
            if (nestedText is String && nestedText.trim().isNotEmpty) {
              buffer.writeln(nestedText.trim());
            }
          }
        }

        final String value = buffer.toString().trim();
        if (value.isNotEmpty) return value;
      }

      throw const FormatException('Assistant text could not be found.');
    } on FormatException catch (error) {
      throw OpenAIProviderException(
        message: 'OpenAI JSON parse error: $error',
        userMessage:
            'AI yanıtı okunamadı. Servis yanıt formatı kontrol edilmeli.',
      );
    }
  }

  OpenAIProviderException _mapHttpError(http.Response response) {
    String details = response.body;
    String? openAIMessage;

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final dynamic message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            openAIMessage = message.trim();
          }
        }
      }
    } catch (_) {
      // Keep raw body as details.
    }

    final String userMessage;
    switch (response.statusCode) {
      case 400:
        userMessage =
            'AI isteği geçersiz görünüyor. Prompt veya model ayarını kontrol etmek gerekiyor.';
        break;
      case 401:
        userMessage = 'OpenAI API anahtarı geçersiz veya eksik.';
        break;
      case 403:
        userMessage =
            'OpenAI erişimi reddedildi. API hesabı ve model yetkilerini kontrol etmek gerekiyor.';
        break;
      case 404:
        userMessage =
            'OpenAI endpoint veya model bulunamadı. Model adını kontrol etmek gerekiyor.';
        break;
      case 429:
        userMessage =
            'OpenAI kullanım limiti dolmuş olabilir. Biraz sonra tekrar denenebilir.';
        break;
      default:
        userMessage = response.statusCode >= 500
            ? 'OpenAI tarafında geçici bir servis sorunu var gibi görünüyor.'
            : 'AI servisi beklenmeyen bir hata döndürdü.';
    }

    if (openAIMessage != null) {
      details = '$details\nOpenAI message: $openAIMessage';
    }

    return OpenAIProviderException(
      message: 'OpenAI HTTP ${response.statusCode}: $details',
      userMessage: userMessage,
      statusCode: response.statusCode,
    );
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 || statusCode == 409 || statusCode == 429 || statusCode >= 500;
  }

  Future<void> _backoff(int attempt) async {
    final int milliseconds = 400 * (attempt + 1) * (attempt + 1);
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
  }

  void _validateConfiguration() {
    if (_apiKey.isEmpty) {
      throw const OpenAIProviderException(
        message: 'OPENAI_API_KEY is missing.',
        userMessage:
            'OpenAI API anahtarı eksik. .env içinde OPENAI_API_KEY tanımlanmalı.',
      );
    }

    if (_model.isEmpty) {
      throw const OpenAIProviderException(
        message: 'OPENAI_MODEL is empty.',
        userMessage: 'OpenAI model adı boş. OPENAI_MODEL ayarını kontrol et.',
      );
    }
  }

  void _debugResponse(http.Response response, int attempt) {
    if (!kDebugMode) return;

    debugPrint(
      '[OpenAIProvider] attempt=$attempt status=${response.statusCode} bodyLength=${response.body.length}',
    );
  }
}

class OpenAIProviderException implements Exception {
  const OpenAIProviderException({
    required this.message,
    required this.userMessage,
    this.statusCode,
  });

  final String message;
  final String userMessage;
  final int? statusCode;

  @override
  String toString() => 'OpenAIProviderException($statusCode): $message';
}

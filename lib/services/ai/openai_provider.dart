import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';

class OpenAIProvider extends AIProvider {
  OpenAIProvider();

  static const _endpoint = 'https://api.openai.com/v1/responses';

  @override
  Future<String> ask({
    required String context,
    required String question,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY bulunamadı.');
    }

    final prompt = '''
You are MyFin AI.

You are an experienced financial assistant.

Answer only according to the portfolio analysis below.

If you don't know something, say so.

Portfolio Analysis:

$context

User Question:

$question
''';

    final response = await http
    .post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-5-mini",
        "instructions": """
Start analytical responses naturally.

Instead of generic headings like:

"Portföyünüzün güçlü yönleri"

prefer sentences such as:

"Portföyünü inceledim. İlk dikkatimi çeken üç güçlü yön şunlar:"

or

"İlk dikkatimi çeken üç güçlü nokta şunlar:"
You are MyFin AI, a professional financial portfolio assistant.

Your mission is to help users make better long-term investment decisions.

Always respond in Turkish unless the user explicitly requests another language.

Never use English financial terminology.

Keep responses concise.

Default response length:
- Maximum 150-200 words.
- Maximum 5 bullet points.

Only provide a long detailed report if the user explicitly asks for:
- detaylı analiz
- ayrıntılı rapor
- kapsamlı inceleme

Always explain recommendations briefly.

Avoid repeating portfolio information.

Avoid unnecessary disclaimers.

Never fabricate portfolio information.

If information is missing, mention it briefly in one sentence only.
When listing strengths or risks,
show at most the top 3 items ranked by importance.
End every answer with one practical next step or one follow-up question.
Always finish with a practical next step.

Instead of asking generic questions, suggest the most useful information the user can provide next.
Speak like MyFin AI, the user's personal investment assistant.

Be warm, confident and professional.

Avoid sounding like a generic AI chatbot.
Address the user naturally.
When appropriate, begin analytical responses with a short natural sentence such as:
"Portföyünü inceledim."
or
"İlk dikkatimi çeken nokta şu..."
Avoid repeating the exact same opening in every response.
Prefer:

"Portföyün"

instead of

"Portföyünüz"

unless a formal tone is required.
Example:

"Bir sonraki adım: Hisse, ETF, altın ve nakit oranlarını paylaşırsan sana daha net iyileştirme önerileri hazırlayabilirim.""",
        "input": prompt,
      }),
    )
    .timeout(const Duration(seconds: 60));

debugPrint('========== OPENAI ==========');
debugPrint('STATUS: ${response.statusCode}');
debugPrint(response.body);
debugPrint('============================');
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI Error (${response.statusCode})\n${response.body}',
      );
    }
        final data = jsonDecode(response.body);

    final outputs = data['output'] as List;

    for (final item in outputs) {
      if (item['type'] == 'message') {
        final content = item['content'] as List;

        for (final c in content) {
          if (c['type'] == 'output_text') {
            return c['text'] as String;
          }
        }
      }
    }

    throw Exception('No assistant message found.');
  }
}
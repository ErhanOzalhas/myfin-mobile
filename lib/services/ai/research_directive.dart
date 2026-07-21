const List<String> _productTerms = <String>[
  'portföy',
  'ürün',
  'urun',
  'varlık',
  'hisse',
  'fon',
  'altın',
  'dolar',
  'euro',
  'gümüş',
  'gumus',
  'btc',
  'bitcoin',
  'eth',
  'kripto',
  'bist',
  'nasdaq',
];

const List<String> _historyRequestTerms = <String>[
  'geçmiş',
  'tarihsel',
  'uzun vade',
  'son 10 yıl',
  '10 yıll',
  'son 5 yıl',
  '5 yıll',
  'son 3 yıl',
  '3 yıll',
  '10 yıllık',
  '5 yıllık',
  '3 yıllık',
  'yıl bazında',
  'yıl bazlı',
  'yıl yıl',
  'yıllık',
  'yıl sonu',
  'her yıl',
  'yıllar içinde',
  'dönemsel',
  'eskiden',
  'o dönem',
  'geçen yıl',
  'önceki yıl',
];

const List<String> _crisisTerms = <String>[
  'kriz',
  'kapanma',
  'resesyon',
  'çöküş',
  'büyük buhran',
  'finansal şok',
  'piyasa çöküşü',
  '2008',
  '2020',
  '2021',
  '2001',
];

const List<String> _trendOrLevelTerms = <String>[
  'trend',
  'gelişim',
  'değişim',
  'performans',
  'karşılaştır',
  'karsilastir',
  'benzer seviye',
  'seviye',
  'destek',
  'direnç',
  'zirve',
  'dip',
  'yukarı',
  'aşağı',
  'yüksel',
  'düşüş',
  'kapanış',
  'yıl sonu',
  'yıllık',
  'yön',
  'kırılma',
  'pivot',
];

const List<String> _newsRequestTerms = <String>[
  'haber',
  'gündem',
  'gelişme',
  'son durum',
  'bugün ne oldu',
  'ne oldu',
  'kap',
];

const List<String> _driverTerms = <String>[
  'neden',
  'niye',
  'sebep',
  'etkiledi',
  'tetikledi',
  'nereden',
  'hangi faktör',
];

String buildResearchDirective(String rawQuestion) {
  final String question = rawQuestion.trim().toLowerCase();
  if (question.isEmpty) {
    return '';
  }

  final int? years = _estimateResearchYears(question);
  if (years == null) {
    return '';
  }

  final String horizon = years > 0
      ? ' Uygun olduğunda ${_timeFrameLabel(years)} tarihsel bağlam kullan.'
      : '';
  final String yearlyDirective = _buildYearlyBreakdownDirective(question);

  return '=== ENABLE_WEB_SEARCH ===\n'
      'Bu soru portföydeki ürünlerle ilgili web destekli araştırma gerektiriyor.$horizon '
      'Güncel haberlerin yanı sıra geçmiş raporlar, analizler ve doğrulanmış piyasa yorumları kullan. '
      'Önemli olayları ve kırılma noktalarını tarihlerle açıkla; geçmiş yorumları güncel gerçekmiş gibi sunma; kanıtlanmamış nedensellik kurma; çıkarımı açıkça çıkarım olarak belirt. '
      'Cevabın sonunda kısa bir "ASIDE" notu ekle: hangi veri kapsamına dayandığın, hangi dönemlerin güvenilir olduğu ve varsa önemli varsayımları not et.'
      '${yearlyDirective.isEmpty ? '' : ' $yearlyDirective'}';
}

String buildFormattedAnswerDirective() {
  return '=== FORMATTED_ANSWER ===\n'
      'Cevabı şu formatta ver:\n'
      '- Kısa bir ana sonuç.\n'
      '- Gerekiyorsa en fazla 3 madde ile net bir açıklama.\n'
      '- "ASIDE:" başlığı altında veri sınırlarını, tarihsel kapsamı ve önemli varsayımları belirt.\n'
      '- Yıllık veya yıl bazlı isteklerde, imkân varsa her yılı ayrı göster. Eğer yalnızca bir yıl verisi varsa bunu açıkça belirt ve sadece mevcut yılı sun.\n'
      '- Eğer kaynak kullanıldıysa "Kaynaklar:" başlığı altında maddeleyen bir liste sun.';
}

int? _estimateResearchYears(String question) {
  final int? explicit = _parseExplicitYearRange(question);
  if (explicit != null) {
    return explicit.clamp(1, 20);
  }

  if (_containsAny(question, _crisisTerms) && _containsAny(question, _productTerms)) {
    return 15;
  }

  if (_containsAny(question, ['son 10 yıl', '10 yıllık']) && _containsAny(question, _productTerms)) {
    return 10;
  }

  if (_containsAny(question, _historyRequestTerms) && _containsAny(question, _productTerms)) {
    return 10;
  }

  if (_containsAny(question, _trendOrLevelTerms) && _containsAny(question, _productTerms)) {
    return 10;
  }

  if (_containsAny(question, _driverTerms) && _containsAny(question, _productTerms)) {
    return 5;
  }

  if (_containsAny(question, _newsRequestTerms) && _containsAny(question, _productTerms)) {
    return 3;
  }

  if (_containsAny(question, _historyRequestTerms)) {
    return 5;
  }

  return null;

  return null;
}

int? _parseExplicitYearRange(String question) {
  final RegExp yearPattern = RegExp(r'son\s*(\d{1,2})\s*yıl');
  final Match? match = yearPattern.firstMatch(question);
  if (match != null) {
    return int.tryParse(match.group(1) ?? '');
  }

  final RegExp alternatePattern = RegExp(r'(\d{1,2})\s*yıll');
  final Match? alternate = alternatePattern.firstMatch(question);
  if (alternate != null) {
    return int.tryParse(alternate.group(1) ?? '');
  }

  return null;
}

bool _containsAny(String text, List<String> terms) {
  return terms.any(text.contains);
}

String _buildYearlyBreakdownDirective(String question) {
  final bool needsYearly = _containsAny(question, <String>[
    'yıl bazında',
    'yıl bazlı',
    'yıl yıl',
    'yıllık',
    'yıl sonu',
    'her yıl',
    'annual',
    'year by year',
    'yearly',
  ]);

  if (!needsYearly) {
    return '';
  }

  return 'Cevabın bir bölümünde mümkünse yıl bazında bir tablo veya yıllık liste ver: "2020: ...", "2021: ..." şeklinde.';
}

String _timeFrameLabel(int years) {
  if (years <= 1) {
    return 'son 1 yıla kadar';
  }
  return 'son $years yıla kadar';
}

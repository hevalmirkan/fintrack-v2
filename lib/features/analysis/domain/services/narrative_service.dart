import '../entities/lite_argus_result.dart';

/// Market stance enum (professional analyst terminology)
enum ArgusStatus {
  pozitif, // Green - Healthy Bull (Strong trend + low risk)
  riskli, // Orange - Volatile Bull (Strong trend + high risk)
  zayif, // Red - Bearish (Weak trend)
  notr, // Grey/Blue - Neutral/Consolidation
}

/// Extension for ArgusStatus styling and labels
extension ArgusStatusExtension on ArgusStatus {
  String get label {
    switch (this) {
      case ArgusStatus.pozitif:
        return 'POZİTİF GÖRÜNÜM';
      case ArgusStatus.riskli:
        return 'GÜÇLÜ AMA RİSKLİ';
      case ArgusStatus.zayif:
        return 'NEGATİF BASKI';
      case ArgusStatus.notr:
        return 'YÖN ARAYIŞI';
    }
  }

  String get shortLabel {
    switch (this) {
      case ArgusStatus.pozitif:
        return 'POZİTİF';
      case ArgusStatus.riskli:
        return 'RİSKLİ';
      case ArgusStatus.zayif:
        return 'ZAYIF';
      case ArgusStatus.notr:
        return 'NÖTR';
    }
  }

  String get emoji {
    switch (this) {
      case ArgusStatus.pozitif:
        return '🟢';
      case ArgusStatus.riskli:
        return '🟠';
      case ArgusStatus.zayif:
        return '🔴';
      case ArgusStatus.notr:
        return '⚪';
    }
  }

  /// Hex color for the status
  int get colorValue {
    switch (this) {
      case ArgusStatus.pozitif:
        return 0xFF00D09C; // Green
      case ArgusStatus.riskli:
        return 0xFFF59E0B; // Amber/Orange
      case ArgusStatus.zayif:
        return 0xFFEF4444; // Red
      case ArgusStatus.notr:
        return 0xFF6B7280; // Grey
    }
  }
}

/// Structured professional narrative output
class ArgusNarrative {
  final ArgusStatus status;
  final String headline; // Professional title
  final String coachSentence; // One assertive summary sentence
  final String detail; // Deep analytical paragraph
  final String technicalNote; // Optional technical observation

  const ArgusNarrative({
    required this.status,
    required this.headline,
    required this.coachSentence,
    required this.detail,
    this.technicalNote = '',
  });
}

/// Narrative Engine V3 - The Professional Analyst
///
/// Generates deep, nuanced market insights based on combination analysis.
/// Tone: Professional, assertive, educational. NO buy/sell commands.
///
/// Structure: Fact + Interpretation + Boundary
class NarrativeService {
  const NarrativeService();

  /// Determine market stance from score combinations (STRICT RULES)
  ArgusStatus determineStatus(LiteArgusResult result) {
    final trend = result.trendScore;
    final risk = result.riskScore;

    // Check for insufficient data first
    if (result.dataQuality == DataQuality.limited ||
        result.dataQuality == DataQuality.mock) {
      return ArgusStatus.notr;
    }

    // SCENARIO 1: "Sağlıklı Yükseliş" (Healthy Bull)
    // Strong trend + Low risk = Sustainable uptrend
    if (trend > 70 && risk < 50) {
      return ArgusStatus.pozitif;
    }

    // SCENARIO 2: "Agresif/Riskli Yükseliş" (Volatile Bull)
    // Strong trend + High risk = Overheated market
    if (trend > 70 && risk >= 50) {
      return ArgusStatus.riskli;
    }

    // SCENARIO 3: "Zayıf/Düşüş Eğilimi" (Bearish)
    // Weak trend = Sellers in control
    if (trend < 40) {
      return ArgusStatus.zayif;
    }

    // SCENARIO 4: "Kararsızlık/Yatay" (Neutral)
    // Everything else = Consolidation phase
    return ArgusStatus.notr;
  }

  /// Generate comprehensive professional narrative from Argus analysis
  ArgusNarrative generateInsight(LiteArgusResult result) {
    final status = determineStatus(result);
    final trend = result.trendScore;
    final risk = result.riskScore;
    final momentum = result.momentumScore;

    switch (status) {
      case ArgusStatus.pozitif:
        return _generateHealthyBullNarrative(trend, momentum, risk);
      case ArgusStatus.riskli:
        return _generateVolatileBullNarrative(trend, momentum, risk);
      case ArgusStatus.zayif:
        return _generateBearishNarrative(trend, momentum, risk);
      case ArgusStatus.notr:
        return _generateNeutralNarrative(trend, momentum, risk);
    }
  }

  /// Scenario 1: Healthy Bull - Strong trend with controlled risk
  ArgusNarrative _generateHealthyBullNarrative(
      double trend, double momentum, double risk) {
    return ArgusNarrative(
      status: ArgusStatus.pozitif,
      headline: 'Sağlıklı Yükseliş Trendi',
      coachSentence:
          'Ana trend güçlü ve bu hareket, düşük oynaklık ile destekleniyor.',
      detail:
          'Ana trend güçlü ve bu yükseliş, düşük oynaklık (risk) ile destekleniyor. '
          'Bu kombinasyon genelde sağlıklı ve sürdürülebilir bir yükseliş trendine işaret eder. '
          'Mevcut teknik yapı güçlü kalmaya devam ediyor. '
          'Trend skoru ${trend.toInt()} puanla pozitif bölgede seyrederken, '
          'risk seviyesi ${risk.toInt()} ile kontrol altında görünüyor.',
      technicalNote: momentum > 70
          ? 'Momentum da yukarı yönlü katılım sağlıyor, bu trendin gücünü teyit eder.'
          : 'Momentumun trendi daha aktif desteklemesi bekleniyor.',
    );
  }

  /// Scenario 2: Volatile Bull - Strong but overheated
  ArgusNarrative _generateVolatileBullNarrative(
      double trend, double momentum, double risk) {
    return ArgusNarrative(
      status: ArgusStatus.riskli,
      headline: 'Güçlü Ama Dikkat Gerektiren',
      coachSentence:
          'Yukarı yönlü momentum çok güçlü olsa da, risk seviyesi dikkat çekici.',
      detail:
          'Yukarı yönlü momentum çok güçlü olsa da, risk seviyesindeki artış dikkat çekici. '
          'Bu tür "aşırı ısınmış" piyasalar, hızlı kazanç fırsatları sunduğu kadar '
          'sert ve ani geri çekilme risklerini de barındırır. '
          'Trend ${trend.toInt()} puanla güçlü görünse de, '
          '${risk.toInt()} seviyesindeki risk volatilitenin arttığını gösteriyor. '
          'Bu dönemler yakın takip gerektirir.',
      technicalNote: risk > 70
          ? 'Risk seviyesi kritik eşiğin üzerinde. Ani dalgalanmalara hazırlıklı olunmalı.'
          : 'Volatilite yüksek ancak henüz kritik seviyelere ulaşmamış.',
    );
  }

  /// Scenario 3: Bearish - Weak trend, sellers dominant
  ArgusNarrative _generateBearishNarrative(
      double trend, double momentum, double risk) {
    return ArgusNarrative(
      status: ArgusStatus.zayif,
      headline: 'Düşüş Baskısı Hakim',
      coachSentence:
          'Satıcıların piyasaya hakim olduğu ve trendin aşağı yönlü olduğu bir dönem.',
      detail:
          'Satıcıların piyasaya hakim olduğu ve trendin aşağı yönlü olduğu bir dönem. '
          'Alım iştahı düşük ve momentum zayıf. '
          'Henüz net bir taban oluşumu veya güçlü bir dönüş sinyali teknik olarak teyit edilmemiş durumda. '
          'Trend skoru ${trend.toInt()} ile negatif bölgede seyrediyor. '
          'Bu tablo savunmacı bir piyasa yaklaşımını işaret ediyor.',
      technicalNote: momentum < 40
          ? 'Momentum da zayıf, bu durum satış baskısının devam ettiğine işaret.'
          : 'Momentum nispeten dirençli, olası bir toparlanma için ilk işaret olabilir.',
    );
  }

  /// Scenario 4: Neutral - Consolidation, no clear direction
  ArgusNarrative _generateNeutralNarrative(
      double trend, double momentum, double risk) {
    return ArgusNarrative(
      status: ArgusStatus.notr,
      headline: 'Yön Arayışı (Konsolidasyon)',
      coachSentence: 'Piyasa şu anda kararsız bir bantta hareket ediyor.',
      detail: 'Piyasa şu anda kararsız bir bantta hareket ediyor; '
          'ne alıcılar ne de satıcılar net bir üstünlük kurabilmiş değil. '
          'Bu tür yatay süreçlerde teknik göstergeler sık sık yanıltıcı sinyaller üretebilir. '
          'Trend ${trend.toInt()}, Momentum ${momentum.toInt()}, Risk ${risk.toInt()} seviyeleri '
          'karışık bir tablo çiziyor. Kırılımın yönü beklenmeli.',
      technicalNote: _getNeutralTechnicalNote(trend, momentum, risk),
    );
  }

  String _getNeutralTechnicalNote(double trend, double momentum, double risk) {
    if (momentum > 60 && trend > 50) {
      return 'Momentum yükseliyor, bu pozitif bir kırılım öncesine işaret edebilir.';
    } else if (momentum < 40 && trend < 50) {
      return 'Momentum zayıflıyor, aşağı yönlü kırılım riski bulunuyor.';
    } else if (risk > 60) {
      return 'Volatilite yüksek, kırılım sert bir hareketle gelebilir.';
    }
    return 'Göstergeler netlik kazanana kadar temkinli bir yaklaşım önerilir.';
  }

  /// Generate quick one-liner for summary views (professional tone)
  String generateQuickSummary(LiteArgusResult result) {
    final status = determineStatus(result);
    switch (status) {
      case ArgusStatus.pozitif:
        return 'Güçlü ve sağlıklı trend, düşük volatilite.';
      case ArgusStatus.riskli:
        return 'Güçlü momentum, yüksek risk. Yakın takip gerekli.';
      case ArgusStatus.zayif:
        return 'Satış baskısı hakim, taban arayışı devam ediyor.';
      case ArgusStatus.notr:
        return 'Konsolidasyon süreci, yön belirsiz.';
    }
  }

  /// Generate ultra-short status for compact views
  String generateOneWordStatus(LiteArgusResult result) {
    final status = determineStatus(result);
    return status.shortLabel;
  }
}

import 'package:flutter/material.dart';

import '../entities/lite_argus_result.dart';

/// Council Narrative - Professional market stance without directives
///
/// Philosophy: INFORM, don't INSTRUCT
/// NO: "Buy", "Sell", "Hold", "You should..."
/// YES: "Momentum indicates...", "Risk levels suggest...", "The council observes..."
class CouncilNarrativeService {
  const CouncilNarrativeService();

  /// Build council narrative from Argus analysis
  CouncilNarrative buildCouncilNarrative(LiteArgusResult result) {
    final trend = result.trendScore;
    final momentum = result.momentumScore;
    final risk = result.riskScore;

    // Determine the dominant signal
    final scenario = _determineScenario(trend, momentum, risk);

    return scenario;
  }

  CouncilNarrative _determineScenario(
      double trend, double momentum, double risk) {
    // SCENARIO 1: High Momentum + High Risk = Volatile Rally
    if (momentum >= 70 && risk >= 60) {
      return CouncilNarrative(
        headline: 'Yüksek Hareket, Kırılgan Zemin',
        body:
            'Momentum çok güçlü (${momentum.toInt()}%). Ancak oynaklık belirgin şekilde artmış durumda (Risk: ${risk.toInt()}%). '
            'Bu tür dönemler hızlı yükselişler kadar sert geri çekilmeler de içerir. '
            'Konsey, hareketin boyutuna dikkat çekiyor.',
        sentiment: CouncilSentiment.cautious,
        ringColor: const Color(0xFFF59E0B), // Orange
        emoji: '⚡',
      );
    }

    // SCENARIO 2: Strong Trend + Low Risk = Healthy Trend
    if (trend >= 65 && risk < 45) {
      return CouncilNarrative(
        headline: 'Sağlam Zemin',
        body:
            'Trend istikrarlı (${trend.toInt()}%) ve risk seviyesi görece düşük (${risk.toInt()}%). '
            'Bu, hareketin daha dengeli ilerlediğine işaret eder. '
            'Konsey, mevcut yapının sağlıklı olduğunu gözlemliyor.',
        sentiment: CouncilSentiment.positive,
        ringColor: const Color(0xFF00D09C), // Green
        emoji: '🟢',
      );
    }

    // SCENARIO 3: High Momentum, Neutral Trend = Building Pressure
    if (momentum >= 70 && trend >= 40 && trend < 65) {
      return CouncilNarrative(
        headline: 'İlgi Artışı',
        body: 'Momentum ${momentum.toInt()}% seviyesinde güçlü. '
            'Trend henüz net bir yön belirlememiş olsa da (${trend.toInt()}%), hareket artıyor. '
            'Konsey, piyasanın bir kırılıma hazırlandığını gözlemliyor.',
        sentiment: CouncilSentiment.watchful,
        ringColor: const Color(0xFF7C3AED), // Purple
        emoji: '🚀',
      );
    }

    // SCENARIO 4: Weak Trend = Bearish Pressure
    if (trend < 40) {
      return CouncilNarrative(
        headline: 'Düşüş Baskısı',
        body: 'Trend ${trend.toInt()}% ile zayıf bölgede. '
            'Satıcılar görece üstün konumda. '
            'Konsey, net bir toparlanma sinyali henüz gözlemlemiyor.',
        sentiment: CouncilSentiment.bearish,
        ringColor: const Color(0xFFEF4444), // Red
        emoji: '🔴',
      );
    }

    // SCENARIO 5: High Risk Only = Volatility Alert
    if (risk >= 70) {
      return CouncilNarrative(
        headline: 'Yüksek Oynaklık',
        body: 'Risk seviyesi ${risk.toInt()}% ile yüksek. '
            'Fiyat hareketleri her iki yönde beklenenden sert olabilir. '
            'Konsey, dikkatli takip öneriyor.',
        sentiment: CouncilSentiment.cautious,
        ringColor: const Color(0xFFF59E0B), // Orange
        emoji: '⚠️',
      );
    }

    // SCENARIO 6: Mixed/Neutral = Consolidation
    return CouncilNarrative(
      headline: 'Konsey Görüşleri Ayrıştı',
      body:
          'Trend (${trend.toInt()}%), Momentum (${momentum.toInt()}%), Risk (${risk.toInt()}%). '
          'Göstergeler net bir uzlaşı sunmuyor. '
          'Piyasa karar aşamasında, kırılım yönü henüz belirsiz.',
      sentiment: CouncilSentiment.neutral,
      ringColor: const Color(0xFF6B7280), // Grey
      emoji: '⚪',
    );
  }

  /// Generate one-liner for compact views
  String generateQuickInsight(LiteArgusResult result) {
    final narrative = buildCouncilNarrative(result);
    return narrative.headline;
  }
}

/// Council sentiment levels
enum CouncilSentiment {
  positive, // Green - Strong healthy trend
  watchful, // Purple - High momentum, watch closely
  cautious, // Orange - High risk/volatility
  bearish, // Red - Weak trend
  neutral, // Grey - Mixed signals
}

extension CouncilSentimentExtension on CouncilSentiment {
  String get label {
    switch (this) {
      case CouncilSentiment.positive:
        return 'Güçlü';
      case CouncilSentiment.watchful:
        return 'İlgi Var';
      case CouncilSentiment.cautious:
        return 'Dikkat';
      case CouncilSentiment.bearish:
        return 'Zayıf';
      case CouncilSentiment.neutral:
        return 'Kararsız';
    }
  }
}

/// Council narrative output
class CouncilNarrative {
  final String headline;
  final String body;
  final CouncilSentiment sentiment;
  final Color ringColor;
  final String emoji;

  const CouncilNarrative({
    required this.headline,
    required this.body,
    required this.sentiment,
    required this.ringColor,
    required this.emoji,
  });
}

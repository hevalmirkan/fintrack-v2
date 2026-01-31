import 'package:flutter/material.dart';

import '../entities/argus_insight.dart';
import '../entities/lite_argus_result.dart';

/// Service that generates Turkish educational insights from analysis results
/// Tone: Helpful coach, NOT trading advisor
class AnalysisExplainerService {
  /// Generate insights from analysis result
  List<ArgusInsight> generateInsights(LiteArgusResult result) {
    final insights = <ArgusInsight>[];

    // Analyze each component and generate insights
    insights.addAll(_analyzeTrend(result));
    insights.addAll(_analyzeMomentum(result));
    insights.addAll(_analyzeRisk(result));
    insights.addAll(_analyzeOverallHealth(result));

    return insights;
  }

  /// Analyze trend and generate insights
  List<ArgusInsight> _analyzeTrend(LiteArgusResult result) {
    final insights = <ArgusInsight>[];

    if (result.trendScore >= 80) {
      insights.add(const ArgusInsight(
        title: 'Trend Güçlü',
        body:
            'Fiyat, son dönemde ortalamalarının üzerinde seyrediyor. Bu genelde ilginin arttığını gösterir.',
        severity: InsightSeverity.positive,
        icon: Icons.trending_up,
      ));
    } else if (result.trendScore >= 55) {
      insights.add(const ArgusInsight(
        title: 'Pozitif Sinyal',
        body:
            'Fiyat ortalamasının üzerinde ama henüz güçlü bir trend oluşmamış.',
        severity: InsightSeverity.neutral,
        icon: Icons.show_chart,
      ));
    } else if (result.trendScore >= 40) {
      insights.add(const ArgusInsight(
        title: 'Kararsız Hareket',
        body: 'Fiyat belirli bir yön gösteremiyor. Piyasa kararsız görünüyor.',
        severity: InsightSeverity.neutral,
        icon: Icons.trending_flat,
      ));
    } else {
      insights.add(const ArgusInsight(
        title: 'Zayıf Trend',
        body:
            'Fiyat ortalamalarının altında seyrediyor. İlgi azalmış olabilir.',
        severity: InsightSeverity.caution,
        icon: Icons.trending_down,
      ));
    }

    return insights;
  }

  /// Analyze momentum and generate insights
  List<ArgusInsight> _analyzeMomentum(LiteArgusResult result) {
    final insights = <ArgusInsight>[];

    if (result.momentumScore >= 70) {
      insights.add(const ArgusInsight(
        title: 'Güçlü Momentum',
        body:
            'Son 30 günde belirgin bir hareket var. Fiyat hız kazanmış görünüyor.',
        severity: InsightSeverity.positive,
        icon: Icons.rocket_launch,
      ));
    } else if (result.momentumScore <= 30) {
      insights.add(const ArgusInsight(
        title: 'Zayıf Momentum',
        body: 'Son 30 günde düşüş yaşanmış. Hareket yavaşlamış görünüyor.',
        severity: InsightSeverity.caution,
        icon: Icons.pause_circle,
      ));
    } else {
      insights.add(const ArgusInsight(
        title: 'Momentum Dengeli',
        body:
            'Son haftalarda fiyat belirgin bir hız kazanmış ya da kaybetmiş görünmüyor.',
        severity: InsightSeverity.neutral,
        icon: Icons.horizontal_rule,
      ));
    }

    return insights;
  }

  /// Analyze risk and generate insights
  List<ArgusInsight> _analyzeRisk(LiteArgusResult result) {
    final insights = <ArgusInsight>[];

    if (result.riskScore >= 70) {
      insights.add(const ArgusInsight(
        title: 'Yüksek Oynaklık',
        body:
            'Fiyat kısa sürede hızlı değişiyor. Bu durum hem fırsat hem de stres anlamına gelebilir.',
        severity: InsightSeverity.negative,
        icon: Icons.warning_amber,
      ));
    } else if (result.riskScore <= 40) {
      insights.add(const ArgusInsight(
        title: 'Düşük Oynaklık',
        body:
            'Fiyat sakin seyrediyor. Daha öngörülebilir hareketler gözlemleniyor.',
        severity: InsightSeverity.positive,
        icon: Icons.security,
      ));
    } else {
      insights.add(const ArgusInsight(
        title: 'Orta Oynaklık',
        body:
            'Fiyat normal ölçüde dalgalanıyor. Ne çok sakin ne de çok hareketli.',
        severity: InsightSeverity.neutral,
        icon: Icons.waves,
      ));
    }

    return insights;
  }

  /// Analyze overall health and generate summary
  List<ArgusInsight> _analyzeOverallHealth(LiteArgusResult result) {
    final insights = <ArgusInsight>[];

    if (result.overallHealth >= 70) {
      // Strong overall
      if (result.riskScore >= 70) {
        insights.add(const ArgusInsight(
          title: 'Güçlü Ama Dalgalı',
          body:
              'Genel tablo iyi görünse de oynaklık yüksek. Dalgalanmalara hazırlıklı olunmalı.',
          severity: InsightSeverity.caution,
          icon: Icons.info_outline,
        ));
      } else {
        insights.add(const ArgusInsight(
          title: 'Dengeli Görünüm',
          body: 'Hem trend hem momentum olumlu, oynaklık makul seviyede.',
          severity: InsightSeverity.positive,
          icon: Icons.check_circle_outline,
        ));
      }
    } else if (result.overallHealth <= 40) {
      // Weak overall
      insights.add(const ArgusInsight(
        title: 'Zayıf Performans',
        body: 'Genel tablo olumsuz görünüyor. Daha iyi zamanlar beklenebilir.',
        severity: InsightSeverity.negative,
        icon: Icons.sentiment_dissatisfied,
      ));
    } else {
      // Neutral overall
      if (result.trendScore >= 50 && result.riskScore >= 70) {
        insights.add(const ArgusInsight(
          title: 'Potansiyel Var, Oynaklık Yüksek',
          body: 'Trend olumlu ama oynaklık fazla. Dikkatli takip önerilir.',
          severity: InsightSeverity.neutral,
          icon: Icons.balance,
        ));
      } else {
        insights.add(const ArgusInsight(
          title: 'Nötr Durum',
          body:
              'Belirgin bir yön veya hareket görülmüyor. Durum netleşene kadar takip edilebilir.',
          severity: InsightSeverity.neutral,
          icon: Icons.remove_circle_outline,
        ));
      }
    }

    return insights;
  }

  /// Generate a one-line coach summary
  String generateCoachSummary(LiteArgusResult result) {
    if (result.overallHealth >= 70 && result.riskScore < 50) {
      return 'Bu varlık şu an dengeli ve sakin görünüyor.';
    } else if (result.overallHealth >= 70 && result.riskScore >= 50) {
      return 'Genel tablo olumlu ancak oynaklık dikkat gerektiriyor.';
    } else if (result.overallHealth <= 40) {
      return 'Genel tablo zayıf görünüyor, beklemek düşünülebilir.';
    } else if (result.trendScore >= 60) {
      return 'Trend pozitif ama henüz netleşmiş değil.';
    } else if (result.riskScore >= 70) {
      return 'Yüksek oynaklık gözlemleniyor, dikkatli takip önerilir.';
    } else {
      return 'Bu varlık şu anda dengeli ancak dalgalanmalara açık görünüyor.';
    }
  }
}

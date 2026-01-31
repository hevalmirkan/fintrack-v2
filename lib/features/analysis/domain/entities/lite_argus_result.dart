import 'package:equatable/equatable.dart';

import 'argus_insight.dart';

/// Confidence level for analysis
enum ConfidenceLevel {
  low,
  medium,
  high,
}

extension ConfidenceLevelExtension on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.low:
        return 'Düşük Güven';
      case ConfidenceLevel.medium:
        return 'Orta Güven';
      case ConfidenceLevel.high:
        return 'Yüksek Güven';
    }
  }
}

/// Data quality indicator
enum DataQuality {
  good, // Real market data
  limited, // Partial/incomplete data
  mock, // Simulated/test data
}

extension DataQualityExtension on DataQuality {
  String get label {
    switch (this) {
      case DataQuality.good:
        return 'Gerçek Veri';
      case DataQuality.limited:
        return 'Sınırlı Veri';
      case DataQuality.mock:
        return 'Simülasyon';
    }
  }

  String get description {
    switch (this) {
      case DataQuality.good:
        return 'Güncel piyasa verilerine dayalı';
      case DataQuality.limited:
        return 'Kısmi veri ile hesaplandı';
      case DataQuality.mock:
        return 'Test amaçlı örnek verilerle üretildi';
    }
  }
}

/// Result of LITE ARGUS analysis
class LiteArgusResult extends Equatable {
  /// Overall health score (0-100)
  final double overallHealth;

  /// Trend strength score (0-100)
  final double trendScore;

  /// Momentum score (0-100)
  final double momentumScore;

  /// Risk/Volatility score (0-100)
  final double riskScore;

  /// SMA20 value
  final double sma20;

  /// SMA50 value
  final double sma50;

  /// Current price
  final double currentPrice;

  /// When was this analysis generated
  final DateTime generatedAt;

  /// How confident are we in this analysis
  final ConfidenceLevel confidenceLevel;

  /// Quality of the underlying data
  final DataQuality dataQuality;

  /// Generated insights
  final List<ArgusInsight> insights;

  const LiteArgusResult({
    required this.overallHealth,
    required this.trendScore,
    required this.momentumScore,
    required this.riskScore,
    required this.sma20,
    required this.sma50,
    required this.currentPrice,
    required this.generatedAt,
    required this.confidenceLevel,
    required this.dataQuality,
    required this.insights,
  });

  /// Helper: Get health status label
  String get healthLabel {
    if (overallHealth >= 70) return 'Güçlü';
    if (overallHealth >= 40) return 'Nötr';
    return 'Zayıf';
  }

  /// Helper: Get trend label
  String get trendLabel {
    if (trendScore >= 70) return 'Güçlü Yükseliş';
    if (trendScore >= 40) return 'Yatay/Kararsız';
    return 'Düşüş Eğilimi';
  }

  /// Helper: Get risk label
  String get riskLabel {
    if (riskScore >= 70) return 'Yüksek Risk';
    if (riskScore >= 40) return 'Orta Risk';
    return 'Düşük Risk';
  }

  @override
  List<Object?> get props => [
        overallHealth,
        trendScore,
        momentumScore,
        riskScore,
        sma20,
        sma50,
        currentPrice,
        generatedAt,
        confidenceLevel,
        dataQuality,
        insights,
      ];
}

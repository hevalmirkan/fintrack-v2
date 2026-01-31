import 'dart:math';

import '../entities/lite_argus_result.dart';
import '../entities/argus_insight.dart';

/// LITE ARGUS: Simple technical analysis service
/// Calculates trend, momentum, and risk scores from price data
class LiteArgusService {
  /// Analyze price data and generate scores
  ///
  /// [prices]: List of historical prices (newest first)
  /// [currentPrice]: Current/latest price
  /// [isMockData]: Whether the data is simulated
  LiteArgusResult analyze({
    required List<double> prices,
    required double currentPrice,
    bool isMockData = false,
  }) {
    // Need at least 50 data points for SMA50
    if (prices.length < 50) {
      return _generateInsufficientDataResult(currentPrice, isMockData);
    }

    // Calculate SMAs
    final sma20 = _calculateSMA(prices, 20);
    final sma50 = _calculateSMA(prices, 50);

    // Calculate scores
    final trendScore = _calculateTrendScore(currentPrice, sma20, sma50);
    final momentumScore = _calculateMomentumScore(prices);
    final riskScore = _calculateRiskScore(prices);

    // Overall health: Weighted average
    // Trend: 40%, Momentum: 30%, Stability: 30% (100 - riskScore)
    final overallHealth =
        ((trendScore * 0.4) + (momentumScore * 0.3) + ((100 - riskScore) * 0.3))
            .clamp(0.0, 100.0);

    // Determine confidence based on data points
    final confidence = prices.length >= 60
        ? ConfidenceLevel.high
        : prices.length >= 50
            ? ConfidenceLevel.medium
            : ConfidenceLevel.low;

    return LiteArgusResult(
      overallHealth: overallHealth,
      trendScore: trendScore,
      momentumScore: momentumScore,
      riskScore: riskScore,
      sma20: sma20,
      sma50: sma50,
      currentPrice: currentPrice,
      generatedAt: DateTime.now(),
      confidenceLevel: confidence,
      dataQuality: isMockData ? DataQuality.mock : DataQuality.good,
      insights: [], // Will be filled by AnalysisExplainerService
    );
  }

  /// Calculate Simple Moving Average
  double _calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return 0.0;

    final relevantPrices = prices.take(period).toList();
    final sum = relevantPrices.reduce((a, b) => a + b);
    return sum / period;
  }

  /// Calculate Trend Score (0-100)
  /// Based on relationship between Price, SMA20, SMA50
  double _calculateTrendScore(double price, double sma20, double sma50) {
    // Strong uptrend: Price > SMA20 > SMA50
    if (price > sma20 && sma20 > sma50) {
      // Calculate strength based on distances
      final pricePremium = ((price - sma20) / sma20 * 100).clamp(0.0, 20.0);
      return (80 + pricePremium).clamp(0.0, 100.0);
    }

    // Strong downtrend: Price < SMA20 < SMA50
    if (price < sma20 && sma20 < sma50) {
      // Calculate weakness based on distances
      final priceDiscount = ((sma20 - price) / sma20 * 100).clamp(0.0, 20.0);
      return (40 - priceDiscount).clamp(0.0, 100.0);
    }

    // Neutral/Choppy: Mixed signals
    // Base on price vs SMA20 only
    if (price > sma20) {
      return 55.0 + ((price - sma20) / sma20 * 15).clamp(0.0, 15.0);
    } else {
      return 45.0 - ((sma20 - price) / sma20 * 15).clamp(0.0, 15.0);
    }
  }

  /// Calculate Momentum Score (0-100)
  /// Based on 30-day performance
  double _calculateMomentumScore(List<double> prices) {
    if (prices.length < 30) return 50.0;

    final current = prices.first;
    final thirtyDaysAgo = prices[min(29, prices.length - 1)];

    // Calculate return percentage
    final returnPercent = ((current - thirtyDaysAgo) / thirtyDaysAgo) * 100;

    // Map to 0-100 scale
    // Strong negative (-20% or worse) = 0
    // Neutral (0%) = 50
    // Strong positive (+20% or better) = 100
    if (returnPercent >= 20) return 100.0;
    if (returnPercent <= -20) return 0.0;

    // Linear mapping for -20% to +20%
    return ((returnPercent + 20) / 40 * 100).clamp(0.0, 100.0);
  }

  /// Calculate Risk Score (0-100)
  /// Based on volatility (standard deviation of returns)
  double _calculateRiskScore(List<double> prices) {
    if (prices.length < 30) return 50.0;

    // Calculate daily returns for last 30 days
    final returns = <double>[];
    for (int i = 0; i < min(29, prices.length - 1); i++) {
      final dailyReturn = ((prices[i] - prices[i + 1]) / prices[i + 1]) * 100;
      returns.add(dailyReturn);
    }

    // Calculate standard deviation
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) /
            returns.length;
    final stdDev = sqrt(variance);

    // Map volatility to risk score
    // Low volatility (< 2% daily) = Low risk (0-40)
    // Medium volatility (2-5% daily) = Medium risk (40-70)
    // High volatility (> 5% daily) = High risk (70-100)
    if (stdDev <= 2.0) {
      return (stdDev / 2.0 * 40).clamp(0.0, 40.0);
    } else if (stdDev <= 5.0) {
      return (40 + ((stdDev - 2.0) / 3.0 * 30)).clamp(40.0, 70.0);
    } else {
      return (70 + ((stdDev - 5.0) / 5.0 * 30).clamp(0.0, 30.0))
          .clamp(70.0, 100.0);
    }
  }

  /// Generate minimal result when insufficient data
  LiteArgusResult _generateInsufficientDataResult(
      double currentPrice, bool isMockData) {
    return LiteArgusResult(
      overallHealth: 50.0,
      trendScore: 50.0,
      momentumScore: 50.0,
      riskScore: 50.0,
      sma20: currentPrice,
      sma50: currentPrice,
      currentPrice: currentPrice,
      generatedAt: DateTime.now(),
      confidenceLevel: ConfidenceLevel.low,
      dataQuality: isMockData ? DataQuality.mock : DataQuality.limited,
      insights: [],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../market/domain/models/market_asset.dart';
import '../entities/lite_argus_result.dart';
import 'council_narrative_service.dart';

/// Scout Category - Visual categorization for the Stories Bar
enum ScoutCategory {
  portfolio, // 💼 User's own assets - always VIP
  watchlist, // 👁️ User's watchlist - priority #2
  momentum, // 🚀 High momentum from market
  risk, // ⚠️ High volatility alert
  trend, // 📈 Strong trend
  discovery, // 🔍 General market discovery
}

extension ScoutCategoryExtension on ScoutCategory {
  String get label {
    switch (this) {
      case ScoutCategory.portfolio:
        return 'Portföy';
      case ScoutCategory.watchlist:
        return 'İzleme';
      case ScoutCategory.momentum:
        return 'Momentum';
      case ScoutCategory.risk:
        return 'Dikkat';
      case ScoutCategory.trend:
        return 'Trend';
      case ScoutCategory.discovery:
        return 'Keşif';
    }
  }

  String get emoji {
    switch (this) {
      case ScoutCategory.portfolio:
        return '💼';
      case ScoutCategory.watchlist:
        return '👁️';
      case ScoutCategory.momentum:
        return '🚀';
      case ScoutCategory.risk:
        return '⚠️';
      case ScoutCategory.trend:
        return '📈';
      case ScoutCategory.discovery:
        return '🔍';
    }
  }

  Color get defaultColor {
    switch (this) {
      case ScoutCategory.portfolio:
        return const Color(0xFF00D09C); // Green VIP
      case ScoutCategory.watchlist:
        return const Color(0xFF3B82F6); // Blue
      case ScoutCategory.momentum:
        return const Color(0xFF7C3AED); // Purple
      case ScoutCategory.risk:
        return const Color(0xFFF59E0B); // Orange
      case ScoutCategory.trend:
        return const Color(0xFF00D09C); // Green
      case ScoutCategory.discovery:
        return const Color(0xFF6B7280); // Grey
    }
  }

  /// Priority for sorting (higher = shown first)
  int get priority {
    switch (this) {
      case ScoutCategory.portfolio:
        return 100; // Always first
      case ScoutCategory.watchlist:
        return 90;
      case ScoutCategory.risk:
        return 80; // Show tension first
      case ScoutCategory.momentum:
        return 70;
      case ScoutCategory.trend:
        return 60;
      case ScoutCategory.discovery:
        return 50;
    }
  }
}

/// Scout Result - Individual item in the Scout feed
class ScoutResult {
  final MarketAsset asset;
  final ScoutCategory category;
  final ScoutArgusData argusData;
  final CouncilNarrative narrative;
  final double? lastPrice;
  final double? changePercent;
  final bool isUserAsset;
  final bool isWatchlist;

  const ScoutResult({
    required this.asset,
    required this.category,
    required this.argusData,
    required this.narrative,
    this.lastPrice,
    this.changePercent,
    this.isUserAsset = false,
    this.isWatchlist = false,
  });

  String get label => category.label;
  Color get ringColor => narrative.ringColor;
  bool get shouldPulse => argusData.overallScore >= 80 || isUserAsset;
}

/// Lightweight Argus data for Scout
class ScoutArgusData {
  final int trendScore;
  final int momentumScore;
  final int riskScore;
  final int overallScore;

  const ScoutArgusData({
    required this.trendScore,
    required this.momentumScore,
    required this.riskScore,
    required this.overallScore,
  });

  /// Convert from LiteArgusResult
  factory ScoutArgusData.fromLiteArgus(LiteArgusResult result) {
    return ScoutArgusData(
      trendScore: result.trendScore.toInt(),
      momentumScore: result.momentumScore.toInt(),
      riskScore: result.riskScore.toInt(),
      overallScore: result.overallHealth.toInt(),
    );
  }

  /// Create synthetic data from price change
  factory ScoutArgusData.fromPriceChange(double changePercent) {
    final change = changePercent;

    // Trend score based on direction
    int trendScore;
    if (change >= 3) {
      trendScore = 85;
    } else if (change >= 1.5) {
      trendScore = 75;
    } else if (change >= 0.5) {
      trendScore = 65;
    } else if (change >= -0.5) {
      trendScore = 55;
    } else if (change >= -1.5) {
      trendScore = 45;
    } else if (change >= -3) {
      trendScore = 35;
    } else {
      trendScore = 20;
    }

    // Momentum from absolute change
    final absChange = change.abs();
    int momentumScore;
    if (absChange >= 5) {
      momentumScore = 95;
    } else if (absChange >= 3) {
      momentumScore = 85;
    } else if (absChange >= 2) {
      momentumScore = 75;
    } else if (absChange >= 1) {
      momentumScore = 65;
    } else if (absChange >= 0.5) {
      momentumScore = 55;
    } else {
      momentumScore = 40;
    }

    // Risk from volatility
    int riskScore;
    if (absChange >= 8) {
      riskScore = 90;
    } else if (absChange >= 5) {
      riskScore = 75;
    } else if (absChange >= 3) {
      riskScore = 60;
    } else if (absChange >= 1) {
      riskScore = 40;
    } else {
      riskScore = 25;
    }

    // Overall weighted
    final overallScore = ((trendScore * 0.35) +
            (momentumScore * 0.4) +
            ((100 - riskScore) * 0.25))
        .round()
        .clamp(0, 100);

    return ScoutArgusData(
      trendScore: trendScore,
      momentumScore: momentumScore,
      riskScore: riskScore,
      overallScore: overallScore,
    );
  }
}

/// Scout Service V2 - Personal Market Radar
///
/// Priority Rules:
/// 1. USER FIRST - Portfolio assets always included
/// 2. WATCHLIST - User's tracked assets
/// 3. MARKET FILL - Only if high score/momentum
///
/// Sorting: Tension first (Risk, Momentum), then calm (Trend)
class ScoutService {
  static const int maxResults = 8;
  static const int minResults = 5;

  final CouncilNarrativeService _narrativeService;

  ScoutService({CouncilNarrativeService? narrativeService})
      : _narrativeService = narrativeService ?? const CouncilNarrativeService();

  /// Build personalized Scout feed
  List<ScoutResult> buildScoutFeed({
    required List<AnalyzedAsset> allAssets,
    Set<String> portfolioAssetIds = const {},
    Set<String> watchlistAssetIds = const {},
  }) {
    final portfolioResults = <ScoutResult>[];
    final watchlistResults = <ScoutResult>[];
    final marketResults = <ScoutResult>[];

    print('[Scout] 🎯 Building feed: ${allAssets.length} assets, '
        '${portfolioAssetIds.length} portfolio, ${watchlistAssetIds.length} watchlist');

    for (final analyzed in allAssets) {
      final isPortfolio = portfolioAssetIds.contains(analyzed.asset.id);
      final isWatchlist = watchlistAssetIds.contains(analyzed.asset.id);

      // Generate council narrative
      final fakeArgusResult = _createFakeLiteArgusResult(analyzed.argusData);
      final narrative =
          _narrativeService.buildCouncilNarrative(fakeArgusResult);

      if (isPortfolio) {
        // VIP: Always include portfolio assets
        portfolioResults.add(ScoutResult(
          asset: analyzed.asset,
          category: ScoutCategory.portfolio,
          argusData: analyzed.argusData,
          narrative: narrative,
          lastPrice: analyzed.lastPrice,
          changePercent: analyzed.changePercent,
          isUserAsset: true,
          isWatchlist: false,
        ));
      } else if (isWatchlist) {
        // Priority 2: Watchlist assets
        watchlistResults.add(ScoutResult(
          asset: analyzed.asset,
          category: ScoutCategory.watchlist,
          argusData: analyzed.argusData,
          narrative: narrative,
          lastPrice: analyzed.lastPrice,
          changePercent: analyzed.changePercent,
          isUserAsset: false,
          isWatchlist: true,
        ));
      } else {
        // Market: Only add if interesting
        final category = _categorizeMarketAsset(analyzed.argusData);
        if (category != null) {
          marketResults.add(ScoutResult(
            asset: analyzed.asset,
            category: category,
            argusData: analyzed.argusData,
            narrative: narrative,
            lastPrice: analyzed.lastPrice,
            changePercent: analyzed.changePercent,
            isUserAsset: false,
            isWatchlist: false,
          ));
        }
      }
    }

    // Combine with VIP priority
    final results = <ScoutResult>[];

    // Add all portfolio (VIP)
    results.addAll(portfolioResults);

    // Add all watchlist
    results.addAll(watchlistResults);

    // Fill with market until maxResults
    if (results.length < maxResults) {
      // Sort market: Tension first (high risk, high momentum)
      marketResults.sort((a, b) {
        // Risk first (tension)
        if (a.argusData.riskScore >= 70 && b.argusData.riskScore < 70)
          return -1;
        if (b.argusData.riskScore >= 70 && a.argusData.riskScore < 70) return 1;

        // Then momentum
        if (a.argusData.momentumScore >= 70 && b.argusData.momentumScore < 70)
          return -1;
        if (b.argusData.momentumScore >= 70 && a.argusData.momentumScore < 70)
          return 1;

        // Then overall score
        return b.argusData.overallScore.compareTo(a.argusData.overallScore);
      });

      final remaining = maxResults - results.length;
      results.addAll(marketResults.take(remaining));
    }

    // Final sort within each tier
    results.sort((a, b) {
      // VIP always first
      if (a.isUserAsset && !b.isUserAsset) return -1;
      if (!a.isUserAsset && b.isUserAsset) return 1;

      // Watchlist second
      if (a.isWatchlist && !b.isWatchlist) return -1;
      if (!a.isWatchlist && b.isWatchlist) return 1;

      // Then by category priority
      return b.category.priority.compareTo(a.category.priority);
    });

    print('[Scout] ✅ Feed built: ${portfolioResults.length} VIP + '
        '${watchlistResults.length} watchlist + '
        '${results.length - portfolioResults.length - watchlistResults.length} market');

    return results.take(maxResults).toList();
  }

  /// Categorize market asset based on signals
  ScoutCategory? _categorizeMarketAsset(ScoutArgusData data) {
    // Only include if interesting enough

    // High risk = show as alert
    if (data.riskScore >= 70) {
      return ScoutCategory.risk;
    }

    // High momentum = show as opportunity
    if (data.momentumScore >= 70) {
      return ScoutCategory.momentum;
    }

    // Strong trend + low risk
    if (data.trendScore >= 65 && data.riskScore < 45) {
      return ScoutCategory.trend;
    }

    // High overall score
    if (data.overallScore >= 70) {
      return ScoutCategory.discovery;
    }

    // Not interesting enough
    return null;
  }

  /// Create fake LiteArgusResult for narrative generation
  LiteArgusResult _createFakeLiteArgusResult(ScoutArgusData data) {
    return LiteArgusResult(
      overallHealth: data.overallScore.toDouble(),
      trendScore: data.trendScore.toDouble(),
      momentumScore: data.momentumScore.toDouble(),
      riskScore: data.riskScore.toDouble(),
      sma20: 0,
      sma50: 0,
      currentPrice: 0,
      generatedAt: DateTime.now(),
      confidenceLevel: ConfidenceLevel.medium,
      dataQuality: DataQuality.good,
      insights: [],
    );
  }
}

/// Combined asset with analysis data
class AnalyzedAsset {
  final MarketAsset asset;
  final ScoutArgusData argusData;
  final double? lastPrice;
  final double? changePercent;

  const AnalyzedAsset({
    required this.asset,
    required this.argusData,
    this.lastPrice,
    this.changePercent,
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lite_argus_result.dart';
import '../../domain/services/analysis_explainer_service.dart';
import '../../domain/services/lite_argus_service.dart';
import '../../../market/data/services/market_data_service.dart';
import '../../../market/data/static/market_catalog.dart';
import '../../../market/domain/entities/candle.dart';

// Service Providers
final liteArgusServiceProvider = Provider((ref) => LiteArgusService());

final analysisExplainerServiceProvider =
    Provider((ref) => AnalysisExplainerService());

final marketDataServiceProvider = Provider((ref) => MarketDataService());

// Analysis Provider - CONNECTED TO REAL DATA VIA MARKET CATALOG
final liteArgusAnalysisProvider =
    FutureProvider.family<LiteArgusResult, String>((ref, symbol) async {
  final argusService = ref.read(liteArgusServiceProvider);
  final explainerService = ref.read(analysisExplainerServiceProvider);
  final marketDataService = ref.read(marketDataServiceProvider);

  bool isMockData = false;
  List<Candle> candles = [];

  try {
    // Find asset in catalog by symbol
    final marketAsset = MarketCatalog.findBySymbol(symbol);

    if (marketAsset == null) {
      print(
          '[ArgusProvider] ⚠️ Symbol $symbol not in catalog, returning limited analysis');
      isMockData = true;
    } else {
      print(
          '[ArgusProvider] 📈 Fetching candles for ${marketAsset.name} (${marketAsset.id})');

      // Fetch REAL historical data using verified MarketAsset
      candles = await marketDataService.fetchCandlesForAsset(
        asset: marketAsset,
        days: 60,
      );

      print('[ArgusProvider] ✅ Got ${candles.length} real candles for $symbol');
    }
  } catch (e) {
    print('[ArgusProvider] ❌ Real data fetch failed: $e');
    isMockData = true;
  }

  // Validate we have enough data
  if (candles.isEmpty) {
    // Return result with low confidence indicating no data
    final emptyResult = LiteArgusResult(
      overallHealth: 50.0,
      trendScore: 50.0,
      momentumScore: 50.0,
      riskScore: 50.0,
      sma20: 0.0,
      sma50: 0.0,
      currentPrice: 0.0,
      generatedAt: DateTime.now(),
      confidenceLevel: ConfidenceLevel.low,
      dataQuality: DataQuality.limited,
      insights: [],
    );

    // Add warning insight
    final insights = explainerService.generateInsights(emptyResult);
    return LiteArgusResult(
      overallHealth: emptyResult.overallHealth,
      trendScore: emptyResult.trendScore,
      momentumScore: emptyResult.momentumScore,
      riskScore: emptyResult.riskScore,
      sma20: emptyResult.sma20,
      sma50: emptyResult.sma50,
      currentPrice: emptyResult.currentPrice,
      generatedAt: emptyResult.generatedAt,
      confidenceLevel: ConfidenceLevel.low,
      dataQuality: DataQuality.limited,
      insights: insights,
    );
  }

  // Extract close prices from candles (newest first)
  final prices = candles.map((c) => c.close).toList();
  final currentPrice = prices.first;

  // Determine data quality
  final dataQuality = isMockData
      ? DataQuality.mock
      : (candles.length >= 50 ? DataQuality.good : DataQuality.limited);

  // Run ARGUS analysis with REAL data
  var result = argusService.analyze(
    prices: prices,
    currentPrice: currentPrice,
    isMockData: isMockData,
  );

  // Generate educational insights
  final insights = explainerService.generateInsights(result);

  // Return complete result
  return LiteArgusResult(
    overallHealth: result.overallHealth,
    trendScore: result.trendScore,
    momentumScore: result.momentumScore,
    riskScore: result.riskScore,
    sma20: result.sma20,
    sma50: result.sma50,
    currentPrice: result.currentPrice,
    generatedAt: DateTime.now(),
    confidenceLevel:
        candles.length >= 50 ? ConfidenceLevel.high : ConfidenceLevel.medium,
    dataQuality: dataQuality,
    insights: insights,
  );
});

// Coach Summary Provider
final coachSummaryProvider =
    Provider.family<String, LiteArgusResult>((ref, result) {
  final explainer = ref.read(analysisExplainerServiceProvider);
  return explainer.generateCoachSummary(result);
});

// Provider to check if symbol is in catalog
final isInCatalogProvider = Provider.family<bool, String>((ref, symbol) {
  return MarketCatalog.findBySymbol(symbol) != null;
});

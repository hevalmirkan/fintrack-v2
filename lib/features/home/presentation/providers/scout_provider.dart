import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../market/domain/models/market_asset.dart';
import '../../../market/presentation/screens/market_board_screen.dart';
import '../../../portfolio/data/portfolio_provider.dart';
import '../../../analysis/domain/services/scout_service.dart';

/// Provider for Scout results - Personal Market Radar
///
/// Priority Rules:
/// 1. Portfolio assets (VIP - always shown)
/// 2. Watchlist assets (priority #2)
/// 3. Market fillers (only if interesting)
final scoutResultsProvider =
    FutureProvider.autoDispose<List<ScoutResult>>((ref) async {
  // Get market data
  final marketBoardAsync = ref.watch(marketBoardProvider);

  // Get user's portfolio symbols from REACTIVE Notifier
  final userPortfolioSymbols = ref.watch(userPortfolioSymbolsProvider);

  return marketBoardAsync.when(
    data: (state) {
      print(
          '[Scout] 📊 Processing ${state.quotes.length} quotes (${userPortfolioSymbols.length} portfolio items)');

      if (state.quotes.isEmpty) {
        print('[Scout] ⚠️ No quotes available');
        return <ScoutResult>[];
      }

      final scoutService = ScoutService();
      final analyzedAssets = <AnalyzedAsset>[];
      final portfolioAssetIds = <String>{};
      final watchlistAssetIds = <String>{}; // TODO: Implement watchlist

      // Process each successful quote
      int successCount = 0;
      for (final quote in state.quotes) {
        if (!quote.isSuccess) continue;
        successCount++;

        // Check if this is a user's portfolio asset (REACTIVE)
        final isPortfolioAsset =
            userPortfolioSymbols.contains(quote.asset.symbol.toLowerCase());
        if (isPortfolioAsset) {
          portfolioAssetIds.add(quote.asset.id);
        }

        // Generate Argus data from price change
        final argusData =
            ScoutArgusData.fromPriceChange(quote.changePercent24h ?? 0.0);

        analyzedAssets.add(AnalyzedAsset(
          asset: quote.asset,
          argusData: argusData,
          lastPrice: quote.price,
          changePercent: quote.changePercent24h,
        ));
      }

      print(
          '[Scout] ✅ Analyzed $successCount quotes, ${portfolioAssetIds.length} are portfolio items');

      // Build personalized Scout feed
      final results = scoutService.buildScoutFeed(
        allAssets: analyzedAssets,
        portfolioAssetIds: portfolioAssetIds,
        watchlistAssetIds: watchlistAssetIds,
      );

      print('[Scout] 🎯 Feed built: ${results.length} items');
      for (final r in results) {
        print(
            '[Scout]   - ${r.asset.symbol} (${r.label}): ${r.narrative.headline}');
      }

      return results;
    },
    loading: () {
      print('[Scout] ⏳ Waiting for market data...');
      return <ScoutResult>[];
    },
    error: (e, __) {
      print('[Scout] ❌ Error: $e');
      return <ScoutResult>[];
    },
  );
});

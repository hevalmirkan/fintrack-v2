/// =====================================================
/// MOBILE MARKET PROVIDER — Phase 8.5
/// =====================================================
/// Riverpod provider for mobile market data.
/// =====================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mobile_market_service.dart';

/// Mobile market service instance
final mobileMarketServiceProvider = Provider<MobileMarketService>((ref) {
  return MobileMarketService();
});

/// Mobile market state provider
final mobileMarketProvider =
    FutureProvider.autoDispose<MobileMarketState>((ref) async {
  final service = ref.read(mobileMarketServiceProvider);
  await service.init();
  return await service.fetchAll();
});

/// Force refresh provider
final mobileMarketRefreshProvider =
    FutureProvider.family<MobileMarketState, bool>((ref, forceRefresh) async {
  final service = ref.read(mobileMarketServiceProvider);
  await service.init();
  return await service.fetchAll(forceRefresh: forceRefresh);
});

/// Single quote provider
final mobileQuoteProvider =
    Provider.family<MobileQuote?, String>((ref, assetId) {
  final state = ref.watch(mobileMarketProvider);
  return state.whenOrNull(
    data: (data) => data[assetId],
  );
});

/// USD/TRY rate provider (for conversions)
final usdTryRateProvider = Provider<double>((ref) {
  final state = ref.watch(mobileMarketProvider);
  return state.whenOrNull(
        data: (data) => data.usdTryRate,
      ) ??
      35.5; // Fallback rate
});

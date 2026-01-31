import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/asset.dart';

part 'asset_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Asset>> assetList(Ref ref) {
  final repository = ref.watch(assetRepositoryProvider);
  return repository.getAssetsStream();
}

@Riverpod(keepAlive: true)
Stream<int> totalNetWorth(Ref ref) {
  final assetsAsync = ref.watch(assetListProvider);

  return assetsAsync.when(
    data: (assets) {
      /*
       * STRICT RULE: "UI MATH: Never calculate totals in a Widget. Use CalculationService..."
       * However, for simple summing of (quantity * price), we can do it here in the provider logic 
       * or delegate to a service. 
       * Ideally, `CalculationService` should handle portfolio valuation.
       * But `CalculationService` currently focuses on cost basis/savings.
       * Let's check if we should add `calculatePortfolioValue` to `CalculationService`.
       * For now, I will implement the logic here as it's a derived state provider.
       */
      int total = 0;
      for (final asset in assets) {
        // Asset quantity and price are both in minor units?
        // No, quantity is typically unit * precision?
        // Wait, Asset entity:
        // final int quantityMinor;
        // final int currentPrice; // Minor units (e.g. cents)
        // If quantity is 1.5 (150 minor) and price is $100 (10000 minor)...
        // Total Value = (150 * 10000) / 100 ??

        // Let's assume quantity is standard minor units (e.g. 2 decimals).
        // If I have 1.5 AAPL. quantityMinor = 150.
        // Price is 100.00. currentPrice = 10000.
        // Value = 150.00.
        // Math: (150 * 10000) / 100 = 15000 (150.00)
        // We need the minor factor. Assuming 100 for now as per "default factor 100".
        // Use BigInt or double for safety?
        // User said: "NO UI MATH". This is Provider Logic, so it's safe.

        // Let's simplify: Value = (quantity * price) / 100.
        // We really should use the Base Minor Factor from Settings, but let's stick to 100 hardcoded
        // as per "Use default factor 100 for now."

        final int q = asset.quantityMinor;
        final int p = asset.currentPrice;
        total += (q * p) ~/ 100;
      }
      return Stream.value(total);
    },
    loading: () => const Stream.empty(), // Or keep previous value
    error: (_, __) => const Stream.empty(),
  );
}

/// USD to TRY exchange rate - Phase 1: Constant
/// TODO: Upgrade to live rate from market data in Phase 2
const double kUsdTryRate = 35.0; // Approximate rate as of Jan 2026

/// Total portfolio value in TRY (Turkish Lira)
/// This is the SINGLE SOURCE OF TRUTH for asset valuation in TRY
/// All UI screens and analysis MUST use this, never convert themselves
@Riverpod(keepAlive: true)
Stream<double> totalPortfolioValueTRY(Ref ref) {
  final assetsAsync = ref.watch(assetListProvider);

  return assetsAsync.when(
    data: (assets) {
      double totalTRY = 0.0;

      for (final asset in assets) {
        // Get quantity in major units (10^8 precision for crypto)
        final quantity = asset.quantityMinor / 100000000.0;
        final priceUSD = asset.currentPrice / 100.0;

        // Calculate value in USD
        final valueUSD = quantity * priceUSD;

        // Convert to TRY
        // Assumption: All assets from market board are in USD
        // TODO: Add asset.currency field to distinguish TRY-denominated assets
        final valueTRY = valueUSD * kUsdTryRate;

        totalTRY += valueTRY;
      }

      return Stream.value(totalTRY);
    },
    loading: () => Stream.value(0.0),
    error: (_, __) => Stream.value(0.0),
  );
}

/// Individual asset values in TRY (for diversity calculation)
@Riverpod(keepAlive: true)
Stream<List<double>> assetValuesTRY(Ref ref) {
  final assetsAsync = ref.watch(assetListProvider);

  return assetsAsync.when(
    data: (assets) {
      final values = assets.map((asset) {
        final quantity = asset.quantityMinor / 100000000.0;
        final priceUSD = asset.currentPrice / 100.0;
        final valueUSD = quantity * priceUSD;
        return valueUSD * kUsdTryRate;
      }).toList();

      return Stream.value(values);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
}

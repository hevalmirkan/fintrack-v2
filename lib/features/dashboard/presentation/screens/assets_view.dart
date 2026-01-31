import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assets/domain/entities/asset.dart';
import '../../../assets/presentation/providers/asset_providers.dart';

/// Assets View - Displays user's portfolio assets
///
/// Watches assetListProvider for reactive updates from Firestore
class AssetsView extends ConsumerWidget {
  const AssetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);

    return assetsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D09C)),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Varlıklar yüklenemedi',
                style: TextStyle(color: Colors.grey.shade300)),
            const SizedBox(height: 4),
            Text(error.toString(),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
      data: (assets) {
        if (assets.isEmpty) {
          return _buildEmptyState(context);
        }

        // Calculate total value (quantityMinor and price in cents, divide by 100)
        double totalValue = 0;
        for (final a in assets) {
          final amount = a.quantityMinor / 100000000.0; // 10^8 precision
          final price = (a.lastKnownPrice ?? a.averagePrice) / 100.0;
          totalValue += amount * price;
        }

        return Container(
          color: const Color(0xFF0D1117),
          child: Column(
            children: [
              _buildPortfolioHeader(totalValue, assets.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    return _buildAssetCard(context, assets[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz varlık eklenmedi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scout\'tan bir varlık ekleyerek başlayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioHeader(double totalValue, int assetCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2332), Color(0xFF161B22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portföy Değeri',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$assetCount varlık',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00D09C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, Asset asset) {
    // Calculate values from asset (quantity in 10^8 precision, price in cents)
    final amount = asset.quantityMinor / 100000000.0;
    final avgPrice = asset.averagePrice / 100.0;
    final totalValue = amount * avgPrice;

    // Get current price if available
    final currentPrice =
        asset.lastKnownPrice != null ? asset.lastKnownPrice! / 100.0 : avgPrice;
    final currentValue = amount * currentPrice;

    // Calculate P/L
    final pnl = currentValue - totalValue;
    final pnlPercent = totalValue > 0 ? (pnl / totalValue) * 100 : 0.0;
    final isProfit = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Asset Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D09C).withOpacity(0.2),
                      const Color(0xFF00D09C).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    asset.symbol.length > 2
                        ? asset.symbol.substring(0, 2)
                        : asset.symbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D09C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Asset Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      asset.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Value Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isProfit ? Colors.green : Colors.red)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isProfit ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFF30363D).withOpacity(0.5), height: 1),
          const SizedBox(height: 12),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dynamic formatting for crypto: 8 decimals for small amounts, 2 for large
              _buildDetailItem('Miktar', _formatAmount(amount)),
              _buildDetailItem(
                  'Ort. Maliyet', '\$${avgPrice.toStringAsFixed(2)}'),
              _buildDetailItem(
                  'Güncel Fiyat', '\$${currentPrice.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Dynamic decimal formatter for asset quantities
  /// Uses 8 decimals for small amounts (<0.01), 2 for larger
  /// Removes trailing zeros for cleaner display
  String _formatAmount(double amount) {
    if (amount == 0) return '0';
    if (amount >= 0.01) {
      return amount.toStringAsFixed(2);
    }
    // For small amounts, use up to 8 decimals and trim trailing zeros
    String s = amount.toStringAsFixed(8);
    // Remove trailing zeros
    s = s.replaceFirst(RegExp(r'0+$'), '');
    // Remove trailing dot if exists (e.g., "1." -> "1")
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
}

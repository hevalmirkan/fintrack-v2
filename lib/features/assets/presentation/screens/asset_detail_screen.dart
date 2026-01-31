import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/format_service.dart';
import '../../../market/domain/repositories/i_market_price_repository.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/asset.dart';
import '../../domain/services/portfolio_calculation_service.dart';
import '../providers/portfolio_providers.dart';
// ARGUS Analysis imports
import '../../../analysis/presentation/providers/argus_providers.dart';
import '../../../analysis/presentation/widgets/argus_dashboard.dart';
import '../../../analysis/domain/entities/lite_argus_result.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetRepo = ref.watch(assetRepositoryProvider);
    final calcService = ref.watch(portfolioCalculationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Varlık Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(context, ref, assetId),
          ),
        ],
      ),
      body: FutureBuilder<Asset?>(
        future: assetRepo.getAssetById(assetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Varlık bulunamadı'));
          }

          final asset = snapshot.data!;
          final profitLoss = calcService.calculateAssetProfitLoss(asset);

          return RefreshIndicator(
            onRefresh: () async {
              try {
                await ref.read(
                    refreshAssetPriceProvider(assetId, asset.symbol).future);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fiyat güncellenemedi: $e')),
                  );
                }
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Asset Header
                _buildHeaderCard(context, asset),
                const SizedBox(height: 16),

                // P/L Card
                _buildProfitLossCard(context, ref, profitLoss),
                const SizedBox(height: 16),

                // Price Comparison Card
                _buildPriceComparisonCard(context, ref, asset, profitLoss),
                const SizedBox(height: 16),

                // Quantity Card
                _buildQuantityCard(context, asset),
                const SizedBox(height: 16),

                // Last Update
                if (asset.hasMarketData) _buildLastUpdateCard(context, asset),
                const SizedBox(height: 24),

                // ARGUS Analysis Section
                _buildArgusAnalysisSection(context, ref, asset),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<Asset?>(
        future: assetRepo.getAssetById(assetId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final asset = snapshot.data!;

          return FloatingActionButton.extended(
            heroTag: 'fab_asset_detail',
            onPressed: () {
              _showPriceRefreshDialog(context, ref, assetId, asset.symbol);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Fiyat Güncelle'),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Asset asset) {
    final hasLiveTracking = asset.apiId != null && asset.apiId!.isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    asset.symbol,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    asset.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Live/Manual Tracking Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasLiveTracking
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasLiveTracking
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasLiveTracking ? Icons.cloud_done : Icons.edit_note,
                    size: 16,
                    color: hasLiveTracking ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasLiveTracking ? 'Canlı Veri' : 'Manuel Takip',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasLiveTracking ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitLossCard(
      BuildContext context, WidgetRef ref, AssetWithProfitLoss profitLoss) {
    final isProfit = profitLoss.isProfit;
    final color = isProfit ? Colors.green : Colors.red;
    final icon = isProfit ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProfit ? 'KÂR' : 'ZARAR',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                  Text(
                    'Güncel fiyata göre',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ref
                .read(formatServiceProvider)
                .formatCurrency(profitLoss.profitLoss.abs()),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isProfit ? '+' : ''}${profitLoss.profitLossPercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceComparisonCard(BuildContext context, WidgetRef ref,
      Asset asset, AssetWithProfitLoss profitLoss) {
    final fmt = ref.read(formatServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fiyat Karşılaştırması',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              context,
              'Ortalama Maliyet',
              fmt.formatCurrency(asset.averagePrice),
              Icons.calculate,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildPriceRow(
              context,
              'Güncel Fiyat',
              fmt.formatCurrency(asset.displayPrice),
              Icons.show_chart,
              profitLoss.isProfit ? Colors.green : Colors.red,
            ),
            const Divider(height: 24),
            _buildPriceRow(
              context,
              'Toplam Değer',
              fmt.formatCurrency(profitLoss.totalValue),
              Icons.account_balance_wallet,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildQuantityCard(BuildContext context, Asset asset) {
    final quantity = asset.quantityMinor / 100000000.0;
    final formattedQuantity = quantity == quantity.toInt()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.purple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Miktar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    formattedQuantity,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateCard(BuildContext context, Asset asset) {
    final lastUpdate = asset.lastPriceUpdate;
    final formattedDate = lastUpdate != null
        ? '${lastUpdate.day}.${lastUpdate.month}.${lastUpdate.year} ${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}'
        : 'Bilinmiyor';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            'Son güncelleme: $formattedDate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, String assetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varlığı Sil'),
        content: const Text(
            'Bu varlığı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(assetRepositoryProvider).deleteAsset(assetId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Varlık silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showPriceRefreshDialog(
      BuildContext context, WidgetRef ref, String assetId, String symbol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fiyat Güncelleniyor'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Piyasa verileri alınıyor...'),
          ],
        ),
      ),
    );

    ref.read(refreshAssetPriceProvider(assetId, symbol).future).then((_) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fiyat güncellendi ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Build the LITE ARGUS Analysis Section (Orion Dashboard)
  Widget _buildArgusAnalysisSection(
    BuildContext context,
    WidgetRef ref,
    Asset asset,
  ) {
    final analysisAsync = ref.watch(liteArgusAnalysisProvider(asset.symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_graph,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'LITE ARGUS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Finansal Koçunuz',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Analysis Content (Orion Dashboard)
        analysisAsync.when(
          data: (result) => Column(
            children: [
              // Data Quality Warning (if not good)
              if (result.dataQuality != DataQuality.good)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.dataQuality == DataQuality.mock
                              ? 'Gerçek piyasa verisi alınamadı. Analiz sınırlı olabilir.'
                              : 'Kısmi veri ile hesaplandı. Sonuçlar tam doğru olmayabilir.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

              // NEW: Orion-Style Argus Dashboard
              ArgusDashboard(result: result),

              // Disclaimer
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu analiz finansal tavsiye değildir. Sadece eğitim amaçlıdır.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const ArgusDashboardSkeleton(),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analiz yüklenemedi: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

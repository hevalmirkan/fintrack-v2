import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/market_data_service.dart';
import '../../data/static/market_catalog.dart';
import '../../domain/models/market_asset.dart';
import '../../../assets/domain/entities/prefilled_asset_data.dart';

/// Provider for market board data (HEIMDALL V2 - Stream-based Cache-First)
final marketBoardProvider =
    StreamProvider.autoDispose<MarketBoardState>((ref) async* {
  final service = MarketDataService();
  await service.initCache();
  yield* service.getMarketDataStream();
});

/// Market Board Screen - Real Market Data Viewer
class MarketBoardScreen extends ConsumerStatefulWidget {
  const MarketBoardScreen({super.key});

  @override
  ConsumerState<MarketBoardScreen> createState() => _MarketBoardScreenState();
}

class _MarketBoardScreenState extends ConsumerState<MarketBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_TabInfo> _tabs = [
    _TabInfo('Özet', null, Icons.dashboard),
    _TabInfo('Kripto', AssetCategory.crypto, Icons.currency_bitcoin),
    _TabInfo('Borsa', AssetCategory.bist, Icons.show_chart),
    _TabInfo(
        'Döviz/Emtia', null, Icons.attach_money), // Combined forex + commodity
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(marketBoardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piyasa Ekranı'),
        actions: [
          // Cache indicator badge
          boardAsync.whenData((state) => state.isCached).value == true
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Önbellek',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(marketBoardProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              // Loading indicator when fetching fresh data
              boardAsync.whenData((state) => state.isLoading).value == true
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs
                    .map((t) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.icon, size: 18),
                              const SizedBox(width: 6),
                              Text(t.label),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketBoardProvider);
          // Wait for new data
          await ref.read(marketBoardProvider.future);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fiyatlar güncellendi 🟢'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: boardAsync.when(
          data: (state) {
            final quotes = state.quotes;
            if (quotes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Piyasa verileri yükleniyor...'),
                  ],
                ),
              );
            }
            return TabBarView(
              controller: _tabController,
              children: [
                // Summary Tab
                _buildSummaryTab(quotes),
                // Crypto Tab
                _buildCategoryTab(quotes, AssetCategory.crypto),
                // BIST Tab
                _buildCategoryTab(quotes, AssetCategory.bist),
                // Forex/Commodity Tab
                _buildForexCommodityTab(quotes),
              ],
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Piyasa verileri yükleniyor...'),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: $error'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(marketBoardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
      // FAB for Manual Add
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-asset'),
        icon: const Icon(Icons.add),
        label: const Text('Manuel Ekle'),
      ),
    );
  }

  Widget _buildSummaryTab(List<MarketQuote> quotes) {
    final successCount = quotes.where((q) => q.isSuccess).length;
    final totalCount = quotes.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        _buildStatusCard(successCount, totalCount),
        const SizedBox(height: 24),

        // Top Movers
        _buildSectionHeader('📈 En Çok Yükselenler'),
        ..._buildTopMovers(quotes, ascending: false),
        const SizedBox(height: 24),

        _buildSectionHeader('📉 En Çok Düşenler'),
        ..._buildTopMovers(quotes, ascending: true),
        const SizedBox(height: 24),

        // Category Summary
        _buildSectionHeader('📊 Kategori Özeti'),
        _buildCategorySummary(quotes),
      ],
    );
  }

  Widget _buildStatusCard(int success, int total) {
    final isAllSuccess = success == total;
    final hasPartial = success > 0 && success < total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAllSuccess
              ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
              : hasPartial
                  ? [
                      Colors.orange.withOpacity(0.2),
                      Colors.orange.withOpacity(0.1)
                    ]
                  : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAllSuccess
              ? Colors.green.withOpacity(0.3)
              : hasPartial
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllSuccess
                ? Icons.check_circle
                : hasPartial
                    ? Icons.warning
                    : Icons.error,
            color: isAllSuccess
                ? Colors.green
                : hasPartial
                    ? Colors.orange
                    : Colors.red,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllSuccess
                      ? 'Tüm Bağlantılar Aktif'
                      : hasPartial
                          ? 'Kısmi Bağlantı'
                          : 'Bağlantı Hatası',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '$success / $total veri kaynağı çalışıyor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(success / total * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopMovers(List<MarketQuote> quotes,
      {required bool ascending}) {
    final sorted = quotes
        .where((q) => q.isSuccess && q.changePercent24h != null)
        .toList()
      ..sort((a, b) => ascending
          ? a.changePercent24h!.compareTo(b.changePercent24h!)
          : b.changePercent24h!.compareTo(a.changePercent24h!));

    return sorted.take(3).map((q) => _buildQuoteListTile(q)).toList();
  }

  Widget _buildCategorySummary(List<MarketQuote> quotes) {
    return Column(
      children: AssetCategory.values.map((category) {
        final categoryQuotes =
            quotes.where((q) => q.asset.category == category).toList();
        final successCount = categoryQuotes.where((q) => q.isSuccess).length;

        return ListTile(
          leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(category.label),
          trailing: Text(
            '$successCount / ${categoryQuotes.length}',
            style: TextStyle(
              color: successCount == categoryQuotes.length
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryTab(List<MarketQuote> quotes, AssetCategory category) {
    final filtered = quotes.where((q) => q.asset.category == category).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Bu kategoride varlık yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildQuoteListTile(filtered[index]),
    );
  }

  Widget _buildForexCommodityTab(List<MarketQuote> quotes) {
    final filtered = quotes
        .where((q) =>
            q.asset.category == AssetCategory.forex ||
            q.asset.category == AssetCategory.commodity)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildSectionHeader('💱 Döviz'),
        ...quotes
            .where((q) => q.asset.category == AssetCategory.forex)
            .map((q) => _buildQuoteListTile(q)),
        const SizedBox(height: 16),
        _buildSectionHeader('🥇 Emtia'),
        ...quotes
            .where((q) => q.asset.category == AssetCategory.commodity)
            .map((q) => _buildQuoteListTile(q)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildQuoteListTile(MarketQuote quote) {
    final isSuccess = quote.isSuccess;
    final changePercent = quote.changePercent24h;
    final isPositive = changePercent != null && changePercent >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: quote.isSuccess ? () => _onQuoteTap(quote) : null,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSuccess
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isSuccess
                  ? Text(
                      quote.asset.symbol.length > 4
                          ? quote.asset.symbol.substring(0, 4)
                          : quote.asset.symbol,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : const Icon(Icons.error_outline, color: Colors.red),
            ),
          ),
          title: Text(
            quote.asset.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            quote.asset.symbol,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          trailing: isSuccess
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(quote.price!, quote.asset.category),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (changePercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                            Text(
                              '${changePercent.abs().toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 20),
                    Text(
                      'Hata',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _onQuoteTap(MarketQuote quote) {
    // Create pre-filled data from quote
    final prefilledData = PrefilledAssetData.fromQuote(quote);

    // Navigate to add asset with pre-filled data
    context.push('/add-asset', extra: prefilledData);
  }

  String _formatPrice(double price, AssetCategory category) {
    if (category == AssetCategory.bist) {
      return '₺${price.toStringAsFixed(2)}';
    } else if (category == AssetCategory.forex) {
      return price.toStringAsFixed(4);
    } else if (price >= 1000) {
      return '\$${price.toStringAsFixed(0)}';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(6)}';
    }
  }
}

class _TabInfo {
  final String label;
  final AssetCategory? category;
  final IconData icon;

  _TabInfo(this.label, this.category, this.icon);
}

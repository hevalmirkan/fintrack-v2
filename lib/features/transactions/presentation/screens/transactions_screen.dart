import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Use FinanceProvider for LOCAL STATE
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';
import '../../../finance/domain/models/wallet.dart';
// Add Transaction Screen for Edit
import 'add_transaction_screen.dart';
// Category Constants
import '../../../../core/constants/category_constants.dart';

/// Filter type enum
enum TransactionFilter { all, income, expense }

/// Date range preset enum
enum DateRangePreset { thisMonth, lastMonth, last7Days, allTime, custom }

/// Transactions Screen V2 - With Advanced Filtering
///
/// Uses financeProvider (LOCAL STATE)
/// Filter logic is purely UI-side, does NOT modify provider
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Basic filters
  TransactionFilter _selectedFilter = TransactionFilter.all;
  String _searchQuery = '';

  // Advanced filters
  DateRangePreset _datePreset = DateRangePreset.allTime;
  DateTimeRange? _customDateRange;
  String? _selectedCategoryFilter;
  String? _selectedWalletFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check if any advanced filters are active
  bool get _hasActiveFilters {
    return _datePreset != DateRangePreset.allTime ||
        _selectedCategoryFilter != null ||
        _selectedWalletFilter != null;
  }

  /// Get filter summary text for chip
  String get _filterSummaryText {
    final parts = <String>[];

    if (_datePreset != DateRangePreset.allTime) {
      parts.add(_getDatePresetLabel(_datePreset));
    }
    if (_selectedCategoryFilter != null) {
      parts.add(_selectedCategoryFilter!);
    }
    if (_selectedWalletFilter != null) {
      final wallets = ref.read(financeProvider).wallets;
      final wallet = wallets.firstWhere(
        (w) => w.id == _selectedWalletFilter,
        orElse: () => wallets.first,
      );
      parts.add(wallet.name);
    }

    return parts.join(' + ');
  }

  String _getDatePresetLabel(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.thisMonth:
        return 'Bu Ay';
      case DateRangePreset.lastMonth:
        return 'Geçen Ay';
      case DateRangePreset.last7Days:
        return 'Son 7 Gün';
      case DateRangePreset.allTime:
        return 'Tüm Zamanlar';
      case DateRangePreset.custom:
        return 'Özel Tarih';
    }
  }

  /// Get date range based on preset
  DateTimeRange? _getDateRange() {
    final now = DateTime.now();

    switch (_datePreset) {
      case DateRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case DateRangePreset.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case DateRangePreset.last7Days:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DateRangePreset.custom:
        return _customDateRange;
      case DateRangePreset.allTime:
        return null;
    }
  }

  /// Clear all advanced filters
  void _clearAllFilters() {
    setState(() {
      _datePreset = DateRangePreset.allTime;
      _customDateRange = null;
      _selectedCategoryFilter = null;
      _selectedWalletFilter = null;
    });
  }

  String _formatCurrency(int amountMinor) {
    final amount = amountMinor / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Group transactions by month/year
  Map<String, List<FinanceTransaction>> _groupByMonth(
      List<FinanceTransaction> transactions) {
    final Map<String, List<FinanceTransaction>> grouped = {};
    final dateFormat = DateFormat('MMMM yyyy', 'tr_TR');

    for (final tx in transactions) {
      final key = dateFormat.format(tx.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }

    return grouped;
  }

  /// Apply ALL filters (basic + advanced) to transactions
  List<FinanceTransaction> _applyFilters(
      List<FinanceTransaction> transactions) {
    var filtered = List<FinanceTransaction>.from(transactions);

    // 1. Apply type filter (income/expense)
    if (_selectedFilter == TransactionFilter.income) {
      filtered = filtered
          .where((tx) => tx.type == FinanceTransactionType.income)
          .toList();
    } else if (_selectedFilter == TransactionFilter.expense) {
      filtered = filtered
          .where((tx) => tx.type == FinanceTransactionType.expense)
          .toList();
    }

    // 2. Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final categoryMatch =
            tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
        final descMatch = (tx.description ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return categoryMatch || descMatch;
      }).toList();
    }

    // 3. Apply DATE RANGE filter (ignore time component)
    final dateRange = _getDateRange();
    if (dateRange != null) {
      final startDate = DateTime(
          dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final endDate = DateTime(dateRange.end.year, dateRange.end.month,
          dateRange.end.day, 23, 59, 59);

      filtered = filtered.where((tx) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            txDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    // 4. Apply CATEGORY filter
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((tx) => tx.category == _selectedCategoryFilter)
          .toList();
    }

    // 5. Apply WALLET filter
    if (_selectedWalletFilter != null) {
      filtered =
          filtered.where((tx) => tx.walletId == _selectedWalletFilter).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet() {
    // Local state for bottom sheet
    DateRangePreset tempDatePreset = _datePreset;
    DateTimeRange? tempCustomRange = _customDateRange;
    String? tempCategory = _selectedCategoryFilter;
    String? tempWallet = _selectedWalletFilter;

    final wallets = ref.read(financeProvider).wallets;
    final allCategories = [
      ...CategoryConstants.allExpenseCategories,
      ...CategoryConstants.incomeCategories,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gelişmiş Filtreler',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // A. DATE RANGE SECTION
                            const Text(
                              '📅 Tarih Aralığı',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: DateRangePreset.values
                                  .where((p) => p != DateRangePreset.custom)
                                  .map((preset) {
                                final isSelected = tempDatePreset == preset;
                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      tempDatePreset = preset;
                                      if (preset != DateRangePreset.custom) {
                                        tempCustomRange = null;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF58A6FF)
                                          : const Color(0xFF21262D),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF58A6FF)
                                            : const Color(0xFF30363D),
                                      ),
                                    ),
                                    child: Text(
                                      _getDatePresetLabel(preset),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Custom date range button
                            OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  locale: const Locale('tr', 'TR'),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF58A6FF),
                                          surface: Color(0xFF161B22),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    tempDatePreset = DateRangePreset.custom;
                                    tempCustomRange = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(
                                tempDatePreset == DateRangePreset.custom &&
                                        tempCustomRange != null
                                    ? '${DateFormat('dd/MM').format(tempCustomRange!.start)} - ${DateFormat('dd/MM').format(tempCustomRange!.end)}'
                                    : 'Özel Tarih Seç',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    tempDatePreset == DateRangePreset.custom
                                        ? const Color(0xFF58A6FF)
                                        : Colors.grey,
                                side: BorderSide(
                                  color:
                                      tempDatePreset == DateRangePreset.custom
                                          ? const Color(0xFF58A6FF)
                                          : const Color(0xFF30363D),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // B. CATEGORY SECTION
                            const Text(
                              '🏷️ Kategori',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              value: tempCategory,
                              dropdownColor: const Color(0xFF21262D),
                              decoration: InputDecoration(
                                hintText: 'Tüm Kategoriler',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                filled: true,
                                fillColor: const Color(0xFF0D1117),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF30363D)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF30363D)),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tüm Kategoriler',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                ...allCategories.map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    )),
                              ],
                              onChanged: (val) =>
                                  setSheetState(() => tempCategory = val),
                            ),

                            const SizedBox(height: 24),

                            // C. WALLET SECTION
                            const Text(
                              '👛 Cüzdan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              value: tempWallet,
                              dropdownColor: const Color(0xFF21262D),
                              decoration: InputDecoration(
                                hintText: 'Tüm Cüzdanlar',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                filled: true,
                                fillColor: const Color(0xFF0D1117),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF30363D)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF30363D)),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tüm Cüzdanlar',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                ...wallets.map((wallet) => DropdownMenuItem(
                                      value: wallet.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            wallet.type == WalletType.cash
                                                ? Icons.wallet
                                                : Icons.credit_card,
                                            size: 18,
                                            color:
                                                wallet.type == WalletType.cash
                                                    ? Colors.green
                                                    : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(wallet.name,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    )),
                              ],
                              onChanged: (val) =>
                                  setSheetState(() => tempWallet = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempDatePreset = DateRangePreset.allTime;
                                  tempCustomRange = null;
                                  tempCategory = null;
                                  tempWallet = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side:
                                    const BorderSide(color: Color(0xFF30363D)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Temizle'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _datePreset = tempDatePreset;
                                  _customDateRange = tempCustomRange;
                                  _selectedCategoryFilter = tempCategory;
                                  _selectedWalletFilter = tempWallet;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF238636),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Uygula',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(financeProvider).transactions;
    final filteredTransactions = _applyFilters(transactions);
    final groupedTransactions = _groupByMonth(filteredTransactions);

    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          // Search & Filter Area
          _buildSearchAndFilterArea(),

          // Active Filter Chip
          if (_hasActiveFilters) _buildActiveFilterChip(),

          // Grouped Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildGroupedList(groupedTransactions),
          ),
        ],
      ),
    );
  }

  /// Active filter summary chip
  Widget _buildActiveFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          Expanded(
            child: Chip(
              label: Text(
                'Filtre: $_filterSummaryText',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: const Color(0xFF238636).withOpacity(0.3),
              deleteIcon:
                  const Icon(Icons.close, size: 16, color: Colors.white70),
              onDeleted: _clearAllFilters,
              side: const BorderSide(color: Color(0xFF238636)),
            ),
          ),
        ],
      ),
    );
  }

  /// Search bar and filter chips
  Widget _buildSearchAndFilterArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar with Filter Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Harcama ara...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey.shade500),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF58A6FF)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button with Active Indicator
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: Stack(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters
                          ? const Color(0xFF238636)
                          : Colors.grey,
                      size: 28,
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF238636),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip(TransactionFilter.all, 'Tümü'),
              const SizedBox(width: 8),
              _buildFilterChip(TransactionFilter.income, 'Gelir'),
              const SizedBox(width: 8),
              _buildFilterChip(TransactionFilter.expense, 'Gider'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TransactionFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    Color chipColor;
    Color textColor;

    if (isSelected) {
      switch (filter) {
        case TransactionFilter.all:
          chipColor = const Color(0xFF58A6FF);
          textColor = Colors.white;
        case TransactionFilter.income:
          chipColor = const Color(0xFF00D09C);
          textColor = Colors.white;
        case TransactionFilter.expense:
          chipColor = const Color(0xFFFF6B6B);
          textColor = Colors.white;
      }
    } else {
      chipColor = const Color(0xFF21262D);
      textColor = Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : const Color(0xFF30363D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Grouped list with month headers + NET TOTAL
  Widget _buildGroupedList(Map<String, List<FinanceTransaction>> grouped) {
    final monthKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: monthKeys.length,
      itemBuilder: (context, index) {
        final month = monthKeys[index];
        final transactions = grouped[month]!;

        // Calculate monthly net total
        int monthlyIncome = 0;
        int monthlyExpense = 0;
        for (final tx in transactions) {
          if (tx.type == FinanceTransactionType.income) {
            monthlyIncome += tx.amountMinor;
          } else {
            monthlyExpense += tx.amountMinor;
          }
        }
        final netTotal = monthlyIncome - monthlyExpense;
        final isPositive = netTotal >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header with Net Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Monthly Net Total
                  Text(
                    '${isPositive ? '+' : ''}${_formatCurrency(netTotal)}',
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF00D09C)
                          : const Color(0xFFFF6B6B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions for this month
            ...transactions.map((tx) => _buildTransactionTile(tx)),
          ],
        );
      },
    );
  }

  /// Individual transaction tile with TAP TO EDIT and SWIPE TO DELETE
  /// Layout: TITLE=Category (bold), SUBTITLE=Description (if any) + Wallet
  Widget _buildTransactionTile(FinanceTransaction tx) {
    // PHASE 1 INFRASTRUCTURE: Color/Icon based on TransactionType enum
    Color color;
    IconData icon;

    switch (tx.type) {
      case FinanceTransactionType.income:
        color = const Color(0xFF00D09C); // Green for income
        icon = Icons.arrow_downward;
        break;
      case FinanceTransactionType.expense:
        color = const Color(0xFFFF6B6B); // Red for expenses
        icon = Icons.arrow_upward;
        break;
      case FinanceTransactionType.investment:
        color = const Color(0xFF6200EA); // Purple for investments
        icon = Icons.swap_horiz; // Cash → Asset swap, not loss
        break;
      case FinanceTransactionType.transfer:
        color = const Color(0xFF64B5F6); // Blue for transfers
        icon = Icons.sync_alt;
        break;
      case FinanceTransactionType.adjustment:
        color = Colors.grey; // Neutral for adjustments
        icon = Icons.tune;
        break;
    }

    // Find wallet for this transaction
    final wallets = ref.watch(financeProvider).wallets;
    final wallet = wallets.firstWhere(
      (w) => w.id == tx.walletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : wallets.first,
    );

    // Wallet emoji based on type
    final walletEmoji = wallet.type == WalletType.cash ? '💵' : '💳';

    // Check if description exists and is not empty
    final hasDescription =
        tx.description != null && tx.description!.trim().isNotEmpty;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('İşlemi Sil?',
                    style: TextStyle(color: Colors.white)),
                content: Text(
                  '${tx.category} işlemini silmek istediğinize emin misiniz?',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        const Text('Sil', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        ref.read(financeProvider.notifier).deleteTransaction(tx.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tx.category} silindi'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // Navigate to edit screen with transaction
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(transactionToEdit: tx),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              // Leading: Circle with icon (different for investments)
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon, // Uses dynamic icon based on transaction type
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE: Use displayTitle (title if available, else category)
                    Text(
                      tx.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // LINE 1 (Optional): Description
                    if (hasDescription) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // LINE 2: Wallet with emoji
                    const SizedBox(height: 2),
                    Text(
                      '$walletEmoji ${wallet.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing: Amount (sign based on transaction type)
              Text(
                '${tx.type.reducesBalance ? '-' : '+'}${_formatCurrency(tx.amountMinor)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case TransactionFilter.income:
        message = 'Gelir işlemi bulunamadı';
        icon = Icons.arrow_downward;
      case TransactionFilter.expense:
        message = 'Gider işlemi bulunamadı';
        icon = Icons.arrow_upward;
      case TransactionFilter.all:
        message = _searchQuery.isNotEmpty
            ? '"$_searchQuery" için sonuç bulunamadı'
            : _hasActiveFilters
                ? 'Filtre sonucu bulunamadı'
                : 'Henüz işlem yok';
        icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF8B949E)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty &&
              _selectedFilter == TransactionFilter.all &&
              !_hasActiveFilters) ...[
            const SizedBox(height: 8),
            Text(
              'Gelir veya gider ekleyerek başlayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Filtreleri Temizle'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF58A6FF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

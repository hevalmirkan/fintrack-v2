import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_enums.dart';
// Finance Provider for LOCAL STATE
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';
// Category Constants
import '../../../../core/constants/category_constants.dart';
// Live Currency Service
import '../../../../core/services/currency_service.dart';
// 🆕 Phase 3.3: Installments
import '../../../installments/domain/entities/installment.dart';
import '../../../installments/presentation/providers/mock_installment_provider.dart';
// 🆕 Phase 3.3: Subscriptions
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// Pass transaction for EDIT MODE, null for ADD MODE
  final FinanceTransaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

/// Recurring payment type for split logic
enum RecurringType { taksit, abonelik }

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyService = CurrencyService();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Market';
  String _selectedCurrency = 'TRY';
  String _selectedWalletId = 'wallet_cash'; // 🔴 FIX: Use actual wallet ID
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // 🆕 PHASE 3.3: Smart Split/Recurring Logic
  bool _isRecurring = false; // Main toggle
  RecurringType _recurringType = RecurringType.taksit; // Süreli vs Süresiz
  int _installmentCount = 3; // For Taksit
  int _renewalDay = 15; // For Abonelik
  bool _isMonthlyInputMode = false; // false = Total, true = Monthly

  // Live rate display
  String _rateDisplayText = '';
  String _approximateTRYText = '';

  /// Check if we're in EDIT mode
  bool get isEditMode => widget.transactionToEdit != null;

  /// Original transaction ID (for edit)
  String? get _editingId => widget.transactionToEdit?.id;

  @override
  void initState() {
    super.initState();

    // PRE-FILL fields if in EDIT mode
    if (isEditMode) {
      final tx = widget.transactionToEdit!;
      _titleController.text = tx.description ?? '';
      // Display amount in TRY (since we store in TRY)
      _amountController.text = (tx.amountMinor / 100).toStringAsFixed(2);
      _selectedType = tx.type == FinanceTransactionType.income
          ? TransactionType.income
          : TransactionType.expense;
      _selectedCategory = tx.category;
      _selectedCurrency = 'TRY'; // Always show in TRY for edit
      _selectedWalletId = tx.walletId; // Pre-fill wallet
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Get categories based on transaction type
  List<String> get _currentCategories {
    if (_selectedType == TransactionType.income) {
      return CategoryConstants.incomeCategories;
    } else {
      return CategoryConstants.allExpenseCategories;
    }
  }

  /// Update rate display when currency or amount changes
  Future<void> _updateRateDisplay() async {
    final currency = CurrencyService.fromString(_selectedCurrency);
    if (currency == null || currency == Currency.TRY) {
      setState(() {
        _rateDisplayText = '';
        _approximateTRYText = '';
      });
      return;
    }

    // Get live rate
    final rateText = await _currencyService.getRateDisplayText(currency);

    // Get approximate TRY
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0.0;
    final approxText =
        await _currencyService.getApproximateTRYText(amount, currency);

    if (mounted) {
      setState(() {
        _rateDisplayText = rateText;
        _approximateTRYText = approxText;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Parse amount
      String cleanAmount = _amountController.text.replaceAll(',', '.');
      double amountDouble = double.parse(cleanAmount);

      // 2. Convert to TRY using LIVE RATES
      int totalAmountMinor;
      final currency = CurrencyService.fromString(_selectedCurrency);

      if (currency == null || currency == Currency.TRY) {
        totalAmountMinor = (amountDouble * 100).round();
      } else {
        // Convert using LIVE currency service
        totalAmountMinor =
            await _currencyService.convertToTRYMinor(amountDouble, currency);
        debugPrint(
            '[CURRENCY] Live conversion: $amountDouble $_selectedCurrency = ${totalAmountMinor / 100} TRY');
      }

      // 🆕 PHASE 6.7: Capture currency metadata for historical reference
      final double? originalAmount =
          (currency != null && currency != Currency.TRY) ? amountDouble : null;
      final String? originalCurrencyCode =
          (currency != null && currency != Currency.TRY)
              ? _selectedCurrency
              : null;
      // Calculate exchange rate used (TRY per unit of foreign currency)
      final double? usedExchangeRate =
          (originalAmount != null && originalAmount > 0)
              ? (totalAmountMinor / 100) / originalAmount
              : null;

      if (usedExchangeRate != null) {
        debugPrint(
            '[CURRENCY] Exchange rate stored: 1 $_selectedCurrency = ${usedExchangeRate.toStringAsFixed(4)} TRY');
      }

      // 3. Map TransactionType to FinanceTransactionType
      final financeType = _selectedType == TransactionType.income
          ? FinanceTransactionType.income
          : FinanceTransactionType.expense;

      // 🆕 PHASE 3.3: SMART RECURRING LOGIC
      if (_isRecurring &&
          _selectedType == TransactionType.expense &&
          !isEditMode) {
        final now = DateTime.now();

        if (_recurringType == RecurringType.taksit) {
          // --- INSTALLMENT (TAKSIT) MODE ---
          int actualTotalMinor;
          int monthlyAmountMinor;

          if (_isMonthlyInputMode) {
            // User entered MONTHLY amount → Calculate total
            monthlyAmountMinor = totalAmountMinor;
            actualTotalMinor = monthlyAmountMinor * _installmentCount;
            debugPrint(
                '[INSTALLMENT] Monthly mode: ₺${monthlyAmountMinor / 100} × $_installmentCount = ₺${actualTotalMinor / 100}');
          } else {
            // User entered TOTAL → Calculate monthly
            actualTotalMinor = totalAmountMinor;
            monthlyAmountMinor = (totalAmountMinor / _installmentCount).round();
            debugPrint(
                '[INSTALLMENT] Total mode: ₺${actualTotalMinor / 100} / $_installmentCount = ₺${monthlyAmountMinor / 100}/month');
          }

          final planId = 'inst_${now.millisecondsSinceEpoch}';

          // Create InstallmentPlan
          final installment = Installment(
            id: planId,
            title: _titleController.text.isNotEmpty
                ? _titleController.text
                : _selectedCategory,
            totalAmount: actualTotalMinor,
            remainingAmount: actualTotalMinor - monthlyAmountMinor,
            totalInstallments: _installmentCount,
            paidInstallments: 1,
            amountPerInstallment: monthlyAmountMinor,
            startDate: now,
            nextDueDate: DateTime(now.year, now.month + 1, now.day),
          );

          ref
              .read(mockInstallmentProvider.notifier)
              .addInstallment(installment);

          // Create FIRST transaction (deducts wallet)
          final transaction = FinanceTransaction(
            id: 'tx_${now.millisecondsSinceEpoch}',
            walletId: _selectedWalletId,
            type: financeType,
            amountMinor: monthlyAmountMinor,
            category: 'Taksit / Borç',
            title:
                '${_titleController.text.isNotEmpty ? _titleController.text : _selectedCategory} - Taksit 1/$_installmentCount',
            description: 'Taksit ödemesi',
            date: _selectedDate,
            createdAt: now,
            parentTransactionId: planId,
            installmentIndex: 1,
          );

          await ref.read(financeProvider.notifier).addTransaction(transaction);
          debugPrint('[INSTALLMENT] Plan created + First payment deducted');
        } else {
          // --- SUBSCRIPTION (ABONELİK) MODE ---
          final subId = 'sub_${now.millisecondsSinceEpoch}';

          // Create Subscription
          final subscription = Subscription(
            id: subId,
            title: _titleController.text.isNotEmpty
                ? _titleController.text
                : _selectedCategory,
            amountMinor: totalAmountMinor,
            renewalDay: _renewalDay,
            category: _selectedCategory,
            walletId: _selectedWalletId,
            isActive: true,
            lastPaidDate: now, // First payment is now
            createdAt: now,
          );

          ref.read(subscriptionProvider.notifier).addSubscription(subscription);

          // Create FIRST transaction (deducts wallet)
          final transaction = FinanceTransaction(
            id: 'tx_${now.millisecondsSinceEpoch}',
            walletId: _selectedWalletId,
            type: financeType,
            amountMinor: totalAmountMinor,
            category: 'Abonelik',
            title:
                '${_titleController.text.isNotEmpty ? _titleController.text : _selectedCategory} - Abonelik Ödemesi',
            description: 'İlk abonelik ödemesi',
            date: _selectedDate,
            createdAt: now,
            isRecurring: true,
          );

          await ref.read(financeProvider.notifier).addTransaction(transaction);
          debugPrint(
              '[SUBSCRIPTION] Created: ${_titleController.text} - ₺${totalAmountMinor / 100}/month');
        }
      } else {
        // --- STANDARD MODE ---
        final transaction = FinanceTransaction(
          id: isEditMode
              ? widget.transactionToEdit!.id
              : 'tx_${DateTime.now().millisecondsSinceEpoch}',
          walletId: _selectedWalletId,
          type: financeType,
          amountMinor: totalAmountMinor,
          category: _selectedCategory,
          description: _titleController.text,
          date: _selectedDate,
          createdAt:
              isEditMode ? widget.transactionToEdit!.createdAt : DateTime.now(),
          // 🆕 PHASE 6.7: Store original currency metadata for transparency
          originalAmount: originalAmount,
          originalCurrency: originalCurrencyCode,
          exchangeRate: usedExchangeRate,
        );

        if (isEditMode) {
          await ref.read(financeProvider.notifier).editTransaction(transaction);
        } else {
          await ref.read(financeProvider.notifier).addTransaction(transaction);
        }
      }

      // 6. Close screen
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRecurring
                ? (_recurringType == RecurringType.taksit
                    ? 'Taksit Planı Oluşturuldu ✅'
                    : 'Abonelik Oluşturuldu ✅')
                : isEditMode
                    ? 'İşlem Güncellendi ✅'
                    : 'İşlem Kaydedildi ✅'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint("HATA: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == TransactionType.income;
    final activeColor =
        isIncome ? const Color(0xFF00C853) : const Color(0xFFD32F2F);

    // Reset category if switching type
    if (isIncome &&
        !CategoryConstants.incomeCategories.contains(_selectedCategory)) {
      _selectedCategory = CategoryConstants.incomeCategories.first;
    } else if (!isIncome &&
        !CategoryConstants.allExpenseCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Market';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(isEditMode ? 'İşlem Düzenle' : 'İşlem Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TYPE SELECTOR
              _buildTypeSelector(isIncome),
              const SizedBox(height: 24),

              // DESCRIPTION
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn: Market alışverişi',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: const Icon(Icons.description, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                ),
                // Description is OPTIONAL - no validator
              ),
              const SizedBox(height: 16),

              // AMOUNT + CURRENCY ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Field
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      onChanged: (_) =>
                          _updateRateDisplay(), // Update live rate display
                      decoration: InputDecoration(
                        labelText: 'Tutar',
                        prefixIcon:
                            Icon(Icons.attach_money, color: activeColor),
                        filled: true,
                        fillColor: const Color(0xFF161B22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: activeColor.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: activeColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: activeColor, width: 2),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Tutar giriniz' : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Currency Dropdown
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      dropdownColor: const Color(0xFF161B22),
                      decoration: InputDecoration(
                        labelText: 'Para Birimi',
                        filled: true,
                        fillColor: const Color(0xFF161B22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF30363D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF30363D)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      items:
                          CurrencyConstants.supportedCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(
                            CurrencyConstants.currencySymbols[currency] ??
                                currency,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCurrency = val!);
                        _updateRateDisplay(); // Fetch live rate
                      },
                    ),
                  ),
                ],
              ),

              // Live Rate Display
              if (_rateDisplayText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_exchange,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(_rateDisplayText,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 13)),
                    ],
                  ),
                ),
              ],

              // TRY Approximation Helper
              if (_approximateTRYText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _approximateTRYText,
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // CATEGORY DROPDOWN (Grouped)
              _buildCategoryDropdown(isIncome),

              const SizedBox(height: 16),

              // WALLET SELECTOR
              _buildWalletDropdown(),

              const SizedBox(height: 16),

              // 🆕 PHASE 3.3: TAKSITLENDIR TOGGLE (only for expense)
              if (_selectedType == TransactionType.expense && !isEditMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isRecurring
                          ? Colors.purple.withOpacity(0.5)
                          : const Color(0xFF30363D),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color:
                                    _isRecurring ? Colors.purple : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Taksitlendir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isRecurring,
                            onChanged: (value) {
                              setState(() => _isRecurring = value);
                            },
                            activeColor: Colors.purple,
                          ),
                        ],
                      ),

                      // Options only if recurring is enabled
                      if (_isRecurring) ...[
                        const SizedBox(height: 16),

                        // 🆕 TYPE SELECTION: Süreli (Taksit) vs Süresiz (Abonelik)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _recurringType = RecurringType.taksit),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        _recurringType == RecurringType.taksit
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _recurringType == RecurringType.taksit
                                              ? Colors.blue
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: _recurringType ==
                                                  RecurringType.taksit
                                              ? Colors.blue
                                              : Colors.grey,
                                          size: 18),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Süreli (Taksit)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _recurringType ==
                                                  RecurringType.taksit
                                              ? Colors.white
                                              : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _recurringType = RecurringType.abonelik;
                                  _isMonthlyInputMode =
                                      true; // Force monthly for subs
                                }),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        _recurringType == RecurringType.abonelik
                                            ? Colors.orange.withOpacity(0.3)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _recurringType ==
                                              RecurringType.abonelik
                                          ? Colors.orange
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.subscriptions,
                                          color: _recurringType ==
                                                  RecurringType.abonelik
                                              ? Colors.orange
                                              : Colors.grey,
                                          size: 18),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Süresiz (Abonelik)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _recurringType ==
                                                  RecurringType.abonelik
                                              ? Colors.white
                                              : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // CONDITIONAL: Show Calc Mode only for Taksit
                        if (_recurringType == RecurringType.taksit) ...[
                          // Calc Mode Toggle (Total vs Monthly)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _isMonthlyInputMode = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isMonthlyInputMode
                                          ? Colors.purple.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !_isMonthlyInputMode
                                            ? Colors.purple
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    child: Text(
                                      'Toplam Tutar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !_isMonthlyInputMode
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _isMonthlyInputMode = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isMonthlyInputMode
                                          ? Colors.purple.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isMonthlyInputMode
                                            ? Colors.purple
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    child: Text(
                                      'Aylık Tutar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _isMonthlyInputMode
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TAKSIT: Installment Count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taksit Sayısı:',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _installmentCount,
                                    isDense: true,
                                    dropdownColor: const Color(0xFF1E2230),
                                    icon: const Icon(Icons.keyboard_arrow_down,
                                        color: Colors.purple, size: 18),
                                    items: [2, 3, 4, 5, 6, 9, 12, 18, 24]
                                        .map((count) => DropdownMenuItem(
                                              value: count,
                                              child: Text(
                                                '$count Ay',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(
                                          () => _installmentCount = value ?? 3);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Calculation Preview for Taksit
                          Builder(
                            builder: (context) {
                              final amountText =
                                  _amountController.text.replaceAll(',', '.');
                              final enteredAmount =
                                  double.tryParse(amountText) ?? 0.0;

                              if (_isMonthlyInputMode) {
                                final totalCalc =
                                    enteredAmount * _installmentCount;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💡 Girilen Aylık Tutar: ₺${enteredAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📊 Hesaplanan Toplam: ₺${totalCalc.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.purple.shade200,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                final monthlyCalc =
                                    enteredAmount / _installmentCount;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💡 Girilen Toplam: ₺${enteredAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📊 Aylık Taksit: ₺${monthlyCalc.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.purple.shade200,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ], // End of Taksit section

                        // ABONELIK (Subscription) specific UI
                        if (_recurringType == RecurringType.abonelik) ...[
                          // Renewal Day Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Yenileme Günü:',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _renewalDay,
                                    isDense: true,
                                    dropdownColor: const Color(0xFF1E2230),
                                    icon: const Icon(Icons.keyboard_arrow_down,
                                        color: Colors.orange, size: 18),
                                    items: List.generate(28, (i) => i + 1)
                                        .map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(
                                                'Ayın $d\'i',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => _renewalDay = value ?? 15);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💡 Her ay ${_renewalDay}. günde yenilenecek',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ], // End of _isRecurring
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // DATE PICKER
              _buildDatePicker(),

              const SizedBox(height: 32),

              // SAVE BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'KAYDET',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isIncome) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          _buildTypeButton(
            'GELİR',
            Icons.arrow_downward,
            Colors.green,
            TransactionType.income,
          ),
          _buildTypeButton(
            'GİDER',
            Icons.arrow_upward,
            Colors.red,
            TransactionType.expense,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
      String label, IconData icon, Color color, TransactionType type) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isIncome) {
    if (isIncome) {
      // Simple dropdown for income categories
      return DropdownButtonFormField<String>(
        value: _selectedCategory,
        dropdownColor: const Color(0xFF161B22),
        decoration: InputDecoration(
          labelText: 'Kategori',
          prefixIcon: const Icon(Icons.category, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF161B22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
        ),
        items: CategoryConstants.incomeCategories.map((c) {
          return DropdownMenuItem(
            value: c,
            child: Row(
              children: [
                Text(CategoryConstants.getIconForCategory(c),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(c, style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedCategory = val!),
      );
    }

    // Grouped dropdown for expense categories
    final items = <DropdownMenuItem<String>>[];
    for (final entry in CategoryConstants.expenseCategories.entries) {
      // Group header (disabled)
      items.add(DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Text(
          entry.key,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      // Categories in group
      for (final category in entry.value) {
        items.add(DropdownMenuItem(
          value: category,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Text(CategoryConstants.getIconForCategory(category),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(category, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ));
      }
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: const Color(0xFF161B22),
      menuMaxHeight: 400,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(Icons.category, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      items: items,
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedCategory = val);
        }
      },
    );
  }

  Widget _buildWalletDropdown() {
    // Get wallets from financeProvider
    final wallets = ref.watch(financeProvider).wallets;

    // Ensure selected wallet exists, fallback to first
    if (!wallets.any((w) => w.id == _selectedWalletId) && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    return DropdownButtonFormField<String>(
      value: _selectedWalletId,
      dropdownColor: const Color(0xFF161B22),
      decoration: InputDecoration(
        labelText: 'Hesap',
        prefixIcon:
            const Icon(Icons.account_balance_wallet, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      items: wallets.map((wallet) {
        return DropdownMenuItem(
          value: wallet.id,
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color:
                      wallet.type.name == 'cash' ? Colors.green : Colors.blue,
                  size: 18),
              const SizedBox(width: 8),
              Text(wallet.name, style: const TextStyle(color: Colors.white)),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedWalletId = val);
        }
      },
    );
  }

  Widget _buildDatePicker() {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarih',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

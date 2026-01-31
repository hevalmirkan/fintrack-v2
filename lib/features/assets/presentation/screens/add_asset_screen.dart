import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/services/format_service.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_purchase_type.dart';
import '../../domain/entities/prefilled_asset_data.dart';
import '../../../market/domain/models/market_asset.dart';
import '../../../market/data/services/market_data_service.dart';
import '../providers/asset_providers.dart'; // Contains kUsdTryRate
import '../providers/portfolio_providers.dart';
// 🔴 CRITICAL: Finance Provider for expense transaction creation
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  final PrefilledAssetData? prefilledData;

  const AddAssetScreen({super.key, this.prefilledData});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingHistoricalPrice = false;
  bool _isFromMarketBoard = false;
  String? _apiId;
  MarketSource? _source;
  DateTime? _selectedDate;
  String? _historicalPriceHelperText;
  AssetPurchaseType _purchaseType = AssetPurchaseType.addToPortfolio;
  int _inputMode = 0; // 0 = Miktar Gir (Quantity), 1 = Tutar Gir (Amount)
  final _totalAmountController =
      TextEditingController(); // For "buy by amount" mode

  // 🆕 WALLET SELECTION (MANDATORY)
  String? _selectedWalletId;

  // 🆕 CURRENCY INPUT MODE: 0 = USD, 1 = TRY
  int _currencyInputMode = 0;

  // 🆕 CACHED CALCULATIONS for reactive display
  double _cachedTotalCostTRY = 0.0;
  double _cachedQuantity = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill from Market Board if data provided
    if (widget.prefilledData != null) {
      _isFromMarketBoard = true;
      _apiId = widget.prefilledData!.apiId;
      _source = widget.prefilledData!.source;
      _symbolController.text = widget.prefilledData!.symbol;
      _nameController.text = widget.prefilledData!.name;
      _priceController.text =
          widget.prefilledData!.currentPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  /// Calculate quantity display text from total amount (for helper text)
  String? _calculateQuantityFromAmount() {
    final priceText = _priceController.text.replaceAll(',', '.');
    final amountText = _totalAmountController.text.replaceAll(',', '.');

    final price = double.tryParse(priceText);
    final amount = double.tryParse(amountText);

    if (price == null || price <= 0 || amount == null || amount <= 0) {
      return null;
    }

    final quantity = amount / price;
    return 'Miktar: ${quantity.toStringAsFixed(6)}';
  }

  /// 🆕 REACTIVE CALCULATION: Update quantity and cost from inputs
  /// Handles both USD and TRY input modes
  void _recalculateCosts() {
    final priceText = _priceController.text.replaceAll(',', '.');
    final priceUSD = double.tryParse(priceText) ?? 0.0;

    if (priceUSD <= 0) {
      _cachedQuantity = 0.0;
      _cachedTotalCostTRY = 0.0;
      return;
    }

    double enteredAmount = 0.0;

    if (_inputMode == 0) {
      // Mode: Miktar Gir (Quantity entered directly)
      final qtyText = _quantityController.text.replaceAll(',', '.');
      _cachedQuantity = double.tryParse(qtyText) ?? 0.0;

      // Calculate cost: quantity * price (USD) * rate
      final costUSD = _cachedQuantity * priceUSD;
      _cachedTotalCostTRY = costUSD * kUsdTryRate;
    } else {
      // Mode: Tutar Gir (Amount entered)
      final amountText = _totalAmountController.text.replaceAll(',', '.');
      enteredAmount = double.tryParse(amountText) ?? 0.0;

      if (_currencyInputMode == 0) {
        // USD mode: User enters USD amount
        final costUSD = enteredAmount;
        _cachedTotalCostTRY = costUSD * kUsdTryRate;
        _cachedQuantity = costUSD / priceUSD;
      } else {
        // TRY mode: User enters TRY amount
        _cachedTotalCostTRY = enteredAmount;
        final costUSD = enteredAmount / kUsdTryRate;
        _cachedQuantity = costUSD / priceUSD;
      }

      // Update quantity controller for display
      if (_cachedQuantity > 0) {
        _quantityController.text = _cachedQuantity.toStringAsFixed(8);
      }
    }
  }

  /// Update quantity controller from total amount input (legacy support)
  void _updateQuantityFromAmount() {
    _recalculateCosts();
  }

  /// 🆕 Check if save should be blocked due to insufficient funds
  /// Credit cards ALLOW debt, only cash wallets check balance
  bool get _hasInsufficientFunds {
    if (_purchaseType != AssetPurchaseType.buyNow) return false;

    final wallets = ref.read(financeProvider).wallets;
    if (wallets.isEmpty) return false;

    final selectedWallet = wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => wallets.first,
    );

    // Credit cards allow debt - no insufficient funds check
    if (selectedWallet.type.name == 'creditCard') return false;

    final balance = selectedWallet.balanceMinor / 100.0;
    return balance < _cachedTotalCostTRY;
  }

  /// Generate symbol from name for manual assets
  String _generateSymbolFromName(String name) {
    // Take first 4-5 characters of name, uppercase, remove spaces
    final clean = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length >= 4) {
      return clean.substring(0, 4);
    }
    return clean.isNotEmpty ? clean : 'ASSET';
  }

  /// TIME MACHINE: Fetch historical price for selected date
  Future<void> _fetchHistoricalPrice(DateTime date) async {
    if (_apiId == null || _source == null) return;

    setState(() {
      _isLoadingHistoricalPrice = true;
      _selectedDate = date;
      _historicalPriceHelperText = null;
    });

    try {
      final service = MarketDataService();
      final price = await service.fetchPriceAtDate(
        apiId: _apiId!,
        source: _source!,
        date: date,
      );

      if (mounted) {
        if (price != null) {
          _priceController.text = price.toStringAsFixed(2);
          final formattedDate = DateFormat('d MMMM yyyy', 'tr_TR').format(date);
          setState(() {
            _historicalPriceHelperText =
                '✅ $formattedDate tarihindeki fiyat getirildi';
          });
        } else {
          setState(() {
            _historicalPriceHelperText =
                '⚠️ Bu tarih için fiyat bulunamadı. Manuel girebilirsiniz.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historicalPriceHelperText =
              '⚠️ Fiyat getirilemedi: ${e.toString().split(':').last.trim()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistoricalPrice = false);
      }
    }
  }

  /// Show date picker for Time Machine
  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2010), // Bitcoin started in 2009
      lastDate: now,
      helpText: 'Alış tarihini seçin',
      confirmText: 'Fiyatı Getir',
      cancelText: 'İptal',
    );

    if (picked != null) {
      await _fetchHistoricalPrice(picked);
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Parse Inputs - Use HIGH PRECISION for quantity (10^8 for crypto like satoshis)
      // Price uses standard 100x factor (cents)
      final quantityText = _quantityController.text.replaceAll(',', '.');
      final priceText = _priceController.text.replaceAll(',', '.');

      final quantityDouble = double.tryParse(quantityText) ?? 0.0;
      final priceDouble = double.tryParse(priceText) ?? 0.0;

      // Store quantity with 100000000x factor for 8 decimal precision (satoshi-level)
      final quantityMinor = (quantityDouble * 100000000).round();
      // Store price with standard 100x factor (cents)
      final priceMinor = (priceDouble * 100).round();

      print(
          '[ASSET] Parse: qty=$quantityDouble -> minor=$quantityMinor, price=$priceDouble -> minor=$priceMinor');

      // 2. Generate symbol if empty (manual mode only)
      String symbol = _symbolController.text.toUpperCase().trim();
      if (symbol.isEmpty && !_isFromMarketBoard) {
        symbol = _generateSymbolFromName(_nameController.text);
      }

      // 3. Create Entity with apiId for live tracking
      final newAsset = Asset(
        id: '',
        symbol: symbol,
        name: _nameController.text,
        quantityMinor: quantityMinor, // High precision (10^8)
        averagePrice: priceMinor, // Standard precision (10^2)
        currentPrice: priceMinor,
        apiId: _apiId, // Store apiId for Heimdall/Argus
      );

      // 4. Call Repository with purchase type
      await ref
          .read(assetRepositoryProvider)
          .addAsset(newAsset, purchaseType: _purchaseType)
          .timeout(const Duration(seconds: 10));

      // 5. CRITICAL: Create expense transaction if PURCHASING (not initial holding)
      if (_purchaseType == AssetPurchaseType.buyNow) {
        // Use the ORIGINAL double values for expense calculation (no precision loss)
        final totalCostUSD = quantityDouble * priceDouble;

        // DEBUG: Log parsed values to diagnose 0-value bug
        print(
            '[ASSET] DEBUG: quantityMinor=$quantityMinor, priceMinor=$priceMinor');
        print(
            '[ASSET] DEBUG: quantityDouble=$quantityDouble, priceDouble=$priceDouble, totalCostUSD=$totalCostUSD');
        print(
            '[ASSET] DEBUG: priceController="${_priceController.text}", quantityController="${_quantityController.text}"');

        // GUARD: Skip expense if total is 0 (shouldn't happen with valid input)
        if (totalCostUSD <= 0) {
          print(
              '[ASSET] WARNING: Skipping expense transaction - totalCostUSD is 0 or negative');
        } else {
          // 🆕 Use pre-calculated values and selected wallet
          final totalCostTRY = _cachedTotalCostTRY;
          final totalCostMinorTRY = (totalCostTRY * 100).round();

          // Use SELECTED wallet (mandatory)
          final walletId = _selectedWalletId ?? 'wallet_cash';

          // PHASE 1 INFRASTRUCTURE: Create investment transaction with full metadata
          final investmentTransaction = FinanceTransaction(
            id: 'tx_asset_${DateTime.now().millisecondsSinceEpoch}',

            // DISPLAY & INTENT
            title: '$symbol Alimi', // Explicit UI title
            description:
                'Yatirim islemi - \$${totalCostUSD.toStringAsFixed(2)}',

            // CORE BEHAVIOR
            type:
                FinanceTransactionType.investment, // Cash → Asset (NOT expense)
            category: FinanceCategory.investment, // For analytics

            // MONEY
            amountMinor: totalCostMinorTRY, // TRY amount

            // WALLET
            walletId: walletId,

            // INVESTMENT METADATA
            assetId: symbol, // Link to asset
            toAssetId: symbol, // Target asset
            originalAmount: totalCostUSD, // USD amount
            originalCurrency: 'USD',

            // DATES
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );

          // Add transaction to deduct from cash
          await ref
              .read(financeProvider.notifier)
              .addTransaction(investmentTransaction);

          print(
              '[ASSET] Created INVESTMENT: ${totalCostMinorTRY / 100} TRY (\$${totalCostUSD.toStringAsFixed(2)}) for $symbol');
        }
      }

      if (mounted) {
        // 6. CRITICAL: Invalidate providers to refresh state
        ref.invalidate(assetListProvider);
        ref.invalidate(portfolioSummaryProvider);

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_purchaseType == AssetPurchaseType.buyNow
                ? 'Varlık satın alındı! Gider işlemi oluşturuldu ✅'
                : _isFromMarketBoard
                    ? 'Varlık canlı takip ile eklendi ✅'
                    : 'Varlık portföye eklendi ✅'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _parseMinor(String text) {
    final clean = text.replaceAll(',', '.');
    final doubleVal = double.tryParse(clean) ?? 0.0;
    return (doubleVal * 100).round();
  }

  int _calculateTotalCost() {
    final quantity = _parseMinor(_quantityController.text);
    final price = _parseMinor(_priceController.text);
    return (quantity * price) ~/ 100;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fmt = ref.watch(formatServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFromMarketBoard ? 'Varlık Ekle' : 'Manuel Varlık Ekle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Tracking Badge
              _buildTrackingBadge(),
              const SizedBox(height: 16),

              // Symbol (OPTIONAL in manual mode)
              TextFormField(
                controller: _symbolController,
                decoration: InputDecoration(
                  labelText:
                      _isFromMarketBoard ? 'Sembol' : 'Sembol (Opsiyonel)',
                  hintText: _isFromMarketBoard
                      ? 'Örn: BTC'
                      : 'Boş bırakırsanız otomatik oluşturulur',
                  prefixIcon: const Icon(Icons.label),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isFromMarketBoard
                      ? const Icon(Icons.lock, color: Colors.grey)
                      : null,
                ),
                readOnly: _isFromMarketBoard,
                textCapitalization: TextCapitalization.characters,
                // Symbol is OPTIONAL in manual mode, REQUIRED in market mode
                validator: _isFromMarketBoard
                    ? (v) => v == null || v.isEmpty ? 'Sembol gerekli' : null
                    : null, // No validation for manual mode
              ),
              const SizedBox(height: 16),

              // Name (REQUIRED)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Varlık Adı',
                  hintText: 'Örn: Apple Inc., Bitcoin, Evim',
                  prefixIcon: const Icon(Icons.business),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isFromMarketBoard
                      ? const Icon(Icons.lock, color: Colors.grey)
                      : null,
                ),
                readOnly: _isFromMarketBoard,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Varlık adı gerekli' : null,
              ),
              const SizedBox(height: 16),

              // INPUT MODE TOGGLE: Miktar Gir vs Tutar Gir
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2230),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Mode 0: Miktar Gir (Quantity)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _inputMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _inputMode == 0
                                ? Colors.blueAccent.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: _inputMode == 0
                                ? Border.all(color: Colors.blueAccent)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Miktar Gir',
                              style: TextStyle(
                                color: _inputMode == 0
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                fontWeight: _inputMode == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Mode 1: Tutar Gir (Amount)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _inputMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _inputMode == 1
                                ? Colors.greenAccent.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: _inputMode == 1
                                ? Border.all(color: Colors.greenAccent)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Tutar Gir (\$)',
                              style: TextStyle(
                                color: _inputMode == 1
                                    ? Colors.greenAccent
                                    : Colors.grey,
                                fontWeight: _inputMode == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CONDITIONAL FIELD: Either Quantity or Total Amount
              if (_inputMode == 0) ...[
                // Mode A: Miktar Gir (User enters quantity)
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: 'Orn: 1.5, 100',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Miktar gerekli';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val <= 0)
                      return 'Gecerli miktar giriniz';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                // Mode B: Tutar Gir (User enters amount)
                // 🆕 CURRENCY TOGGLE: USD vs TRY
                Row(
                  children: [
                    // Currency selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2230),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currencyInputMode == 0
                              ? Colors.greenAccent.withOpacity(0.5)
                              : Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _currencyInputMode,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('USD \$',
                                  style: TextStyle(color: Colors.greenAccent)),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('TRY ₺',
                                  style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _currencyInputMode = value ?? 0;
                              _recalculateCosts();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Amount input field
                    Expanded(
                      child: TextFormField(
                        controller: _totalAmountController,
                        decoration: InputDecoration(
                          labelText: _currencyInputMode == 0
                              ? 'Toplam Tutar (USD)'
                              : 'Toplam Tutar (TL)',
                          hintText: _currencyInputMode == 0
                              ? 'Örn: 100, 500'
                              : 'Örn: 1000, 5000',
                          prefixIcon: Icon(
                            _currencyInputMode == 0
                                ? Icons.attach_money
                                : Icons.currency_lira,
                          ),
                          border: const OutlineInputBorder(),
                          helperText: _calculateQuantityFromAmount(),
                          helperStyle:
                              const TextStyle(color: Colors.greenAccent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Tutar gerekli';
                          final val = double.tryParse(v.replaceAll(',', '.'));
                          if (val == null || val <= 0)
                            return 'Geçerli tutar giriniz';
                          return null;
                        },
                        onChanged: (_) => setState(() {
                          _recalculateCosts();
                        }),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Price with Time Machine button
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Alış Fiyatı (\$)',
                  hintText: 'Örn: 100.50',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  helperText: _historicalPriceHelperText,
                  helperMaxLines: 2,
                  // Time Machine button for market assets
                  suffixIcon: _isFromMarketBoard
                      ? _isLoadingHistoricalPrice
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.calendar_month),
                              tooltip: 'Tarih Seç (Time Machine)',
                              onPressed: _showDatePicker,
                            )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Fiyat gerekli';
                  final val = double.tryParse(v.replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Geçerli fiyat giriniz';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              // Time Machine hint for market assets
              if (_isFromMarketBoard) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geçmiş bir tarihte aldıysanız, 📅 butonuna tıklayarak o tarihteki fiyatı getirebilirsiniz.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Total Cost Display
              _buildTotalCostCard(fmt, colors),
              const SizedBox(height: 16),

              // 🆕 WALLET SELECTOR (MANDATORY)
              _buildWalletSelector(colors),
              const SizedBox(height: 24),

              // Purchase Type Selection
              _buildPurchaseTypeSelector(colors),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  // 🆕 Disable if loading OR insufficient funds on cash wallet
                  onPressed:
                      (_isLoading || _hasInsufficientFunds) ? null : _saveAsset,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_hasInsufficientFunds ? Icons.block : Icons.add),
                  label: Text(_isLoading
                      ? 'Ekleniyor...'
                      : _hasInsufficientFunds
                          ? 'Yetersiz Bakiye'
                          : _purchaseType == AssetPurchaseType.buyNow
                              ? 'Satın Al ve Ekle'
                              : 'Portföye Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingBadge() {
    if (_isFromMarketBoard) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.15),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.cloud_done, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Canlı Veri Takibi Aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Kaynak: ${_source?.label ?? 'Bilinmiyor'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _source == MarketSource.coinGecko
                    ? const Color(0xFF00D09C).withOpacity(0.2)
                    : const Color(0xFF7B61FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _source?.label ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _source == MarketSource.coinGecko
                      ? const Color(0xFF00D09C)
                      : const Color(0xFF7B61FF),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manuel Takip',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Fiyat güncellemeleri manuel yapılacak',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTotalCostCard(FormatService fmt, ColorScheme colors) {
    // Use reactive cached values
    _recalculateCosts();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withOpacity(0.5),
            colors.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.calculate, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hesaplama Özeti',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main cost display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Maliyet (TL):',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '₺${_cachedTotalCostTRY.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // USD equivalent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USD Karşılığı:',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '\$${(_cachedTotalCostTRY / kUsdTryRate).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),

          // Quantity display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alınacak Miktar:',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                _formatAssetQuantity(_cachedQuantity),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format asset quantity with appropriate decimal places
  String _formatAssetQuantity(double amount) {
    if (amount == 0) return '0';
    if (amount >= 1) return amount.toStringAsFixed(4);
    // For small amounts, show more precision
    String s = amount.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  /// 🆕 WALLET SELECTOR (MANDATORY)
  Widget _buildWalletSelector(ColorScheme colors) {
    final wallets = ref.watch(financeProvider).wallets;

    // Auto-select first wallet if none selected
    if (_selectedWalletId == null && wallets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedWalletId = wallets.first.id);
      });
    }

    // Get selected wallet
    final selectedWallet = wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : wallets.first,
    );
    final balance = selectedWallet.balanceMinor / 100.0;

    // 🆕 FIX: Credit cards ALWAYS allow debt (no insufficient funds check)
    // Only check balance for cash wallets in buyNow mode
    final isCreditCard = selectedWallet.type.name == 'creditCard';
    final hasInsufficientFunds = _purchaseType == AssetPurchaseType.buyNow &&
        !isCreditCard && // Credit cards skip this check
        balance < _cachedTotalCostTRY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Kaynağı',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: hasInsufficientFunds
                ? Colors.red.withOpacity(0.1)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasInsufficientFunds
                  ? Colors.red.withOpacity(0.5)
                  : colors.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWalletId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: wallets.map((wallet) {
                final emoji = wallet.type.name == 'cash' ? '💵' : '💳';
                final walletBalance = wallet.balanceMinor / 100.0;
                return DropdownMenuItem<String>(
                  value: wallet.id,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(wallet.name),
                        ],
                      ),
                      Text(
                        '₺${walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: walletBalance < 0
                              ? Colors.red
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedWalletId = value);
              },
            ),
          ),
        ),
        // Insufficient funds warning
        if (hasInsufficientFunds) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yetersiz bakiye! Mevcut: ₺${balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPurchaseTypeSelector(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İşlem Türü',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                AssetPurchaseType.addToPortfolio,
                'Portföye Ekle',
                'Sadece kayıt tut',
                Icons.folder_copy,
                colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                AssetPurchaseType.buyNow,
                'Satın Al',
                'Gider olarak kaydet',
                Icons.shopping_cart,
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    AssetPurchaseType type,
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colors,
  ) {
    final isSelected = _purchaseType == type;

    // Neon colors for better visibility
    const selectedGradient = [
      Color(0xFF6B21A8),
      Color(0xFF7C3AED)
    ]; // Deep Purple
    const selectedBorderColor = Color(0xFF8B5CF6); // Violet
    const selectedContentColor = Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _purchaseType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: selectedGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedBorderColor
                : colors.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBorderColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Checkmark for selected
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(height: 4),
            Icon(
              icon,
              color: isSelected ? selectedContentColor : colors.onSurface,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? selectedContentColor : colors.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? selectedContentColor.withOpacity(0.8)
                    : colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

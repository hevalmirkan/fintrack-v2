/// ====================================================
/// PHASE 4 STEP 3 — ADD SHARED EXPENSE SCREEN
/// ====================================================
///
/// This screen allows users to add a new expense to a shared group.
///
/// CRITICAL WALLET SAFETY RULES:
/// - Wallet transaction occurs ONLY if payer.isCurrentUser == true
/// - If payer is NOT currentUser: NO FinanceTransaction, NO wallet change
/// - Provider handles this logic internally
///
/// PHASE 4 GOLDEN CONTRACT:
/// "Expense creates debt. Wallet changes only if I am involved."
/// ====================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/currency_service.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../providers/shared_expense_provider.dart';

class AddSharedExpenseScreen extends ConsumerStatefulWidget {
  final SharedGroup group;

  const AddSharedExpenseScreen({super.key, required this.group});

  @override
  ConsumerState<AddSharedExpenseScreen> createState() =>
      _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState
    extends ConsumerState<AddSharedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  late String _selectedPayerId;
  late Set<String> _selectedSplitMemberIds;
  DateTime _selectedDate = DateTime.now();
  bool _isLendingMode = false; // Phase 5.4: Lending Mode (Borç Verme)

  // 🆕 PHASE 6.7: Multi-Currency Support
  String _selectedCurrency = 'TRY';
  final _exchangeRateController = TextEditingController();
  static const List<String> _supportedCurrencies = ['TRY', 'USD', 'EUR', 'GBP'];
  final _currencyService = CurrencyService();
  bool _isFetchingRate = false;

  /// Auto-fetch exchange rate when currency changes
  Future<void> _fetchExchangeRate() async {
    if (_selectedCurrency == 'TRY') return;

    setState(() => _isFetchingRate = true);

    try {
      final currency = CurrencyService.fromString(_selectedCurrency);
      if (currency != null && currency != Currency.TRY) {
        final rate = await _currencyService.getRate(currency);
        if (mounted) {
          _exchangeRateController.text = rate.toStringAsFixed(2);
          debugPrint(
              '[SHARED] Auto-fetched rate: 1 $_selectedCurrency = $rate TRY');
        }
      }
    } catch (e) {
      debugPrint('[SHARED] Failed to fetch rate, manual entry required: $e');
    } finally {
      if (mounted) setState(() => _isFetchingRate = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Default payer: currentUser ("Ben")
    final currentUser = widget.group.currentUser;
    _selectedPayerId = currentUser?.id ?? widget.group.members.first.id;

    // Default split: ALL members checked
    _selectedSplitMemberIds = widget.group.members.map((m) => m.id).toSet();
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title:
            const Text('Harcama Ekle', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group info header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.group.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================== DESCRIPTION ====================
            const Text('Açıklama',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Yemek, Market, Benzin...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1E2230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama gerekli';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // 🆕 PHASE 6.7: UNIFIED AMOUNT + CURRENCY ROW (matches personal tx)
            const Text('Tutar',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
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
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon:
                          const Icon(Icons.attach_money, color: Colors.green),
                      filled: true,
                      fillColor: const Color(0xFF1E2230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}), // Refresh preview
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Geçerli tutar girin';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Currency Dropdown (Compact)
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2230),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: const Color(0xFF1E2230),
                        isExpanded: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        items: _supportedCurrencies.map((currency) {
                          final symbols = {
                            'TRY': '₺',
                            'USD': '\$',
                            'EUR': '€',
                            'GBP': '£'
                          };
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('${symbols[currency]}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                            _fetchExchangeRate(); // 🤖 Auto-fetch rate
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🆕 EXCHANGE RATE (only for foreign currencies)
            if (_selectedCurrency != 'TRY') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _exchangeRateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Kur (1 $_selectedCurrency = ? ₺)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.currency_exchange,
                            color: Colors.orange),
                        suffixText: _isFetchingRate ? '...' : null,
                        filled: true,
                        fillColor: const Color(0xFF1E2230),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}), // Refresh preview
                      validator: (value) {
                        if (_selectedCurrency != 'TRY') {
                          final rate = double.tryParse(value ?? '');
                          if (rate == null || rate <= 0) {
                            return 'Geçerli kur girin';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  // Refresh button
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isFetchingRate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: _isFetchingRate ? null : _fetchExchangeRate,
                    tooltip: 'Güncel kuru al',
                  ),
                ],
              ),
              // Live preview
              Builder(builder: (context) {
                final amount = double.tryParse(_amountController.text) ?? 0;
                final rate = double.tryParse(_exchangeRateController.text) ?? 0;
                final tryAmount = amount * rate;
                if (amount > 0 && rate > 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${amount.toStringAsFixed(2)} $_selectedCurrency = ${CurrencyFormatter.formatShort(tryAmount)}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],

            const SizedBox(height: 20),

            // ==================== DATE ====================
            const Text('Tarih',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2230),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today,
                        color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================== PAYER DROPDOWN ====================
            const Text('Ödeyen',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPayerId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E2230),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: m.isCurrentUser
                                      ? Colors.orange
                                      : Colors.grey,
                                  child: Text(
                                    m.name[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  m.isCurrentUser ? 'Ben (Sen)' : m.name,
                                  style: TextStyle(
                                    color: m.isCurrentUser
                                        ? Colors.orange
                                        : Colors.white,
                                    fontWeight: m.isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      final oldPayerId = _selectedPayerId;
                      _selectedPayerId = v;

                      // HOTFIX: If in lending mode, swap exclusion from old payer to new payer
                      if (_isLendingMode) {
                        _selectedSplitMemberIds
                            .add(oldPayerId); // Restore old payer
                        _selectedSplitMemberIds.remove(v); // Exclude new payer
                      }
                    });
                  },
                ),
              ),
            ),

            // Wallet impact warning
            Builder(builder: (_) {
              final selectedPayer =
                  members.where((m) => m.id == _selectedPayerId).firstOrNull;
              final isCurrentUserPaying = selectedPayer?.isCurrentUser ?? false;

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      isCurrentUserPaying
                          ? Icons.account_balance_wallet
                          : Icons.info_outline,
                      color: isCurrentUserPaying ? Colors.orange : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCurrentUserPaying
                          ? '⚠️ Cüzdanından düşecek'
                          : 'Cüzdanını etkilemez',
                      style: TextStyle(
                        color: isCurrentUserPaying
                            ? Colors.orange
                            : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // ==================== PHASE 5.4: LENDING MODE TOGGLE ====================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLendingMode
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLendingMode
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Borç Verme Modu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tamamı karşı tarafa borç olarak kaydedilir',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isLendingMode,
                        onChanged: (value) {
                          setState(() {
                            _isLendingMode = value;
                            if (value) {
                              // HOTFIX: Remove PAYER from split in lending mode (not currentUser)
                              // The payer lends money, so payer.share = 0
                              _selectedSplitMemberIds.remove(_selectedPayerId);
                            } else {
                              // Add payer back in normal mode
                              _selectedSplitMemberIds.add(_selectedPayerId);
                            }
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                  if (_isLendingMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Ödeyenin payı 0 olarak kaydedilir. Tüm tutar borç olarak yazılır.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================== SPLIT PARTICIPANTS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bölüşenler',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(
                  '${_selectedSplitMemberIds.length}/${members.length} üye',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isLendingMode
                  ? 'Sadece karşı taraf borcunu öder'
                  : 'Eşit Bölüşüm (her kişi aynı payı öder)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Member checkboxes
            ...members.map((m) => CheckboxListTile(
                  value: _selectedSplitMemberIds.contains(m.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedSplitMemberIds.add(m.id);
                      } else {
                        // Must have at least 1 member in split
                        if (_selectedSplitMemberIds.length > 1) {
                          _selectedSplitMemberIds.remove(m.id);
                        }
                      }
                    });
                  },
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: m.isCurrentUser
                            ? Colors.orange
                            : Colors.grey.shade700,
                        child: Text(
                          m.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        m.isCurrentUser ? 'Ben (Sen)' : m.name,
                        style: TextStyle(
                          color: m.isCurrentUser ? Colors.orange : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  activeColor: Colors.green,
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                )),

            const SizedBox(height: 24),

            // ==================== SUMMARY ====================
            if (_amountController.text.isNotEmpty &&
                _selectedSplitMemberIds.isNotEmpty)
              _buildSplitSummary(),

            const SizedBox(height: 16),

            // ==================== ADD BUTTON ====================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Harcama Ekle',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final splitCount = _selectedSplitMemberIds.length;
    final perPerson = splitCount > 0 ? amount / splitCount : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Özet',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Toplam: ${CurrencyFormatter.format(amount)}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Kişi başı: ${CurrencyFormatter.format(perPerson.toDouble())} ($splitCount kişi)',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1E2230),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _addExpense() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSplitMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('En az bir bölüşen seçin'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final description = _descController.text.trim();
    final inputAmount = double.parse(_amountController.text);

    // 🆕 PHASE 6.7: Convert to TRY if foreign currency
    // CRITICAL: All debt calculations happen in TRY
    double totalAmountTRY;
    if (_selectedCurrency != 'TRY') {
      final rate = double.parse(_exchangeRateController.text);
      totalAmountTRY = inputAmount * rate;
      debugPrint(
          '[SHARED] Currency conversion: $inputAmount $_selectedCurrency × $rate = $totalAmountTRY TRY');
    } else {
      totalAmountTRY = inputAmount;
    }

    final splitCount = _selectedSplitMemberIds.length;
    final perPerson = totalAmountTRY / splitCount;

    // ================================================================
    // BUILD SPLIT MAP (EQUAL SPLIT)
    // Each selected member gets an equal share (IN TRY)
    // ================================================================
    final splitMap = <String, double>{};
    for (final memberId in _selectedSplitMemberIds) {
      splitMap[memberId] = perPerson;
    }

    try {
      // ================================================================
      // CRITICAL: Call provider's addExpense
      // - Wallet transaction ONLY if payer.isCurrentUser == true
      // - Provider handles this logic internally
      // - ALL amounts are in TRY
      // ================================================================
      ref.read(sharedExpenseProvider.notifier).addExpense(
            groupId: widget.group.id,
            payerId: _selectedPayerId,
            totalAmount: totalAmountTRY, // 🆕 Use TRY amount
            splitMap: splitMap,
            description: _selectedCurrency != 'TRY'
                ? '$description ($inputAmount $_selectedCurrency)'
                : description,
          );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$description eklendi ✅ (${CurrencyFormatter.formatShort(totalAmountTRY)})'),
          backgroundColor: Colors.green,
        ),
      );
    } on SharedExpenseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hata: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }
}

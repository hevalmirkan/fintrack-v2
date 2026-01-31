// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/installment.dart';
// Finance Provider for LOCAL STATE
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';

// Simplified formatter - just filters invalid chars, NO auto-formatting
class SimpleCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow only digits, comma, and single dot
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d,.]'), '');

    // Replace comma with dot for decimal
    filtered = filtered.replaceAll(',', '.');

    // Prevent multiple decimal points
    int dotCount = '.'.allMatches(filtered).length;
    if (dotCount > 1) {
      return oldValue;
    }

    // Limit to 2 decimal places
    if (filtered.contains('.')) {
      List<String> parts = filtered.split('.');
      if (parts.length == 2 && parts[1].length > 2) {
        filtered = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class AddInstallmentScreen extends ConsumerStatefulWidget {
  const AddInstallmentScreen({super.key});

  @override
  ConsumerState<AddInstallmentScreen> createState() =>
      _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends ConsumerState<AddInstallmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _countController = TextEditingController();
  final _initiallyPaidCountController = TextEditingController(text: '0');

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _totalAmountController.dispose();
    _countController.dispose();
    _initiallyPaidCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse inputs
      final title = _titleController.text;
      final cleanAmount = _totalAmountController.text.trim();
      final totalAmountDouble = double.parse(cleanAmount);
      final totalAmountMinor = (totalAmountDouble * 100).round();
      final count = int.parse(_countController.text);
      final initiallyPaid =
          int.tryParse(_initiallyPaidCountController.text) ?? 0;

      // Validation
      if (totalAmountMinor <= 0) {
        throw Exception('Tutar sıfırdan büyük olmalıdır');
      }
      if (initiallyPaid >= count) {
        throw Exception(
            'Ödenmiş taksit sayısı toplam taksit sayısından az olmalıdır');
      }

      // Calculations
      final amountPerInstallment = (totalAmountMinor / count).floor();

      // Create Installment Entity
      final installment = Installment(
        id: 'inst_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        totalAmount: totalAmountMinor,
        remainingAmount: totalAmountMinor,
        totalInstallments: count,
        paidInstallments: initiallyPaid,
        amountPerInstallment: amountPerInstallment,
        startDate: _selectedDate,
        nextDueDate: _selectedDate,
      );

      // --- LOGIC FIX: Create expense transaction for LOCAL STATE ---
      // IF "Şimdi Öde" (Pay Now) → initiallyPaid == 0 → Create expense for first month
      // IF "Önceden Ödendi" → initiallyPaid > 0 → No new expense (already paid previously)
      if (initiallyPaid == 0) {
        // Create expense transaction for first installment payment
        final expenseTransaction = FinanceTransaction(
          id: 'tx_inst_${DateTime.now().millisecondsSinceEpoch}',
          walletId: 'wallet_default',
          type: FinanceTransactionType.expense,
          amountMinor: amountPerInstallment,
          category: 'Taksit / Borç',
          description: '$title - Taksit 1/$count',
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Update LOCAL state - Dashboard will update immediately
        await ref
            .read(financeProvider.notifier)
            .addTransaction(expenseTransaction);
        print(
            '[LOGIC] Taksit: İlk ödeme gideri oluşturuldu: $amountPerInstallment');
      } else {
        print('[LOGIC] Taksit: Önceden ödendi, yeni gider oluşturulmadı');
      }

      // Also save to repository (background, non-blocking)
      try {
        await ref
            .read(installmentRepositoryProvider)
            .addInstallment(installment, initiallyPaidCount: initiallyPaid)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        print('[REPO] ⚠️ Installment repo failed (ignored): $e');
        // Continue - local state is already updated
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(initiallyPaid == 0
                ? 'Taksit planı oluşturuldu, ilk ödeme gidere eklendi ✅'
                : 'Taksit planı oluşturuldu ✅'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taksit Ekle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Borç / Ürün Adı',
                  hintText: 'Örn: iPhone 15 Pro',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [SimpleCurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Toplam Borç Tutarı',
                  hintText: 'Örn: 50000 veya 50000.50',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  suffixText: 'TL',
                  helperText:
                      'Noktayı ondalık ayırıcı olarak kullanabilirsiniz',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tutar giriniz';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Geçerli sayı giriniz';
                  }
                  final amount = double.parse(v.trim());
                  if (amount <= 0) {
                    return 'Tutar sıfırdan büyük olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Taksit Sayısı',
                  hintText: 'Örn: 6',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Sayı giriniz';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Pozitif tam sayı giriniz';
                  if (n > 60) return 'Maksimum 60 taksit';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initiallyPaidCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Daha Önce Ödenmiş Taksit Sayısı',
                  hintText: 'Varsayılan: 0',
                  prefixIcon: Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(),
                  helperText: 'Opsiyonel - Geçmişte ödenen taksitler için',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Geçerli sayı giriniz';

                  final totalCount = int.tryParse(_countController.text);
                  if (totalCount != null && n >= totalCount) {
                    return 'Toplam taksit sayısından az olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'İlk Ödeme Tarihi',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

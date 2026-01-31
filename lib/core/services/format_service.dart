import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

part 'format_service.g.dart';

@Riverpod(keepAlive: true)
FormatService formatService(Ref ref) {
  return FormatService(ref);
}

class FormatService {
  final Ref _ref;

  FormatService(this._ref);

  String formatCurrency(int amountMinor) {
    final settings = _ref.read(settingsProvider).value;
    final currencyCode = settings?.baseCurrency ?? 'USD';
    final minorFactor = settings?.baseMinorFactor ?? 2; // Default 100

    final factor = _getPowerOfTen(minorFactor);
    final amount = amountMinor / factor;

    return NumberFormat.currency(
            symbol: '', name: currencyCode, decimalDigits: minorFactor)
        .format(amount)
        .trim(); // Trim to remove potential trailing spaces if symbol is empty
    // Start with simple symbol-less formatting or use standard currency symbols.
    // User requested: "100.50 ₺". So number first, then symbol?
    // Let's use standard compact currency for now or simple "100.50 USD".
    // Better: NumberFormat.simpleCurrency(name: currencyCode).format(amount);

    // Strict user request: "10050 minor units -> '100.50 ₺'"
    // This implies we want the symbol.
    final fmt =
        NumberFormat.currency(name: currencyCode, decimalDigits: minorFactor);
    return fmt.format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  int _getPowerOfTen(int exponent) {
    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}

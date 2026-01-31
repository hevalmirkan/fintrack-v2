/// =====================================================
/// FRANKFURTER SERVICE — Phase 8.5: Fiat Exchange Rates
/// =====================================================
/// No API key required. Uses public Frankfurter API.
/// Fetches real-time forex rates (USD, EUR, GBP to TRY).
/// =====================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from Frankfurter API
class FrankfurterRate {
  final String currency;
  final double rateTry; // 1 unit = X TRY

  FrankfurterRate({
    required this.currency,
    required this.rateTry,
  });
}

/// Frankfurter Public API Service (No API Key Required)
class FrankfurterService {
  static const String _baseUrl = 'https://api.frankfurter.app';

  /// v1.0 Locked Set - Fiat Currencies
  static const List<String> supportedFiat = ['USD', 'EUR', 'GBP'];

  /// Fetch all fiat rates to TRY at once
  Future<Map<String, FrankfurterRate>> fetchAllRates() async {
    final results = <String, FrankfurterRate>{};

    try {
      // Frankfurter returns rates FROM base TO other currencies
      // We want: 1 USD = ? TRY, 1 EUR = ? TRY, 1 GBP = ? TRY
      // So we fetch TRY base and then invert

      final url = Uri.parse('$_baseUrl/latest?from=TRY&to=USD,EUR,GBP');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        // Frankfurter returns: 1 TRY = X USD
        // We need: 1 USD = Y TRY (so Y = 1/X)
        for (final currency in supportedFiat) {
          final rate = rates[currency];
          if (rate != null) {
            final rateValue = (rate as num).toDouble();
            final invertedRate = 1 / rateValue; // 1 USD = invertedRate TRY

            results[currency] = FrankfurterRate(
              currency: currency,
              rateTry: invertedRate,
            );
          }
        }
      }
    } catch (e) {
      // Return empty on error - caller will handle fallback
    }

    return results;
  }

  /// Fetch a single currency rate to TRY
  Future<double?> fetchRate(String currency) async {
    try {
      final url = Uri.parse('$_baseUrl/latest?from=TRY&to=$currency');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates[currency];

        if (rate != null) {
          return 1 / (rate as num).toDouble();
        }
      }
    } catch (e) {
      // Silent fail
    }

    return null;
  }

  /// Check if we support this currency
  bool isSupported(String currency) =>
      supportedFiat.contains(currency.toUpperCase());
}

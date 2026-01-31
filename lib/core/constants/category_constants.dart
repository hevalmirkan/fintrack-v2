/// Finance Categories - Centralized category management
///
/// Contains all predefined income and expense categories
/// organized by logical groups.
class CategoryConstants {
  // ============================================================
  // EXPENSE CATEGORIES (Grouped)
  // ============================================================

  static const Map<String, List<String>> expenseCategories = {
    'Fatura & Ev': [
      'Elektrik',
      'Su',
      'Doğalgaz',
      'İnternet',
      'Telefon',
      'Site Aidatı',
      'Kira',
    ],
    'Ulaşım & Seyahat': [
      'Benzin',
      'Toplu Taşıma',
      'Uçak Bileti',
      'Otel',
      'Tatil',
    ],
    'Eğitim & Kişisel Gelişim': [
      'Kitap/Dergi',
      'Online Kurs',
    ],
    'Devlet & Vergi': [
      'Bağkur',
      'SGK',
      'KYK',
      'MTV',
      'Emlak Vergisi',
    ],
    'Dijital Abonelikler': [
      'Netflix',
      'Spotify',
      'YouTube Premium',
      'iCloud',
      'Amazon Prime',
    ],
    'Yeme & İçme': [
      'Restoran',
      'Fast Food',
      'Market',
      'Kahve',
    ],
    'Sağlık': [
      'İlaç',
      'Doktor',
      'Sigorta',
    ],
    'Diğer': [
      'Hediye',
      'Bağış',
      'Diğer Gider',
    ],
  };

  // ============================================================
  // INCOME CATEGORIES
  // ============================================================

  static const List<String> incomeCategories = [
    'Maaş',
    'Ek Gelir',
    'Yatırım Geliri',
    'Freelance',
    'Kira Geliri',
    'Bonus',
    'Diğer Gelir',
  ];

  // ============================================================
  // FLAT LISTS (for dropdowns)
  // ============================================================

  /// All expense categories flattened into a single list
  static List<String> get allExpenseCategories {
    final List<String> all = [];
    for (final group in expenseCategories.values) {
      all.addAll(group);
    }
    return all;
  }

  /// Get category group name for an expense category
  static String? getGroupForCategory(String category) {
    for (final entry in expenseCategories.entries) {
      if (entry.value.contains(category)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get icon for category
  static String getIconForCategory(String category) {
    final groupIcons = {
      'Fatura & Ev': '🏠',
      'Ulaşım & Seyahat': '🚗',
      'Eğitim & Kişisel Gelişim': '📚',
      'Devlet & Vergi': '🏛️',
      'Dijital Abonelikler': '📱',
      'Yeme & İçme': '🍔',
      'Sağlık': '🏥',
      'Diğer': '📦',
    };

    final group = getGroupForCategory(category);
    if (group != null) {
      return groupIcons[group] ?? '💰';
    }

    // Income categories
    final incomeIcons = {
      'Maaş': '💼',
      'Ek Gelir': '💵',
      'Yatırım Geliri': '📈',
      'Freelance': '💻',
      'Kira Geliri': '🏢',
      'Bonus': '🎁',
      'Diğer Gelir': '💰',
    };

    return incomeIcons[category] ?? '💰';
  }
}

/// Currency Constants for Multi-Currency Support
class CurrencyConstants {
  // Supported currencies
  static const List<String> supportedCurrencies = [
    'TRY',
    'USD',
    'EUR',
    'GBP',
    'Gold/Gr',
    'BTC',
    'ETH',
  ];

  // Currency display labels
  static const Map<String, String> currencyLabels = {
    'TRY': '₺ Türk Lirası',
    'USD': '\$ Amerikan Doları',
    'EUR': '€ Euro',
    'GBP': '£ İngiliz Sterlini',
    'Gold/Gr': '🥇 Altın (Gram)',
    'BTC': '₿ Bitcoin',
    'ETH': 'Ξ Ethereum',
  };

  // Currency symbols
  static const Map<String, String> currencySymbols = {
    'TRY': '₺',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'Gold/Gr': 'gr',
    'BTC': '₿',
    'ETH': 'Ξ',
  };

  // ============================================================
  // MOCK EXCHANGE RATES (to TRY)
  // ============================================================
  static const Map<String, double> mockRatesToTRY = {
    'TRY': 1.0,
    'USD': 35.5, // 1 USD = 35.5 TRY
    'EUR': 38.2, // 1 EUR = 38.2 TRY
    'GBP': 44.8, // 1 GBP = 44.8 TRY
    'Gold/Gr': 2950.0, // 1 gram gold = 2950 TRY
    'BTC': 3130000.0, // 1 BTC = ~3.13M TRY
    'ETH': 105000.0, // 1 ETH = ~105K TRY
  };

  /// Convert amount from source currency to TRY
  /// Returns amount in MINOR units (kuruş)
  static int convertToTRY(double amount, String fromCurrency) {
    final rate = mockRatesToTRY[fromCurrency] ?? 1.0;
    final amountInTRY = amount * rate;
    return (amountInTRY * 100).round(); // Convert to minor units
  }

  /// Get approximate TRY amount for display
  static String getApproximateTRY(double amount, String fromCurrency) {
    if (fromCurrency == 'TRY') return '';

    final rate = mockRatesToTRY[fromCurrency] ?? 1.0;
    final amountInTRY = amount * rate;

    // Format with thousand separators
    final formatted =
        amountInTRY.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );

    return 'Yaklaşık ₺$formatted olarak kaydedilecek';
  }
}

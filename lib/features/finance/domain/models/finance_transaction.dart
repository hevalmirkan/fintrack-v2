import 'package:equatable/equatable.dart';

/// FinanceTransaction - Represents a personal finance transaction
///
/// This is separate from portfolio/trading transactions.
/// Used for income, expenses, investments, and transfers.
///
/// PHASE 1 INFRASTRUCTURE: This model is forward-compatible for:
/// - Investments (asset purchases)
/// - Installments (Phase 3.3)
/// - Recurring transactions
/// - Shared/group expenses (Phase 4)
/// - Reports & exports
class FinanceTransaction extends Equatable {
  final String id;

  // ===== DISPLAY & INTENT =====
  /// Explicit UI title (e.g., "BTC Alımı", "Netflix Aboneliği")
  /// If null, UI should fallback to category label
  final String? title;

  /// Optional detail text for additional context
  final String? description;

  // ===== CORE BEHAVIOR =====
  /// What actually happened (logic-safe behavior)
  final FinanceTransactionType type;

  /// Why it happened (for analytics/reports)
  final String category;
  final String? subcategory;

  // ===== MONEY =====
  /// Amount in minor units (kuruş) - Always TRY
  final int amountMinor;

  /// Source wallet ID
  final String walletId;

  /// Transaction date
  final DateTime date;
  final DateTime createdAt;

  // ===== INVESTMENT METADATA =====
  /// Linked asset ID (for investment transactions)
  final String? assetId;

  /// Target asset ID (for cash → asset conversions)
  final String? toAssetId;

  /// Original amount in foreign currency (if applicable)
  final double? originalAmount;

  /// Original currency code (USD, EUR, etc.)
  final String? originalCurrency;

  /// Exchange rate used at transaction creation (historical reference only)
  /// This is NEVER used for recalculation - purely for transparency
  final double? exchangeRate;

  // ===== INSTALLMENT / SPLIT PREP (Phase 3.3) =====
  /// Parent transaction ID (main installment/split plan)
  final String? parentTransactionId;

  /// Current installment index (e.g., 3 of 10)
  final int? installmentIndex;

  /// Total installment count (e.g., 10)
  final int? installmentTotal;

  // ===== RECURRING PREP =====
  /// Created from a recurring template?
  final bool isRecurring;

  /// Link to recurring template
  final String? recurringId;

  // ===== TAGGING (Phase 4) =====
  /// User-defined tags (e.g., "#Tatil", "#Ortak", "#AhmetOdedi")
  final List<String>? tags;

  // ===== FLEXIBLE METADATA =====
  /// Additional key-value pairs for future extensibility
  final Map<String, dynamic>? metadata;

  const FinanceTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amountMinor,
    required this.category,
    this.subcategory,
    this.title,
    this.description,
    required this.date,
    this.isRecurring = false,
    this.recurringId,
    this.metadata,
    required this.createdAt,
    // Investment metadata
    this.assetId,
    this.toAssetId,
    this.originalAmount,
    this.originalCurrency,
    this.exchangeRate,
    // Installment metadata
    this.parentTransactionId,
    this.installmentIndex,
    this.installmentTotal,
    // Tagging
    this.tags,
  });

  /// Amount in major units
  double get amount => amountMinor / 100;

  /// Signed amount (negative for expenses/investments)
  double get signedAmount {
    switch (type) {
      case FinanceTransactionType.expense:
      case FinanceTransactionType.investment:
        return -amount;
      case FinanceTransactionType.income:
        return amount;
      case FinanceTransactionType.transfer:
      case FinanceTransactionType.adjustment:
        return amount; // Transfers are neutral in net calculation
    }
  }

  /// Display amount with sign
  String displayAmount({String currency = '₺'}) {
    final sign = (type == FinanceTransactionType.expense ||
            type == FinanceTransactionType.investment)
        ? '-'
        : '+';
    return '$sign$currency${amount.toStringAsFixed(2)}';
  }

  /// Display title (title if available, otherwise category)
  String get displayTitle => title?.isNotEmpty == true ? title! : category;

  /// Is this an investment transaction?
  bool get isInvestment => type == FinanceTransactionType.investment;

  /// Is this part of an installment plan?
  bool get isInstallment => parentTransactionId != null;

  /// Installment display string (e.g., "3/10")
  String? get installmentDisplay {
    if (installmentIndex != null && installmentTotal != null) {
      return '$installmentIndex/$installmentTotal';
    }
    return null;
  }

  FinanceTransaction copyWith({
    String? id,
    String? walletId,
    FinanceTransactionType? type,
    int? amountMinor,
    String? category,
    String? subcategory,
    String? title,
    String? description,
    DateTime? date,
    bool? isRecurring,
    String? recurringId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? assetId,
    String? toAssetId,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
    String? parentTransactionId,
    int? installmentIndex,
    int? installmentTotal,
    List<String>? tags,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      assetId: assetId ?? this.assetId,
      toAssetId: toAssetId ?? this.toAssetId,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'type': type.name,
        'amountMinor': amountMinor,
        'category': category,
        'subcategory': subcategory,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'isRecurring': isRecurring,
        'recurringId': recurringId,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        // Investment metadata
        'assetId': assetId,
        'toAssetId': toAssetId,
        'originalAmount': originalAmount,
        'originalCurrency': originalCurrency,
        'exchangeRate': exchangeRate,
        // Installment metadata
        'parentTransactionId': parentTransactionId,
        'installmentIndex': installmentIndex,
        'installmentTotal': installmentTotal,
        // Tags
        'tags': tags,
      };

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      type: _parseTransactionType(json['type'] as String),
      amountMinor: json['amountMinor'] as int,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // Investment metadata
      assetId: json['assetId'] as String?,
      toAssetId: json['toAssetId'] as String?,
      originalAmount: (json['originalAmount'] as num?)?.toDouble(),
      originalCurrency: json['originalCurrency'] as String?,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      // Installment metadata
      parentTransactionId: json['parentTransactionId'] as String?,
      installmentIndex: json['installmentIndex'] as int?,
      installmentTotal: json['installmentTotal'] as int?,
      // Tags
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Parse transaction type with fallback for legacy data
  static FinanceTransactionType _parseTransactionType(String typeName) {
    // Handle legacy 'expense' that should be 'investment' based on category
    // This is handled at read-time for backwards compatibility
    return FinanceTransactionType.values.byName(typeName);
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        type,
        amountMinor,
        category,
        subcategory,
        title,
        description,
        date,
        isRecurring,
        recurringId,
        metadata,
        createdAt,
        assetId,
        toAssetId,
        originalAmount,
        originalCurrency,
        exchangeRate,
        parentTransactionId,
        installmentIndex,
        installmentTotal,
        tags,
      ];
}

/// Transaction types for personal finance
/// Defines WHAT actually happened (behavioral intent)
enum FinanceTransactionType {
  /// Money coming in (salary, freelance, gifts)
  income,

  /// Money going out for consumption (food, bills, entertainment)
  expense,

  /// Cash → Asset conversion (NOT consumption, just form change)
  investment,

  /// Wallet → Wallet movement (no net change)
  transfer,

  /// System or manual balance correction
  adjustment,
}

extension FinanceTransactionTypeExtension on FinanceTransactionType {
  String get displayName {
    switch (this) {
      case FinanceTransactionType.income:
        return 'Gelir';
      case FinanceTransactionType.expense:
        return 'Gider';
      case FinanceTransactionType.investment:
        return 'Yatırım';
      case FinanceTransactionType.transfer:
        return 'Transfer';
      case FinanceTransactionType.adjustment:
        return 'Düzeltme';
    }
  }

  String get icon {
    switch (this) {
      case FinanceTransactionType.income:
        return '📥';
      case FinanceTransactionType.expense:
        return '📤';
      case FinanceTransactionType.investment:
        return '📈';
      case FinanceTransactionType.transfer:
        return '🔄';
      case FinanceTransactionType.adjustment:
        return '⚙️';
    }
  }

  /// Whether this type reduces wallet balance
  bool get reducesBalance {
    switch (this) {
      case FinanceTransactionType.expense:
      case FinanceTransactionType.investment:
        return true;
      case FinanceTransactionType.income:
      case FinanceTransactionType.transfer:
      case FinanceTransactionType.adjustment:
        return false;
    }
  }
}

/// Predefined expense categories
class FinanceCategory {
  static const Map<String, List<String>> expenseCategories = {
    'Yiyecek & İçecek': ['Market', 'Restoran', 'Kahve', 'Fast Food'],
    'Ulaşım': ['Yakıt', 'Toplu Taşıma', 'Taksi', 'Araç Bakım'],
    'Faturalar': ['Elektrik', 'Doğalgaz', 'Su', 'İnternet', 'Telefon'],
    'Kira & Konut': ['Kira', 'Aidat', 'Tamirat'],
    'Sağlık': ['İlaç', 'Doktor', 'Sigorta'],
    'Eğlence': ['Sinema', 'Oyun', 'Hobi', 'Spor'],
    'Giyim': ['Kıyafet', 'Ayakkabı', 'Aksesuar'],
    'Yatırım': ['Kripto', 'Hisse', 'Altın', 'Döviz'],
    'Diğer': ['Hediye', 'Bağış', 'Diğer'],
  };

  static const List<String> incomeCategories = [
    'Maaş',
    'Freelance',
    'Yatırım Geliri',
    'Kira Geliri',
    'Hediye',
    'Diğer',
  ];

  /// Investment category constant
  static const String investment = 'Yatırım';
}

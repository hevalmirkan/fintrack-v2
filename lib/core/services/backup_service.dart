/// ====================================================
/// PHASE 6 — BACKUP SERVICE
/// ====================================================
///
/// Provides full data backup and restore functionality.
///
/// CRITICAL RULES:
/// - Backup contains ONLY source-of-truth data
/// - NO derived state (balances, totals, net worth)
/// - Restore MUST validate before clearing existing data
/// - On failure: DO NOT wipe existing data
/// ====================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

// Conditional import for web download
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_helper.dart';

import '../../features/finance/data/finance_provider.dart';
import '../../features/finance/domain/models/wallet.dart';
import '../../features/finance/domain/models/finance_transaction.dart';
import '../../features/assets/domain/entities/asset.dart';
import '../../features/shared_expenses/presentation/providers/shared_expense_provider.dart';
import '../../features/shared_expenses/domain/entities/shared_expense_models.dart';
import '../../features/subscriptions/presentation/providers/subscription_provider.dart';
import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/installments/presentation/providers/mock_installment_provider.dart';
import '../../features/installments/domain/entities/installment.dart';

/// Backup metadata version
const int kBackupVersion = 1;
const String kAppIdentifier = 'fintrack_v2';

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final String? errorMessage;
  final int? itemsRestored;

  const RestoreResult({
    required this.success,
    this.errorMessage,
    this.itemsRestored,
  });

  factory RestoreResult.success(int items) => RestoreResult(
        success: true,
        itemsRestored: items,
      );

  factory RestoreResult.failure(String message) => RestoreResult(
        success: false,
        errorMessage: message,
      );
}

/// Backup validation result
class BackupValidation {
  final bool isValid;
  final String? error;
  final int? version;
  final DateTime? createdAt;

  const BackupValidation({
    required this.isValid,
    this.error,
    this.version,
    this.createdAt,
  });
}

/// Main Backup Service
class BackupService {
  // ============================================================
  // EXPORT (Backup Generation)
  // ============================================================

  /// Generate backup data from all providers
  static Map<String, dynamic> generateBackupData(WidgetRef ref) {
    final financeState = ref.read(financeProvider);
    final sharedState = ref.read(sharedExpenseProvider);
    final subscriptionState = ref.read(subscriptionProvider);
    final installmentState = ref.read(mockInstallmentProvider);

    return {
      // FINANCE DATA
      'wallets': financeState.wallets.map((w) => _walletToJson(w)).toList(),
      'transactions': financeState.transactions.map((t) => t.toJson()).toList(),
      'assets': financeState.assets.map((a) => _assetToJson(a)).toList(),

      // INSTALLMENTS (from mock provider)
      'installments': installmentState.installments
          .map((i) => _installmentToJson(i))
          .toList(),

      // SUBSCRIPTIONS
      'subscriptions': subscriptionState.subscriptions
          .map((s) => _subscriptionToJson(s))
          .toList(),

      // SHARED EXPENSES
      'sharedGroups':
          sharedState.groups.map((g) => _sharedGroupToJson(g)).toList(),
      'sharedTransactions': sharedState.transactions
          .map((t) => _groupTransactionToJson(t))
          .toList(),
      'sharedSplits': sharedState.splits.map((s) => _splitToJson(s)).toList(),
    };
  }

  /// Generate full backup JSON with metadata
  static String generateBackupJson(WidgetRef ref) {
    final backup = {
      'app': kAppIdentifier,
      'backupVersion': kBackupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': generateBackupData(ref),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Export backup file (share on mobile, download on web)
  static Future<bool> exportBackupFile(WidgetRef ref) async {
    try {
      final jsonString = generateBackupJson(ref);
      final fileName =
          'fintrack_backup_${_formatDateForFilename(DateTime.now())}.json';

      if (kIsWeb) {
        // Web: Use conditionally imported dart:html helper
        downloadFileWeb(fileName, jsonString, 'application/json');
        print('[BACKUP] Web export triggered: $fileName');
        return true;
      } else {
        // Mobile: Save to temp and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'FinTrack Yedek - ${_formatDateForDisplay(DateTime.now())}',
        );
        return true;
      }
    } catch (e) {
      print('[BACKUP] Export failed: $e');
      return false;
    }
  }

  // ============================================================
  // IMPORT (Restore)
  // ============================================================

  /// Validate backup JSON before restore
  static BackupValidation validateBackup(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check app identifier
      if (json['app'] != kAppIdentifier) {
        return const BackupValidation(
          isValid: false,
          error: 'Bu dosya FinTrack yedek dosyası değil.',
        );
      }

      // Check version
      final version = json['backupVersion'] as int?;
      if (version == null || version > kBackupVersion) {
        return BackupValidation(
          isValid: false,
          error: 'Yedek versiyonu desteklenmiyor (v$version).',
        );
      }

      // Check data exists
      if (json['data'] == null) {
        return const BackupValidation(
          isValid: false,
          error: 'Yedek dosyası bozuk veya eksik.',
        );
      }

      // Parse created date
      DateTime? createdAt;
      if (json['createdAt'] != null) {
        createdAt = DateTime.tryParse(json['createdAt'] as String);
      }

      return BackupValidation(
        isValid: true,
        version: version,
        createdAt: createdAt,
      );
    } catch (e) {
      return BackupValidation(
        isValid: false,
        error: 'JSON dosyası okunamadı: $e',
      );
    }
  }

  /// Pick backup file from device
  static Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        return utf8.decode(result.files.single.bytes!);
      }

      // Fallback for platforms that don't support bytes
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }

      return null;
    } catch (e) {
      print('[BACKUP] File pick failed: $e');
      return null;
    }
  }

  /// Restore from backup JSON
  /// CRITICAL: Only call after user confirmation
  static Future<RestoreResult> restoreFromBackup(
    String jsonString,
    WidgetRef ref,
  ) async {
    // Step 1: Validate
    final validation = validateBackup(jsonString);
    if (!validation.isValid) {
      return RestoreResult.failure(validation.error ?? 'Bilinmeyen hata');
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;

      int itemCount = 0;

      // Step 2: Parse all data BEFORE clearing
      // This ensures we don't lose data if parsing fails

      // Parse wallets
      final wallets = (data['wallets'] as List<dynamic>?)
              ?.map((w) => _walletFromJson(w as Map<String, dynamic>))
              .toList() ??
          [];

      // Parse transactions
      final transactions = (data['transactions'] as List<dynamic>?)
              ?.map(
                  (t) => FinanceTransaction.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      // Parse assets
      final assets = (data['assets'] as List<dynamic>?)
              ?.map((a) => _assetFromJson(a as Map<String, dynamic>))
              .toList() ??
          [];

      // Parse installments
      final installments = (data['installments'] as List<dynamic>?)
              ?.map((i) => _installmentFromJson(i as Map<String, dynamic>))
              .toList() ??
          [];

      // Parse subscriptions
      final subscriptions = (data['subscriptions'] as List<dynamic>?)
              ?.map((s) => _subscriptionFromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      // Parse shared expenses
      final sharedGroups = (data['sharedGroups'] as List<dynamic>?)
              ?.map((g) => _sharedGroupFromJson(g as Map<String, dynamic>))
              .toList() ??
          [];
      final sharedTransactions = (data['sharedTransactions'] as List<dynamic>?)
              ?.map((t) => _groupTransactionFromJson(t as Map<String, dynamic>))
              .toList() ??
          [];
      final sharedSplits = (data['sharedSplits'] as List<dynamic>?)
              ?.map((s) => _splitFromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      // Step 3: Restore all data (parsing succeeded)
      // Restore finance state
      ref.read(financeProvider.notifier).restoreFromBackup(
            wallets: wallets,
            transactions: transactions,
            assets: assets,
          );
      itemCount += wallets.length + transactions.length + assets.length;

      // Restore shared expenses
      ref.read(sharedExpenseProvider.notifier).restoreFromBackup(
            groups: sharedGroups,
            transactions: sharedTransactions,
            splits: sharedSplits,
          );
      itemCount +=
          sharedGroups.length + sharedTransactions.length + sharedSplits.length;

      // Restore subscriptions
      ref.read(subscriptionProvider.notifier).restoreFromBackup(subscriptions);
      itemCount += subscriptions.length;

      // Restore installments
      ref
          .read(mockInstallmentProvider.notifier)
          .restoreFromBackup(installments);
      itemCount += installments.length;

      print('[BACKUP] Restore completed: $itemCount items');
      return RestoreResult.success(itemCount);
    } catch (e) {
      print('[BACKUP] Restore failed: $e');
      return RestoreResult.failure('Geri yükleme başarısız: $e');
    }
  }

  // ============================================================
  // SERIALIZATION HELPERS
  // ============================================================

  // --- WALLET ---
  static Map<String, dynamic> _walletToJson(Wallet w) => {
        'id': w.id,
        'name': w.name,
        'type': w.type.name,
        'currency': w.currency,
        'balanceMinor': w.balanceMinor,
        'iconName': w.iconName,
        'isActive': w.isActive,
        'createdAt': w.createdAt.toIso8601String(),
      };

  static Wallet _walletFromJson(Map<String, dynamic> j) => Wallet(
        id: j['id'] as String,
        name: j['name'] as String,
        type: WalletType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => WalletType.cash,
        ),
        currency: j['currency'] as String? ?? 'TRY',
        balanceMinor: j['balanceMinor'] as int? ?? 0,
        iconName: j['iconName'] as String? ?? 'wallet',
        isActive: j['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  // --- ASSET ---
  static Map<String, dynamic> _assetToJson(Asset a) => {
        'id': a.id,
        'symbol': a.symbol,
        'name': a.name,
        'averagePrice': a.averagePrice,
        'currentPrice': a.currentPrice,
        'quantityMinor': a.quantityMinor,
        'lastKnownPrice': a.lastKnownPrice,
        'lastPriceUpdate': a.lastPriceUpdate?.toIso8601String(),
        'apiId': a.apiId,
      };

  static Asset _assetFromJson(Map<String, dynamic> j) => Asset(
        id: j['id'] as String,
        symbol: j['symbol'] as String,
        name: j['name'] as String,
        averagePrice: j['averagePrice'] as int,
        currentPrice: j['currentPrice'] as int,
        quantityMinor: j['quantityMinor'] as int,
        lastKnownPrice: j['lastKnownPrice'] as int?,
        lastPriceUpdate: j['lastPriceUpdate'] != null
            ? DateTime.parse(j['lastPriceUpdate'] as String)
            : null,
        apiId: j['apiId'] as String?,
      );

  // --- INSTALLMENT ---
  static Map<String, dynamic> _installmentToJson(Installment i) => {
        'id': i.id,
        'title': i.title,
        'totalAmount': i.totalAmount,
        'remainingAmount': i.remainingAmount,
        'totalInstallments': i.totalInstallments,
        'paidInstallments': i.paidInstallments,
        'amountPerInstallment': i.amountPerInstallment,
        'startDate': i.startDate.toIso8601String(),
        'nextDueDate': i.nextDueDate.toIso8601String(),
      };

  static Installment _installmentFromJson(Map<String, dynamic> j) =>
      Installment(
        id: j['id'] as String,
        title: j['title'] as String,
        totalAmount: j['totalAmount'] as int,
        remainingAmount: j['remainingAmount'] as int,
        totalInstallments: j['totalInstallments'] as int,
        paidInstallments: j['paidInstallments'] as int,
        amountPerInstallment: j['amountPerInstallment'] as int,
        startDate: DateTime.parse(j['startDate'] as String),
        nextDueDate: DateTime.parse(j['nextDueDate'] as String),
      );

  // --- SUBSCRIPTION ---
  static Map<String, dynamic> _subscriptionToJson(Subscription s) => {
        'id': s.id,
        'title': s.title,
        'amountMinor': s.amountMinor,
        'renewalDay': s.renewalDay,
        'category': s.category,
        'walletId': s.walletId,
        'isActive': s.isActive,
        'lastPaidDate': s.lastPaidDate?.toIso8601String(),
        'createdAt': s.createdAt.toIso8601String(),
      };

  static Subscription _subscriptionFromJson(Map<String, dynamic> j) =>
      Subscription(
        id: j['id'] as String,
        title: j['title'] as String,
        amountMinor: j['amountMinor'] as int,
        renewalDay: j['renewalDay'] as int,
        category: j['category'] as String,
        walletId: j['walletId'] as String,
        isActive: j['isActive'] as bool? ?? true,
        lastPaidDate: j['lastPaidDate'] != null
            ? DateTime.parse(j['lastPaidDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  // --- SHARED GROUP ---
  static Map<String, dynamic> _sharedGroupToJson(SharedGroup g) => {
        'id': g.id,
        'title': g.title,
        'currency': g.currency,
        'members': g.members.map((m) => _memberToJson(m)).toList(),
        'createdAt': g.createdAt.toIso8601String(),
        'isActive': g.isActive,
      };

  static SharedGroup _sharedGroupFromJson(Map<String, dynamic> j) =>
      SharedGroup(
        id: j['id'] as String,
        title: j['title'] as String,
        currency: j['currency'] as String? ?? 'TRY',
        members: (j['members'] as List<dynamic>)
            .map((m) => _memberFromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        isActive: j['isActive'] as bool? ?? true,
      );

  static Map<String, dynamic> _memberToJson(GroupMember m) => {
        'id': m.id,
        'name': m.name,
        'isCurrentUser': m.isCurrentUser,
        // NOTE: currentBalance is derived, will be recalculated from transactions
      };

  static GroupMember _memberFromJson(Map<String, dynamic> j) => GroupMember(
        id: j['id'] as String,
        name: j['name'] as String,
        isCurrentUser: j['isCurrentUser'] as bool? ?? false,
        currentBalance: 0, // Will be recalculated
      );

  // --- GROUP TRANSACTION ---
  static Map<String, dynamic> _groupTransactionToJson(GroupTransaction t) => {
        'id': t.id,
        'groupId': t.groupId,
        'type': t.type.name,
        'payerId': t.payerId,
        'receiverId': t.receiverId,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'description': t.description,
        'createdAt': t.createdAt.toIso8601String(),
        'financeTransactionId': t.financeTransactionId,
      };

  static GroupTransaction _groupTransactionFromJson(Map<String, dynamic> j) =>
      GroupTransaction(
        id: j['id'] as String,
        groupId: j['groupId'] as String,
        type: GroupTransactionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => GroupTransactionType.expense,
        ),
        payerId: j['payerId'] as String,
        receiverId: j['receiverId'] as String?,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        description: j['description'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        financeTransactionId: j['financeTransactionId'] as String?,
      );

  // --- SPLIT ---
  static Map<String, dynamic> _splitToJson(TransactionSplit s) => {
        'transactionId': s.transactionId,
        'memberId': s.memberId,
        'owedAmount': s.owedAmount,
      };

  static TransactionSplit _splitFromJson(Map<String, dynamic> j) =>
      TransactionSplit(
        transactionId: j['transactionId'] as String,
        memberId: j['memberId'] as String,
        owedAmount: (j['owedAmount'] as num).toDouble(),
      );

  // ============================================================
  // UTILITY HELPERS
  // ============================================================

  static String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_'
        '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDateForDisplay(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/backup_service.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../assets/presentation/providers/asset_providers.dart';
import '../../../coach/data/services/gemini_service.dart';
import '../../../coach/presentation/providers/coach_provider.dart';

/// Settings screen with notification toggles and data management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Theme Section
          _buildSectionHeader(context, '🎨 Görünüm'),
          ListTile(
            leading: Icon(themeState.mode.icon),
            title: const Text('Tema'),
            subtitle: Text(themeState.mode.label),
            trailing: SegmentedButton<AppThemeMode>(
              segments: AppThemeMode.values.map((mode) {
                return ButtonSegment<AppThemeMode>(
                  value: mode,
                  icon: Icon(mode.icon, size: 18),
                  tooltip: mode.label,
                );
              }).toList(),
              selected: {themeState.mode},
              onSelectionChanged: (selected) {
                ref.read(themeProvider.notifier).setThemeMode(selected.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Divider(),

          // Notifications Section
          _buildSectionHeader(context, '🔔 Bildirimler'),
          notificationSettings.when(
            data: (settings) => Column(
              children: [
                SwitchListTile(
                  title: const Text('Günlük Finans İpuçları'),
                  subtitle: const Text('Her gün saat 09:00\'da finansal terim'),
                  value: settings.dailyNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleDailyNotifications(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Haftalık Rapor'),
                  subtitle: const Text('Her Pazar saat 21:00\'de özet rapor'),
                  value: settings.weeklyReportEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleWeeklyReport(value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Bildirimleri Test Et'),
                  subtitle: const Text('Hemen bildirim gönder'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    try {
                      await ref
                          .read(notificationSettingsProvider.notifier)
                          .sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test bildirimi gönderildi! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const ListTile(
              title: Text('Bildirim ayarları yüklenemedi'),
            ),
          ),
          const Divider(),

          // App Section
          _buildSectionHeader(context, '📱 Uygulama'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Önbelleği Temizle'),
            subtitle: const Text('Piyasa verilerini temizle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showClearCacheDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Verileri Sıfırla',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('TÜM verileri sil (geri alınamaz)'),
            trailing: const Icon(Icons.warning, color: Colors.red, size: 20),
            onTap: () => _showResetDataDialog(context, ref),
          ),
          const Divider(),

          // ==================== PHASE 6: BACKUP & EXPORT ====================
          _buildSectionHeader(context, '💾 Veri ve Yedekleme'),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('Yedek Al'),
            subtitle: const Text('Tüm verileri JSON olarak dışa aktar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('Yedeği Geri Yükle'),
            subtitle: const Text('JSON dosyasından verileri içe aktar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleRestore(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Excel / CSV Olarak İndir'),
            subtitle: const Text('İşlem geçmişini CSV olarak dışa aktar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleCsvExport(context, ref),
          ),
          const Divider(),

          // ==================== PHASE 7: AI COACH SECTION ====================
          _buildSectionHeader(context, '🤖 AI Koç'),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Colors.purple),
            title: const Text('AI Koç Ekranı'),
            subtitle: const Text('Finansal asistanınızla sohbet edin'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/coach'),
          ),
          // 📘 API Key Guide (ExpansionTile)
          ExpansionTile(
            leading: const Icon(Icons.key, color: Colors.amber),
            title: const Text('🔑 API Anahtarı Nasıl Alınır?'),
            subtitle: const Text('Adım adım rehber'),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Google hesabınız yoksa önce bir Google/Gmail hesabı oluşturmalısınız.',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "1. 'Ücretsiz Anahtar Al' butonuna tıklayın.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '2. Google hesabınızla giriş yapın.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "3. 'Get API key' → 'Create in new project' seçin.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "4. 'AIza...' ile başlayan kodu kopyalayın.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "5. AI Koç ekranındaki ayarlardan anahtarı yapıştırın.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Open API Key page button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label:
                          const Text('Ücretsiz Anahtar Al (Google AI Studio)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/app/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 🧪 Connection Tester
          ListTile(
            leading: const Icon(Icons.wifi_tethering, color: Colors.green),
            title: const Text('Bağlantıyı Test Et'),
            subtitle: const Text('API anahtarınızı doğrulayın'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () async {
              final gemini = ref.read(geminiServiceProvider);
              final hasKey = await gemini.hasApiKey();

              if (!hasKey) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Önce API anahtarı girin!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              // Show loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Bağlantı test ediliyor...'),
                      ],
                    ),
                    duration: Duration(seconds: 10),
                  ),
                );
              }

              final result = await gemini.testConnection();

              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result),
                    backgroundColor:
                        result.contains('BAŞARILI') ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(context, 'ℹ️ Hakkında'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versiyon'),
            subtitle: Text('v1.0.0 (Beta)'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Geliştirici'),
            subtitle: const Text('FinTrack Education Team'),
            trailing: const Icon(Icons.favorite, color: Colors.red, size: 16),
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  // ==================== PHASE 6: BACKUP HANDLERS ====================

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Yedek oluşturuluyor...'),
          duration: Duration(seconds: 1)),
    );

    final success = await BackupService.exportBackupFile(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Yedek başarıyla oluşturuldu!'
              : '❌ Yedek oluşturulamadı'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    // Pick file
    final jsonString = await BackupService.pickBackupFile();
    if (jsonString == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya seçilmedi')),
        );
      }
      return;
    }

    // Validate
    final validation = BackupService.validateBackup(jsonString);
    if (!validation.isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${validation.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Confirm dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Geri Yükleme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mevcut verileriniz silinecek ve yedekten geri yüklenecek.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (validation.createdAt != null)
              Text(
                'Yedek tarihi: ${validation.createdAt!.day}.${validation.createdAt!.month}.${validation.createdAt!.year}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),
            const Text('Devam etmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Restore
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Geri yükleniyor...'), duration: Duration(seconds: 1)),
    );

    final result = await BackupService.restoreFromBackup(jsonString, ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? '✅ ${result.itemsRestored} öğe geri yüklendi!'
              : '❌ ${result.errorMessage}'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCsvExport(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('CSV oluşturuluyor...'),
          duration: Duration(seconds: 1)),
    );

    final success = await CsvExportService.exportCsvFile(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ CSV başarıyla oluşturuldu!'
              : '❌ CSV oluşturulamadı'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.orange),
            SizedBox(width: 8),
            Text('Önbelleği Temizle'),
          ],
        ),
        content: const Text(
          'Piyasa fiyat önbelleği temizlenecek. Verileriniz silinmeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Clear cache implementation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Önbellek temizlendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Tüm Verileri Sıfırla'),
          ],
        ),
        content: const Text(
          'DİKKAT!\n\n'
          'Tüm varlıklarınız, işlemleriniz ve ayarlarınız kalıcı olarak silinecek.\n\n'
          'Bu işlem GERİ ALINAMAZ. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                // BUG FIX: Cancel notifications FIRST before any data clearing
                await ref
                    .read(notificationSettingsProvider.notifier)
                    .clearNotificationSettings();

                // Get current user
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('Kullanıcı bulunamadı');
                }

                // Delete all Firestore data
                final firestore = FirebaseFirestore.instance;

                // Delete assets
                final assetsSnapshot = await firestore
                    .collection('users')
                    .doc(userId)
                    .collection('assets')
                    .get();
                for (final doc in assetsSnapshot.docs) {
                  await doc.reference.delete();
                }

                // Delete transactions
                final transactionsSnapshot = await firestore
                    .collection('users')
                    .doc(userId)
                    .collection('transactions')
                    .get();
                for (final doc in transactionsSnapshot.docs) {
                  await doc.reference.delete();
                }

                // Delete installments
                final installmentsSnapshot = await firestore
                    .collection('users')
                    .doc(userId)
                    .collection('installments')
                    .get();
                for (final doc in installmentsSnapshot.docs) {
                  await doc.reference.delete();
                }

                // CRITICAL: Reset in-memory state to update UI IMMEDIATELY
                await ref.read(financeProvider.notifier).resetData();

                // Invalidate asset providers to force refresh
                ref.invalidate(assetListProvider);
                ref.invalidate(totalPortfolioValueTRYProvider);
                ref.invalidate(assetValuesTRYProvider);

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog

                  // Navigate back to dashboard to force clean state
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tum veriler silindi ve sifirlandi.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }
}

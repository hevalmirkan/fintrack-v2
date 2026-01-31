// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/installment.dart';
import '../providers/mock_installment_provider.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../shared_expenses/presentation/screens/shared_groups_tab.dart';
import '../../../shared_expenses/presentation/screens/create_group_screen.dart';

/// ====================================================
/// FINAL FAB FIX WITH HEROTAG
/// ====================================================
/// Each FAB has a UNIQUE heroTag to prevent hero conflict.
/// Uses animation.value.round() for real-time tab index.
/// ====================================================

class InstallmentsScreen extends ConsumerStatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  ConsumerState<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends ConsumerState<InstallmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlarım'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: 'Taksitler'),
            Tab(icon: Icon(Icons.subscriptions), text: 'Abonelikler'),
            Tab(icon: Icon(Icons.group), text: 'Ortak'),
          ],
        ),
      ),
      // ================================================================
      // FAB with unique heroTags to prevent hero conflict
      // ================================================================
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final int currentIndex = _tabController.animation!.value.round();

          if (currentIndex == 2) {
            // ORTAK TAB
            return FloatingActionButton(
              heroTag: 'fab_ortak_unique', // UNIQUE heroTag
              key: const ValueKey('fab_ortak'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.group_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
            );
          }

          if (currentIndex == 1) {
            // ABONELIKLER TAB
            return FloatingActionButton(
              heroTag: 'fab_abonelik_unique', // UNIQUE heroTag
              key: const ValueKey('fab_abonelik'),
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add),
              onPressed: () {
                _showAddSubscriptionDialog(context, ref);
              },
            );
          }

          // TAKSITLER TAB (currentIndex == 0)
          return FloatingActionButton(
            heroTag: 'fab_taksit_unique', // UNIQUE heroTag
            key: const ValueKey('fab_taksit'),
            child: const Icon(Icons.add),
            onPressed: () {
              context.push('/add-installment');
            },
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstallmentsTab(context, ref),
          _buildSubscriptionsTab(context, ref),
          const SharedGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildInstallmentsTab(BuildContext context, WidgetRef ref) {
    final installmentState = ref.watch(mockInstallmentProvider);
    final installments = installmentState.installments;
    final totalDebt = installmentState.totalRemainingDebt;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900.withOpacity(0.8), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('Toplam Kalan Borç',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(CurrencyFormatter.formatFromMinorShort(totalDebt),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: installments.isEmpty
              ? _buildEmptyState(Icons.money_off, 'Henüz taksit yok')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: installments.length,
                  itemBuilder: (context, index) =>
                      _InstallmentCard(item: installments[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsTab(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final subscriptions = subscriptionState.subscriptions;
    final totalMonthly = subscriptionState.totalMonthlyAmount;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade900.withOpacity(0.8), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('Aylık Abonelik Gideri',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(CurrencyFormatter.formatFromMinorShort(totalMonthly),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: subscriptions.isEmpty
              ? _buildEmptyState(Icons.subscriptions, 'Henüz abonelik yok')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) =>
                      _SubscriptionCard(subscription: subscriptions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    int selectedDay = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2230),
          title: const Text('Abonelik Ekle',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Abonelik Adı',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Netflix, Spotify...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Aylık Tutar (₺)',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Yenileme Günü: ',
                      style: TextStyle(color: Colors.grey)),
                  DropdownButton<int>(
                    value: selectedDay,
                    dropdownColor: const Color(0xFF1E2230),
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d',
                                style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedDay = v ?? 1),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0;
                if (title.isEmpty || amount <= 0) return;

                ref
                    .read(subscriptionProvider.notifier)
                    .addSubscription(Subscription(
                      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      amountMinor: (amount * 100).round(),
                      renewalDay: selectedDay,
                      category: 'Abonelik',
                      walletId: 'wallet_default',
                      createdAt: DateTime.now(),
                    ));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$title eklendi ✅'),
                      backgroundColor: Colors.green),
                );
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallmentCard extends ConsumerWidget {
  final Installment item;
  const _InstallmentCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFinished = item.isFullyPaid;
    final progress = item.progress;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isFinished ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(item.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isFinished)
                  const Chip(
                    label: Text('Bitti',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: 'Sil',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade700,
                valueColor: AlwaysStoppedAnimation(
                    isFinished ? Colors.green : Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${item.paidInstallments} / ${item.totalInstallments} Taksit',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                Text(
                    'Kalan: ${CurrencyFormatter.formatFromMinorShort(item.remainingAmount)}',
                    style: TextStyle(
                        color: isFinished ? Colors.green : Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'Aylık: ${CurrencyFormatter.formatFromMinorShort(item.monthlyAmount)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            if (!isFinished) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, ref),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Ödeme Yap'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    final wallets = ref.read(financeProvider).wallets;
    String selectedWalletId =
        wallets.isNotEmpty ? wallets.first.id : 'wallet_default';
    final paymentAmount = item.amountPerInstallment;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.title} - Taksit ${item.paidInstallments + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tutar: ${CurrencyFormatter.formatFromMinor(paymentAmount)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white)),
                title: const Text('Şimdi Öde',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Cüzdandan düşer, işlemde görünür',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(mockInstallmentProvider.notifier)
                      .payInstallment(
                        installmentId: item.id,
                        mode: InstallmentPaymentMode.payNow,
                        walletId: selectedWalletId,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${item.title} taksiti ödendi ✅'),
                          backgroundColor: Colors.green),
                    );
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child:
                        Icon(Icons.check_circle_outline, color: Colors.white)),
                title: const Text('Ödenmiş Olarak İşaretle',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Sadece ilerleme güncellenir, cüzdan etkilenmez',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(mockInstallmentProvider.notifier)
                      .payInstallment(
                        installmentId: item.id,
                        mode: InstallmentPaymentMode.markAsPaid,
                        walletId: selectedWalletId,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${item.title} işaretlendi'),
                          backgroundColor: Colors.blue),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: const Text('Taksit Planını Sil?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Bu plan silinecek ancak geçmiş ödemeler korunacak.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref
                  .read(mockInstallmentProvider.notifier)
                  .deleteInstallment(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Plan silindi'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDue = subscription.isDueThisMonth;
    final isPaidThisMonth = ref
        .watch(subscriptionProvider.notifier)
        .isPaidThisMonth(subscription.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDue && !isPaidThisMonth
              ? Colors.orange.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.subscriptions,
                  color: subscription.isActive ? Colors.purple : Colors.grey,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Ayın ${subscription.renewalDay}'i",
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  if (isPaidThisMonth)
                    const Text('✅ Bu ay ödendi',
                        style: TextStyle(color: Colors.green, fontSize: 12))
                  else if (isDue)
                    const Text('⚠️ Ödemesi gelmiş',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    CurrencyFormatter.formatFromMinorShort(
                        subscription.amountMinor),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPaidThisMonth)
                      TextButton(
                        onPressed: () => _paySubscription(context, ref),
                        child: const Text('Öde',
                            style: TextStyle(color: Colors.green)),
                      )
                    else
                      const Icon(Icons.check, color: Colors.green, size: 20),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _paySubscription(BuildContext context, WidgetRef ref) async {
    final wallets = ref.read(financeProvider).wallets;
    final walletId = wallets.isNotEmpty ? wallets.first.id : 'wallet_default';

    await ref.read(subscriptionProvider.notifier).paySubscription(
          subscriptionId: subscription.id,
          walletId: walletId,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${subscription.title} ödendi ✅'),
            backgroundColor: Colors.green),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title:
            const Text('Aboneliği Sil?', style: TextStyle(color: Colors.white)),
        content: const Text('Geçmiş ödemeler korunacak.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref
                  .read(subscriptionProvider.notifier)
                  .deleteSubscription(subscription.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

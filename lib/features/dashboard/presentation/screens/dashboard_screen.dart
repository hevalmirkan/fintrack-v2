import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/format_service.dart';
import '../../../../core/widgets/info_icon_button.dart';

import '../../../home/presentation/screens/home_screen.dart';
import '../../../market/presentation/screens/market_board_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../installments/presentation/screens/installments_screen.dart';
import '../../../analysis/presentation/screens/analysis_screen.dart';

// 🔴 KRİTİK: AssetsView GERÇEK DOSYADAN GELİYOR
import 'assets_view.dart';

import '../providers/dashboard_provider.dart';
import '../widgets/recent_transactions_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _buildBody(),
      // FAB: Hide for Piyasa (1), Analiz (5), AND Taksitler (4)
      // Taksitler (index 4) has its own FAB in InstallmentsScreen for sub-tabs
      floatingActionButton:
          (_currentIndex == 1 || _currentIndex == 4 || _currentIndex == 5)
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    switch (_currentIndex) {
                      case 0:
                      case 3:
                        context.push('/add-transaction');
                        break;
                      case 2:
                        context.push('/add-asset');
                        break;
                    }
                  },
                  child: const Icon(Icons.add),
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Panel'),
          NavigationDestination(
              icon: Icon(Icons.candlestick_chart), label: 'Piyasa'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet), label: 'Varlıklar'),
          NavigationDestination(
              icon: Icon(Icons.swap_horiz), label: 'İşlemler'),
          NavigationDestination(
              icon: Icon(Icons.credit_card), label: 'Taksitler'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Analiz'),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'FinTrack';
      case 1:
        return 'Piyasa';
      case 2:
        return 'Varlıklar';
      case 3:
        return 'İşlemler';
      case 4:
        return 'Taksitler';
      case 5:
        return 'Analiz';
      default:
        return 'FinTrack';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MarketBoardScreen();
      case 2:
        return const AssetsView(); // ✅ ARTIK GERÇEK
      case 3:
        return const TransactionsScreen();
      case 4:
        return const InstallmentsScreen();
      case 5:
        return const AnalysisScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

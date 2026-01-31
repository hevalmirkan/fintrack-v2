import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int netWorth; // Total net worth (assets + cash)
  final int cashBalance; // Available cash (income - expense) - CAN be negative
  final int monthlyIncome; // Income this month
  final int monthlyExpense; // Expenses this month
  final int totalAssetValue; // Sum of all asset values

  const DashboardStats({
    required this.netWorth,
    required this.cashBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.totalAssetValue,
  });

  const DashboardStats.empty()
      : netWorth = 0,
        cashBalance = 0,
        monthlyIncome = 0,
        monthlyExpense = 0,
        totalAssetValue = 0;

  @override
  List<Object?> get props =>
      [netWorth, cashBalance, monthlyIncome, monthlyExpense, totalAssetValue];
}

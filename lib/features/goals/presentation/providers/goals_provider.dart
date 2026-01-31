/// =====================================================
/// GOALS PROVIDER — Phase 8
/// =====================================================
/// State management for Financial Goals.
/// CRUD operations + persistence via SharedPreferences (JSON).
/// =====================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/financial_goal.dart';

const _goalsStorageKey = 'financial_goals_v1';

/// Goals state
class GoalsState {
  final List<FinancialGoal> goals;
  final bool isLoading;

  const GoalsState({
    this.goals = const [],
    this.isLoading = true,
  });

  List<FinancialGoal> get activeGoals =>
      goals.where((g) => !g.isCompleted).toList();

  List<FinancialGoal> get completedGoals =>
      goals.where((g) => g.isCompleted).toList();

  double get totalTargetAmount =>
      goals.fold(0.0, (sum, g) => sum + g.targetAmount);

  double get totalCurrentAmount =>
      goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  double get overallProgress {
    if (totalTargetAmount <= 0) return 0;
    return (totalCurrentAmount / totalTargetAmount * 100).clamp(0, 100);
  }

  GoalsState copyWith({
    List<FinancialGoal>? goals,
    bool? isLoading,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Goals notifier with CRUD operations
class GoalsNotifier extends Notifier<GoalsState> {
  @override
  GoalsState build() {
    _loadGoals();
    return const GoalsState();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_goalsStorageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final goals = jsonList
            .map((json) => FinancialGoal.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(goals: goals, isLoading: false);
      } else {
        state = state.copyWith(goals: [], isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(goals: [], isLoading: false);
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.goals.map((g) => g.toJson()).toList();
      await prefs.setString(_goalsStorageKey, jsonEncode(jsonList));
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> createGoal({
    required String title,
    required double targetAmount,
    DateTime? targetDate,
    String icon = '🎯',
    int colorValue = 0xFF6366F1,
  }) async {
    final newGoal = FinancialGoal(
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      icon: icon,
      colorValue: colorValue,
    );

    state = state.copyWith(goals: [...state.goals, newGoal]);
    await _saveGoals();
  }

  Future<void> addMoney(String goalId, double amount) async {
    if (amount <= 0) return;

    final updatedGoals = state.goals.map((g) {
      if (g.id == goalId) {
        final newAmount = g.currentAmount + amount;
        final isNowComplete = newAmount >= g.targetAmount;

        return g.copyWith(
          currentAmount: newAmount,
          isCompleted: isNowComplete,
        );
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }

  Future<void> updateGoal(
    String goalId, {
    String? title,
    double? targetAmount,
    DateTime? targetDate,
    String? icon,
    int? colorValue,
  }) async {
    final updatedGoals = state.goals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(
          title: title,
          targetAmount: targetAmount,
          targetDate: targetDate,
          icon: icon,
          colorValue: colorValue,
        );
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }

  Future<void> deleteGoal(String goalId) async {
    final updatedGoals = state.goals.where((g) => g.id != goalId).toList();
    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }

  Future<void> completeGoal(String goalId) async {
    final updatedGoals = state.goals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(isCompleted: true);
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }

  Future<void> reopenGoal(String goalId) async {
    final updatedGoals = state.goals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(isCompleted: false);
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(
  GoalsNotifier.new,
);

final goalByIdProvider = Provider.family<FinancialGoal?, String>((ref, id) {
  final goals = ref.watch(goalsProvider).goals;
  try {
    return goals.firstWhere((g) => g.id == id);
  } catch (_) {
    return null;
  }
});

/// =====================================================
/// COACH PROVIDER — Phase 7: AI Coach
/// =====================================================
/// State management for AI Coach feature.
/// =====================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../coach/data/services/gemini_service.dart';
import '../../../coach/data/services/snapshot_service.dart';
import '../../../coach/domain/models/financial_snapshot.dart';

/// Singleton GeminiService provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Coach settings state
class CoachSettingsState {
  final bool isEnabled;
  final bool hasApiKey;
  final String? maskedApiKey;
  final bool isLoading;

  const CoachSettingsState({
    this.isEnabled = false,
    this.hasApiKey = false,
    this.maskedApiKey,
    this.isLoading = true,
  });

  CoachSettingsState copyWith({
    bool? isEnabled,
    bool? hasApiKey,
    String? maskedApiKey,
    bool? isLoading,
  }) {
    return CoachSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      maskedApiKey: maskedApiKey ?? this.maskedApiKey,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Coach settings notifier
class CoachSettingsNotifier extends Notifier<CoachSettingsState> {
  @override
  CoachSettingsState build() {
    _loadSettings();
    return const CoachSettingsState();
  }

  Future<void> _loadSettings() async {
    final gemini = ref.read(geminiServiceProvider);
    final isEnabled = await gemini.isEnabled();
    final hasKey = await gemini.hasApiKey();
    final maskedKey = await gemini.getMaskedApiKey();

    state = state.copyWith(
      isEnabled: isEnabled,
      hasApiKey: hasKey,
      maskedApiKey: maskedKey,
      isLoading: false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final gemini = ref.read(geminiServiceProvider);
    await gemini.setEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> setApiKey(String apiKey) async {
    final gemini = ref.read(geminiServiceProvider);
    await gemini.setApiKey(apiKey);
    final maskedKey = await gemini.getMaskedApiKey();
    state = state.copyWith(
      hasApiKey: true,
      maskedApiKey: maskedKey,
    );
  }

  Future<void> clearApiKey() async {
    final gemini = ref.read(geminiServiceProvider);
    await gemini.clearApiKey();
    state = state.copyWith(
      hasApiKey: false,
      maskedApiKey: null,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadSettings();
  }
}

/// Coach settings provider
final coachSettingsProvider =
    NotifierProvider<CoachSettingsNotifier, CoachSettingsState>(
        CoachSettingsNotifier.new);

/// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Coach chat state
class CoachChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? monthlyInsight;
  final bool insightLoading;

  const CoachChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.monthlyInsight,
    this.insightLoading = false,
  });

  CoachChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? monthlyInsight,
    bool? insightLoading,
  }) {
    return CoachChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      monthlyInsight: monthlyInsight ?? this.monthlyInsight,
      insightLoading: insightLoading ?? this.insightLoading,
    );
  }
}

/// Coach chat notifier
class CoachChatNotifier extends Notifier<CoachChatState> {
  @override
  CoachChatState build() {
    return const CoachChatState();
  }

  /// Generate monthly insight
  Future<void> generateMonthlyInsight() async {
    state = state.copyWith(insightLoading: true, error: null);

    try {
      final gemini = ref.read(geminiServiceProvider);
      final snapshotService = ref.read(snapshotServiceProvider);
      final snapshot = await snapshotService.generateSnapshot();

      final result = await gemini.generateMonthlyInsight(snapshot);

      if (result is AiSuccess) {
        state = state.copyWith(
          monthlyInsight: result.response,
          insightLoading: false,
        );
      } else if (result is AiError) {
        state = state.copyWith(
          error: result.message,
          insightLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Beklenmeyen hata: $e',
        insightLoading: false,
      );
    }
  }

  /// Ask a question to the coach
  Future<void> askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(content: question, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final gemini = ref.read(geminiServiceProvider);
      final snapshotService = ref.read(snapshotServiceProvider);
      final snapshot = await snapshotService.generateSnapshot();

      final result = await gemini.askQuestion(question, snapshot);

      if (result is AiSuccess) {
        final aiMessage = ChatMessage(content: result.response, isUser: false);
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
      } else if (result is AiError) {
        state = state.copyWith(
          error: result.message,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Beklenmeyen hata: $e',
        isLoading: false,
      );
    }
  }

  /// Clear chat history
  void clearChat() {
    state = const CoachChatState();
  }
}

/// Coach chat provider
final coachChatProvider =
    NotifierProvider<CoachChatNotifier, CoachChatState>(CoachChatNotifier.new);

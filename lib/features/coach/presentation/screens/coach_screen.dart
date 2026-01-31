/// =====================================================
/// COACH SCREEN — Phase 7: AI Coach
/// =====================================================
/// Main UI for AI Coach feature.
/// Sections: Monthly Insight + Q&A Chat
/// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/coach_provider.dart';
import '../../data/services/gemini_service.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-generate insight when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(coachSettingsProvider);
      if (settings.hasApiKey && settings.isEnabled) {
        ref.read(coachChatProvider.notifier).generateMonthlyInsight();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(coachSettingsProvider);
    final chatState = ref.watch(coachChatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('🧠', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('AI Koç',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !settings.hasApiKey
              ? _buildNoApiKeyState()
              : !settings.isEnabled
                  ? _buildDisabledState()
                  : _buildMainContent(chatState),
    );
  }

  /// No API Key state
  Widget _buildNoApiKeyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 24),
            const Text(
              'API Anahtarı Gerekli',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Koç\'u kullanmak için bir Gemini API anahtarı girmelisin. Ücretsiz bir anahtar alabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openApiKeyPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ücretsiz Anahtar Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showSettingsSheet(context),
              child: const Text('Anahtarı Gir'),
            ),
          ],
        ),
      ),
    );
  }

  /// AI Coach disabled state
  Widget _buildDisabledState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_outline,
                size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 24),
            const Text(
              'AI Koç Devre Dışı',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Koç özelliğini ayarlardan aktif edebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ref.read(coachSettingsProvider.notifier).setEnabled(true);
                ref.read(coachChatProvider.notifier).generateMonthlyInsight();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aktif Et'),
            ),
          ],
        ),
      ),
    );
  }

  /// Main content with insight and chat
  Widget _buildMainContent(CoachChatState chatState) {
    return Column(
      children: [
        // Privacy disclaimer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue.withOpacity(0.1),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verileriniz analiz için Google Gemini\'ye anonim olarak gönderilir.',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Section A: Monthly Insight
              _buildMonthlyInsightSection(chatState),

              const SizedBox(height: 24),

              // Section B: Chat messages
              if (chatState.messages.isNotEmpty) ...[
                const Text(
                  'Sohbet',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...chatState.messages.map(_buildChatMessage),
                if (chatState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],

              // Error display
              if (chatState.error != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(chatState.error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 100), // Space for input
            ],
          ),
        ),

        // Question input
        _buildQuestionInput(),
      ],
    );
  }

  /// Monthly Insight Section
  Widget _buildMonthlyInsightSection(CoachChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bu Ayın Yorumu',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.refresh, color: Colors.white54, size: 20),
                onPressed: chatState.insightLoading
                    ? null
                    : () => ref
                        .read(coachChatProvider.notifier)
                        .generateMonthlyInsight(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (chatState.insightLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (chatState.monthlyInsight != null)
            Text(
              chatState.monthlyInsight!,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5),
            )
          else
            const Text(
              'Analiz oluşturmak için sağ üstteki yenile butonuna tıklayın.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
    );
  }

  /// Build a chat message bubble
  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.blue.withOpacity(0.2)
              : const Color(0xFF1E2230),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: message.isUser
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isUser ? Icons.person : Icons.smart_toy,
                  color: message.isUser ? Colors.blue : Colors.purple,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isUser ? 'Sen' : 'AI Koç',
                  style: TextStyle(
                    color: message.isUser ? Colors.blue : Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Question input field
  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Koç\'a bir soru sor...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1E2230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendQuestion,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _sendQuestion(_questionController.text),
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _sendQuestion(String question) {
    if (question.trim().isEmpty) return;
    ref.read(coachChatProvider.notifier).askQuestion(question);
    _questionController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openApiKeyPage() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSettingsSheet(BuildContext context) {
    final apiKeyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final settings = ref.watch(coachSettingsProvider);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Koç Ayarları',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Enable/Disable toggle
                  SwitchListTile(
                    title: const Text('AI Koç Aktif',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      settings.isEnabled ? 'Aktif' : 'Devre dışı',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    value: settings.isEnabled,
                    onChanged: (val) => ref
                        .read(coachSettingsProvider.notifier)
                        .setEnabled(val),
                    activeColor: Colors.green,
                  ),

                  const Divider(color: Color(0xFF30363D)),

                  // API Key status
                  ListTile(
                    leading: Icon(
                        settings.hasApiKey ? Icons.key : Icons.key_off,
                        color: settings.hasApiKey ? Colors.green : Colors.grey),
                    title: const Text('API Anahtarı',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      settings.maskedApiKey ?? 'Girilmemiş',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: settings.hasApiKey
                        ? TextButton(
                            onPressed: () => ref
                                .read(coachSettingsProvider.notifier)
                                .clearApiKey(),
                            child: const Text('Sil',
                                style: TextStyle(color: Colors.red)),
                          )
                        : null,
                  ),

                  // API Key input
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Yeni API anahtarı gir',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1E2230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final key = apiKeyController.text.trim();
                            if (key.isNotEmpty) {
                              await ref
                                  .read(coachSettingsProvider.notifier)
                                  .setApiKey(key);
                              apiKeyController.clear();
                              if (context.mounted) Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _openApiKeyPage,
                        child: const Text('Ücretsiz Al'),
                      ),
                    ],
                  ),
                  // Instructions moved to SettingsScreen
                ],
              ),
            );
          },
        );
      },
    );
  }
}

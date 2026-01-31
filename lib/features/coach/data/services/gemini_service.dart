/// =====================================================
/// GEMINI SERVICE — Phase 7: AI Coach (BYOK)
/// =====================================================
/// Bring Your Own Key architecture for Gemini AI.
/// User provides their own API key for privacy.
/// =====================================================

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/financial_snapshot.dart';

/// Result types for AI operations
sealed class AiResult {}

class AiSuccess extends AiResult {
  final String response;
  AiSuccess(this.response);
}

class AiError extends AiResult {
  final String message;
  final AiErrorType type;
  AiError(this.message, this.type);
}

enum AiErrorType {
  noApiKey,
  invalidApiKey,
  quotaExceeded,
  networkError,
  unknown,
}

/// Gemini AI Service with BYOK architecture
class GeminiService {
  static const _apiKeyStorageKey = 'gemini_api_key';
  static const _enabledStorageKey = 'ai_coach_enabled';
  static const _storage = FlutterSecureStorage();

  GenerativeModel? _model;
  String? _cachedApiKey;

  Future<bool> isEnabled() async {
    final value = await _storage.read(key: _enabledStorageKey);
    return value == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _enabledStorageKey, value: enabled.toString());
  }

  Future<String?> getMaskedApiKey() async {
    final key = await _storage.read(key: _apiKeyStorageKey);
    if (key == null || key.isEmpty) return null;
    if (key.length < 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyStorageKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
    _cachedApiKey = apiKey;
    _model = null;
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
    _cachedApiKey = null;
    _model = null;
  }

  /// Test API connection with a simple prompt
  Future<String> testConnection() async {
    try {
      final model = await _getModel();
      if (model == null) {
        return 'HATA: API anahtarı girilmemiş';
      }

      final response = await model.generateContent([
        Content.text("Sadece 'ok' yaz, başka bir şey yazma."),
      ]);

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return 'BAŞARILI ✅';
      }
      return 'HATA: Boş yanıt alındı';
    } catch (e) {
      return 'HATA: $e';
    }
  }

  Future<GenerativeModel?> _getModel() async {
    if (_model != null) return _model;

    _cachedApiKey ??= await _storage.read(key: _apiKeyStorageKey);
    if (_cachedApiKey == null || _cachedApiKey!.isEmpty) return null;

    _model = GenerativeModel(
      model: 'models/gemini-1.5-flash',
      apiKey: _cachedApiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
    return _model;
  }

  Future<AiResult> generateMonthlyInsight(FinancialSnapshot snapshot) async {
    try {
      final model = await _getModel();
      if (model == null) {
        return AiError('API anahtarı girilmemiş', AiErrorType.noApiKey);
      }

      final prompt = _buildInsightPrompt(snapshot);
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return AiError('Boş yanıt alındı', AiErrorType.unknown);
      }

      return AiSuccess(text);
    } on GenerativeAIException catch (e) {
      return AiError('API Hatası: ${e.message}', AiErrorType.unknown);
    } catch (e) {
      return AiError('Hata: $e', AiErrorType.networkError);
    }
  }

  Future<AiResult> askQuestion(
      String question, FinancialSnapshot snapshot) async {
    try {
      final model = await _getModel();
      if (model == null) {
        return AiError('API anahtarı girilmemiş', AiErrorType.noApiKey);
      }

      final prompt = _buildQuestionPrompt(question, snapshot);
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return AiError('Boş yanıt alındı', AiErrorType.unknown);
      }

      return AiSuccess(text);
    } on GenerativeAIException catch (e) {
      return AiError('API Hatası: ${e.message}', AiErrorType.unknown);
    } catch (e) {
      return AiError('Hata: $e', AiErrorType.networkError);
    }
  }

  String _buildInsightPrompt(FinancialSnapshot snapshot) {
    final snapshotJson = jsonEncode(snapshot.toPromptJson());

    return '''
Sen bir kişisel finans danışmanısın. Aşağıdaki finansal verileri analiz et ve Türkçe olarak kullanıcıya yardımcı bir yorum yap.

## KURALLAR:
1. Yorum yapay, samimi ve destekleyici bir tonda olmalı
2. Spesifik yatırım tavsiyesi VERME (hisse, kripto önerme)
3. Verilere dayalı, somut gözlemler yap
4. Maksimum 200 kelime kullan
5. Emoji ile renklendir ama abartma

## FİNANSAL VERİLER:
$snapshotJson

## YAPILACAKLAR:
1. Bu ayın gelir/gider dengesini yorumla
2. Geçen aya göre değişimi belirt
3. En yüksek harcama kategorisine dikkat çek
4. Varsa borç durumunu değerlendir
5. Bir pozitif ve bir geliştirilebilir nokta belirt

Yanıtını doğrudan ver, "İşte analizim:" gibi girişler yapma.
''';
  }

  String _buildQuestionPrompt(String question, FinancialSnapshot snapshot) {
    final snapshotJson = jsonEncode(snapshot.toPromptJson());

    return '''
Sen bir kişisel finans danışmanısın. Kullanıcının sorusunu aşağıdaki finansal verilerine dayanarak Türkçe olarak yanıtla.

## KURALLAR:
1. Sadece verilen verilere dayanarak yanıt ver
2. Spesifik yatırım tavsiyesi VERME
3. Bilmiyorsan "Bu konuda yeterli verim yok" de
4. Kısa ve öz yanıt ver (max 150 kelime)
5. Destekleyici ve yargılayıcı olmayan bir ton kullan

## FİNANSAL VERİLER:
$snapshotJson

## KULLANICININ SORUSU:
$question

Yanıtını doğrudan ver.
''';
  }
}

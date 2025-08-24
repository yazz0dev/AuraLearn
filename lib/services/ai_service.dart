import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

/// A singleton service to interact with the Firebase AI (Gemini) models with caching.
class AIService {
  // Private constructor
  AIService._();

  // Singleton instance
  static final AIService instance = AIService._();
  
  // Cache service for AI responses
  final CacheService _cache = CacheService();

  // Initialize the Google AI model using the Firebase SDK
  // This securely calls the Gemini API through a Firebase proxy.

  // Set the thinking configuration to disable thinking for faster responses
  final _model = FirebaseAI.googleAI().generativeModel(
    // FIX: Ensured the correct and latest model name is used.
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(
      temperature: 0.4, // Controls randomness for more consistent output
      thinkingConfig: ThinkingConfig(thinkingBudget: 0),
    ),
  );

  /// Helper method to clean JSON response from AI (removes markdown code blocks)
  String _cleanJsonResponse(String response) {
    // Remove markdown code blocks if present
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// Generates content by calling the Gemini API with caching support
  /// via the secure Firebase AI SDK.
  ///
  /// Returns the generated text or an error message if it fails.
  Future<String> generateContent(String prompt, {bool useCache = true}) async {
    // Create cache key from prompt hash
    final promptHash = prompt.hashCode.toString();
    final cacheKey = 'ai_content_$promptHash';
    
    // Check cache first if enabled
    if (useCache) {
      final cached = await _cache.get<String>(cacheKey, ttl: const Duration(hours: 24));
      if (cached != null) {
        debugPrint('AI Cache HIT for prompt hash: $promptHash');
        return cached;
      }
    }

    final result = await _generateContentWithRetry(
      () => _model.generateContent([Content.text(prompt)]),
      prompt,
    );
    
    // Cache successful results
    if (useCache && !result.startsWith('Failed') && !result.startsWith('Network') && !result.startsWith('An error')) {
      await _cache.set(cacheKey, result, ttl: const Duration(hours: 24));
      debugPrint('AI response cached for prompt hash: $promptHash');
    }
    
    return result;
  }

  /// Internal method to handle content generation with retry logic
  Future<String> _generateContentWithRetry(
    Future<GenerateContentResponse> Function() generateFunction,
    String prompt, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint(
          "🤖 AI Service: Starting content generation (attempt $attempts/$maxRetries)",
        );
        debugPrint("📝 Prompt length: ${prompt.length} characters");
        debugPrint(
          "🔍 First 200 chars of prompt: ${prompt.length > 200 ? prompt.substring(0, 200) : prompt}...",
        );

        final startTime = DateTime.now();
        final response = await generateFunction();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        debugPrint(
          "⏱️ AI Service: Request completed in ${duration.inMilliseconds}ms",
        );

        if (response.text != null) {
          debugPrint("✅ AI Service: Response received successfully");
          debugPrint("📊 Response length: ${response.text!.length} characters");
          debugPrint(
            "🔍 First 200 chars of response: ${response.text!.length > 200 ? response.text!.substring(0, 200) : response.text!}...",
          );
          return _cleanJsonResponse(response.text!);
        } else {
          debugPrint("❌ AI Service: Response was empty");
          return 'Failed to generate content. The response was empty.';
        }
      } catch (e) {
        debugPrint('❌ AI Service Error (attempt $attempts/$maxRetries): $e');
        debugPrint('🔧 Error type: ${e.runtimeType}');

        // Check if it's a network-related error that we should retry
        final errorString = e.toString().toLowerCase();
        final isNetworkError =
            errorString.contains('failed to fetch') ||
            errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('timeout') ||
            errorString.contains('ping_failed') ||
            errorString.contains('clientexception');

        if (isNetworkError && attempts < maxRetries) {
          debugPrint(
            '🔄 Network error detected, retrying in ${attempts * 2} seconds...',
          );
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }

        // Return appropriate error message based on error type
        if (isNetworkError) {
          return 'Network connection failed. Please check your internet connection and try again.';
        } else if (errorString.contains('quota') ||
            errorString.contains('billing')) {
          return 'API quota exceeded or billing issue. Please check your Firebase project billing settings.';
        } else if (errorString.contains('permission') ||
            errorString.contains('unauthorized')) {
          return 'Permission denied. Please check your Firebase project configuration.';
        } else {
          return 'An error occurred while generating content. Please try again later.';
        }
      }
    }

    return 'Failed to generate content after $maxRetries attempts. Please check your connection and try again.';
  }

  /// Generates content with PDF file directly uploaded to AI with caching
  /// via the secure Firebase AI SDK.
  ///
  /// Returns the generated text or an error message if it fails.
  Future<String> generateContentWithPdf(
    String prompt,
    Uint8List pdfBytes,
    String mimeType, {
    bool useCache = true,
  }) async {
    debugPrint("📄 Starting PDF analysis:");
    debugPrint("📄 PDF size: ${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)} MB");
    debugPrint("📄 MIME type: $mimeType");
    debugPrint("📄 Prompt type: Syllabus analysis");

    // Create cache key from prompt and PDF hash
    final pdfHash = pdfBytes.hashCode.toString();
    final promptHash = prompt.hashCode.toString();
    final cacheKey = 'ai_pdf_${promptHash}_$pdfHash';
    
    // Check cache first if enabled
    if (useCache) {
      final cached = await _cache.get<String>(cacheKey, ttl: const Duration(days: 7));
      if (cached != null) {
        debugPrint('AI PDF Cache HIT for hashes: $promptHash, $pdfHash');
        return cached;
      }
    }

    // Validate PDF size (Firebase AI has limits)
    const maxSizeBytes = 20 * 1024 * 1024; // 20MB limit for Firebase AI
    if (pdfBytes.length > maxSizeBytes) {
      debugPrint("❌ PDF too large for AI processing: ${pdfBytes.length} bytes");
      return 'PDF file is too large for AI processing. Please use a smaller file (under 20MB).';
    }

    try {
      final result = await _generateContentWithRetry(
        () => _model.generateContent([
          Content.multi([
            TextPart(prompt), 
            InlineDataPart(mimeType, pdfBytes)
          ]),
        ]),
        prompt,
        maxRetries: 2, // Fewer retries for PDF processing as it's more resource intensive
      );

      debugPrint("📄 PDF analysis completed successfully");
      
      // Cache successful PDF analysis results (longer TTL since PDFs don't change often)
      if (useCache && !result.startsWith('Failed') && !result.startsWith('Network') && !result.startsWith('An error')) {
        await _cache.set(cacheKey, result, ttl: const Duration(days: 7));
        debugPrint('AI PDF response cached for hashes: $promptHash, $pdfHash');
      }
      
      return result;
    } catch (e) {
      debugPrint("❌ PDF processing failed: $e");
      
      // Handle PDF-specific errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid') && errorString.contains('pdf')) {
        return 'The uploaded file appears to be corrupted or is not a valid PDF. Please try uploading a different PDF file.';
      } else if (errorString.contains('size') || errorString.contains('large')) {
        return 'PDF file is too large for processing. Please compress the PDF or use a smaller file.';
      } else if (errorString.contains('format') || errorString.contains('mime')) {
        return 'Unsupported file format. Please ensure you are uploading a valid PDF file.';
      }
      
      // Fall back to generic error handling
      rethrow;
    }
  }

  /// Clear AI response cache
  Future<void> clearCache() async {
    // Get all cache keys and remove AI-related ones
    final stats = _cache.getCacheStats();
    final keys = stats['memory_cache_keys'] as List<String>;
    
    for (final key in keys) {
      if (key.startsWith('ai_content_') || key.startsWith('ai_pdf_')) {
        await _cache.remove(key);
      }
    }
    
    debugPrint('AI cache cleared');
  }

  /// Get cache statistics for AI responses
  Map<String, dynamic> getCacheStats() {
    final stats = _cache.getCacheStats();
    final keys = stats['memory_cache_keys'] as List<String>;
    
    final aiKeys = keys.where((key) => 
      key.startsWith('ai_content_') || key.startsWith('ai_pdf_')).toList();
    
    return {
      'total_ai_cached_responses': aiKeys.length,
      'ai_cache_keys': aiKeys,
    };
  }
}
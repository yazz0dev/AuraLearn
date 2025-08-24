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

  // --- FIX: Initialize both the primary and fallback models as requested. ---
  final _primaryModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(
      temperature: 0.4,
      thinkingConfig: ThinkingConfig(thinkingBudget: 0),
    ),
  );

  final _fallbackModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
    generationConfig: GenerationConfig(
      temperature: 0.4,
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

    final content = [Content.text(prompt)];
    final result = await _generateContentWithRetry(content, prompt);
    
    // Cache successful results
    if (useCache && !result.startsWith('Failed') && !result.startsWith('Network') && !result.startsWith('An error')) {
      await _cache.set(cacheKey, result, ttl: const Duration(hours: 24));
      debugPrint('AI response cached for prompt hash: $promptHash');
    }
    
    return result;
  }

  /// Internal method to handle content generation with retry and fallback logic
  Future<String> _generateContentWithRetry(
    List<Content> content,
    String promptForLogging, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint(
          "🤖 AI Service: Generating with primary model (gemini-2.5-flash)... Attempt $attempts/$maxRetries",
        );
        debugPrint("📝 Prompt length: ${promptForLogging.length} characters");

        final startTime = DateTime.now();
        final response = await _primaryModel.generateContent(content);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        debugPrint("⏱️ Primary model request completed in ${duration.inMilliseconds}ms");

        if (response.text != null) {
          debugPrint("✅ Primary model response received successfully");
          return _cleanJsonResponse(response.text!);
        } else {
          debugPrint("❌ Primary model response was empty");
          return 'Failed to generate content. The response was empty.';
        }
      } catch (e) {
        debugPrint('❌ Primary model error (attempt $attempts/$maxRetries): $e');
        final errorString = e.toString().toLowerCase();
        
        // --- FIX: Check for rate limit error to trigger fallback model ---
        final isRateLimitError = errorString.contains('rate limit') ||
                                 errorString.contains('resource has been exhausted') ||
                                 errorString.contains('429');
        
        if (isRateLimitError) {
          debugPrint("⚠️ Primary model rate-limited. Switching to fallback (gemini-2.5-flash-lite).");
          try {
            final fallbackStartTime = DateTime.now();
            final fallbackResponse = await _fallbackModel.generateContent(content);
            final fallbackEndTime = DateTime.now();
            final fallbackDuration = fallbackEndTime.difference(fallbackStartTime);
            debugPrint("⏱️ Fallback model request completed in ${fallbackDuration.inMilliseconds}ms");
            
            if (fallbackResponse.text != null) {
              debugPrint("✅ Fallback model succeeded.");
              return _cleanJsonResponse(fallbackResponse.text!);
            } else {
               debugPrint("❌ Fallback model response was empty");
               return 'Failed to generate content (Fallback response empty).';
            }
          } catch (fallbackError) {
            debugPrint("❌ Fallback model also failed: $fallbackError");
            return 'An error occurred while generating content (both models failed). Please try again later.';
          }
        }
        
        final isNetworkError =
            errorString.contains('failed to fetch') ||
            errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('timeout');

        if (isNetworkError && attempts < maxRetries) {
          debugPrint(
            '🔄 Network error detected, retrying primary model in ${attempts * 2} seconds...',
          );
          await Future.delayed(Duration(seconds: attempts * 2));
          continue; // Continue the loop to retry with the primary model
        }

        // Return appropriate error message for other unrecoverable errors
        if (errorString.contains('quota') || errorString.contains('billing')) {
          return 'API quota exceeded or billing issue. Please check your Firebase project billing settings.';
        } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
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
      final content = [
        Content.multi([
          TextPart(prompt), 
          InlineDataPart(mimeType, pdfBytes)
        ]),
      ];

      final result = await _generateContentWithRetry(content, prompt);

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
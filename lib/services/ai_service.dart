import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// A singleton service to interact with the Firebase AI (Gemini) models.
class AIService {
  // Private constructor
  AIService._();

  // Singleton instance
  static final AIService instance = AIService._();

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

  /// Generates content by calling the Gemini API directly from the client
  /// via the secure Firebase AI SDK.
  ///
  /// Returns the generated text or an error message if it fails.
  Future<String> generateContent(String prompt) async {
    return _generateContentWithRetry(
      () => _model.generateContent([Content.text(prompt)]),
      prompt,
    );
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

  /// Generates content with PDF file directly uploaded to AI
  /// via the secure Firebase AI SDK.
  ///
  /// Returns the generated text or an error message if it fails.
  Future<String> generateContentWithPdf(
    String prompt,
    Uint8List pdfBytes,
    String mimeType,
  ) async {
    debugPrint("📄 Starting PDF analysis:");
    debugPrint("📄 PDF size: ${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)} MB");
    debugPrint("📄 MIME type: $mimeType");
    debugPrint("📄 Prompt type: Syllabus analysis");

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
}
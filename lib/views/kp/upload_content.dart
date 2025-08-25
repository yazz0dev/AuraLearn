import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/services/ai_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../enums/user_role.dart';

// Enum to manage the UI state of the multi-step process
enum UploadStep { syllabus, materials, generating, done }

class UploadContentPage extends StatefulWidget {
  final String subjectId;
  final String? uploadType;

  const UploadContentPage({
    super.key,
    required this.subjectId,
    this.uploadType,
  });

  @override
  State<UploadContentPage> createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage> {
  UploadStep _currentStep = UploadStep.syllabus;
  bool _isLoading = true;
  bool _isProcessing = false;

  Map<String, dynamic>? _subjectData;
  PlatformFile? _syllabusFile;
  final List<PlatformFile> _materialFiles = [];
  List<DocumentSnapshot> _generatedTopics = [];

  // Progress tracking
  String _currentProcessingStep = '';
  double _processingProgress = 0.0;
  int _currentTopicIndex = 0;
  int _totalTopics = 0;

  // PDF page selection
  int? _startPage;
  int? _endPage;
  int? _totalPages;

  // Compression tracking
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  String _compressionStatus = '';

  @override
  void initState() {
    super.initState();
    if (widget.uploadType == 'material') {
      _currentStep = UploadStep.materials;
    }
    _loadSubjectData();
  }

  /// Helper method to extract text from a PDF file.
  Future<String> _extractTextFromPdf(PlatformFile file) async {
    try {
      // Use bytes directly on web, read from path on mobile/desktop
      final pdfBytes = kIsWeb
          ? file.bytes!
          : await File(file.path!).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      String text;
      if (_startPage != null && _endPage != null) {
        // Extract text from specific page range
        text = '';
        for (int pageIndex = _startPage! - 1; pageIndex < _endPage!; pageIndex++) {
          if (pageIndex < document.pages.count) {
            text += PdfTextExtractor(document).extractText(startPageIndex: pageIndex);
            text += '\n\n';
          }
        }
      } else {
        // Extract text from all pages
        text = PdfTextExtractor(document).extractText();
      }

      document.dispose();
      return text;
    } catch (e) {
      // FIX: Guard BuildContext usage with a mounted check.
      if (!mounted) return "";
      Toast.show(
        context,
        "Error reading PDF file: ${file.name}",
        type: ToastType.error,
      );
      return "";
    }
  }

  /// Helper method to get PDF page count
  Future<int> _getPdfPageCount(PlatformFile file) async {
    try {
      debugPrint('Getting page count for ${file.name}');
      final pdfBytes = kIsWeb
          ? file.bytes!
          : await File(file.path!).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final pageCount = document.pages.count;
      document.dispose();
      debugPrint('PDF ${file.name} has $pageCount pages');
      return pageCount;
    } catch (e) {
      debugPrint('Error getting page count for ${file.name}: $e');
      return 0;
    }
  }

  /// Compress PDF file to reduce size using multiple strategies
  Future<Uint8List?> _compressPdf(PlatformFile file) async {
    try {
      setState(() {
        _isCompressing = true;
        _compressionProgress = 0.0;
        _compressionStatus = 'Starting compression...';
      });

      final originalBytes = kIsWeb ? file.bytes! : await File(file.path!).readAsBytes();
      final originalSize = originalBytes.length;
      const targetSize = 6 * 1024 * 1024; // 6MB target

      debugPrint('Starting compression for ${file.name}, original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // Strategy 1: Basic compression with best compression level
      setState(() {
        _compressionProgress = 0.2;
        _compressionStatus = 'Applying basic compression...';
      });

      try {
        final document = PdfDocument(inputBytes: originalBytes);
        
        // Set highest compression level
        document.compressionLevel = PdfCompressionLevel.best;
        
        // Remove form fields if they exist
        try {
          if (document.form.fields.count > 0) {
            document.form.fields.clear();
            debugPrint('Cleared form fields');
          }
        } catch (e) {
          debugPrint('Could not clear form fields: $e');
        }

        final compressedBytes = await document.save();
        document.dispose();

        final compressedData = Uint8List.fromList(compressedBytes);
        final ratio = ((originalSize - compressedData.length) / originalSize * 100);
        
        debugPrint('Basic compression result: ${(compressedData.length / 1024 / 1024).toStringAsFixed(2)}MB (${ratio.toStringAsFixed(1)}% reduction)');
        
        if (compressedData.length <= targetSize) {
          setState(() {
            _compressionProgress = 1.0;
            _compressionStatus = 'Compression successful!';
          });
          return compressedData;
        }
      } catch (e) {
        debugPrint('Basic compression failed: $e');
      }

      // Strategy 2: Text extraction and recreation (most effective for text PDFs)
      setState(() {
        _compressionProgress = 0.5;
        _compressionStatus = 'Extracting and optimizing content...';
      });

      try {
        final sourceDoc = PdfDocument(inputBytes: originalBytes);
        final textExtractor = PdfTextExtractor(sourceDoc);
        final allText = textExtractor.extractText();
        
        if (allText.isNotEmpty && allText.trim().length > 100) {
          final newDoc = PdfDocument();
          newDoc.compressionLevel = PdfCompressionLevel.best;
          
          // Calculate how many pages we need based on text length
          const charsPerPage = 3000; // Approximate characters per page
          final totalPages = (allText.length / charsPerPage).ceil();
          
          for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
            setState(() {
              _compressionProgress = 0.5 + (0.3 * (pageIndex / totalPages));
              _compressionStatus = 'Creating page ${pageIndex + 1}/$totalPages...';
            });
            
            final page = newDoc.pages.add();
            final graphics = page.graphics;
            
            // Calculate text for this page
            final startIndex = pageIndex * charsPerPage;
            final endIndex = math.min(startIndex + charsPerPage, allText.length);
            final pageText = allText.substring(startIndex, endIndex);
            
            // Draw text with proper formatting
            graphics.drawString(
              pageText,
              PdfStandardFont(PdfFontFamily.helvetica, 9),
              bounds: Rect.fromLTWH(40, 40, page.size.width - 80, page.size.height - 80),
              format: PdfStringFormat(
                lineAlignment: PdfVerticalAlignment.top,
                alignment: PdfTextAlignment.left,
                wordWrap: PdfWordWrapType.word,
              ),
            );
            
            // Add page number
            graphics.drawString(
              'Page ${pageIndex + 1}',
              PdfStandardFont(PdfFontFamily.helvetica, 8),
              bounds: Rect.fromLTWH(page.size.width - 100, page.size.height - 30, 60, 20),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
          }
          
          sourceDoc.dispose();

          final optimizedBytes = await newDoc.save();
          newDoc.dispose();

          final optimizedData = Uint8List.fromList(optimizedBytes);
          final ratio = ((originalSize - optimizedData.length) / originalSize * 100);
          
          debugPrint('Text optimization result: ${(optimizedData.length / 1024 / 1024).toStringAsFixed(2)}MB (${ratio.toStringAsFixed(1)}% reduction)');
          
          if (optimizedData.length <= targetSize) {
            setState(() {
              _compressionProgress = 1.0;
              _compressionStatus = 'Compression successful!';
            });
            return optimizedData;
          }
        }
        
        sourceDoc.dispose();
      } catch (e) {
        debugPrint('Text extraction compression failed: $e');
      }

      // Strategy 3: Page-by-page compression with reduced quality
      setState(() {
        _compressionProgress = 0.8;
        _compressionStatus = 'Applying aggressive compression...';
      });

      try {
        final result = await _compressPdfAggressively(originalBytes);
        
        if (result.length <= targetSize) {
          setState(() {
            _compressionProgress = 1.0;
            _compressionStatus = 'Compression successful!';
          });
          return result;
        }
        
        // Return the best result even if it doesn't meet target
        setState(() {
          _compressionProgress = 1.0;
          _compressionStatus = 'Best compression achieved';
        });
        return result;
      } catch (e) {
        debugPrint('Aggressive compression failed: $e');
      }

      setState(() {
        _compressionProgress = 1.0;
        _compressionStatus = 'Compression failed';
      });
      
      return null;

    } catch (e) {
      debugPrint('PDF compression error: $e');
      if (mounted) {
        setState(() {
          _isCompressing = false;
          _compressionStatus = 'Compression failed';
        });
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  /// Aggressive PDF compression as last resort
  Future<Uint8List> _compressPdfAggressively(Uint8List originalBytes) async {
    try {
      final sourceDoc = PdfDocument(inputBytes: originalBytes);
      final newDoc = PdfDocument();
      newDoc.compressionLevel = PdfCompressionLevel.best;
      
      // Only extract essential content
      final textExtractor = PdfTextExtractor(sourceDoc);
      final extractedText = textExtractor.extractText();
      
      if (extractedText.isNotEmpty) {
        // Create a single page with all content in smaller font
        final page = newDoc.pages.add();
        final graphics = page.graphics;
        
        // Use very small font to fit more content
        graphics.drawString(
          extractedText,
          PdfStandardFont(PdfFontFamily.helvetica, 8),
          bounds: Rect.fromLTWH(20, 20, page.size.width - 40, page.size.height - 40),
          format: PdfStringFormat(
            lineAlignment: PdfVerticalAlignment.top,
            alignment: PdfTextAlignment.left,
            wordWrap: PdfWordWrapType.word,
          ),
        );
      } else {
        // If no text extracted, create minimal document
        final page = newDoc.pages.add();
        final graphics = page.graphics;
        graphics.drawString(
          'Content extracted from ${sourceDoc.pages.count} page(s)',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(50, 50, 200, 50),
        );
      }
      
      sourceDoc.dispose();
      
      final aggressiveBytes = await newDoc.save();
      newDoc.dispose();
      
      return Uint8List.fromList(aggressiveBytes);
    } catch (e) {
      debugPrint('Aggressive compression error: $e');
      // Return original bytes if everything fails
      return originalBytes;
    }
  }

  /// Show dialog for page selection when PDF has more than 50 pages
  Future<bool> _showPageSelectionDialog(String fileName, int totalPages) async {
    debugPrint('Showing page selection dialog for $fileName with $totalPages pages');
    if (!mounted) return false;

    _startPage = null;
    _endPage = null;
    _totalPages = totalPages;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'PDF Page Selection',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$fileName has $_totalPages pages, which exceeds the 50-page limit.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Start Page',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _startPage = int.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'End Page',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _endPage = int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Max 50 pages allowed',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_startPage != null && _endPage != null) {
                  final pageRange = _endPage! - _startPage! + 1;
                  if (_startPage! >= 1 &&
                      _endPage! <= totalPages &&
                      _startPage! <= _endPage! &&
                      pageRange <= 50) {
                    Navigator.of(context).pop(true);
                  } else {
                    Toast.show(
                      context,
                      'Invalid page range. Please ensure start ≤ end and range ≤ 50 pages.',
                      type: ToastType.error,
                    );
                  }
                } else {
                  Toast.show(
                    context,
                    'Please enter both start and end page numbers.',
                    type: ToastType.error,
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    debugPrint('Page selection dialog result: $result');
    return result ?? false;
  }

  Future<void> _loadSubjectData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .get();

      if (doc.exists) {
        _subjectData = doc.data();
        if (_currentStep == UploadStep.materials ||
            _subjectData?['hasSyllabus'] == true) {
          await _fetchExistingTopics();
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          Toast.show(context, 'Subject not found', type: ToastType.error);
          if (context.canPop()) {
            context.pop();
          } else {
            // If can't pop, navigate to a safe route like dashboard
            context.go('/kp/dashboard');
          }
        }
      }
    } catch (e) {
      // FIX: Guard BuildContext usage with a mounted check.
      if (!mounted) return;
      Toast.show(context, 'Error loading subject: $e', type: ToastType.error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExistingTopics() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('topics')
        .orderBy('order')
        .get();

    if (snapshot.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _generatedTopics = snapshot.docs;
        });
      }
    }
  }

  // --- Step 1: Syllabus & Topic Generation ---
  Future<void> _pickSyllabus() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = result.files.first;

      // Check file size and compress if needed
      if (file.size > 6 * 1024 * 1024) {
        debugPrint('File size ${(file.size / 1024 / 1024).toStringAsFixed(1)}MB exceeds 6MB limit, attempting compression...');

        final compressedBytes = await _compressPdf(file);
        if (compressedBytes != null) {
          // Create a new PlatformFile with compressed data
          final compressedFile = PlatformFile(
            name: file.name,
            size: compressedBytes.length,
            bytes: compressedBytes,
          );

          if (compressedFile.size <= 6 * 1024 * 1024) {
            debugPrint('Compression successful! New size: ${(compressedFile.size / 1024 / 1024).toStringAsFixed(1)}MB');
            // Use compressed file
            _syllabusFile = compressedFile;
          } else {
            if (mounted) {
              Toast.show(
                context,
                'Unable to compress file below 6MB. Current size: ${(compressedFile.size / 1024 / 1024).toStringAsFixed(1)}MB\n\nPlease use a smaller PDF file.',
                type: ToastType.error,
              );
            }
            return;
          }
        } else {
          if (mounted) {
            Toast.show(
              context,
              'Compression failed. Please use a smaller PDF file (under 6MB).',
              type: ToastType.error,
            );
          }
          return;
        }
      } else {
        debugPrint('File size ${(file.size / 1024 / 1024).toStringAsFixed(1)}MB is within 6MB limit, no compression needed');
        _syllabusFile = file;
      }

      // Check page count using the final file (original or compressed)
      final pageCount = await _getPdfPageCount(_syllabusFile!);
      debugPrint('PDF ${_syllabusFile!.name} has $pageCount pages');

      if (pageCount > 50) {
        debugPrint('Showing page selection dialog for ${_syllabusFile!.name}');
        if (mounted) {
          final shouldContinue = await _showPageSelectionDialog(_syllabusFile!.name, pageCount);
          if (!shouldContinue) {
            debugPrint('User cancelled page selection');
            return;
          }
          debugPrint('User selected page range: $_startPage - $_endPage');
        }
      } else {
        debugPrint('PDF has $pageCount pages, no page selection needed');
      }

      setState(() {
        // _syllabusFile is already set above (original or compressed)
        // Reset page selection for next file
        _startPage = null;
        _endPage = null;
        _totalPages = null;
      });
      if (mounted) {
        Toast.show(context, 'Syllabus file selected!', type: ToastType.info);
      }
    }
  }

  Future<void> _generateTopics() async {
    if (_syllabusFile == null) {
      Toast.show(
        context,
        'Please select a syllabus file',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentProcessingStep = 'Uploading syllabus to AI...';
      _processingProgress = 0.2;
    });

    try {
      // Get PDF bytes for direct upload to AI
      final pdfBytes = kIsWeb
          ? _syllabusFile!.bytes!
          : await File(_syllabusFile!.path!).readAsBytes();

      setState(() {
        _currentProcessingStep = 'Analyzing syllabus with AI...';
        _processingProgress = 0.5;
      });

      // Get the subject name from the current subject data
      final currentSubjectName = _subjectData?['name'] ?? 'Unknown Subject';

      final systemPrompt = '''
      You are an expert academic assistant specialized in analyzing syllabus documents. Your task is to:

      ANALYZING SYLLABUS FOR SUBJECT: "$currentSubjectName"

      1. This syllabus document is for the subject: "$currentSubjectName"
      2. Extract all learning topics, modules, units, chapters, or lessons from this syllabus
      3. Focus on the content structure and learning objectives for this specific subject

      CRITICAL REQUIREMENTS:
      - MAXIMUM 50 topics can be extracted (prioritize the most important topics if more than 50 exist)
      - Extract topics that are relevant to "$currentSubjectName"
      - If the syllabus content doesn't match "$currentSubjectName", still extract the available topics

      ANALYSIS GUIDELINES:
      - Look for section headings like "Topics", "Modules", "Units", "Chapters", "Syllabus Content", "Course Content"
      - Identify numbered or bulleted lists of topics
      - Extract both main topics and subtopics if clearly defined
      - Ignore administrative content (grading, attendance, contact info, etc.)
      - Focus on actual learning content that students will study
      - Extract topics in the logical order they appear in the syllabus

      OUTPUT FORMAT:
      Return a valid JSON object with this structure:
      {
        "subject_name": "$currentSubjectName",
        "topics": [
          {"title": "Topic 1 Name"},
          {"title": "Topic 2 Name"},
          {"title": "Subtopic under Topic 2"},
          ...
        ]
      }

      IMPORTANT:
      - Maximum 50 topics in the topics array
      - Each topic should be a clear, concise learning objective or content area for "$currentSubjectName"
      - Maintain the logical order as presented in the syllabus
      - Include both main topics and important subtopics (within the 50 topic limit)
      - Ensure all titles are descriptive and educational in nature
      - Return only the JSON object, no additional text or explanations
      ''';

      final String response = await AIService.instance.generateContentWithPdf(
        systemPrompt,
        pdfBytes,
        'application/pdf',
      );

      setState(() {
        _currentProcessingStep = 'Parsing AI response...';
        _processingProgress = 0.8;
      });

      // Validate and parse AI response
      Map<String, dynamic> aiResponse;
      List<dynamic> topicsFromAI;
      final subjectName = currentSubjectName; // Use the subject name from current context

      try {
        aiResponse = jsonDecode(response);

        // Validate response structure
        if (!aiResponse.containsKey('topics')) {
          throw Exception('Invalid AI response structure. Missing topics.');
        }

        topicsFromAI = aiResponse['topics'];
        if (topicsFromAI.isEmpty) {
          throw Exception('No topics were extracted from the syllabus. Please ensure the PDF contains a clear topic structure.');
        }

        // Enforce 50 topic limit
        if (topicsFromAI.length > 50) {
          debugPrint('Warning: AI returned ${topicsFromAI.length} topics, limiting to 50');
          topicsFromAI = topicsFromAI.take(50).toList();
        }

        // Validate each topic has required fields
        for (int i = 0; i < topicsFromAI.length; i++) {
          final topic = topicsFromAI[i];
          if (topic is! Map<String, dynamic> || !topic.containsKey('title') || topic['title'].toString().trim().isEmpty) {
            throw Exception('Invalid topic structure at position ${i + 1}. Each topic must have a non-empty title.');
          }
        }

        debugPrint('Successfully parsed subject: "$subjectName"');
        debugPrint('Successfully parsed ${topicsFromAI.length} topics from AI response');

        // Log extracted topics for debugging
        for (int i = 0; i < topicsFromAI.length; i++) {
          debugPrint('Topic ${i + 1}: ${topicsFromAI[i]['title']}');
        }

      } catch (e) {
        debugPrint('Failed to parse AI response: $e');
        debugPrint('AI Response: $response');
        throw Exception('Failed to parse topics from AI response. The syllabus format may not be supported. Please try a different PDF or contact support.');
      }

      setState(() {
        _currentProcessingStep = 'Saving topics to database...';
        _processingProgress = 0.9;
      });

      final batch = FirebaseFirestore.instance.batch();
      final subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId);
      final topicsCollection = subjectRef.collection('topics');

      for (int i = 0; i < topicsFromAI.length; i++) {
        final topicRef = topicsCollection.doc();
        batch.set(topicRef, {
          'title': topicsFromAI[i]['title'],
          'order': i + 1,
          'status': 'pending_review',
          'subject_name': subjectName, // Include identified subject name
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Update subject with syllabus info and identified subject name
      batch.update(subjectRef, {
        'hasSyllabus': true,
        'identified_subject_name': subjectName,
        'total_topics': topicsFromAI.length,
        'syllabus_processed_at': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();

      await _fetchExistingTopics();

      if (mounted) {
        setState(() {
          _processingProgress = 1.0;
          _currentProcessingStep = 'Complete!';
        });

        Toast.show(
          context,
          'Successfully generated ${topicsFromAI.length} topics for "$subjectName"!',
          type: ToastType.success,
        );

        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() => _currentStep = UploadStep.materials);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to generate topics: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
          _currentProcessingStep = '';
        });
      }
    }
  }

  // --- Step 2: Study Materials & Content Generation ---
  Future<void> _pickMaterials() async {
    if (_materialFiles.length >= 10) {
      Toast.show(
        context,
        'Maximum of 10 material files allowed.',
        type: ToastType.error,
      );
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      int availableSlots = 10 - _materialFiles.length;
      List<PlatformFile> validFiles = [];

      for (final file in result.files.take(availableSlots)) {
        // Check file size (10MB limit for materials)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            Toast.show(
              context,
              '${file.name}: File size must be less than 10MB. Current size: ${(file.size / 1024 / 1024).toStringAsFixed(1)}MB',
              type: ToastType.error,
            );
          }
          continue;
        }

        validFiles.add(file);
      }

      if (validFiles.isNotEmpty) {
        setState(() {
          _materialFiles.addAll(validFiles);
          // Reset page selection for next file
          _startPage = null;
          _endPage = null;
          _totalPages = null;
        });
        if (mounted) {
          Toast.show(
            context,
            'Added ${validFiles.length} file(s)',
            type: ToastType.info,
          );
        }
      }
    }
  }

  void _removeMaterialFile(int index) {
    setState(() => _materialFiles.removeAt(index));
  }

  // --- FIX: Refactored for batch processing and source tracking ---
  Future<void> _generateContent() async {
    if (_materialFiles.isEmpty) {
      Toast.show(
        context,
        'Please add at least one study material file.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = UploadStep.generating;
      _totalTopics = _generatedTopics.length;
      _currentTopicIndex = 0; // Represents total processed topics
      _currentProcessingStep = 'Extracting text from materials...';
      _processingProgress = 0.0;
    });

    try {
      // Concatenate text from all PDFs
      String allMaterialsText = "";
      for (int i = 0; i < _materialFiles.length; i++) {
        final file = _materialFiles[i];
        setState(() {
          _currentProcessingStep =
              'Extracting text from ${file.name}... (${i + 1}/${_materialFiles.length})';
          _processingProgress =
              (i / _materialFiles.length) * 0.2; // First 20% for extraction
        });
        final text = await _extractTextFromPdf(file);
        allMaterialsText = '$allMaterialsText$text\n\n';
      }

      if (allMaterialsText.trim().isEmpty) {
        throw Exception(
          "Could not extract any text from the provided material files.",
        );
      }

      // Filter topics that still need content generation
      final topicsToProcess = <DocumentSnapshot>[];
      for (final topicDoc in _generatedTopics) {
        final existingContent = await FirebaseFirestore.instance
            .collection('content_chunks')
            .where('topic_id', isEqualTo: topicDoc.id)
            .where('subject_id', isEqualTo: widget.subjectId)
            .limit(1)
            .get();
        if (existingContent.docs.isEmpty) {
          topicsToProcess.add(topicDoc);
        } else {
          // Update progress for skipped topics
          if (mounted) {
            setState(() {
              _currentTopicIndex++;
              _currentProcessingStep = 'Skipping generated: ${topicDoc['title']}';
              _processingProgress =
                  0.2 + ((_currentTopicIndex / _totalTopics) * 0.75);
            });
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      }

      if (topicsToProcess.isEmpty) {
        if (mounted) {
          Toast.show(context, 'All content has already been generated.',
              type: ToastType.info);
        }
      } else {
        // Batch processing logic
        const batchSize = 5; // Process 5 topics per AI request
        for (int i = 0; i < topicsToProcess.length; i += batchSize) {
          final batchTopics = topicsToProcess.sublist(
              i,
              i + batchSize > topicsToProcess.length
                  ? topicsToProcess.length
                  : i + batchSize);
          final topicTitles =
              batchTopics.map((doc) => doc['title'] as String).toList();

          final batchNumber = (i / batchSize).floor() + 1;
          final totalBatches = (topicsToProcess.length / batchSize).ceil();

          setState(() {
            _currentProcessingStep =
                'Processing batch $batchNumber of $totalBatches...';
          });

          // Updated prompt for batching
          final systemPrompt = '''
          You are a helpful teaching assistant. Your task is to generate educational content for a given list of topics, based **strictly and solely** on the provided "Context" from study materials.

          **CONTEXT:**
          $allMaterialsText

          **TOPICS TO PROCESS:**
          ${jsonEncode(topicTitles)}

          **CRITICAL INSTRUCTIONS:**
          1.  **Grounding:** For EACH topic, you MUST generate content that is directly supported by the information in the "CONTEXT". Do not invent information or use external knowledge. If the context does not contain relevant information for a topic, state that explicitly in the content.
          2.  **Structure:** For EACH topic in the list, create exactly two distinct, detailed content chunks.
          3.  **Content:** Each chunk must have a "title" and "content". The "content" must be at least 40 words long and be written in an educational, clear, and engaging style.

          **OUTPUT FORMAT:**
          Your output must be a single, valid JSON array. Each object in the array corresponds to a topic from the input list and must maintain the original order.

          The structure for each object in the array MUST be:
          {
            "topic_title": "The exact title of the topic from the input list",
            "content_chunks": [
              {
                "title": "Chunk 1 Title (e.g., Introduction to Topic)",
                "content": "Chunk 1 content based *only* on the provided context..."
              },
              {
                "title": "Chunk 2 Title (e.g., Key Concepts of Topic)",
                "content": "Chunk 2 content based *only* on the provided context..."
              }
            ]
          }

          **IMPORTANT:**
          - If the context is insufficient for a topic, the "content" for its chunks should be: "The provided study materials do not contain sufficient information to generate content for this topic."
          - Do not create content for topics not in the input list.
          - Adhere strictly to the JSON format. No extra text or explanations.
          ''';

          final prompt = systemPrompt;

          final String response =
              await AIService.instance.generateContent(prompt);
          final List<dynamic> aiResponse = jsonDecode(response);

          final firestoreBatch = FirebaseFirestore.instance.batch();
          final chunksCollection =
              FirebaseFirestore.instance.collection('content_chunks');
          final sourceFileNames = _materialFiles.map((f) => f.name).toList();

          for (var topicData in aiResponse) {
            final topicTitle = topicData['topic_title'];
            final contentChunks = topicData['content_chunks'] as List<dynamic>;

            final originalTopicDoc = batchTopics.firstWhere(
              (doc) => doc['title'] == topicTitle,
              orElse: () => throw Exception(
                  'AI response topic "$topicTitle" not found in original batch.'),
            );

            for (int j = 0; j < contentChunks.length; j++) {
              final chunkRef = chunksCollection.doc();
              firestoreBatch.set(chunkRef, {
                'title': contentChunks[j]['title'],
                'content': contentChunks[j]['content'],
                'order': j + 1,
                'topic_id': originalTopicDoc.id,
                'subject_id': widget.subjectId,
                'source_files': sourceFileNames, // Track source files
                'createdAt': FieldValue.serverTimestamp(),
              });
            }

            // Mark topic as completed
            final topicRef = FirebaseFirestore.instance
                .collection('subjects')
                .doc(widget.subjectId)
                .collection('topics')
                .doc(originalTopicDoc.id);
            firestoreBatch.update(topicRef, {
              'content_generated': true,
              'content_generated_at': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              setState(() {
                _currentTopicIndex++;
                _currentProcessingStep = 'Generated: $topicTitle';
                _processingProgress =
                    0.2 + ((_currentTopicIndex / _totalTopics) * 0.75);
              });
            }
          }
          await firestoreBatch.commit();
        }
      }

      setState(() {
        _currentProcessingStep = 'Finalizing content generation...';
        _processingProgress = 0.95;
      });

      // Update subject to mark content generation as complete
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
        'hasMaterial': true,
        'hasContent': true,
        'content_generation_completed_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _processingProgress = 1.0;
          _currentProcessingStep = 'Content generation complete!';
        });

        Toast.show(
          context,
          'All content generated successfully!',
          type: ToastType.success,
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() => _currentStep = UploadStep.done);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to generate content: ${e.toString()}',
          type: ToastType.error,
        );
        setState(() => _currentStep = UploadStep.materials);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
          _currentProcessingStep = '';
          _currentTopicIndex = 0;
          _totalTopics = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.kp,
      appBarTitle: 'AI Content Generation',
      bottomNavIndex: 0,
      showBottomBar: false,
      showCloseButton: true,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case UploadStep.syllabus:
        return _buildSyllabusStep();
      case UploadStep.materials:
        return _buildMaterialsStep();
      case UploadStep.generating:
        return _buildGeneratingStep();
      case UploadStep.done:
        return _buildDoneStep();
    }
  }

  Widget _buildStepUI({
    required String title,
    required String subtitle,
    required Widget content,
    Widget? primaryAction,
    Widget? secondaryAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        content,
        const SizedBox(height: 32),
        // --- FIX: Replaced Row with Wrap to prevent overflow ---
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12, // Horizontal space between buttons
          runSpacing: 12, // Vertical space if they wrap
          children: [
            if (secondaryAction != null) secondaryAction,
            if (primaryAction != null) primaryAction,
          ],
        ),
      ],
    );
  }

  Widget _buildSyllabusStep() {
    return _buildStepUI(
      title: 'Step 1: Generate Topics from Syllabus',
      subtitle:
          'Upload your subject\'s syllabus (PDF). Our AI will analyze it and generate a structured list of topics.',
      content: Column(
        children: [
          _buildFileUploadBox(
            title: _generatedTopics.isNotEmpty ? 'Syllabus Document (Uploaded)' : 'Syllabus Document',
            fileName: _syllabusFile?.name ?? (_generatedTopics.isNotEmpty ? 'syllabus.pdf' : null),
            onTap: _pickSyllabus,
          ),
          if (_generatedTopics.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildCompactTopicsBubbles(),
          ],
        ],
      ),
      primaryAction: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isProcessing || _isCompressing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isCompressing
                    ? Colors.orange.withAlpha(25)
                    : Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isCompressing
                      ? Colors.orange.withAlpha(76)
                      : Colors.blue.withAlpha(76),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompressing ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCompressing
                        ? (_compressionStatus.isNotEmpty ? _compressionStatus : 'Compressing PDF...')
                        : (_currentProcessingStep.isNotEmpty ? _currentProcessingStep : 'Processing...'),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if ((_processingProgress > 0 || _compressionProgress > 0)) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _isCompressing ? _compressionProgress : _processingProgress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompressing ? Colors.orange : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${((_isCompressing ? _compressionProgress : _processingProgress) * 100).toInt()}% Complete',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ],
          ElevatedButton.icon(
            icon: (_isProcessing || _isCompressing)
                ? const SizedBox.shrink()
                : const Icon(Icons.psychology, size: 18),
            label: (_isProcessing || _isCompressing)
                ? Text(_isCompressing ? 'Compressing...' : 'Processing...')
                : Text(_generatedTopics.isNotEmpty ? 'Regenerate Topics' : 'Generate Topics & Continue'),
            onPressed: (_isProcessing || _isCompressing) ? null : _generateTopics,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsStatusList() {
    if (_generatedTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    final topicsWithContent = _generatedTopics
        .where((doc) =>
            (doc.data() as Map<String, dynamic>)['content_generated'] == true)
        .length;
    final allGenerated = topicsWithContent == _generatedTopics.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            allGenerated ? Colors.green.withAlpha(25) : Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: allGenerated
                ? Colors.green.withAlpha(76)
                : Colors.blue.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allGenerated ? Icons.check_circle : Icons.info,
                color: allGenerated ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allGenerated
                      ? 'All content generated for ${_generatedTopics.length} topics!'
                      : '$topicsWithContent of ${_generatedTopics.length} topics have content',
                  style: TextStyle(
                    color: allGenerated ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (!allGenerated) ...[
            const SizedBox(height: 12),
            const Text(
              'Topics needing content:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  children: _generatedTopics.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['content_generated'] != true;
                  }).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['title'] ?? 'Untitled Topic',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialsStep() {
    return _buildStepUI(
      title: 'Step 2: Generate Content from Materials',
      subtitle:
          'Upload up to 10 study material PDFs. The AI will use these to create content for the topics from Step 1.',
      content: Column(
        children: [
          _buildTopicsStatusList(),
          const SizedBox(height: 24),
          _buildFileUploadBox(
            title: 'Study Material Documents (${_materialFiles.length}/10)',
            onTap: _pickMaterials,
          ),
          const SizedBox(height: 16),
          _buildSelectedMaterialsList(),
        ],
      ),
      secondaryAction: TextButton(
        onPressed: () => setState(() => _currentStep = UploadStep.syllabus),
        child: const Text('Back to Syllabus'),
      ),
      primaryAction: ElevatedButton.icon(
        icon: const Icon(Icons.model_training, size: 18),
        label: const Text('Generate All Content'),
        onPressed: _isProcessing ? null : _generateContent,
      ),
    );
  }

  Widget _buildGeneratingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Animated progress circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _processingProgress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _processingProgress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                Text(
                  '${(_processingProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Current step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blue.withAlpha(76)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _currentProcessingStep.isNotEmpty
                          ? _currentProcessingStep
                          : 'AI is generating content...', 
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Topic progress (if generating content)
            if (_totalTopics > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Processing Topics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentTopicIndex of $_totalTopics topics completed',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalTopics > 0
                          ? _currentTopicIndex / _totalTopics
                          : 0,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[300]!,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This process may take several minutes. Please do not close this page.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneStep() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Content Generation Complete!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'The generated content has been sent for admin approval. You can review it now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                context.go('/kp/review-content/${widget.subjectId}'),
            child: const Text('Review Generated Content'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // If can't pop, navigate to a safe route like dashboard
                context.go('/kp/dashboard');
              }
            },
            child: const Text('Back to Dashboard'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFileUploadBox({
    required String title,
    String? fileName,
    required VoidCallback onTap,
  }) {
    final hasFile = fileName != null;
    final hasTopicsGenerated = _generatedTopics.isNotEmpty && _syllabusFile == null;

    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: hasFile
              ? Colors.green.withAlpha(25)
              : hasTopicsGenerated
                  ? Colors.blue.withAlpha(25)
                  : Colors.black.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? Colors.green.withAlpha(76)
                : hasTopicsGenerated
                    ? Colors.blue.withAlpha(76)
                    : Colors.white24,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                hasFile
                    ? Icons.check_circle
                    : hasTopicsGenerated
                        ? Icons.check_circle_outline
                        : Icons.upload_file,
                key: ValueKey('${hasFile}_$hasTopicsGenerated'),
                size: 40,
                color: hasFile
                    ? Colors.green
                    : hasTopicsGenerated
                        ? Colors.blue
                        : Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: hasFile
                    ? Colors.green[100]
                    : hasTopicsGenerated
                        ? Colors.blue[100]
                        : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName ?? (hasTopicsGenerated ? 'Syllabus processed successfully' : 'Tap to select file(s)'),
              style: TextStyle(
                color: hasFile
                    ? Colors.green[200]
                    : hasTopicsGenerated
                        ? Colors.blue[200]
                        : Colors.white54,
                fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFile) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'File uploaded successfully',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else if (hasTopicsGenerated) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Topics already generated',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTopicsBubbles() {
    if (_generatedTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_generatedTopics.length} Topics Generated',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _generatedTopics.map((doc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withAlpha(102),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      doc['title'] ?? 'Untitled Topic',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSelectedMaterialsList() {
    if (_materialFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_open, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Selected Materials (${_materialFiles.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._materialFiles.asMap().entries.map((entry) {
          int idx = entry.key;
          PlatformFile file = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(76)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
                style: TextStyle(color: Colors.blue[200], fontSize: 12),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: _isProcessing
                      ? null
                      : () => _removeMaterialFile(idx),
                  tooltip: 'Remove file',
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
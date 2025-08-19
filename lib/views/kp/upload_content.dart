import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:auralearn/services/ai_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
      final String text = PdfTextExtractor(document).extractText();
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
          context.pop();
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
      setState(() {
        _syllabusFile = result.files.first;
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

      const systemPrompt =
          'You are an academic assistant. Analyze the syllabus document and extract the topics. Your output must be a valid JSON array of objects, where each object has a "title" property. Ignore all other sections like course information, grading, etc. Focus only on the learning topics/modules.';

      final String response = await AIService.instance.generateContentWithPdf(
        systemPrompt,
        pdfBytes,
        'application/pdf',
      );

      setState(() {
        _currentProcessingStep = 'Parsing AI response...';
        _processingProgress = 0.8;
      });

      final List<dynamic> topicsFromAI = jsonDecode(response);

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
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      batch.update(subjectRef, {'hasSyllabus': true});
      await batch.commit();

      await _fetchExistingTopics();

      if (mounted) {
        setState(() {
          _processingProgress = 1.0;
          _currentProcessingStep = 'Complete!';
        });

        Toast.show(
          context,
          'Topics generated successfully!',
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
      List<PlatformFile> pickedFiles = result.files
          .take(availableSlots)
          .toList();
      setState(() {
        _materialFiles.addAll(pickedFiles);
      });
      if (mounted) {
        Toast.show(
          context,
          'Added ${pickedFiles.length} file(s)',
          type: ToastType.info,
        );
      }
    }
  }

  void _removeMaterialFile(int index) {
    setState(() => _materialFiles.removeAt(index));
  }

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
      _currentTopicIndex = 0;
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
              (i / _materialFiles.length) * 0.3; // First 30% for extraction
        });

        final text = await _extractTextFromPdf(file);
        allMaterialsText = '$allMaterialsText$text\n\n';
      }

      // NOTE: This simple concatenation might exceed model context limits for very large documents.
      // A more advanced implementation would use chunking and a RAG (Retrieval-Augmented Generation) pipeline.
      if (allMaterialsText.trim().isEmpty) {
        throw Exception(
          "Could not extract any text from the provided material files.",
        );
      }

      setState(() {
        _currentProcessingStep = 'Preparing to generate content...';
        _processingProgress = 0.3;
      });

      final batch = FirebaseFirestore.instance.batch();
      final chunksCollection = FirebaseFirestore.instance.collection(
        'content_chunks',
      );
      final subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId);

      for (
        int topicIndex = 0;
        topicIndex < _generatedTopics.length;
        topicIndex++
      ) {
        final topicDoc = _generatedTopics[topicIndex];

        setState(() {
          _currentTopicIndex = topicIndex + 1;
          _currentProcessingStep =
              'Generating content for: ${topicDoc['title']}';
          _processingProgress =
              0.3 +
              ((topicIndex / _generatedTopics.length) *
                  0.6); // 30-90% for content generation
        });

        const systemPrompt =
            'You are a helpful teaching assistant. Based *only* on the provided context, generate two distinct, detailed content chunks for the given topic. Each chunk must have a "title" and "content" (at least 40 words). Output must be a valid JSON array of two objects.';
        final prompt =
            '$systemPrompt\n\nTopic: "${topicDoc['title']}"\n\nContext: "$allMaterialsText"';

        final String response = await AIService.instance.generateContent(
          prompt,
        );
        final List<dynamic> chunksFromAI = jsonDecode(response);

        for (int i = 0; i < chunksFromAI.length; i++) {
          final chunkRef = chunksCollection.doc();
          batch.set(chunkRef, {
            'title': chunksFromAI[i]['title'],
            'content': chunksFromAI[i]['content'],
            'order': i + 1,
            'topic_id': topicDoc.id,
            'subject_id': widget.subjectId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() {
        _currentProcessingStep = 'Saving all content to database...';
        _processingProgress = 0.95;
      });

      batch.update(subjectRef, {'hasMaterial': true, 'hasContent': true});
      await batch.commit();

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

        // Small delay to show completion
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
      content: _buildFileUploadBox(
        title: 'Syllabus Document',
        fileName: _syllabusFile?.name,
        onTap: _pickSyllabus,
      ),
      primaryAction: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isProcessing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(width: 8),
                  Text(
                    _currentProcessingStep.isNotEmpty
                        ? _currentProcessingStep
                        : 'Processing...',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_processingProgress > 0) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _processingProgress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_processingProgress * 100).toInt()}% Complete',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ],
          ElevatedButton.icon(
            icon: _isProcessing
                ? const SizedBox.shrink()
                : const Icon(Icons.psychology, size: 18),
            label: _isProcessing
                ? const Text('Processing...')
                : const Text('Generate & Go to Next Step'),
            onPressed: _isProcessing ? null : _generateTopics,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsStep() {
    return _buildStepUI(
      title: 'Step 2: Generate Content from Materials',
      subtitle:
          'Upload up to 10 study material PDFs. The AI will use these to create content for the topics below.',
      content: Column(
        children: [
          _buildGeneratedTopicsList(),
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
            onPressed: () => context.pop(),
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

    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: hasFile
              ? Colors.green.withAlpha(25)
              : Colors.black.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? Colors.green.withAlpha(76) : Colors.white24,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                key: ValueKey(hasFile),
                size: 40,
                color: hasFile ? Colors.green : Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: hasFile ? Colors.green[100] : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName ?? 'Tap to select file(s)',
              style: TextStyle(
                color: hasFile ? Colors.green[200] : Colors.white54,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedTopicsList() {
    if (_generatedTopics.isEmpty) {
      return const Text(
        'No topics generated yet. Complete Step 1 first.',
        style: TextStyle(color: Colors.orange),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI-Generated Topics:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          ..._generatedTopics.map(
            (doc) => Text(
              '• ${doc['title']}',
              style: const TextStyle(color: Colors.white70),
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

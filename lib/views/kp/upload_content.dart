import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auralearn/components/toast.dart';

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
  String? _syllabusFileName;
  final List<String> _materialFileNames = [];
  bool _isUploading = false;
  Map<String, dynamic>? _subjectData;
  bool _isLoading = true;
  List<String> _generatedTopics = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
  }

  Future<void> _loadSubjectData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _subjectData = doc.data();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Toast.show(context, 'Subject not found', type: ToastType.error);
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Error loading subject: $e', type: ToastType.error);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickSyllabus() async {
    // Placeholder for file picker integration
    setState(() => _syllabusFileName = 'syllabus_${DateTime.now().millisecondsSinceEpoch}.pdf');
    if (mounted) {
      Toast.show(context, 'Syllabus file selected', type: ToastType.success);
    }
  }

  Future<void> _pickMaterial() async {
    // Check if syllabus is uploaded first
    if (!(_subjectData?['hasSyllabus'] ?? false)) {
      Toast.show(context, 'Please upload syllabus first', type: ToastType.error);
      return;
    }

    // Check if we've reached the limit of 10 files
    if (_materialFileNames.length >= 10) {
      Toast.show(context, 'Maximum 10 files allowed', type: ToastType.error);
      return;
    }

    // Placeholder for file picker integration - simulate multiple file selection
    final newFileName = 'material_${DateTime.now().millisecondsSinceEpoch}.pdf';
    setState(() {
      _materialFileNames.add(newFileName);
    });
    
    if (mounted) {
      Toast.show(context, 'Study material file added (${_materialFileNames.length}/10)', type: ToastType.success);
    }
  }

  Future<void> _uploadSyllabus() async {
    if (_syllabusFileName == null) {
      Toast.show(context, 'Please select a syllabus file first', type: ToastType.error);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Simulate syllabus processing and topic generation
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate topics from syllabus (placeholder logic)
      final topics = [
        'Introduction to ${_subjectData?['name'] ?? 'Subject'}',
        'Fundamentals and Basic Concepts',
        'Core Principles and Theories',
        'Advanced Topics and Applications',
        'Case Studies and Examples',
        'Review and Assessment'
      ];

      // Create upload record
      final uploadData = {
        'subjectId': widget.subjectId,
        'uploadedBy': user.uid,
        'fileName': _syllabusFileName,
        'fileType': 'syllabus',
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'processed',
        'fileUrl': 'placeholder_url_$_syllabusFileName',
        'generatedTopics': topics,
      };

      await FirebaseFirestore.instance.collection('uploads').add(uploadData);

      // Update subject to mark syllabus as uploaded
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
        'hasSyllabus': true,
        'syllabusUploadedAt': FieldValue.serverTimestamp(),
        'topics': topics,
      });

      setState(() {
        _generatedTopics = topics;
        _subjectData = {..._subjectData!, 'hasSyllabus': true, 'topics': topics};
      });

      if (mounted) {
        Toast.show(context, 'Syllabus uploaded and topics generated!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Upload failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadMaterial() async {
    if (_materialFileNames.isEmpty) {
      Toast.show(context, 'Please select study material files first', type: ToastType.error);
      return;
    }

    if (!(_subjectData?['hasSyllabus'] ?? false)) {
      Toast.show(context, 'Please upload syllabus first', type: ToastType.error);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Simulate processing each file and creating content chunks
      for (int i = 0; i < _materialFileNames.length; i++) {
        final fileName = _materialFileNames[i];
        
        // Simulate PDF to text conversion and chunking
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate creating content chunks (50k tokens per batch)
        final chunks = _generateContentChunks(fileName, i);
        
        // Store chunks in content_chunks collection
        final batch = FirebaseFirestore.instance.batch();
        
        for (int j = 0; j < chunks.length; j++) {
          final chunkRef = FirebaseFirestore.instance.collection('content_chunks').doc();
          batch.set(chunkRef, {
            'subjectId': widget.subjectId,
            'sourceDocument': {
              'fileName': fileName,
              'fileIndex': i,
              'chunkIndex': j,
              'totalChunks': chunks.length,
            },
            'content': chunks[j],
            'uploadedBy': user.uid,
            'uploadedAt': FieldValue.serverTimestamp(),
            'tokenCount': chunks[j].length, // Approximate token count
          });
        }
        
        await batch.commit();
      }

      // Create upload record for all materials
      final uploadData = {
        'subjectId': widget.subjectId,
        'uploadedBy': user.uid,
        'fileNames': _materialFileNames,
        'fileType': 'material',
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'processed',
        'totalFiles': _materialFileNames.length,
      };

      await FirebaseFirestore.instance.collection('uploads').add(uploadData);

      // Update subject to mark material as uploaded
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
        'hasMaterial': true,
        'materialUploadedAt': FieldValue.serverTimestamp(),
        'materialFileCount': _materialFileNames.length,
      });

      if (mounted) {
        Toast.show(context, 'Study materials uploaded and processed successfully!', type: ToastType.success);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Upload failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeMaterialFile(int index) {
    setState(() {
      _materialFileNames.removeAt(index);
    });
    Toast.show(context, 'File removed', type: ToastType.success);
  }

  List<String> _generateContentChunks(String fileName, int fileIndex) {
    // Simulate content chunking - in real app, this would process actual PDF content
    final sampleContent = '''
    This is sample content from $fileName. 
    In a real implementation, this would be the actual text extracted from the PDF file.
    The content would be split into chunks of approximately 50,000 tokens each.
    Each chunk would contain meaningful sections of the document to maintain context.
    ''';
    
    // Simulate multiple chunks per file
    return List.generate(3, (index) => 
      '$sampleContent\n\nChunk ${index + 1} of file ${fileIndex + 1}: $fileName'
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
            onPressed: () => context.pop(),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final boxBg = isDark ? Colors.grey[900] : Colors.white;
    final innerBg = isDark ? Colors.grey[850] : Colors.grey[100];
    
    final subjectName = _subjectData?['name'] ?? 'Subject';
    final uploadType = widget.uploadType;
    final showSyllabus = uploadType == null || uploadType == 'syllabus';
    final showMaterial = uploadType == null || uploadType == 'material';
    final hasSyllabus = _subjectData?['hasSyllabus'] ?? false;
    final topics = _subjectData?['topics'] as List<dynamic>? ?? _generatedTopics;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(subjectName, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              // Syllabus section
              if (showSyllabus) ...[
                Center(child: Text('Syllabus', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18))),
                const SizedBox(height: 12),
                _buildUploadSection(
                  title: 'Syllabus Document',
                  fileName: _syllabusFileName,
                  onPickFile: _pickSyllabus,
                  onUpload: _uploadSyllabus,
                  uploadButtonText: 'Upload Syllabus',
                  boxBg: boxBg,
                  innerBg: innerBg,
                  acceptedFormats: 'PDF, TXT',
                  placeholder: 'Tap to select syllabus file',
                ),
                
                // Show generated topics if syllabus is uploaded
                if (topics.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
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
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Generated Topics',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...topics.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                
                if (showMaterial) const SizedBox(height: 32),
              ],

              // Material section
              if (showMaterial) ...[
                Row(
                  children: [
                    Text('Study Material', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    if (!hasSyllabus)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Upload syllabus first',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // File selection area
                GestureDetector(
                  onTap: hasSyllabus && !_isUploading ? _pickMaterial : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: hasSyllabus ? boxBg : boxBg?.withAlpha(127),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasSyllabus 
                            ? Colors.grey.shade500.withAlpha((0.35 * 255).round())
                            : Colors.grey.shade500.withAlpha((0.15 * 255).round()),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: hasSyllabus ? Colors.grey : Colors.grey.withAlpha(127),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasSyllabus 
                              ? 'Tap to add study material files (${_materialFileNames.length}/10)'
                              : 'Upload syllabus first to enable material upload',
                          style: TextStyle(
                            color: hasSyllabus 
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(127),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PDF, TXT (Max 10 files)',
                          style: TextStyle(
                            color: hasSyllabus ? Colors.grey : Colors.grey.withAlpha(127), 
                            fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Show selected files
                if (_materialFileNames.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withAlpha(76)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Files (${_materialFileNames.length}/10)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._materialFileNames.asMap().entries.map((entry) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.description, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red, size: 16),
                                  onPressed: _isUploading ? null : () => _removeMaterialFile(entry.key),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Upload button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (hasSyllabus && _materialFileNames.isNotEmpty && !_isUploading) 
                        ? _uploadMaterial 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Upload Study Materials (${_materialFileNames.length} files)',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String? fileName,
    required VoidCallback onPickFile,
    required VoidCallback onUpload,
    required String uploadButtonText,
    required Color? boxBg,
    required Color? innerBg,
    required String acceptedFormats,
    required String placeholder,
  }) {
    return Column(
      children: [
        // File picker box
        GestureDetector(
          onTap: _isUploading ? null : onPickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade500.withAlpha((0.35 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  fileName != null ? Icons.check_circle : Icons.upload_file,
                  color: fileName != null ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  fileName ?? placeholder,
                  style: TextStyle(
                    color: fileName != null 
                        ? Colors.green 
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: fileName != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  acceptedFormats,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: _isUploading ? null : onPickFile,
                    child: Text(_isUploading ? 'Uploading...' : 'Select File'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploading ? null : onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    uploadButtonText,
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
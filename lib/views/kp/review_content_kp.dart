import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';

class ReviewContentKPPage extends StatefulWidget {
  final String subjectId;

  const ReviewContentKPPage({super.key, required this.subjectId});

  @override
  State<ReviewContentKPPage> createState() => _ReviewContentKPPageState();
}

class _ReviewContentKPPageState extends State<ReviewContentKPPage> {
  Map<String, dynamic>? _subjectData;
  bool _isLoading = true;
  bool _isGenerating = false;

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

  Future<void> _generateContent() async {
    setState(() => _isGenerating = true);

    try {
      // Simulate content generation
      await Future.delayed(const Duration(seconds: 3));

      // Update subject to mark content as generated
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
            'hasContent': true,
            'contentGeneratedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Toast.show(
          context,
          'Content generated successfully!',
          type: ToastType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to generate content: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
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
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjectName = _subjectData?['name'] ?? 'Subject';
    final hasSyllabus = _subjectData?['hasSyllabus'] ?? false;
    final hasMaterial = _subjectData?['hasMaterial'] ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review: $subjectName',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Status cards
            _buildStatusCard(
              'Syllabus',
              hasSyllabus ? 'Uploaded' : 'Not uploaded',
              hasSyllabus ? Icons.check_circle : Icons.pending,
              hasSyllabus ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              'Study Material',
              hasMaterial ? 'Uploaded' : 'Not uploaded',
              hasMaterial ? Icons.check_circle : Icons.pending,
              hasMaterial ? Colors.green : Colors.orange,
            ),

            const SizedBox(height: 32),

            // Content generation section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Content Generation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasSyllabus && hasMaterial
                        ? 'Ready to generate AI content from uploaded materials'
                        : 'Upload both syllabus and study material to generate content',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (hasSyllabus && hasMaterial && !_isGenerating)
                          ? _generateContent
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Generate AI Content',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  Widget _buildStatusCard(
    String title,
    String status,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(status, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

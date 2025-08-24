import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';

import '../../enums/user_role.dart';

class ReviewContentKPPage extends StatefulWidget {
  final String subjectId;
  const ReviewContentKPPage({super.key, required this.subjectId});

  @override
  State<ReviewContentKPPage> createState() => _ReviewContentKPPageState();
}

class _ReviewContentKPPageState extends State<ReviewContentKPPage> {
  Future<Map<String, dynamic>>? _contentFuture;
  bool _isProcessingAction = false; // Prevents duplicate clicks

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadTopicsAndContent();
  }

  // --- FIX: Updated logic to be more explicit and reliable ---
  /// Checks if all topics are in a "completed" state from the KP's perspective.
  /// If so, it updates the parent subject's status to 'admin_review'.
  Future<void> _checkAndFinalizeSubjectStatus() async {
    try {
      final allTopicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .get();

      if (allTopicsSnapshot.docs.isEmpty) return;

      // A topic is considered "processed" by the KP if its status is no longer 'generated' or 'regenerating'.
      final allTopicsProcessed = allTopicsSnapshot.docs.every((topicDoc) {
        final status = topicDoc.data()['status'] as String?;
        return status != 'generated' && status != 'regenerating';
      });

      if (allTopicsProcessed) {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .update({
              'status': 'admin_review',
              'all_topics_accepted_at': FieldValue.serverTimestamp(),
            });
        debugPrint('All topics accepted. Subject status updated to admin_review.');
        if (mounted) {
          Toast.show(context, 'All topics accepted! Subject sent for admin review.', type: ToastType.success);
        }
      }
    } catch (e) {
      debugPrint('Error checking topic acceptance: $e');
    }
  }

  // --- Action: Accept all remaining topics ---
  Future<void> _acceptAllTopics() async {
    setState(() => _isProcessingAction = true);
    try {
      // Correctly target topics that are 'generated' or have no status field yet
      final topicsToAcceptSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .where('status', whereIn: ['generated', null]).get();

      if (topicsToAcceptSnapshot.docs.isEmpty) {
        if (!mounted) return;
        Toast.show(context, 'All topics have already been accepted.', type: ToastType.info);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final topicDoc in topicsToAcceptSnapshot.docs) {
        batch.update(topicDoc.reference, {
          'status': 'pending_review',
          'accepted_by_kp': true,
          'accepted_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        Toast.show(context, 'Accepted ${topicsToAcceptSnapshot.docs.length} remaining topics.', type: ToastType.success);
      }
      await _checkAndFinalizeSubjectStatus();
    } catch (e) {
      debugPrint('Error accepting all topics: $e');
      if (mounted) {
        Toast.show(context, 'Failed to accept topics: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _contentFuture = _loadTopicsAndContent(); // Refresh UI
        });
      }
    }
  }

  // --- Action: Accept a single topic ---
  Future<void> _acceptTopic(String topicId) async {
    setState(() => _isProcessingAction = true);
    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({
            'status': 'pending_review',
            'accepted_by_kp': true,
            'accepted_at': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Toast.show(context, 'Topic accepted and submitted for review.', type: ToastType.success);
      }
      await _checkAndFinalizeSubjectStatus();
    } catch (e) {
      debugPrint('Error accepting topic: $e');
      if (mounted) {
        Toast.show(context, 'Failed to accept topic: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _contentFuture = _loadTopicsAndContent(); // Refresh UI
        });
      }
    }
  }
  
  // --- Action: Regenerate a single topic ---
  Future<void> _regenerateTopic(String topicId) async {
    setState(() => _isProcessingAction = true);
    try {
      final topicRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId);

      // Mark topic as regenerating for immediate UI feedback
      await topicRef.update({
        'status': 'regenerating',
        'regenerated_at': FieldValue.serverTimestamp(),
      });
      
      // Refresh UI to show "regenerating" state
      if (mounted) {
        setState(() {
         _contentFuture = _loadTopicsAndContent();
        });
        Toast.show(context, 'Requesting new content from AI...', type: ToastType.info);
      }

      // This is where you would call your AI service.
      // We will simulate it here.
      await _performContentRegeneration(topicId);

      // AI process would set status back to 'generated' upon completion
      if (mounted) {
        Toast.show(context, 'Content regenerated successfully!', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('Error regenerating content: $e');
      if (mounted) {
        Toast.show(context, 'Failed to regenerate content: $e', type: ToastType.error);
      }
      // Reset status on failure
      try {
        await FirebaseFirestore.instance.collection('subjects').doc(widget.subjectId)
        .collection('topics').doc(topicId).update({'status': 'generated'});
      } catch (resetError) {
        debugPrint('Failed to reset topic status after error: $resetError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _contentFuture = _loadTopicsAndContent(); // Final refresh
        });
      }
    }
  }

  // --- Helper: Simulate AI call for regeneration ---
  Future<void> _performContentRegeneration(String topicId) async {
    try {
      // Simulate AI service call - replace with actual AI integration
      await Future.delayed(const Duration(seconds: 5));

      final topicDoc = await FirebaseFirestore.instance.collection('subjects').doc(widget.subjectId).collection('topics').doc(topicId).get();
      final originalTitle = topicDoc.data()?['title'] ?? 'Untitled';

      // Delete old content chunks before creating new ones
      final oldChunksSnapshot = await FirebaseFirestore.instance
          .collection('content_chunks')
          .where('topic_id', isEqualTo: topicId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in oldChunksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Simulate generating new content
      final regeneratedContent = 'This is the newly regenerated content for "$originalTitle". It includes updated information and examples based on the latest materials provided.';
      final chunk1Title = 'Introduction to $originalTitle (Revised)';
      final chunk2Title = 'Advanced Concepts in $originalTitle (Revised)';

      // Add new chunks
      final chunksCollection = FirebaseFirestore.instance.collection('content_chunks');
      batch.set(chunksCollection.doc(), {
        'title': chunk1Title,
        'content': regeneratedContent,
        'order': 1,
        'topic_id': topicId,
        'subject_id': widget.subjectId,
        'createdAt': FieldValue.serverTimestamp(),
      });
       batch.set(chunksCollection.doc(), {
        'title': chunk2Title,
        'content': 'Further details and advanced topics regarding "$originalTitle" are discussed here, providing a deeper understanding.',
        'order': 2,
        'topic_id': topicId,
        'subject_id': widget.subjectId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the topic status back to 'generated' so KP can review it again
      batch.update(topicDoc.reference, {
        'status': 'generated',
        'last_regenerated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

    } catch (e) {
      debugPrint('Error in content regeneration logic: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadTopicsAndContent() async {
    final subjectDoc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subjectId)
        .get();

    if (!subjectDoc.exists) throw Exception('Subject not found');

    final topicsSnapshot =
        await subjectDoc.reference.collection('topics').orderBy('order').get();

    List<Map<String, dynamic>> topicsWithContent = [];

    for (final topicDoc in topicsSnapshot.docs) {
      final chunksSnapshot = await FirebaseFirestore.instance
          .collection('content_chunks')
          .where('topic_id', isEqualTo: topicDoc.id)
          .orderBy('order')
          .get();

      topicsWithContent.add({
        'topicId': topicDoc.id,
        'topic': topicDoc.data(),
        'chunks': chunksSnapshot.docs.map((d) => d.data()).toList(),
      });
    }

    return {
      'subject': subjectDoc.data(),
      'topicsWithContent': topicsWithContent
    };
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.kp,
      appBarTitle: 'Review Content',
      bottomNavIndex: 0,
      showBottomBar: false,
      showCloseButton: true,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No content found.'));
          }

          final data = snapshot.data!;
          final subject = data['subject'];
          final topicsWithContent =
              data['topicsWithContent'] as List<Map<String, dynamic>>;
          
          final hasUnacceptedTopics = topicsWithContent.any((t) => t['topic']['status'] == 'generated' || t['topic']['status'] == null);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                subject['name'],
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Subject status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSubjectStatusColor(subject['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Status: ${_getSubjectStatusText(subject['status'])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getSubjectStatusDescription(subject['status']),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              // Accept all button
              if(hasUnacceptedTopics)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessingAction ? null : _acceptAllTopics,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Accept All Remaining Topics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withAlpha(25),
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              if (topicsWithContent.isEmpty)
                _buildEmptyState()
              else
                ...topicsWithContent.map((item) => _buildTopicCard(item)),
            ],
          );
        },
      ),
    );
  }

  // --- UI Helper Methods ---

  Color _getSubjectStatusColor(String? status) {
    switch (status) {
      case 'admin_review': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getSubjectStatusText(String? status) {
    switch (status) {
      case 'admin_review': return 'PENDING ADMIN REVIEW';
      case 'approved': return 'APPROVED BY ADMIN';
      case 'rejected': return 'REJECTED BY ADMIN';
      default: return 'KP REVIEW IN PROGRESS';
    }
  }

  String _getSubjectStatusDescription(String? status) {
    switch (status) {
      case 'admin_review': return 'All topics have been accepted. The subject is now waiting for the administrator to approve it.';
      case 'approved': return 'This subject has been approved by the admin and is ready for students.';
      case 'rejected': return 'This subject was rejected by the admin. Please review feedback and make changes.';
      default: return 'Review each topic below. You can accept topics individually or use "Accept All" when you are ready.';
    }
  }

  Color _getTopicStatusColor(String? status) {
    switch (status) {
      case 'pending_review': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'regenerating': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getTopicStatusText(String? status) {
    switch (status) {
      case 'pending_review': return 'ACCEPTED BY KP';
      case 'approved': return 'APPROVED BY ADMIN';
      case 'rejected': return 'REJECTED BY ADMIN';
      case 'regenerating': return 'REGENERATING';
      default: return 'GENERATED';
    }
  }
  
  Widget _buildTopicCard(Map<String, dynamic> item) {
    final topic = item['topic'];
    final chunks = item['chunks'] as List<dynamic>;
    final topicId = item['topicId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          topic['title'] ?? 'Untitled Topic',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          'Status: ${_getTopicStatusText(topic['status'])}',
          style: TextStyle(color: _getTopicStatusColor(topic['status']), fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chunks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No content chunks found for this topic.'),
                  )
                else
                  ...chunks.map((chunk) => _buildContentChunk(chunk)),
                const Divider(height: 24),
                _buildTopicActions(topic, topicId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicActions(Map<String, dynamic> topic, String topicId) {
    final status = topic['status'] as String?;

    switch (status) {
      case 'generated':
      case null: // Treat null status as 'generated'
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingAction ? null : () => _acceptTopic(topicId),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withAlpha(25),
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingAction ? null : () => _regenerateTopic(topicId),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withAlpha(25),
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        );
      case 'regenerating':
        return const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
              ),
              SizedBox(width: 8),
              Text('Regenerating content...', style: TextStyle(color: Colors.orange)),
            ],
          ),
        );
      default:
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: _getTopicStatusColor(status), size: 16),
              const SizedBox(width: 8),
              Text(
                _getTopicStatusText(status),
                style: TextStyle(color: _getTopicStatusColor(status), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildContentChunk(Map<String, dynamic> chunk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chunk['title'] ?? 'Untitled Chunk',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.blue[300]),
          ),
          const SizedBox(height: 8),
          Text(
            chunk['content'] ?? 'No content',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: const [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'No Content Generated Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Use the "Upload Content" feature on your dashboard to generate topics and learning materials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
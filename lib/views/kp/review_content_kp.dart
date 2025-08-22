import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';

class ReviewContentKPPage extends StatefulWidget {
  final String subjectId;
  const ReviewContentKPPage({super.key, required this.subjectId});

  @override
  State<ReviewContentKPPage> createState() => _ReviewContentKPPageState();
}

class _ReviewContentKPPageState extends State<ReviewContentKPPage> {
  Future<Map<String, dynamic>>? _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadTopicsAndContent();
  }

  // Check if all topics are accepted by KP
  Future<bool> _checkAllTopicsAccepted() async {
    try {
      final allTopicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .get();

      if (allTopicsSnapshot.docs.isEmpty) return false;

      // Check if all topics are either pending_review or approved
      for (final topicDoc in allTopicsSnapshot.docs) {
        final status = topicDoc.data()['status'] as String?;
        if (status == 'generated' || status == 'regenerating' || status == null) {
          return false; // Still has topics that KP hasn't accepted
        }
      }

      return true; // All topics have been processed by KP
    } catch (e) {
      debugPrint('Error checking topic acceptance: $e');
      return false;
    }
  }

  // Update subject status to admin_review when all topics are accepted
  Future<void> _updateSubjectStatusToAdminReview() async {
    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
            'status': 'admin_review',
            'all_topics_accepted_at': FieldValue.serverTimestamp(),
          });
      debugPrint('Subject status updated to admin_review');
    } catch (e) {
      debugPrint('Error updating subject status: $e');
    }
  }

  // Accept all topics - mark all as ready for admin review
  Future<void> _acceptAllTopics() async {
    try {
      // Get topics with 'generated' status
      final generatedTopicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .where('status', isEqualTo: 'generated')
          .get();

      // Get topics with null status (topics that don't have status field)
      final nullStatusTopicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .where('status', isNull: true)
          .get();

      final allTopicDocs = [...generatedTopicsSnapshot.docs, ...nullStatusTopicsSnapshot.docs];

      if (allTopicDocs.isEmpty) {
        if (!mounted) return;
        Toast.show(context, 'No topics to accept', type: ToastType.info);
        return;
      }

      int acceptedCount = 0;
      for (final topicDoc in allTopicDocs) {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('topics')
            .doc(topicDoc.id)
            .update({
              'status': 'pending_review',
              'accepted_by_kp': true,
              'accepted_at': FieldValue.serverTimestamp(),
            });
        acceptedCount++;
      }

      // Check if all topics are now accepted and update subject status
      final allAccepted = await _checkAllTopicsAccepted();
      if (allAccepted) {
        await _updateSubjectStatusToAdminReview();
        if (!mounted) return;
        Toast.show(context, 'All $acceptedCount topics accepted! Subject is now ready for admin review.', type: ToastType.success);
      } else {
        if (!mounted) return;
        Toast.show(context, 'Successfully accepted $acceptedCount topics for admin review', type: ToastType.success);
      }

      // Refresh the content
      if (mounted) {
        setState(() {
          _contentFuture = _loadTopicsAndContent();
        });
      }
    } catch (e) {
      debugPrint('Error accepting all topics: $e');
      if (mounted) {
        Toast.show(context, 'Failed to accept topics: $e', type: ToastType.error);
      }
    }
  }

  // Accept a topic - mark as ready for admin review
  Future<void> _acceptTopic(String topicId) async {
    try {
      // Get current topic data to preserve it
      final topicDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .get();

      if (!topicDoc.exists) {
        if (!mounted) return;
        Toast.show(context, 'Topic not found', type: ToastType.error);
        return;
      }

      // Update topic status and add timestamp
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

      // Check if all topics are now accepted and update subject status
      final allAccepted = await _checkAllTopicsAccepted();
      if (allAccepted) {
        await _updateSubjectStatusToAdminReview();
        if (!mounted) return;
        Toast.show(context, 'Topic accepted! All topics are now ready for admin review.', type: ToastType.success);
      } else {
        if (!mounted) return;
        Toast.show(context, 'Topic submitted for admin review', type: ToastType.success);
      }

      // Refresh the content
      if (mounted) {
        setState(() {
          _contentFuture = _loadTopicsAndContent();
        });
      }
    } catch (e) {
      debugPrint('Error accepting topic: $e');
      if (mounted) {
        Toast.show(context, 'Failed to submit topic: $e', type: ToastType.error);
      }
    }
  }

  // Accept and regenerate a topic - accept current version and request regeneration
  Future<void> _acceptAndRegenerateTopic(String topicId) async {
    try {
      // First, get the current topic data to preserve it
      final topicDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .get();

      if (!topicDoc.exists) {
        if (!mounted) return;
        Toast.show(context, 'Topic not found', type: ToastType.error);
        return;
      }

      final topicData = topicDoc.data()!;
      final originalTitle = topicData['title'] as String?;
      final originalContent = topicData['content'] as String?;

      // Accept the topic first
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({
            'status': 'regenerating',
            'accepted_by_kp': true,
            'accepted_at': FieldValue.serverTimestamp(),
            'regenerated_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Toast.show(context, 'Topic accepted and regeneration requested', type: ToastType.info);

      // Perform regeneration
      await _performContentRegeneration(topicId, originalTitle, originalContent);

      // After regeneration, update status to pending_review since it was already accepted
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({
            'status': 'pending_review',
          });

      // Refresh the content
      if (mounted) {
        setState(() {
          _contentFuture = _loadTopicsAndContent();
        });
        Toast.show(context, 'Topic accepted and regenerated successfully', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('Error accepting and regenerating topic: $e');
      // Reset status on error
      try {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('topics')
            .doc(topicId)
            .update({'status': 'generated'});
      } catch (resetError) {
        debugPrint('Error resetting topic status: $resetError');
      }

      if (mounted) {
        Toast.show(context, 'Failed to accept and regenerate: $e', type: ToastType.error);
      }
    }
  }

  // Regenerate content for a topic
  Future<void> _regenerateTopic(String topicId) async {
    try {
      // First, get the current topic data to preserve existing information
      final topicDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .get();

      if (!topicDoc.exists) {
        if (!mounted) return;
        Toast.show(context, 'Topic not found', type: ToastType.error);
        return;
      }

      final topicData = topicDoc.data()!;
      final originalTitle = topicData['title'] as String?;
      final originalContent = topicData['content'] as String?;

      // Mark topic as regenerating
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({
            'status': 'regenerating',
            'regenerated_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Toast.show(context, 'Content regeneration requested', type: ToastType.info);

      // Implement actual regeneration logic
      // This is where you would integrate with your AI service
      await _performContentRegeneration(topicId, originalTitle, originalContent);

      // Verify the regeneration was successful
      final updatedDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .get();

      if (updatedDoc.exists && updatedDoc.data()?['status'] == 'generated') {
        // Refresh the content
        if (mounted) {
          setState(() {
            _contentFuture = _loadTopicsAndContent();
          });
          Toast.show(context, 'Content regenerated successfully', type: ToastType.success);
        }
      } else {
        // If regeneration failed, reset status
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('topics')
            .doc(topicId)
            .update({'status': 'generated'});

        if (mounted) {
          Toast.show(context, 'Regeneration completed', type: ToastType.success);
        }
      }
    } catch (e) {
      // Reset status on error
      try {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('topics')
            .doc(topicId)
            .update({'status': 'generated'});
      } catch (resetError) {
        debugPrint('Error resetting topic status: $resetError');
      }

      if (mounted) {
        Toast.show(context, 'Failed to regenerate content: $e', type: ToastType.error);
      }
    }
  }

  // Perform the actual content regeneration
  Future<void> _performContentRegeneration(String topicId, String? originalTitle, String? originalContent) async {
    try {
      // Simulate AI service call - replace this with actual AI service integration
      await Future.delayed(const Duration(seconds: 3));

      // Generate new content (this would come from your AI service)
      final regeneratedTitle = originalTitle != null ? '$originalTitle (Regenerated)' : 'New Topic Title';
      final regeneratedContent = originalContent != null
          ? '$originalContent\n\n[Regenerated Content Added] - This content has been refreshed and updated with new information.'
          : 'New generated content for this topic.';

      // Update the topic with regenerated content
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({
            'title': regeneratedTitle,
            'content': regeneratedContent,
            'status': 'generated',
            'last_regenerated': FieldValue.serverTimestamp(),
          });

      // Also update content chunks if they exist
      final chunksSnapshot = await FirebaseFirestore.instance
          .collection('content_chunks')
          .where('topic_id', isEqualTo: topicId)
          .get();

      for (final chunkDoc in chunksSnapshot.docs) {
        await chunkDoc.reference.update({
          'title': '${chunkDoc.data()['title'] ?? 'Content'} (Updated)',
          'content': '${chunkDoc.data()['content']}\n\n[Updated content for regenerated topic]',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

    } catch (e) {
      debugPrint('Error in content regeneration: $e');
      // Reset status to generated so user can try again
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('topics')
          .doc(topicId)
          .update({'status': 'generated'});
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
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              // Accept all button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _acceptAllTopics,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Accept All Topics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green),
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

  // Helper methods for subject status
  Color _getSubjectStatusColor(String? status) {
    switch (status) {
      case 'admin_review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange; // kp_review or default
    }
  }

  String _getSubjectStatusText(String? status) {
    switch (status) {
      case 'admin_review':
        return 'READY FOR ADMIN REVIEW';
      case 'approved':
        return 'APPROVED BY ADMIN';
      case 'rejected':
        return 'REJECTED BY ADMIN';
      default:
        return 'KP REVIEW IN PROGRESS';
    }
  }

  String _getSubjectStatusDescription(String? status) {
    switch (status) {
      case 'admin_review':
        return 'All topics have been accepted by you. The subject is now ready for admin review. You can still make changes if needed.';
      case 'approved':
        return 'This subject has been approved by the admin and is ready for student use.';
      case 'rejected':
        return 'This subject was rejected by the admin. Please review the feedback and make necessary changes.';
      default:
        return 'Review each topic for accuracy and completeness. Accept topics individually or use "Accept All Topics" when ready.';
    }
  }

  Widget _buildTopicCard(Map<String, dynamic> item) {
    final topic = item['topic'];
    final chunks = item['chunks'] as List<dynamic>;
    final topicId = item['topicId'] as String;

    Color statusColor;
    String statusText =
        (topic['status'] as String?)?.replaceAll('_', ' ').toUpperCase() ?? 'GENERATED';
    switch (topic['status']) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending_review':
        statusColor = Colors.blue;
        break;
      case 'regenerating':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          topic['title'],
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          'Status: $statusText',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content chunks
                if (chunks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No content chunks found for this topic.'),
                  )
                else
                  ...chunks.map((chunk) => _buildContentChunk(chunk)),

                const Divider(height: 24),

                // Action buttons for KP
                if (topic['status'] == 'generated' || topic['status'] == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        // First row: Accept and Regenerate
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _acceptTopic(topicId),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                                  foregroundColor: Colors.green,
                                  side: BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _regenerateTopic(topicId),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Regenerate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                  foregroundColor: Colors.orange,
                                  side: BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Second row: Accept and Regenerate
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _acceptAndRegenerateTopic(topicId),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Accept & Regenerate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.withValues(alpha: 0.2),
                              foregroundColor: Colors.purple,
                              side: BorderSide(color: Colors.purple),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (topic['status'] == 'regenerating')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Regenerating content...',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'Topic $statusText',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentChunk(Map<String, dynamic> chunk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // FIX: Replaced deprecated `withOpacity` with `withAlpha`.
        color: Colors.black.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chunk['title'],
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.blue[300]),
          ),
          const SizedBox(height: 8),
          Text(
            chunk['content'],
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
              'Use the upload content feature to generate topics and learning materials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import '../../enums/user_role.dart'; // Using the central enum path

/// A page for administrators to review the content of a subject that a
/// Knowledge Partner (KP) has marked as ready for review.
/// The admin can approve or reject the subject as a whole.
class ReviewSubjectPage extends StatefulWidget {
  /// The ID of the subject to be reviewed, passed by the router.
  final String subjectId;

  const ReviewSubjectPage({super.key, required this.subjectId});

  @override
  State<ReviewSubjectPage> createState() => _ReviewSubjectPageState();
}

class _ReviewSubjectPageState extends State<ReviewSubjectPage> {
  String? _subjectName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjectName();
  }

  /// Fetches the subject's name to display in the AppBar while the full content loads.
  Future<void> _loadSubjectName() async {
    if (widget.subjectId.isEmpty) {
      if (mounted) setState(() => _subjectName = 'Invalid Subject');
      return;
    }
    try {
      final subjectDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .get();
      if (mounted && subjectDoc.exists) {
        setState(() {
          _subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
        });
      } else if (mounted) {
        setState(() {
          _subjectName = 'Subject Not Found';
        });
      }
    } catch (e) {
      debugPrint('Error loading subject name: $e');
      if (mounted) {
        setState(() {
          _subjectName = 'Error Loading Name';
        });
      }
    }
  }

  /// Navigates to a different admin page. Used by the desktop navigation bar.
  void _onNavigate(int index) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        context.go('/admin/subjects');
        break;
    }
  }

  /// Loads the full subject details, including all its topics and content chunks.
  Future<Map<String, dynamic>> _loadSubjectData() async {
    if (widget.subjectId.isEmpty) throw Exception('Subject ID not available');

    final subjectDoc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subjectId)
        .get();

    if (!subjectDoc.exists) throw Exception('Subject not found');

    final topicsSnapshot = await subjectDoc.reference.collection('topics').orderBy('order').get();

    List<Map<String, dynamic>> topicsWithContent = [];

    for (final topicDoc in topicsSnapshot.docs) {
      final chunksSnapshot = await FirebaseFirestore.instance
          .collection('content_chunks')
          .where('topic_id', isEqualTo: topicDoc.id)
          .where('subject_id', isEqualTo: widget.subjectId)
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
      'topicsWithContent': topicsWithContent,
      'topicsCount': topicsSnapshot.docs.length,
      'acceptedTopicsCount': topicsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending_review').length,
    };
  }

  /// Approves the subject, changing its status to 'approved' and also approving all its topics.
  Future<void> _approveSubject() async {
    if (widget.subjectId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId);
      final topicsSnapshot = await subjectRef.collection('topics').get();
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the subject's status and activate it
      batch.update(subjectRef, {
        'status': 'approved',
        'isActive': true,
        'admin_approved_at': FieldValue.serverTimestamp(),
      });

      // 2. Update all related topics to 'approved'
      for (final doc in topicsSnapshot.docs) {
        batch.update(doc.reference, {'status': 'approved'});
      }
      
      // 3. Commit all changes at once
      await batch.commit();

      if (!mounted) return;
      Toast.show(context, 'Subject approved and activated successfully!', type: ToastType.success);

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to approve subject: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Rejects the subject and resets its topics for the KP to review again.
  Future<void> _rejectSubject() async {
    if (widget.subjectId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId);
      final topicsSnapshot = await subjectRef.collection('topics').get();
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the subject's status to 'rejected'
      batch.update(subjectRef, {
        'status': 'rejected',
        'admin_rejected_at': FieldValue.serverTimestamp(),
      });
      
      // 2. Reset all topics back to 'generated' for the KP to re-evaluate
      for (final doc in topicsSnapshot.docs) {
        batch.update(doc.reference, {'status': 'generated'});
      }

      // 3. Commit all changes at once
      await batch.commit();

      if (!mounted) return;
      Toast.show(context, 'Subject rejected. Topics have been reset for KP review.', type: ToastType.info);

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to reject subject: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjectId.isEmpty) {
      return AuthenticatedAppLayout(
        role: UserRole.admin,
        appBarTitle: 'Review Subject',
        child: const Center(child: Text('No subject specified for review.')),
      );
    }

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Review: ${_subjectName ?? 'Loading...'}',
      // --- FIX: This page is not a main navigation destination. ---
      bottomNavIndex: null,
      onBottomNavTap: _onNavigate,
      showBottomBar: false,
      showCloseButton: true,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadSubjectData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                      const SizedBox(height: 16),
                      const Text('Failed to Load Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'There was an error fetching the subject data. Please try again later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Subject not found'));
          }

          final subjectData = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubjectOverviewCard(subjectData),
                const SizedBox(height: 24),
                _buildTopicsSummaryCard(subjectData),
                const SizedBox(height: 24),
                if (subjectData['subject']?['status'] == 'admin_review') ...[
                  _buildAdminActionButtons(),
                  const SizedBox(height: 24),
                ],
                _buildTopicsList(subjectData['topicsWithContent'] ?? []),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectOverviewCard(Map<String, dynamic> subjectData) {
    final subject = subjectData['subject'] as Map<String, dynamic>?;
    if (subject == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject['name'] ?? 'Unknown Subject', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _getSubjectStatusColor(subject['status']), borderRadius: BorderRadius.circular(20)),
              child: Text('Status: ${_getSubjectStatusText(subject['status'])}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            Text(_getSubjectStatusDescription(subject['status']), style: const TextStyle(color: Colors.white70)),
            if (subject['identified_subject_name'] != null) ...[
              const SizedBox(height: 12),
              Text('Identified Subject: ${subject['identified_subject_name']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsSummaryCard(Map<String, dynamic> subjectData) {
    final topicsCount = subjectData['topicsCount'] as int? ?? 0;
    final acceptedTopicsCount = subjectData['acceptedTopicsCount'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Content Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryItem(icon: Icons.topic, label: 'Total Topics', value: topicsCount.toString(), color: Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryItem(icon: Icons.check_circle, label: 'KP Accepted', value: acceptedTopicsCount.toString(), color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withAlpha(76))),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('As admin, you review the subject as a whole. Individual topic review was completed by the Knowledge Partner.', style: TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(76))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Review Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Review the subject content as a whole and make your decision:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _rejectSubject,
                    icon: const Icon(Icons.close, size: 18),
                    label: _isLoading ? const Text('Processing...') : const Text('Reject Subject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withAlpha(25), foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _approveSubject,
                    icon: const Icon(Icons.check, size: 18),
                    label: _isLoading ? const Text('Processing...') : const Text('Approve Subject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withAlpha(25), foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsList(List<Map<String, dynamic>> topicsWithContent) {
    if (topicsWithContent.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No topics found for this subject.', style: TextStyle(color: Colors.white70))),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Topic Content Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Review each topic\'s content below. This is for your reference only - individual topic approval was handled by the Knowledge Partner.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ...topicsWithContent.map((item) => _buildTopicCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> item) {
    final topic = item['topic'] as Map<String, dynamic>?;
    final chunks = item['chunks'] as List<dynamic>? ?? [];
    if (topic == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(topic['title'] ?? 'Untitled Topic', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text('Status: ${_getTopicStatusText(topic['status'])}', style: TextStyle(color: _getTopicStatusColor(topic['status']), fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chunks.isEmpty) ...[
                  const Text('No content chunks found for this topic.', style: TextStyle(color: Colors.white70)),
                ] else ...[
                  ...chunks.map((chunk) => _buildContentChunk(chunk as Map<String, dynamic>)),
                ],
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
      decoration: BoxDecoration(color: Colors.black.withAlpha(51), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chunk['title'] ?? 'Content Chunk', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[300])),
          const SizedBox(height: 8),
          Text(chunk['content'] ?? 'No content available', style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

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
      case 'admin_review': return 'READY FOR ADMIN REVIEW';
      case 'approved': return 'APPROVED';
      case 'rejected': return 'REJECTED';
      default: return 'WAITING FOR KP REVIEW';
    }
  }

  String _getSubjectStatusDescription(String? status) {
    switch (status) {
      case 'admin_review': return 'This subject has been reviewed by the Knowledge Partner and is ready for your final approval.';
      case 'approved': return 'This subject has been approved and is available for students.';
      case 'rejected': return 'This subject was rejected and has been sent back for revisions.';
      default: return 'Waiting for the Knowledge Partner to review and accept all topics before admin review.';
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
      case 'approved': return 'APPROVED';
      case 'rejected': return 'REJECTED';
      case 'regenerating': return 'REGENERATING';
      default: return 'GENERATED';
    }
  }
}
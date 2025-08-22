import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import '../../components/bottom_bar.dart';

class ReviewContentPage extends StatefulWidget {
  const ReviewContentPage({super.key});

  @override
  State<ReviewContentPage> createState() => _ReviewContentPageState();
}

class _ReviewContentPageState extends State<ReviewContentPage> {
  String? _subjectId;
  String? _subjectName;
  bool _isInitialized = false;
  int _currentIndex = 0; // Assuming accessed from admin dashboard
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeSubjectData();
    }
  }

  void _initializeSubjectData() async {
    // Get subjectId from GoRouter state
    final routeState = GoRouter.of(context).routerDelegate.currentConfiguration;
    debugPrint('=== ReviewContentPage Initialization ===');
    debugPrint('Current route: ${routeState.uri}');
    debugPrint('Full route state: $routeState');
    debugPrint('Query parameters: ${routeState.uri.queryParameters}');
    debugPrint('All query params keys: ${routeState.uri.queryParameters.keys}');

    final subjectId = routeState.uri.queryParameters['subjectId'];
    debugPrint('Extracted subjectId: $subjectId');
    debugPrint('subjectId is null: ${subjectId == null}');
    debugPrint('subjectId is empty: ${subjectId?.isEmpty}');

    if (subjectId != null && subjectId.isNotEmpty) {
      _subjectId = subjectId;
      // Load subject name
      try {
        final subjectDoc = await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .get();
        if (subjectDoc.exists) {
          _subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
          debugPrint('Loaded subject name: $_subjectName');
        } else {
          debugPrint('Subject document not found for ID: $subjectId');
        }
      } catch (e) {
        debugPrint('Error loading subject: $e');
      }
    } else {
      debugPrint('No subjectId found in route parameters');
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onNavigate(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
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


  // Load subject data and topics for admin review
  Future<Map<String, dynamic>> _loadSubjectData() async {
    if (_subjectId == null) throw Exception('Subject ID not available');

    final subjectDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
        .get();

    if (!subjectDoc.exists) throw Exception('Subject not found');

    final topicsSnapshot = await subjectDoc.reference
          .collection('topics')
        .orderBy('order')
        .get();

    List<Map<String, dynamic>> topicsWithContent = [];

    for (final topicDoc in topicsSnapshot.docs) {
      final chunksSnapshot = await FirebaseFirestore.instance
          .collection('content_chunks')
          .where('topic_id', isEqualTo: topicDoc.id)
          .where('subject_id', isEqualTo: _subjectId)
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

  // Approve subject (admin-level approval)
  Future<void> _approveSubject() async {
    if (_subjectId == null) return;

    setState(() => _isLoading = true);

    try {
      // Update subject status
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .update({
            'status': 'approved',
            'admin_approved_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Toast.show(context, 'Subject approved successfully!', type: ToastType.success);

      // Navigate back or refresh
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to approve subject: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Reject subject (admin-level rejection)
  Future<void> _rejectSubject() async {
    if (_subjectId == null) return;

    setState(() => _isLoading = true);

    try {
      // Update subject status
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .update({
            'status': 'rejected',
            'admin_rejected_at': FieldValue.serverTimestamp(),
          });

      // Reset all topics to 'generated' status so KP can review again
      final topicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .collection('topics')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in topicsSnapshot.docs) {
        batch.update(doc.reference, {'status': 'generated'});
      }
      await batch.commit();

      if (!mounted) return;
      Toast.show(context, 'Subject rejected. Topics reset for KP review.', type: ToastType.success);

      // Navigate back or refresh
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to reject subject: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    debugPrint('Building ReviewContentPage, _isInitialized: $_isInitialized, _subjectId: $_subjectId');

    if (!_isInitialized) {
      return AuthenticatedAppLayout(
        role: UserRole.admin,
        appBarTitle: 'Loading...',
        bottomNavIndex: _currentIndex,
        onBottomNavTap: _onNavigate,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_subjectId == null) {
      return AuthenticatedAppLayout(
        role: UserRole.admin,
        appBarTitle: 'Review Content',
        bottomNavIndex: _currentIndex,
        onBottomNavTap: _onNavigate,
        child: const Center(child: Text('No subject specified')),
      );
    }

        return AuthenticatedAppLayout(
          role: UserRole.admin,
          appBarTitle: 'Review: ${_subjectName ?? 'Unknown Subject'}',
          bottomNavIndex: _currentIndex,
          onBottomNavTap: _onNavigate,
          showBottomBar: true,
          showCloseButton: true,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadSubjectData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                // Subject Overview Card
                _buildSubjectOverviewCard(subjectData),

                const SizedBox(height: 24),

                // Topics Summary Card
                _buildTopicsSummaryCard(subjectData),

                const SizedBox(height: 24),

                // Action Buttons (only show if subject is ready for admin review)
                if (subjectData['subject']?['status'] == 'admin_review') ...[
                  _buildAdminActionButtons(),
                  const SizedBox(height: 24),
                ],

                // Topics List (for viewing only, not for individual approval)
                _buildTopicsList(subjectData['topicsWithContent'] ?? []),
              ],
            ),
          );
        },
      ),
    );
  }



  // Build subject overview card
  Widget _buildSubjectOverviewCard(Map<String, dynamic> subjectData) {
    final subject = subjectData['subject'] as Map<String, dynamic>?;

    if (subject == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject['name'] ?? 'Unknown Subject',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
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
            if (subject['identified_subject_name'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Identified Subject: ${subject['identified_subject_name']}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build topics summary card
  Widget _buildTopicsSummaryCard(Map<String, dynamic> subjectData) {
    final topicsCount = subjectData['topicsCount'] as int? ?? 0;
    final acceptedTopicsCount = subjectData['acceptedTopicsCount'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Content Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
            children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.topic,
                    label: 'Total Topics',
                    value: topicsCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.check_circle,
                    label: 'KP Accepted',
                    value: acceptedTopicsCount.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(76)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'As admin, you review the subject as a whole. Individual topic review was completed by the Knowledge Partner.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build summary item helper
  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build admin action buttons
  Widget _buildAdminActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Review Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Review the subject content as a whole and make your decision:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _rejectSubject,
                    icon: const Icon(Icons.close, size: 18),
                    label: _isLoading ? const Text('Processing...') : const Text('Reject Subject'),
                          style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(25),
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _approveSubject,
                    icon: const Icon(Icons.check, size: 18),
                    label: _isLoading ? const Text('Processing...') : const Text('Approve Subject'),
                          style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withAlpha(25),
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Build topics list (for viewing only)
  Widget _buildTopicsList(List<Map<String, dynamic>> topicsWithContent) {
    if (topicsWithContent.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
                    child: Text(
              'No topics found for this subject.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Topic Content Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Review each topic\'s content below. This is for your reference only - individual topic approval was handled by the Knowledge Partner.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ...topicsWithContent.map((item) => _buildTopicCard(item)),
          ],
        ),
      ),
    );
  }

  // Build individual topic card (view-only)
  Widget _buildTopicCard(Map<String, dynamic> item) {
    final topic = item['topic'] as Map<String, dynamic>?;
    final chunks = item['chunks'] as List<dynamic>? ?? [];

    if (topic == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          topic['title'] ?? 'Untitled Topic',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Status: ${_getTopicStatusText(topic['status'])}',
          style: TextStyle(
            color: _getTopicStatusColor(topic['status']),
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (chunks.isEmpty) ...[
                  const Text(
                    'No content chunks found for this topic.',
                    style: TextStyle(color: Colors.white70),
                  ),
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
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chunk['title'] ?? 'Content Chunk',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chunk['content'] ?? 'No content available',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
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
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'WAITING FOR KP REVIEW';
    }
  }

  String _getSubjectStatusDescription(String? status) {
    switch (status) {
      case 'admin_review':
        return 'This subject has been reviewed by the Knowledge Partner and is ready for your final approval.';
      case 'approved':
        return 'This subject has been approved and is available for students.';
      case 'rejected':
        return 'This subject was rejected and has been sent back for revisions.';
      default:
        return 'Waiting for the Knowledge Partner to review and accept all topics before admin review.';
    }
  }

  // Helper methods for topic status
  Color _getTopicStatusColor(String? status) {
    switch (status) {
      case 'pending_review':
        return Colors.green;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'regenerating':
        return Colors.orange;
      default:
        return Colors.grey; // generated or null
    }
  }

  String _getTopicStatusText(String? status) {
    switch (status) {
      case 'pending_review':
        return 'ACCEPTED BY KP';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'regenerating':
        return 'REGENERATING';
      default:
        return 'GENERATED';
    }
  }
}
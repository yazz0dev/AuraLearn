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



  // Bulk approve all topics for this subject
  Future<void> _bulkApproveAllTopics() async {
    if (_subjectId == null) return;

    try {
      final topicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .collection('topics')
          .where('status', isEqualTo: 'pending_review')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in topicsSnapshot.docs) {
        batch.update(doc.reference, {'status': 'approved'});
      }

      await batch.commit();
      if (!mounted) return;
      Toast.show(context, 'All topics approved successfully', type: ToastType.success);
      // Force a rebuild to update the UI
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to approve topics: $e', type: ToastType.error);
    }
  }

  // Bulk reject all topics for this subject
  Future<void> _bulkRejectAllTopics() async {
    if (_subjectId == null) return;

    try {
      final topicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .collection('topics')
          .where('status', isEqualTo: 'pending_review')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in topicsSnapshot.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }

      await batch.commit();
      if (!mounted) return;
      Toast.show(context, 'All topics rejected', type: ToastType.success);
      // Force a rebuild to update the UI
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to reject topics: $e', type: ToastType.error);
    }
  }

  // Fetch content chunks for a specific topic
  Future<List<QueryDocumentSnapshot>> _getContentChunksForTopic(String topicId) {
    return FirebaseFirestore.instance
        .collection('content_chunks')
        .where('topic_id', isEqualTo: topicId)
        .orderBy('order')
        .get()
        .then((snapshot) => snapshot.docs);
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

    return FutureBuilder<bool>(
      future: _checkAllTopicsAccepted(),
      builder: (context, snapshot) {
        final allTopicsAccepted = snapshot.data ?? false;

        return AuthenticatedAppLayout(
          role: UserRole.admin,
          appBarTitle: 'Review: ${_subjectName ?? 'Unknown Subject'}',
          bottomNavIndex: _currentIndex,
          onBottomNavTap: _onNavigate,
          showBottomBar: true,
          showCloseButton: true,
          child: Column(
            children: [
              // Bulk action buttons - only show if all topics are accepted by KP
              if (allTopicsAccepted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _bulkRejectAllTopics,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _bulkApproveAllTopics,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withValues(alpha: 0.2),
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                const Divider(height: 1),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'Waiting for KP to accept all topics before review',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // Query topics for specific subject only
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(_subjectId)
                      .collection('topics')
                      .where('status', isEqualTo: 'pending_review')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final pendingTopics = snapshot.data?.docs ?? [];

                    if (pendingTopics.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingTopics.length,
                      itemBuilder: (context, index) {
                        final topicDoc = pendingTopics[index];
                        return _buildTopicReviewCard(topicDoc);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkAllTopicsAccepted() async {
    if (_subjectId == null) return false;

    try {
      // Get all topics for this subject
      final allTopicsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subjectId)
          .collection('topics')
          .get();

      if (allTopicsSnapshot.docs.isEmpty) return false;

      // Check if all topics are either pending_review, approved, or rejected
      // (KP has accepted all topics that are ready for review)
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

  Widget _buildTopicReviewCard(DocumentSnapshot topicDoc) {
    final topicData = topicDoc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(topicData['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${topicData['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'PENDING'}', style: const TextStyle(color: Colors.white70)),
        children: [
          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _getContentChunksForTopic(topicDoc.id),
            builder: (context, chunkSnapshot) {
              if (!chunkSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final chunks = chunkSnapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...chunks.map((chunkDoc) => _buildContentChunk(chunkDoc.data() as Map<String, dynamic>)),

                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentChunk(Map<String, dynamic> chunk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chunk['title'], style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[300])),
          const SizedBox(height: 8),
          Text(chunk['content'], style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.white38),
          SizedBox(height: 16),
          Text('Review Queue is Empty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('No new content is pending approval.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
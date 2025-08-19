import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import '../../components/bottom_bar.dart';
import 'dart:async';

class ReviewContentPage extends StatefulWidget {
  const ReviewContentPage({super.key});

  @override
  State<ReviewContentPage> createState() => _ReviewContentPageState();
}

class _ReviewContentPageState extends State<ReviewContentPage> {
  int _currentIndex = 0; // Assuming accessed from admin dashboard

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

  // Action to approve or reject a topic
  Future<void> _updateTopicStatus(DocumentSnapshot topicDoc, String newStatus) async {
    try {
      await topicDoc.reference.update({'status': newStatus});
      if (!mounted) return;
      Toast.show(context, 'Topic status updated to $newStatus', type: ToastType.success);
      setState(() {}); // Re-trigger future builder
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to update status: $e', type: ToastType.error);
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
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Review Content Queue',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      child: StreamBuilder<QuerySnapshot>(
        // Use a collectionGroup query to get all topics pending review
        stream: FirebaseFirestore.instance
            .collectionGroup('topics')
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
    );
  }

  Widget _buildTopicReviewCard(DocumentSnapshot topicDoc) {
    final topicData = topicDoc.data() as Map<String, dynamic>;
    final subjectId = topicDoc.reference.parent.parent!.id;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('subjects').doc(subjectId).get(),
      builder: (context, subjectSnapshot) {
        if (!subjectSnapshot.hasData) return const SizedBox.shrink();
        final subjectName = subjectSnapshot.data?['name'] ?? 'Unknown Subject';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(topicData['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Subject: $subjectName', style: const TextStyle(color: Colors.white70)),
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
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _updateTopicStatus(topicDoc, 'rejected'),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _updateTopicStatus(topicDoc, 'approved'),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
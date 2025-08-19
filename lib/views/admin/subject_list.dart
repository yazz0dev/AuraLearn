import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../components/bottom_bar.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> with TickerProviderStateMixin {
  int _currentIndex = 2; // Subject list is at index 2
  late Stream<QuerySnapshot> _subjectsStream;
  late final AnimationController _pageController;

  @override
  void initState() {
    super.initState();
    _subjectsStream = FirebaseFirestore.instance
        .collection('subjects')
        .orderBy('createdAt', descending: true)
        .snapshots();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        // Already on subjects screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Subject Management',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/admin/create-subject'),
          tooltip: 'Create Subject',
        ),
      ],
      child: PageTransitions.buildSubtlePageTransition(
        controller: _pageController,
        child: StreamBuilder<QuerySnapshot>(
        stream: _subjectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading subjects',
                    style: TextStyle(color: Colors.red[300], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final subjects = snapshot.data?.docs ?? [];

          if (subjects.isEmpty) {
            return _buildEmptyState();
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final data = subject.data() as Map<String, dynamic>;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 200),
                  child: SlideAnimation(
                    verticalOffset: 15.0,
                    child: FadeInAnimation(
                      child: _buildSubjectCard(subject.id, data),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildSubjectCard(String subjectId, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Unnamed Subject';
    final String description = data['description'] ?? 'No description';
    final String code = data['code'] ?? '';
    final int credits = data['credits'] ?? 0;
    final bool isActive = data['isActive'] ?? true;
    final Timestamp? createdAt = data['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => _showSubjectDetails(subjectId, data),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (code.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Code: $code',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            context.pushNamed(
                              'admin-edit-subject',
                              pathParameters: {'subjectId': subjectId},
                              extra: data,
                            );
                          },
                          tooltip: 'Edit Subject',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      '$credits Credits',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(
                        'Created: ${_formatDate(createdAt.toDate())}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Subjects Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first subject to get started',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/admin/create-subject'),
            icon: const Icon(Icons.add),
            label: const Text('Create Subject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubjectDetails(String subjectId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          data['name'] ?? 'Subject Details',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Code', data['code'] ?? 'N/A'),
              _buildDetailRow('Credits', '${data['credits'] ?? 0}'),
              _buildDetailRow(
                'Status',
                data['isActive'] == true ? 'Active' : 'Inactive',
              ),
              _buildDetailRow(
                'Description',
                data['description'] ?? 'No description',
              ),
              if (data['createdAt'] != null)
                _buildDetailRow(
                  'Created',
                  _formatDate((data['createdAt'] as Timestamp).toDate()),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed(
                'admin-edit-subject',
                pathParameters: {'subjectId': subjectId},
                extra: data,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

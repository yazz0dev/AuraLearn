import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/models/subject_model.dart';
import 'package:auralearn/services/firestore_cache_service.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen>
    with TickerProviderStateMixin {
  late final Stream<List<Subject>> _subjectsStream;
  late final AnimationController _pageController;
  final FirestoreCacheService _firestoreCache = FirestoreCacheService();
  String? _expandedSubjectId;

  @override
  void initState() {
    super.initState();
    _subjectsStream = _firestoreCache.getSubjectsStream();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The AuthenticatedAppLayout is now handled by AdminLayout
    return PageTransitions.buildSubtlePageTransition(
      controller: _pageController,
      child: StreamBuilder<List<Subject>>(
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

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return _buildEmptyState();
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 200),
                  child: SlideAnimation(
                    verticalOffset: 15.0,
                    child: FadeInAnimation(
                      child: _buildSubjectCard(subject),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final bool isExpanded = _expandedSubjectId == subject.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => setState(() {
            _expandedSubjectId = isExpanded ? null : subject.id;
          }),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subject.isActive
                                ? Colors.green.withAlpha(30)
                                : Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    subject.isActive ? Colors.green : Colors.red),
                          ),
                          child: Text(
                            subject.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: subject.isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 20, color: Colors.white70),
                          onPressed: () {
                            context.pushNamed(
                              'admin-edit-subject',
                              pathParameters: {'subjectId': subject.id},
                              extra: subject, // Pass the typed Subject object
                            );
                          },
                          tooltip: 'Edit Subject',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subject.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  if (subject.createdAt != null)
                    _buildDetailRow(
                        'Created', _formatDate(subject.createdAt!.toDate())),
                  _buildDetailRow('Status', subject.status ?? 'Not Started'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToReview(subject.id),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Review Content'),
                    ),
                  ),
                ]
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    // Consistent skeleton using a ListView of cards
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.card(height: 100),
        ),
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

  void _navigateToReview(String subjectId) {
    debugPrint('Navigating to review with subjectId: $subjectId');
    context.goNamed('admin-review-subject',
        pathParameters: {'subjectId': subjectId});
  }
}
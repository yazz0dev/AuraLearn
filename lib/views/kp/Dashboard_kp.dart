import 'package:auralearn/components/authenticated_app_layout.dart';
// ignore: unused_import
import 'package:auralearn/components/bottom_bar.dart';
import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/services/firestore_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../enums/user_role.dart';

class DashboardKP extends StatefulWidget {
  const DashboardKP({super.key});

  @override
  State<DashboardKP> createState() => _DashboardKPState();
}

class _DashboardKPState extends State<DashboardKP>
   with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final FirestoreCacheService _firestoreCache = FirestoreCacheService();
  String? _currentUserId;
  List<Map<String, dynamic>>? _cachedSubjects;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects({bool forceRefresh = false}) async {
    if (_currentUserId == null) return;

    try {
      final subjects = await _firestoreCache.getKPSubjects(_currentUserId!, forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _cachedSubjects = subjects;
        });
      }
    } catch (e) {
      debugPrint('Error loading KP subjects: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.kp,
      appBarTitle: 'My Subjects',
      showLogoutButton: true, 
      bottomNavIndex: 0,
      child: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSubjects(forceRefresh: true),
              child: _cachedSubjects == null
                  ? _buildLoadingSkeleton()
                  : _cachedSubjects!.isEmpty
                      ? _buildEmptyState()
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _cachedSubjects!.length,
                            itemBuilder: (context, index) {
                              final subject = _cachedSubjects![index];

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 200),
                                child: SlideAnimation(
                                  verticalOffset: 15.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: _buildSubjectCard(
                                        subjectId: subject['_id'] ?? '',
                                        subjectData: subject,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
    );
  }

  Widget _buildSubjectCard({
    required String subjectId,
    required Map<String, dynamic> subjectData,
  }) {
    final String name = subjectData['name'] ?? 'Unnamed Subject';
    final String description = subjectData['description'] ?? 'No description';
    final String duration = subjectData['duration'] ?? 'Duration not set';

    // Determine subject status and available actions
    final bool hasSyllabus = subjectData['hasSyllabus'] ?? false;
    final bool hasMaterial = subjectData['hasMaterial'] ?? false;
    final bool hasContent = subjectData['hasContent'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
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
                    const SizedBox(height: 4),
                    Text(
                      'Duration: $duration',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getSubjectColor(name),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                'Upload Syllabus',
                Icons.upload_file,
                hasSyllabus ? Colors.green : Colors.blue,
                () => _navigateToUpload(subjectId, 'syllabus'),
                isCompleted: hasSyllabus,
              ),
              _buildActionButton(
                'Upload Material',
                Icons.library_books,
                hasMaterial ? Colors.green : Colors.orange,
                () => _navigateToUpload(subjectId, 'material'),
                isCompleted: hasMaterial,
              ),
              _buildActionButton(
                'Review Content',
                Icons.rate_review,
                hasContent ? Colors.green : Colors.purple,
                () => _navigateToReview(subjectId),
                isCompleted: hasContent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isCompleted = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(isCompleted ? Icons.check_circle : icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCompleted
            ? Colors.green.withAlpha(51)
            : color.withAlpha(51),
        foregroundColor: isCompleted ? Colors.green : color,
        side: BorderSide(color: isCompleted ? Colors.green : color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
      ),
    );
  }

  Color _getSubjectColor(String name) {
    final colors = [
      const Color(0xFFD6C6C2),
      const Color(0xFFF2CACA),
      const Color(0xFFC7A8A3),
      const Color(0xFFB8A8D6),
      const Color(0xFFA8D6C6),
    ];
    return colors[name.hashCode % colors.length];
  }

  void _navigateToUpload(String subjectId, String type) {
    context.push('/kp/upload-content/$subjectId?type=$type');
  }

  void _navigateToReview(String subjectId) {
    context.push('/kp/review-content/$subjectId');
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: SkeletonLoader(
            isLoading: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonShapes.text(width: double.infinity, height: 18),
                            const SizedBox(height: 8),
                            SkeletonShapes.text(width: 100, height: 14),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SkeletonShapes.text(width: double.infinity, height: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FIX: Re-added the _buildEmptyState method that was missing. ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.white.withAlpha(77),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Subjects Assigned',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact your administrator to get assigned',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



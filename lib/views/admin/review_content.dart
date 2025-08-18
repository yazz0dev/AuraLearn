import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auralearn/components/toast.dart';
import '../../components/bottom_bar.dart';

class ReviewContentPage extends StatefulWidget {
  final String? subjectId;

  const ReviewContentPage({super.key, this.subjectId});

  @override
  State<ReviewContentPage> createState() => _ReviewContentPageState();
}

class _ReviewContentPageState extends State<ReviewContentPage> {
  int _currentIndex = 0; // This is accessed from dashboard, so dashboard index
  late Stream<QuerySnapshot> _uploadsStream;
  final Map<String, bool> _expandedUploads = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    if (widget.subjectId != null) {
      // Show uploads for specific subject
      _uploadsStream = FirebaseFirestore.instance
          .collection('uploads')
          .where('subjectId', isEqualTo: widget.subjectId)
          .orderBy('uploadedAt', descending: true)
          .snapshots();
    } else {
      // Show all uploads for review
      _uploadsStream = FirebaseFirestore.instance
          .collection('uploads')
          .where('status', isEqualTo: 'pending_review')
          .orderBy('uploadedAt', descending: true)
          .snapshots();
    }
  }

  void _toggleUpload(String uploadId) {
    setState(() {
      _expandedUploads[uploadId] = !(_expandedUploads[uploadId] ?? false);
    });
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
        context.go('/admin/subjects');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[900] : Colors.white;
    final subtle = isDark ? Colors.grey[400] : Colors.grey[600];

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Review Content',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      child: StreamBuilder<QuerySnapshot>(
        stream: _uploadsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading uploads',
                    style: TextStyle(color: Colors.red[300], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final uploads = snapshot.data?.docs ?? [];

          if (uploads.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                
                // Upload cards
                for (var upload in uploads) ...[
                  _buildUploadCard(upload, cardBg, subtle),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 28),

                // Process PDFs button
                Center(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processAllPDFs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Process All PDFs",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadCard(QueryDocumentSnapshot upload, Color? cardBg, Color? subtle) {
    final data = upload.data() as Map<String, dynamic>;
    final fileName = data['fileName'] ?? 'Unknown file';
    final fileType = data['fileType'] ?? 'unknown';
    final status = data['status'] ?? 'pending';
    final uploadedAt = data['uploadedAt'] as Timestamp?;
    final subjectId = data['subjectId'] ?? '';
    final isExpanded = _expandedUploads[upload.id] ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('subjects').doc(subjectId).get(),
      builder: (context, subjectSnapshot) {
        final subjectName = subjectSnapshot.data?.get('name') ?? 'Unknown Subject';
        
        return GestureDetector(
          onTap: () => _toggleUpload(upload.id),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade500.withAlpha((0.3 * 255).round())),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileTypeIcon(fileType),
                      color: _getFileTypeColor(fileType),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$subjectName • ${fileType.toUpperCase()}',
                            style: TextStyle(color: subtle, fontSize: 13),
                          ),
                          if (uploadedAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Uploaded: ${_formatDate(uploadedAt.toDate())}',
                              style: TextStyle(color: subtle, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[850] 
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Details',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Subject', subjectName),
                      _buildDetailRow('File Type', fileType.toUpperCase()),
                      _buildDetailRow('Status', status.replaceAll('_', ' ').toUpperCase()),
                      if (uploadedAt != null)
                        _buildDetailRow('Uploaded', _formatDate(uploadedAt.toDate())),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _approveUpload(upload.id),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _rejectUpload(upload.id),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _viewFile(data['fileUrl']),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.white.withAlpha(77),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Content to Review',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Uploaded content will appear here for review',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'syllabus':
        return Icons.description;
      case 'material':
        return Icons.library_books;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'syllabus':
        return Colors.blue;
      case 'material':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveUpload(String uploadId) async {
    try {
      await FirebaseFirestore.instance
          .collection('uploads')
          .doc(uploadId)
          .update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Toast.show(context, 'Upload approved successfully', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to approve upload: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _rejectUpload(String uploadId) async {
    try {
      await FirebaseFirestore.instance
          .collection('uploads')
          .doc(uploadId)
          .update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Toast.show(context, 'Upload rejected', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to reject upload: $e', type: ToastType.error);
      }
    }
  }

  void _viewFile(String? fileUrl) {
    if (fileUrl == null) {
      Toast.show(context, 'File URL not available', type: ToastType.error);
      return;
    }
    
    // In a real app, this would open the file viewer
    Toast.show(context, 'Opening file: $fileUrl', type: ToastType.info);
  }

  Future<void> _processAllPDFs() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate PDF processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Toast.show(context, 'All PDFs processed successfully!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to process PDFs: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
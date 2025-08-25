import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:auralearn/models/subject_model.dart';
import 'package:auralearn/models/user_model.dart';
import 'package:auralearn/services/firestore_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../enums/user_role.dart';

class EditSubjectPage extends StatefulWidget {
  final Subject subject;

  const EditSubjectPage({
    super.key,
    required this.subject,
  });

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late bool _isActive;
  bool _isLoading = false;
  bool _isDeleting = false;
  List<AppUser> _kpUsers = [];
  String? _selectedKpId;
  int _currentIndex = 2; // Edit subject page index
  final FirestoreCacheService _firestoreCache = FirestoreCacheService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadKpUsers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.subject.name);
    _descriptionController = TextEditingController(text: widget.subject.description);
    _isActive = widget.subject.isActive;
    _selectedKpId = widget.subject.assignedKpId;
  }

  Future<void> _loadKpUsers() async {
    try {
      final users = await _firestoreCache.getKPUsers();
      if (mounted) {
        setState(() => _kpUsers = users);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to load KP users', type: ToastType.error);
      }
    }
  }

  String? _getValidSelectedKpId() {
    if (_selectedKpId == null) return null;

    // Check if the selected KP ID exists in the loaded KP users
    final kpExists = _kpUsers.any((kp) => kp.id == _selectedKpId);
    return kpExists ? _selectedKpId : null;
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

  Future<void> _updateSubject() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subjectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
        'assignedKpId': _selectedKpId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.id)
          .update(subjectData);

      if (mounted) {
        Toast.show(
          context,
          'Subject updated successfully!',
          type: ToastType.success,
        );
        context.go('/admin/subjects');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to update subject: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSubject() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Delete Subject', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${widget.subject.name}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.id)
          .delete();

      if (mounted) {
        Toast.show(
          context,
          'Subject deleted successfully!',
          type: ToastType.success,
        );
        context.go('/admin/subjects');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to delete subject: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[900] : Colors.grey[100];

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Edit: ${widget.subject.name}',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      showCloseButton: true,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: _isDeleting ? null : _deleteSubject,
          tooltip: 'Delete Subject',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Subject Name
              const Text(
                'Subject Name',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter subject name'
                    : null,
                decoration: InputDecoration(
                  hintText: 'Enter subject name',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Subject Description
              const Text(
                'Subject Description',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter subject description',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Assign Knowledge Provider
              const Text(
                'Assign Knowledge Provider',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _getValidSelectedKpId(),
                  hint: const Text(
                    'Select a Knowledge Provider',
                    style: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: cardBg,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'No KP Assigned',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ..._kpUsers.map(
                      (kp) => DropdownMenuItem<String>(
                        value: kp.id,
                        child: Text(
                          '${kp.name} (${kp.email})',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedKpId = v),
                ),
              ),

              const SizedBox(height: 18),

              // Active Status
              Row(
                children: [
                  const Text(
                    'Active Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeThumbColor: Colors.green,
                  ),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _updateSubject,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Subject',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
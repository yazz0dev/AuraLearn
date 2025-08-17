import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/bottom_bar.dart';

class EditSubjectPage extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;

  const EditSubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectData,
  });

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  int _currentIndex = 2; // Accessed from subjects screen
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _creditsController;

  late bool _isActive;
  bool _isLoading = false;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _kpUsers = [];
  String? _selectedKpId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadKpUsers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.subjectData['name'] ?? '');
    _codeController = TextEditingController(text: widget.subjectData['code'] ?? '');
    _descriptionController = TextEditingController(text: widget.subjectData['description'] ?? '');
    _creditsController = TextEditingController(text: '${widget.subjectData['credits'] ?? 0}');
    _isActive = widget.subjectData['isActive'] ?? true;
    _selectedKpId = widget.subjectData['assignedKpId'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _loadKpUsers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'KP')
          .get();

      setState(() {
        _kpUsers = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to load KP users', type: ToastType.error);
      }
    }
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
        'code': _codeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'credits': int.tryParse(_creditsController.text.trim()) ?? 0,
        'isActive': _isActive,
        'assignedKpId': _selectedKpId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
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
            'Are you sure you want to delete "${widget.subjectData['name']}"? This action cannot be undone.',
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
          .doc(widget.subjectId)
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
      appBarTitle: 'Edit Subject',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
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

              // Subject Code
              const Text(
                'Subject Code',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter subject code'
                    : null,
                decoration: InputDecoration(
                  hintText: 'e.g., CS101, MATH201',
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

              // Credits
              const Text(
                'Credits',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _creditsController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter credits';
                  }
                  final credits = int.tryParse(v.trim());
                  if (credits == null || credits < 1) {
                    return 'Please enter valid credits (1 or more)';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter credit hours',
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
                  initialValue: _selectedKpId,
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
                        value: kp['id'] as String,
                        child: Text(
                          '${kp['name']} (${kp['email']})',
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
                    child: OutlinedButton(
                      onPressed: () => context.go('/admin/subjects'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
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
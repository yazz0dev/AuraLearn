import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/bottom_bar.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({super.key});

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectPageState();
}

class _CreateSubjectPageState extends State<CreateSubjectPage> {
  int _currentIndex = 2; // Accessed from subjects screen
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  final bool _isActive = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _kpUsers = [];
  String? _selectedKpId;

  @override
  void initState() {
    super.initState();
    _loadKpUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
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

  Future<void> _createSubject() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subjectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': _durationController.text.trim(),
        'isActive': _isActive,
        'assignedKpId': _selectedKpId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('subjects').add(subjectData);

      if (mounted) {
        Toast.show(
          context,
          'Subject created successfully!',
          type: ToastType.success,
        );
        context.go('/admin/subjects');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to create subject: ${e.toString()}',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[900] : Colors.grey[100];

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'Create Subject',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      showCloseButton: true,
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

              // Duration
              const Text(
                'Duration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter duration'
                    : null,
                decoration: InputDecoration(
                  hintText: 'e.g., 3 months, 1 semester, 40 hours',
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
                  items: _kpUsers
                      .map(
                        (kp) => DropdownMenuItem<String>(
                          value: kp['id'] as String,
                          child: Text(
                            '${kp['name']} (${kp['email']})',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedKpId = v),
                ),
              ),

              const SizedBox(height: 48),

              // Create Subject button
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _createSubject,
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
                            'Create Subject',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

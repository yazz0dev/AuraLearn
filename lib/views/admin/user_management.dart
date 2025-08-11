import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../components/bottom_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _currentIndex = 1;
  String _search = '';
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'KP', 'Student', 'Admin'];

  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardAdmin(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // --- NEW: Method to show the Add User dialog ---
  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String newRole = 'KP'; // Default role

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Add New User', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => (v!.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: newRole,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        items: ['KP', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                        onChanged: (val) {
                          if (val != null) newRole = val;
                        },
                        decoration: const InputDecoration(labelText: 'Role'),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isLoading = true);
                      await _handleCreateUser(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        role: newRole,
                      );
                      setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- NEW: Logic to handle user creation ---
  Future<void> _handleCreateUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // SECURITY WARNING: Creating users client-side like this is not recommended for production.
    // This requires a second Firebase app instance to avoid signing the admin out.
    // The best practice is to use a Cloud Function with the Firebase Admin SDK.
    try {
      // Create a temporary app to create the user without signing out the admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'temp_user_creation',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create user in Firebase Auth
      UserCredential userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete the temporary app
      await tempApp.delete();

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog on success
        Toast.show(context, 'User created successfully!', type: ToastType.success);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Toast.show(context, e.message ?? 'An unknown error occurred.', type: ToastType.error);
      }
    } catch (e) {
       if (mounted) {
        Toast.show(context, 'An unexpected error occurred.', type: ToastType.error);
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'User Management',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF2C2C2C)),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    underline: Container(),
                    items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha(51),
                    foregroundColor: Colors.blue.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // --- FIX: Use StreamBuilder to get real-time user data ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!.docs;
                final filteredUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toLowerCase() ?? '';
                  final email = data['email']?.toLowerCase() ?? '';
                  final role = data['role'] ?? '';

                  final matchesRole = _selectedRole == 'All' || role == _selectedRole;
                  final matchesSearch = name.contains(_search.toLowerCase()) || email.contains(_search.toLowerCase());
                  
                  return matchesRole && matchesSearch;
                }).toList();

                return AnimationLimiter(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, idx) {
                      final userDoc = filteredUsers[idx];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      
                      return AnimationConfiguration.staggeredList(
                        position: idx,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(userData['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                                        Text(userData['email'] ?? 'No Email', style: const TextStyle(color: Colors.white54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C2C2C),
                                      borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Text(userData['role'] ?? 'No Role', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/components/toast.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../components/bottom_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 1;
  String _search = '';
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'KP', 'Student', 'Admin'];

  late final AnimationController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _pageController.forward();
  }

  @override
  dispose() {
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
        // Navigate back to admin dashboard
        context.go('/admin/dashboard');
        break;
      case 1:
        // Users - already here, no navigation needed
        break;
      case 2:
        // Navigate to subjects screen
        context.go('/admin/subjects');
        break;
    }
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isKP = true; // Default to KP role

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isLoading = false;

        // Get screen size for responsive design
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        final dialogPadding = isSmallScreen ? 20.0 : 32.0;
        final titleFontSize = isSmallScreen ? 20.0 : 24.0;
        final spacing = isSmallScreen ? 16.0 : 32.0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? screenSize.width * 0.95 : 500,
                  maxHeight: screenSize.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(dialogPadding),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mobile-friendly header
                          isSmallScreen
                              ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.person_add,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => context.pop(),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white70,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Add New User',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                                    Expanded(
                              child: Text(
                                'Add New User',
                                style: TextStyle(
                                  color: Colors.white,
                                          fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              style: IconButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                          SizedBox(height: spacing),

                        // Full Name Field
                          Text(
                          'Full Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              borderSide: BorderSide.none,
                            ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 14 : 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Name cannot be empty' : null,
                        ),
                          SizedBox(height: isSmallScreen ? 16 : 20),

                        // Email Field
                          Text(
                          'Email Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              borderSide: BorderSide.none,
                            ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 14 : 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                          SizedBox(height: isSmallScreen ? 16 : 20),

                        // Password Field
                          Text(
                          'Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                        TextFormField(
                          controller: passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter password (min 6 characters)',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              borderSide: BorderSide.none,
                            ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 14 : 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                          ),
                          validator: (v) => (v!.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // Role Selection
                          Text(
                          'Role',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setDialogState(() => isKP = true),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isKP
                                          ? Colors.blue
                                          : Colors.transparent,
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                                    ),
                                    child: Text(
                                      'Knowledge Provider',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isKP
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: isKP
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setDialogState(() => isKP = false),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isKP
                                          ? Colors.blue
                                          : Colors.transparent,
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                                    ),
                                    child: Text(
                                      'Admin',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !isKP
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: !isKP
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                          SizedBox(height: spacing),

                          // Action Buttons - Mobile responsive
                          isSmallScreen
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                if (formKey.currentState!.validate()) {
                                                  setDialogState(
                                                    () => isLoading = true,
                                                  );
                                                  await _handleCreateUser(
                                                    name: nameController.text.trim(),
                                                    email: emailController.text.trim(),
                                                    password: passwordController.text
                                                        .trim(),
                                                    role: isKP ? 'KP' : 'Admin',
                                                  );
                                                  setDialogState(
                                                    () => isLoading = false,
                                                  );
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Create User',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.pop(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                          side: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                        child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setDialogState(
                                            () => isLoading = true,
                                          );
                                          await _handleCreateUser(
                                            name: nameController.text.trim(),
                                            email: emailController.text.trim(),
                                            password: passwordController.text
                                                .trim(),
                                            role: isKP ? 'KP' : 'Admin',
                                          );
                                          setDialogState(
                                            () => isLoading = false,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create User',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
          },
        );
      },
    );
  }

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
      UserCredential userCredential = await tempAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Add user to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Delete the temporary app
      await tempApp.delete();

      if (mounted) {
        context.pop(); // Close dialog on success
        Toast.show(
          context,
          'User created successfully!',
          type: ToastType.success,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Toast.show(
          context,
          e.message ?? 'An unknown error occurred.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'An unexpected error occurred.',
          type: ToastType.error,
        );
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
      child: PageTransitions.buildSubtlePageTransition(
        controller: _pageController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    hintText: 'Search by name or email...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (val) => setState(() => _search = val),
                ),
              ),
              const SizedBox(height: 16),
              // Filter and Add Button Row
              Row(
                children: [
                  // Role Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: const Color(0xFF1E1E1E),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        style: const TextStyle(color: Colors.white),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                        underline: Container(),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  _getRoleIcon(role),
                                  color: _getRoleColor(role),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(role),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedRole = val!),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add User Button
                  ElevatedButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Users List Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 400,
                      child: _buildLoadingSkeleton(),
                    );
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 400,
                      child: _buildErrorState(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SizedBox(
                      height: 400,
                      child: _buildEmptyState(),
                    );
                  }

                  final users = snapshot.data!.docs;
                  final filteredUsers = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toLowerCase() ?? '';
                    final email = data['email']?.toLowerCase() ?? '';
                    final role = data['role'] ?? '';

                    final matchesRole = _selectedRole == 'All' || role == _selectedRole;
                    final matchesSearch = name.contains(_search.toLowerCase()) ||
                                         email.contains(_search.toLowerCase());

                    return matchesRole && matchesSearch;
                  }).toList();

                  return AnimationLimiter(
                    child: Column(
                      children: filteredUsers.map((userDoc) {
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final idx = filteredUsers.indexOf(userDoc);

                        return AnimationConfiguration.staggeredList(
                          position: idx,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildUserCard(userData),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final role = userData['role'] ?? 'Unknown';
    final roleColor = _getRoleColor(role);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetails(userData),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: roleColor.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getRoleIcon(role),
                    color: roleColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userData['email'] ?? 'No Email',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: roleColor.withAlpha(76),
                    ),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please try again later',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No users found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start by adding your first user',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings_rounded;
      case 'KP':
        return Icons.school_rounded;
      case 'Student':
        return Icons.person_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red.shade400;
      case 'KP':
        return Colors.green.shade400;
      case 'Student':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getRoleColor(userData['role'] ?? 'Unknown').withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getRoleColor(userData['role'] ?? 'Unknown').withAlpha(76),
                        ),
                      ),
                      child: Icon(
                        _getRoleIcon(userData['role'] ?? 'Unknown'),
                        color: _getRoleColor(userData['role'] ?? 'Unknown'),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'User Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // User Info
                _buildDetailRow('Name', userData['name'] ?? 'No Name'),
                _buildDetailRow('Email', userData['email'] ?? 'No Email'),
                _buildDetailRow('Role', userData['role'] ?? 'Unknown'),
                if (userData['createdAt'] != null) ...[
                  _buildDetailRow('Created', _formatDate((userData['createdAt'] as Timestamp).toDate())),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: SkeletonLoader(
            isLoading: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SkeletonShapes.avatar(radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonShapes.text(width: 120, height: 16),
                        const SizedBox(height: 6),
                        SkeletonShapes.text(width: 180, height: 14),
                      ],
                    ),
                  ),
                  SkeletonShapes.text(width: 60, height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

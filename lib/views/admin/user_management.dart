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
import 'dart:async';
import '../../enums/user_role.dart';

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
  String? _expandedUserId; // Track which user is expanded
  Timer? _searchDebounceTimer; // Timer for search debouncing
  String _debouncedSearch = ''; // Debounced search value for filtering

  late final AnimationController _pageController;
  late final Map<String, AnimationController> _expansionControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _expansionControllers = {};
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchDebounceTimer?.cancel();
    for (final controller in _expansionControllers.values) {
      controller.dispose();
    }
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

  AnimationController _getExpansionController(String userId) {
    if (!_expansionControllers.containsKey(userId)) {
      _expansionControllers[userId] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
    return _expansionControllers[userId]!;
  }

  void _toggleUserExpansion(String userId) {
    if (_expandedUserId == userId) {
      // Collapse current user - don't setState here, let animation finish first
      _getExpansionController(userId).reverse();
      // Set state after animation completes to prevent unwanted rebuilds
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _expandedUserId == userId) {
          setState(() => _expandedUserId = null);
        }
      });
    } else {
      // Collapse previously expanded user if any
      if (_expandedUserId != null) {
        _getExpansionController(_expandedUserId!).reverse();
      }

      // Expand new user immediately
      setState(() => _expandedUserId = userId);
      _getExpansionController(userId).forward();
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
                    color: Colors.white.withAlpha(13),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(77),
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
                                            color: Colors.blue.withAlpha(26),
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
                                            backgroundColor: Colors.white.withAlpha(26),
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
                                color: Colors.blue.withAlpha(26),
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
                                        backgroundColor: Colors.white.withAlpha(26),
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
                                                  if (!mounted) return;
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
                                            color: Colors.white.withAlpha(51),
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
                                    color: Colors.white.withAlpha(51),
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
                                          if (!mounted) return;
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

      if (!mounted) return;
      context.pop(); // Close dialog on success
      Toast.show(
        context,
        'User created successfully!',
        type: ToastType.success,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Toast.show(
        context,
        e.message ?? 'An unknown error occurred.',
        type: ToastType.error,
      );
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context,
        'An unexpected error occurred.',
        type: ToastType.error,
      );
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
              // Enhanced Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _search.isNotEmpty ? Colors.blue.shade400.withAlpha(100) : Colors.white24,
                    width: _search.isNotEmpty ? 1.5 : 1,
                  ),
                  boxShadow: _search.isNotEmpty
                      ? [
                          BoxShadow(
                            color: Colors.blue.shade400.withAlpha(30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _search.isNotEmpty ? Icons.search : Icons.search_rounded,
                        key: ValueKey(_search.isNotEmpty),
                        color: _search.isNotEmpty ? Colors.blue.shade400 : Colors.white70,
                        size: _search.isNotEmpty ? 22 : 20,
                      ),
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _search = '';
                                _debouncedSearch = '';
                              });
                              _searchDebounceTimer?.cancel();
                            },
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          )
                        : null,
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    // Update immediate search value for UI feedback
                    setState(() => _search = val);

                    // Debounce filtering to prevent excessive rebuilds
                    _searchDebounceTimer?.cancel();
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() => _debouncedSearch = val);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Enhanced Filter and Actions Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    // Role Filter with enhanced design
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedRole != 'All' ? Colors.blue.shade400.withAlpha(100) : Colors.white.withAlpha(30),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: const Color(0xFF252525),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            icon: AnimatedRotation(
                              turns: 0.0, // You could make this rotate on open if needed
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _selectedRole != 'All' ? Colors.blue.shade400 : Colors.white70,
                                size: 18,
                              ),
                            ),
                            underline: Container(),
                            items: _roles.map((role) {
                              final isSelected = role == _selectedRole;
                              return DropdownMenuItem(
                                value: role,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(role).withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getRoleIcon(role),
                                        color: _getRoleColor(role),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.blue.shade400,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedRole = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Enhanced Add User Button
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.blue.shade600.withAlpha(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  // Use debounced search for filtering to prevent excessive rebuilds
                  final searchTerm = _debouncedSearch.toLowerCase().trim();
                  final filteredUsers = searchTerm.isEmpty && _selectedRole == 'All'
                      ? users // No filtering needed
                      : users.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final role = data['role'] ?? '';

                          // Early return if role doesn't match
                          if (_selectedRole != 'All' && role != _selectedRole) {
                            return false;
                          }

                          // If no search term, role match is sufficient
                          if (searchTerm.isEmpty) return true;

                          final name = data['name']?.toLowerCase() ?? '';
                          final email = data['email']?.toLowerCase() ?? '';

                          return name.contains(searchTerm) || email.contains(searchTerm);
                        }).toList();

                  return AnimationLimiter(
                    key: ValueKey('user_list_${filteredUsers.length}_${_search}_$_selectedRole'),
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
                                child: _buildUserCard(userData, userDoc.id),
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

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    final role = userData['role'] ?? 'Unknown';
    final roleColor = _getRoleColor(role);
    final isExpanded = _expandedUserId == userId;
    final expansionController = _getExpansionController(userId);

    return AnimatedBuilder(
      animation: expansionController,
      builder: (context, child) {
        // Only the animated parts are rebuilt here
        return child!;
      },
      child: Container( // Move static content to child to prevent unnecessary rebuilds
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
            onTap: () => _toggleUserExpansion(userId),
            child: Column(
              children: [
                // Main user info row
                Padding(
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
                      // Role Badge and Expand Icon
                      Row(
                        children: [
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
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.expand_more,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expandable details section
                SizeTransition(
                  sizeFactor: expansionController,
                  axis: Axis.vertical,
                  child: FadeTransition(
                    opacity: expansionController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 16),
                            _buildDetailRow('Full Name:', userData['name'] ?? 'No Name'),
                            _buildDetailRow('Email Address:', userData['email'] ?? 'No Email'),
                            _buildDetailRow('Role:', userData['role'] ?? 'Unknown'),
                            if (userData['createdAt'] != null) ...[
                              _buildDetailRow('Created Date:', _formatDate((userData['createdAt'] as Timestamp).toDate())),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (userData['role'] != 'Student') ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      _showEditUserDialog(userData, userId);
                                    },
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue.shade400,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(userId, userData['name']);
                                    },
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade400,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _showEditUserDialog(Map<String, dynamic> userData, String userId) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: userData['name']);
    String selectedRole = userData['role'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isLoading = false;

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
                    color: Colors.white.withAlpha(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(77),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.close, color: Colors.white70),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing),
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
                            validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                              items: ['Admin', 'KP', 'Student']
                                  .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedRole = val;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: spacing),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withAlpha(51)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!.validate()) {
                                            setDialogState(() => isLoading = true);
                                            await _handleUpdateUser(
                                              userId: userId,
                                              name: nameController.text.trim(),
                                              role: selectedRole,
                                            );
                                            if (!context.mounted) return;
                                            setDialogState(() => isLoading = false);
                                            Navigator.of(context).pop();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      : const Text('Update User'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleUpdateUser({
    required String userId,
    required String name,
    required String role,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': name,
        'role': role,
      });
      if (!mounted) return;
      Toast.show(context, 'User updated successfully!', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to update user.', type: ToastType.error);
    }
  }

    Future<void> _showDeleteConfirmationDialog(String userId, String userName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
              const SizedBox(width: 10),
              Text('Delete User', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the user "$userName"?', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text('This action cannot be undone and will only remove user from the database, not from authentication. Please delete from the Firebase console manually.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              child: Text('Delete'),
              onPressed: () {
                _handleDeleteUser(userId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteUser(String userId) async {
    try {
      // Deleting user from Firestore.
      // NOTE: This does not delete the user from Firebase Auth.
      // A cloud function is required for that.
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (!mounted) return;
      Toast.show(context, 'User deleted successfully!', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to delete user.', type: ToastType.error);
    }
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

  // User details are now shown through expandable cards
  // The old dialog-based _showUserDetails method has been replaced with
  // inline expandable views in _buildUserCard for better UX

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
                color: Colors.white.withAlpha(153),
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
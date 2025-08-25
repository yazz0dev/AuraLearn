import 'package:auralearn/components/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../components/app_layout.dart';
import '../utils/page_transitions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = PageTransitions.createStandardController(vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Authentication failed. Please try again.");
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw Exception(
          "User data not found in database. Please contact support.",
        );
      }

      if (!mounted) return;
      
      // Get user role and navigate to appropriate dashboard
      final userData = docSnapshot.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;
      
      Toast.show(context, "Login successful!", type: ToastType.success);

      // Navigate to role-specific dashboard
      if (mounted) {
        debugPrint('Login successful, user role: $userRole');
        switch (userRole) {
          case 'SuperAdmin':
          case 'Admin':
            debugPrint('Navigating to admin dashboard');
            context.go('/admin/dashboard');
            break;
          case 'KP':
            debugPrint('Navigating to KP dashboard');
            context.go('/kp/dashboard');
            break;
          case 'Student':
            debugPrint('Navigating to student dashboard');
            context.go('/student/dashboard');
            break;
          default:
            debugPrint('Unknown role: $userRole, navigating to home');
            context.go('/');
            break;
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "An unknown error occurred.";
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else {
        message = e.message ?? message;
      }
      if (mounted) {
        Toast.show(context, message, type: ToastType.error);
      }
    } catch (e) {
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Toast.show(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        type: ToastType.error,
      );
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
    return AppLayout(
      child: Stack(
        children: [
          _buildAnimatedGradientBackground(),
          _buildAuroraEffect(const Color(0xFF3B82F6), Alignment.topRight),
          _buildAuroraEffect(const Color(0xFF8B5CF6), Alignment.bottomLeft),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                right: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                top: 80, // Space for top bar
                bottom: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildAnimatedGlassForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGlassForm() {
    return PageTransitions.buildSubtlePageTransition(
      controller: _animationController,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 400 ? 20 : 28,
          vertical: MediaQuery.of(context).size.width < 400 ? 24 : 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withAlpha(200),
          borderRadius: BorderRadius.circular(
            MediaQuery.of(context).size.width < 400 ? 20 : 24,
          ),
          border: Border.all(color: Colors.white.withAlpha(38), width: 1),
        ),
        child: Form(key: _formKey, child: _buildFormContents()),
      ),
    );
  }

  Widget _buildFormContents() {
    final formElements = [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) => (v == null || !v.contains('@'))
              ? 'Please enter a valid email'
              : null,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              color: Colors.white.withAlpha(179),
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please enter your password' : null,
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
        GestureDetector(
          onTap: _isLoading ? null : _login,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withAlpha(102),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 400 ? 20 : 24),
        GestureDetector(
          onTap: () {
            context.goNamed('forgot-password');
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don’t have an account? ",
              style: TextStyle(color: Colors.white.withAlpha(179)),
            ),
            GestureDetector(
              onTap: () => context.goNamed('register'),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: formElements.asMap().entries.map((entry) {
        return PageTransitions.buildStaggeredTransition(
          controller: _animationController,
          index: entry.key,
          totalItems: formElements.length,
          child: entry.value,
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedGradientBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF131c31), Color(0xFF1E293B)],
      ),
    ),
  );

  Widget _buildAuroraEffect(Color color, Alignment alignment) =>
      Positioned.fill(
        child: Align(
          alignment: alignment,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withAlpha(64), color.withAlpha(0)],
                ),
              ),
            ),
          ),
        ),
      );
}

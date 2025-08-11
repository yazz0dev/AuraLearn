import 'dart:ui';
import 'package:auralearn/components/toast.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/kp/dashboard_kp.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../components/app_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
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
    setState(() { _isLoading = true; });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Authentication failed. Please try again.");
      }

      // Fetch user role from Firestore
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw Exception("User data not found in database. Please contact support.");
      }

      final role = docSnapshot.data()!['role'];

      if (!mounted) return;
      Toast.show(context, "Login successful!", type: ToastType.success);

      // Navigate based on role
      switch (role) {
        case 'Admin':
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardAdmin()), (Route<dynamic> route) => false);
          break;
        case 'KP':
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardKP()), (Route<dynamic> route) => false);
          break;
        case 'Student':
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const StudentDashboard()), (Route<dynamic> route) => false);
          break;
        default:
          throw Exception("Invalid user role detected.");
      }
    } on FirebaseAuthException catch (e) {
      String message = "An unknown error occurred.";
      // Unify error messages for security
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else {
        message = e.message ?? message;
      }
      if (mounted) {
        Toast.show(context, message, type: ToastType.error);
      }
    } catch (e) {
      if (!mounted) return;
      // Sign out user if data is inconsistent to prevent a broken state
      await FirebaseAuth.instance.signOut();
      // --- FIX: Added 'if (!mounted) return;' to fix use_build_context_synchronously warning ---
      if (!mounted) return;
      Toast.show(context, e.toString().replaceFirst("Exception: ", ""), type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_animationController),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(13)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(38), width: 1),
              ),
              child: Form(
                key: _formKey,
                child: _buildFormContents(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContents() {
    return AnimationLimiter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue your journey',
              style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  color: Colors.white.withAlpha(179),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isLoading ? null : _login,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withAlpha(102), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() => TweenAnimationBuilder<Alignment>(duration: const Duration(seconds: 20), tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight), builder: (context, alignment, child) => Container(decoration: BoxDecoration(gradient: LinearGradient(begin: alignment, end: -alignment, colors: const [Color(0xFF0F172A), Color(0xFF131c31), Color(0xFF1E293B)]))));
  Widget _buildAuroraEffect(Color color, Alignment alignment) => Positioned.fill(child: Align(alignment: alignment, child: AspectRatio(aspectRatio: 1, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withAlpha(64), color.withAlpha(0)]))))));
}
import 'dart:ui';
import 'package:auralearn/components/app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/page_transitions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _oobCode;
  bool _isVerifyingCode = false;
  bool _codeValid = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = PageTransitions.createStandardController(vsync: this);
    _animationController.forward();
    _checkForOobCode();
  }

  void _checkForOobCode() async {
    // Only works on web, for mobile you need to handle deep links differently
    final uri = Uri.base;
    final code = uri.queryParameters['oobCode'];
    if (code != null && code.isNotEmpty) {
      setState(() {
        _oobCode = code;
        _isVerifyingCode = true;
      });
      try {
        await FirebaseAuth.instance.verifyPasswordResetCode(code);
        if (mounted) {
          setState(() {
            _codeValid = true;
          });
        }
      } catch (e) {
        if (mounted) {
          Toast.show(
            context,
            'Invalid or expired reset link.',
            type: ToastType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isVerifyingCode = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        Toast.show(
          context,
          'Password reset link sent to your email.',
          type: ToastType.success,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }
      if (mounted) {
        Toast.show(context, message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          'Failed to send reset email.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _oobCode!,
        newPassword: _newPasswordController.text.trim(),
      );
      if (mounted) {
        Toast.show(
          context,
          'Password has been reset. Please login.',
          type: ToastType.success,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to reset password.';
      if (e.code == 'expired-action-code') {
        message = 'Reset link has expired.';
      } else if (e.code == 'invalid-action-code') {
        message = 'Invalid reset link.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }
      if (mounted) {
        Toast.show(context, message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to reset password.', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                child: _oobCode != null
                    ? _buildResetPasswordForm()
                    : _buildAnimatedGlassForm(),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(26),
                  Colors.white.withAlpha(13),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(38), width: 1),
            ),
            child: Form(key: _formKey, child: _buildFormContents()),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContents() {
    final formElements = [
      const Text(
        'Reset Password',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Enter your email to receive a reset link',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(179),
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 32),
      TextFormField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Email Address',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        validator: (v) {
          if (v == null || !v.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: _isLoading ? null : _sendResetLink,
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
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/login');
          }
        },
        child: Text(
          'Back to Login',
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
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

  Widget _buildResetPasswordForm() {
    if (_isVerifyingCode) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_codeValid) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Invalid or expired reset link.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      );
    }
    return PageTransitions.buildSubtlePageTransition(
      controller: _animationController,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(26),
                  Colors.white.withAlpha(13),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(38), width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set New Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your new password below.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _isLoading ? null : _resetPassword,
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
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.white.withAlpha(179)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() => TweenAnimationBuilder<Alignment>(
    duration: const Duration(seconds: 20),
    tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight),
    builder: (context, alignment, child) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment,
          end: -alignment,
          colors: const [
            Color(0xFF0F172A),
            Color(0xFF131c31),
            Color(0xFF1E293B),
          ],
        ),
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

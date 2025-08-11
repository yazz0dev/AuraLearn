import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:time_range_picker/time_range_picker.dart' as time_range;

import '../../components/app_layout.dart';
import '../../components/toast.dart';
import '../login.dart'; // FIX: Adjust path to reflect file rename.

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  double _examScore = 75.0;
  String? _selectedStream;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _isButtonEnabled = false;

  final Map<String, bool> _selectedDays = {
    'Mon': false, 'Tue': false, 'Wed': false, 'Thu': false,
    'Fri': false, 'Sat': false, 'Sun': false,
  };
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  late AnimationController _animationController;
  final List<String> _streams = ['BSc', 'MSc', 'BTech', 'MTech', 'BE', 'ME', 'BCA', 'MCA', 'MBA', 'Computer Science'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _addListeners();
    _animationController.forward();
  }

  void _addListeners() {
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final isPasswordMatch = _passwordController.text == _confirmPasswordController.text && _passwordController.text.isNotEmpty;
    final areDaysSelected = _selectedDays.containsValue(true);
    final isValid = _nameController.text.isNotEmpty &&
        _validateEmail(_emailController.text) == null &&
        _passwordController.text.length >= 6 &&
        isPasswordMatch &&
        _selectedStream != null &&
        areDaysSelected &&
        _startTime != null &&
        _endTime != null &&
        _acceptTerms;

    if (isValid != _isButtonEnabled) setState(() => _isButtonEnabled = isValid);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Stack(
        children: [
          _buildAnimatedGradientBackground(),
          _buildAuroraEffect(const Color(0xFF3B82F6), Alignment.centerLeft),
          _buildAuroraEffect(const Color(0xFF8B5CF6), Alignment.centerRight),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    _buildAnimatedGlassForm(),
                    const SizedBox(height: 100),
                  ],
                ),
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email Address', Icons.email_outlined, validator: _validateEmail),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock_outline_rounded, obscureText: _obscurePassword, suffixIcon: _togglePasswordVisibility(), validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null),
            const SizedBox(height: 16),
            _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_person_outlined, obscureText: _obscurePassword, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
            const SizedBox(height: 16),
            _buildDropdown(),
            const SizedBox(height: 32),
            _buildSectionHeader('Last Exam Score'),
            const SizedBox(height: 16),
            _buildScoreSlider(),
            const SizedBox(height: 32),
            _buildSectionHeader('Set Your Weekly Availability'),
            const SizedBox(height: 20),
            _buildDaySelector(),
            const SizedBox(height: 24),
            _buildTimeRangePicker(),
            const SizedBox(height: 32),
            _buildTermsCheckbox(),
            const SizedBox(height: 32),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  // --- Aesthetic background widgets ---
  Widget _buildAnimatedGradientBackground() => TweenAnimationBuilder<Alignment>(duration: const Duration(seconds: 20), tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight), builder: (context, alignment, child) => Container(decoration: BoxDecoration(gradient: LinearGradient(begin: alignment, end: -alignment, colors: const [Color(0xFF0F172A), Color(0xFF131c31), Color(0xFF1E293B)]))));
  Widget _buildAuroraEffect(Color color, Alignment alignment) => Positioned.fill(child: Align(alignment: alignment, child: AspectRatio(aspectRatio: 1, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withAlpha(64), color.withAlpha(0)]))))));

  // --- Re-added and Corrected Helper Widgets ---

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) Toast.show(context, 'Please correct the errors before proceeding.', type: ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    final String? startTimeString = _startTime?.format(context);
    final String? endTimeString = _endTime?.format(context);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      final List<String> availableDays = _selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
      final userData = {
        'uid': userCredential.user!.uid, 'name': _nameController.text.trim(),
        'email': _emailController.text.trim(), 'stream': _selectedStream,
        'examScore': _examScore.round(), 'createdAt': FieldValue.serverTimestamp(), 'role': 'Student',
        'availability': { 'days': availableDays, 'startTime': startTimeString, 'endTime': endTimeString }
      };
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
      
      if (mounted) {
        Toast.show(context, 'Registration successful! Please log in.', type: ToastType.success);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'An unknown error occurred.';
      if (e.code == 'weak-password') {
        msg = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'An account already exists for that email.';
      }
      if (mounted) Toast.show(context, msg, type: ToastType.error);
    } catch (e) {
      if (mounted) Toast.show(context, 'Registration failed. Please try again.', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRegisterButton() {
    final bool canPress = _isButtonEnabled && !_isLoading;

    Widget buildChild() {
      if (_isLoading) {
        return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3));
      }
      return Text(
        'Create Account',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: canPress ? Colors.white : Colors.white.withAlpha(128),
        ),
      );
    }

    return GestureDetector(
      onTap: canPress ? _handleRegistration : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: canPress ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: canPress ? null : Border.all(color: Colors.white.withAlpha(51)),
          boxShadow: canPress
              ? [BoxShadow(color: const Color(0xFF3B82F6).withAlpha(102), blurRadius: 20, offset: const Offset(0, 5))]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: canPress ? 0 : 4, sigmaY: canPress ? 0 : 4),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Align(
                  key: ValueKey('isLoading_$_isLoading'),
                  alignment: Alignment.center,
                  child: buildChild(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSlider() {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: Colors.white.withAlpha(50),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF3B82F6).withAlpha(50),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: const Color(0xFF3B82F6),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: _examScore,
              min: 0,
              max: 100,
              divisions: 100,
              label: "${_examScore.round()}",
              onChanged: (double value) => setState(() => _examScore = value),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text("${_examScore.round()}%", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDaySelector() {
    return FormField<bool>(
      validator: (v) => !_selectedDays.containsValue(true) ? 'Please select at least one day' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12.0, runSpacing: 12.0, alignment: WrapAlignment.center,
            children: _selectedDays.keys.map((day) {
              final isSelected = _selectedDays[day]!;
              return ChoiceChip(
                label: Text(day), selected: isSelected, showCheckmark: false,
                onSelected: (selected) { setState(() { _selectedDays[day] = selected; state.didChange(true); _updateButtonState(); }); },
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                backgroundColor: Colors.white.withAlpha(20),
                selectedColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.white.withAlpha(40))),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              );
            }).toList(),
          ),
          if (state.hasError) Padding(padding: const EdgeInsets.only(top: 10.0, left: 12.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
        ],
      ),
    );
  }
  
  Widget _buildTimeRangePicker() {
    String timeRangeText = 'Select Time Range';
    if (_startTime != null && _endTime != null) {
      timeRangeText = '${_startTime!.format(context)} - ${_endTime!.format(context)}';
    }
    return FormField<bool>(
      initialValue: _startTime != null && _endTime != null,
      validator: (value) => !value! ? 'Please select a time range' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectTimeRange(context, state),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Available Hours', errorText: state.errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.access_time_filled_rounded),
              ),
              child: Text(timeRangeText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTimeRange(BuildContext context, FormFieldState state) async {
    final result = await time_range.showTimeRangePicker(context: context, start: _startTime, end: _endTime, use24HourFormat: false);
    if (result != null) {
      setState(() {
        _startTime = result.startTime;
        _endTime = result.endTime;
        state.didChange(true);
        _updateButtonState();
      });
    }
  }

  Widget _buildTermsCheckbox() {
    return FormField<bool>(
      validator: (v) => !_acceptTerms ? 'You must accept the terms' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _acceptTerms,
            onChanged: (v) => setState(() { _acceptTerms = v!; state.didChange(v); _updateButtonState(); }),
            title: const Text('I accept the terms and conditions', style: TextStyle(color: Colors.white70)),
            controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true,
            activeColor: const Color(0xFF3B82F6), checkColor: Colors.white,
          ),
          if (state.hasError) Padding(padding: const EdgeInsets.only(left: 16.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildHeader() => const Text('Create Your Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white));
  Widget _buildSectionHeader(String title) => Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(204)));
  Widget _buildTextField(TextEditingController c, String l, IconData i, {bool obscureText = false, Widget? suffixIcon, String? Function(String?)? validator}) => TextFormField(controller: c, obscureText: obscureText, validator: validator, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), suffixIcon: suffixIcon));
  Widget _buildDropdown() => DropdownButtonFormField<String>(value: _selectedStream, items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() { _selectedStream = v; _updateButtonState(); }), decoration: const InputDecoration(labelText: 'Select Stream', prefixIcon: Icon(Icons.school_outlined)), validator: (v) => v == null ? 'Please select a stream' : null, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white));
  Widget _togglePasswordVisibility() => IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword), color: Colors.white.withAlpha(179));
  String? _validateEmail(String? v) => (v == null || !RegExp(r".+@.+\..+").hasMatch(v)) ? 'Enter a valid email' : null;
}
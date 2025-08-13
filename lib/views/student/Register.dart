import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:time_range_picker/time_range_picker.dart' as time_range;

import '../../components/app_layout.dart';
import '../../components/toast.dart';
import 'dashboard.dart';

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
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
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 100 : 120),
                    _buildAnimatedGlassForm(),
                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 80 : 100),
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
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart)
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 400 ? 20 : 28, 
                vertical: MediaQuery.of(context).size.width < 400 ? 24 : 32
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(13)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : 24),
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
            Text(
              'Register', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: MediaQuery.of(context).size.width < 400 ? 24 : null
              )
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
            _buildTextField(_emailController, 'Email Address', Icons.email_outlined, validator: _validateEmail),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
            _buildTextField(_passwordController, 'Password', Icons.lock_outline_rounded, obscureText: _obscurePassword, suffixIcon: _togglePasswordVisibility(), validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
            _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_person_outlined, obscureText: _obscurePassword, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
            _buildDropdown(),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
            _buildSectionHeader('Last Exam Score'),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 16),
            _buildScoreSlider(),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
            _buildSectionHeader('Set Your Weekly Availability'),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 20),
            _buildDaySelector(),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 20 : 24),
            _buildTimeRangePicker(),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
            _buildTermsCheckbox(),
            SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscureText = false,
        Widget? suffixIcon,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: (_) => _updateButtonState(),
    );
  }

  Widget _togglePasswordVisibility() {
    return IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStream,
      decoration: InputDecoration(
        labelText: 'Select Stream',
        prefixIcon: const Icon(Icons.school_outlined),
      ),
      items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() { _selectedStream = v; _updateButtonState(); }),
      validator: (v) => v == null ? 'Please select a stream' : null,
    );
  }

  Widget _buildSectionHeader(String text) => Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildScoreSlider() {
    return Slider(
      value: _examScore,
      min: 0,
      max: 100,
      divisions: 100,
      label: _examScore.round().toString(),
      onChanged: (v) => setState(() => _examScore = v),
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8,
      children: _selectedDays.keys.map((day) {
        final selected = _selectedDays[day]!;
        return FilterChip(
          label: Text(day),
          selected: selected,
          onSelected: (val) {
            setState(() { _selectedDays[day] = val; _updateButtonState(); });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimeRangePicker() {
    final label = _startTime == null || _endTime == null
        ? 'Select time range'
        : '${_startTime!.format(context)} - ${_endTime!.format(context)}';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await time_range.showTimeRangePicker(
              context: context,
              start: _startTime,
              end: _endTime,
              use24HourFormat: false, // This enables 12-hour format
              strokeWidth: 2,
              ticks: 12,
              ticksColor: Colors.white.withAlpha(102),
              ticksLength: 15,
              handlerColor: const Color(0xFF3B82F6),
              handlerRadius: 8,
              strokeColor: Colors.white.withAlpha(51),
              backgroundColor: const Color(0xFF1E1E1E),
              activeTimeTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              timeTextStyle: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 16,
              ),
            );
            if (result != null) {
              setState(() {
                _startTime = result.startTime;
                _endTime = result.endTime;
                _updateButtonState();
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white.withAlpha(179),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _startTime == null || _endTime == null 
                          ? Colors.white.withAlpha(179) 
                          : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withAlpha(179),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      title: const Text('I accept the Terms and Conditions'),
      value: _acceptTerms,
      onChanged: (v) => setState(() => _acceptTerms = v == true ? true : false),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonEnabled && !_isLoading ? _handleRegistration : null,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Register'),
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() => TweenAnimationBuilder<Alignment>(
    tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight),
    duration: const Duration(seconds: 20),
    builder: (context, alignment, child) => Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: alignment, end: -alignment, colors: const [Color(0xFF0F172A), Color(0xFF131c31), Color(0xFF1E293B)])),
    ),
  );

  Widget _buildAuroraEffect(Color color, Alignment alignment) => Positioned.fill(
    child: Align(
      alignment: alignment,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withAlpha(64), color.withAlpha(0)]),
          ),
        ),
      ),
    ),
  );

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) Toast.show(context, 'Please correct the errors before proceeding.', type: ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    final startTimeString = _startTime?.format(context);
    final endTimeString = _endTime?.format(context);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final availableDays = _selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
      final userData = {
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'stream': _selectedStream,
        'examScore': _examScore.round(),
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'Student',
        'availability': {
          'days': availableDays,
          'startTime': startTimeString,
          'endTime': endTimeString
        }
      };

       await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      if (mounted) {
        Toast.show(context, 'Registration successful! Welcome to the dashboard.', type: ToastType.success);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'An unknown error occurred.';
      if (e.code == 'weak-password') msg = 'The password provided is too weak.';
      else if (e.code == 'email-already-in-use') msg = 'An account already exists for that email.';
      if (mounted) Toast.show(context, msg, type: ToastType.error);
    } catch (e) {
      if (mounted) Toast.show(context, 'Registration failed. Please try again.', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

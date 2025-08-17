import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:time_range_picker/time_range_picker.dart' as time_range;
import '../../components/app_layout.dart';
import '../../components/toast.dart';

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
  final List<String> _streams = ['BSc', 'BTech', 'BCA', 'MCA', 'MBA', 'Other'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _addListeners();
    _animationController.forward();
  }

  void _addListeners() {
    _nameController.addListener(_debounceUpdateButtonState);
    _emailController.addListener(_debounceUpdateButtonState);
    _passwordController.addListener(_debounceUpdateButtonState);
    _confirmPasswordController.addListener(_debounceUpdateButtonState);
  }

  Timer? _debounceTimer;
  void _debounceUpdateButtonState() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _updateButtonState);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 400 ? 20 : 28, 
            vertical: MediaQuery.of(context).size.width < 400 ? 24 : 32
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withAlpha(200),
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
    );
  }

  Widget _buildFormContents() {
    return Column(
      children: [
            Text(
              'Create Your Account', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: MediaQuery.of(context).size.width < 400 ? 24 : null,
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 32),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email Address', Icons.email_outlined, validator: _validateEmail),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock_outline_rounded, obscureText: _obscurePassword, suffixIcon: _togglePasswordVisibility(), validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null),
            const SizedBox(height: 16),
            _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_person_outlined, obscureText: _obscurePassword, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
            const SizedBox(height: 16),
            _buildStreamSelector(),
            const SizedBox(height: 24),
            _buildScoreSelector(),
            const SizedBox(height: 24),
            _buildAvailabilitySection(),
            const SizedBox(height: 24),
            _buildTermsCheckbox(),
            const SizedBox(height: 32),
            _buildRegisterButton(),
          ],
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
      onChanged: (_) => _debounceUpdateButtonState(),
    );
  }

  Widget _togglePasswordVisibility() {
    return IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildStreamSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStream,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Stream',
        prefixIcon: Icon(Icons.school_outlined),
      ),
      dropdownColor: const Color(0xFF1E293B),
      items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() { _selectedStream = v; _debounceUpdateButtonState(); }),
      validator: (v) => v == null ? 'Please select a stream' : null,
    );
  }

  Widget _buildScoreSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Exam Score',
                style: Theme.of(context).inputDecorationTheme.floatingLabelStyle,
              ),
              Text(
                '${_examScore.round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _examScore,
            min: 0,
            max: 100,
            divisions: 20,
            label: _examScore.round().toString(),
            onChanged: (v) => setState(() => _examScore = v),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Your Weekly Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        _buildDaySelector(),
        const SizedBox(height: 16),
        _buildTimeRangePicker(),
      ],
    );
  }
  
  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _selectedDays.keys.map((day) {
        final selected = _selectedDays[day]!;
        return FilterChip(
          label: Text(day),
          selected: selected,
          onSelected: (val) {
            setState(() { _selectedDays[day] = val; _debounceUpdateButtonState(); });
          },
        );
      }).toList(),
    );
  }

  // --- FIX: Reverted time picker to its custom-styled container ---
  Widget _buildTimeRangePicker() {
    final label = _startTime == null || _endTime == null
        ? 'Select Time Range'
        : '${_startTime!.format(context)} - ${_endTime!.format(context)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
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
              use24HourFormat: false,
              strokeWidth: 2,
              ticks: 12,
              ticksColor: Colors.white.withAlpha(102),
              ticksLength: 15,
              handlerColor: const Color(0xFF3B82F6),
              handlerRadius: 8,
              strokeColor: Colors.white.withAlpha(51),
              backgroundColor: const Color(0xFF1E1E1E),
              activeTimeTextStyle: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              timeTextStyle: TextStyle(color: Colors.white.withAlpha(179), fontSize: 16),
            );
            if (result != null) {
              setState(() {
                _startTime = result.startTime;
                _endTime = result.endTime;
                _debounceUpdateButtonState();
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
                      color: _startTime == null ? Colors.white.withAlpha(179) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
      title: const Text('I accept the Terms and Conditions', style: TextStyle(color: Colors.white70)),
      value: _acceptTerms,
      onChanged: (v) => setState(() { _acceptTerms = v ?? false; _debounceUpdateButtonState(); }),
      activeColor: const Color(0xFF3B82F6),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonEnabled && !_isLoading ? _handleRegistration : null,
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text('Create Account'),
      ),
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

  Widget _buildAuroraEffect(Color color, Alignment alignment) => Positioned.fill(
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

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        Toast.show(context, 'Please correct the errors before proceeding.', type: ToastType.error);
      }
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
        Toast.show(context, 'Registration successful! Welcome.', type: ToastType.success);
        context.goNamed('home');
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'An unknown error occurred.';
      if (e.code == 'weak-password') {
        msg = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'An account already exists for that email.';
      }
      if (mounted) {
        Toast.show(context, msg, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Registration failed. Please try again.', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
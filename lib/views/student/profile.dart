//scrum 3

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_range_picker/time_range_picker.dart' as time_range;
import '../../components/authenticated_app_layout.dart';
import '../../components/toast.dart';
import '../../components/bottom_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  String _name = 'Loading...';
  String _email = 'Loading...';

  // Availability data
  final Map<String, bool> _selectedDays = {
    'Mon': false, 'Tue': false, 'Wed': false, 'Thu': false,
    'Fri': false, 'Sat': false, 'Sun': false,
  };
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _email = user.email ?? 'No email';

        // Load user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _name = data['name'] ?? 'No name';

          // Load availability data
          if (data['availability'] != null) {
            final availability = data['availability'] as Map<String, dynamic>;
            final days = availability['days'] as List<dynamic>? ?? [];
            final startTimeStr = availability['startTime'] as String?;
            final endTimeStr = availability['endTime'] as String?;

            // Set selected days
            for (String day in days) {
              if (_selectedDays.containsKey(day)) {
                _selectedDays[day] = true;
              }
            }

            // Parse time strings
            if (startTimeStr != null) {
              _startTime = _parseTimeString(startTimeStr);
            }
            if (endTimeStr != null) {
              _endTime = _parseTimeString(endTimeStr);
            }
          }
        } else {
          // Fallback to display name
          _name = user.displayName ?? 'No name';
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _name = 'Error loading name';
      _email = 'Error loading email';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final time = TimeOfDay(
        hour: int.parse(timeStr.split(':')[0]),
        minute: int.parse(timeStr.split(':')[1].split(' ')[0]),
      );
      return time;
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }



  Future<void> _saveChanges() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final availableDays = _selectedDays.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

        final startTimeString = _startTime?.format(context);
        final endTimeString = _endTime?.format(context);

        await _firestore.collection('users').doc(user.uid).update({
          'availability': {
            'days': availableDays,
            'startTime': startTimeString,
            'endTime': endTimeString
          }
        });

        if (mounted) {
          Toast.show(context, 'Changes saved successfully!', type: ToastType.success);
        }
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        Toast.show(context, 'Failed to save changes', type: ToastType.error);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    debugPrint('Logout button pressed');

    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Confirm Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Content
                  const Text(
                    'Are you sure you want to log out of your account? You\'ll need to sign in again to access your dashboard.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Logout',
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
        );
      },
    );

    if (shouldLogout != true) {
      debugPrint('Logout cancelled by user');
      return;
    }

    debugPrint('Attempting to sign out...');
    try {
      await _auth.signOut();
      debugPrint('Firebase sign out successful');

      if (mounted) {
        Toast.show(context, 'Logged out successfully', type: ToastType.success);
      }
      debugPrint('Navigating to landing screen...');

      // Wait a brief moment for the auth state to update, then navigate
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // Use go instead of goNamed to ensure we hit the root route
        context.go('/');
      }
      debugPrint('Navigation to "/" completed');
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        Toast.show(
          context,
          'Failed to log out. Please try again.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthenticatedAppLayout(
      role: UserRole.student,
      appBarTitle: 'My Profile',
      showCloseButton: true,
      child: _isLoading ? _buildLoadingState() : _buildProfileContent(isDark),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildProfileContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          // avatar
          CircleAvatar(
            radius: 56,
            backgroundColor: primaryColor(context).withAlpha((0.1 * 255).round()),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              child: ClipOval(
                child: Icon(Icons.person, size: 64, color: primaryColor(context)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_email, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // Learning Preferences card
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Learning Preferences', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Availability', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 10),

                // Days selector (matching register.dart)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _selectedDays.keys.map((day) {
                    final selected = _selectedDays[day]!;
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          _selectedDays[day] = val;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Time range picker (matching register.dart design)
                _buildTimeRangePicker(),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saveChanges,
                    child: Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Account & Security
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Account & Security', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // navigate to change password
                    },
                    child: Text('Change Password', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _handleLogout(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Log Out', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
}
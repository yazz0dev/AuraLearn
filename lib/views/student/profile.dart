//scrum 3

import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _learningGoalController = TextEditingController();
  final String _name = 'Name';
  final String _email = '*******@email.com';
  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final Set<int> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? initial) : (_endTime ?? initial),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(t, alwaysUse24HourFormat: false);
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Changes saved')),
    );
  }

  @override
  void dispose() {
    _learningGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('My Profile', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            // avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: primaryColor(context).withOpacity(0.1),
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
            Text(_email, style: TextStyle(color: Colors.grey),),
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
                  Text('Learning Goal', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _learningGoalController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your learning goal',
                      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Study Availability', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 10),

                  // Days row
                  Wrap(
                    spacing: 8,
                    children: List.generate(_days.length, (i) {
                      final selected = _selectedDays.contains(i);
                      return ChoiceChip(
                        label: Text(_days[i], style: TextStyle(fontWeight: FontWeight.w600)),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            if (selected) {
                              _selectedDays.remove(i);
                            } else {
                              _selectedDays.add(i);
                            }
                          });
                        },
                        selectedColor: primaryColor(context).withOpacity(0.2),
                        backgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _pickTime(true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(_startTime == null ? 'Start Time' : _formatTime(_startTime)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _pickTime(false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(_endTime == null ? 'End Time' : _formatTime(_endTime)),
                          ),
                        ),
                      ),
                    ],
                  ),

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
                    onTap: () {
                      // log out
                    },
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
      ),
    );
  }
}
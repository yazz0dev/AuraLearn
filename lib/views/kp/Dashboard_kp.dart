import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:flutter/material.dart';

class DashboardKP extends StatefulWidget {
  const DashboardKP({super.key});

  @override
  State<DashboardKP> createState() => _DashboardKPState();
}

class _DashboardKPState extends State<DashboardKP> {

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.kp,
      appBarTitle: 'My Subjects',
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0, top: 4.0, bottom: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        )
      ],
      showBottomBar: false,
      bottomNavIndex: 0, 
      onBottomNavTap: (index) {},
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSubjectCard(
            status: 'Syllabus Pending',
            title: 'Subject 1',
            description: 'Upload the syllabus to proceed.',
            buttonText: 'Upload Syllabus',
            imageColor: const Color(0xFFD6C6C2),
            onButtonPressed: () {},
          ),
          const SizedBox(height: 24),
          _buildSubjectCard(
            status: 'Ready for Material',
            title: 'Subject 2',
            description: 'Study material can now be uploaded.',
            buttonText: 'Upload Study Material',
            imageColor: const Color(0xFFF2CACA),
            onButtonPressed: () {},
          ),
          const SizedBox(height: 24),
          _buildSubjectCard(
            status: 'Awaiting Review',
            title: 'Subject 3',
            description: 'Review Uploaded content.',
            buttonText: 'Review',
            imageColor: const Color(0xFFC7A8A3),
            onButtonPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard({
    required String status,
    required String title,
    required String description,
    required String buttonText,
    required Color imageColor,
    required VoidCallback onButtonPressed,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  // --- FIX: Replaced deprecated `withOpacity` with `withAlpha` ---
                  backgroundColor: Colors.white.withAlpha(230), // 255 * 0.9 = 229.5 -> 230
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: imageColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
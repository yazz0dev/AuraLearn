import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Progress Tracking Coming Soon',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
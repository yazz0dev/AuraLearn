//scrum 2

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UploadContentPage extends StatefulWidget {
  const UploadContentPage({super.key});

  @override
  State<UploadContentPage> createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage> {
  String? _syllabusFileName;
  String? _materialFileName;

  Future<void> _pickSyllabus() async {
    // placeholder for file picker integration
    setState(() => _syllabusFileName = 'syllabus.pdf');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syllabus selected')));
  }

  Future<void> _pickMaterial() async {
    setState(() => _materialFileName = 'material.pdf');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material selected')));
  }

  void _uploadSyllabus() {
    if (_syllabusFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a syllabus first')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syllabus uploaded')));
  }

  void _uploadMaterial() {
    if (_materialFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select material first')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material uploaded')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final boxBg = isDark ? Colors.grey[900] : Colors.white;
    final innerBg = isDark ? Colors.grey[850] : Colors.grey[100];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/kp/dashboard');
            }
          },
        ),
        title: Text('General Chemistry', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(child: Text('Syllabus', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 12),

              // Syllabus box
              GestureDetector(
                onTap: _pickSyllabus,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: boxBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade500.withAlpha((0.35 * 255).round())),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        _syllabusFileName ?? 'Tap to select a file',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 6),
                      Text('PDF, TXT', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: innerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: _pickSyllabus,
                          child: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadSyllabus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Upload Syllabus', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),

              const SizedBox(height: 26),
              Center(child: Text('Material', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 12),

              // Material box
              GestureDetector(
                onTap: _pickMaterial,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: boxBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade500.withAlpha((0.35 * 255).round())),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        _materialFileName ?? 'Tap to select study material',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 6),
                      Text('PDF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: innerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: _pickMaterial,
                          child: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadMaterial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Upload Material', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
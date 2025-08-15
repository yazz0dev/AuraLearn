//scrum 2

import 'package:flutter/material.dart';

class ReviewContentPage extends StatefulWidget {
  const ReviewContentPage({super.key});

  @override
  State<ReviewContentPage> createState() => _ReviewContentPageState();
}

class _ReviewContentPageState extends State<ReviewContentPage> {
  final List<String> _topics = ['Topic 1', 'Topic 2', 'Topic 3'];
  final List<bool> _expanded = [false, false, false];

  void _toggle(int i) {
    setState(() {
      _expanded[i] = !_expanded[i];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? Colors.grey[900] : Colors.white;
    final subtle = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Reviewing: Subject', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // topic cards
              for (var i = 0; i < _topics.length; i++) ...[
                GestureDetector(
                  onTap: () => _toggle(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_topics[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (i == 0) ...[
                                const SizedBox(height: 6),
                                Text('AI generated Content chunk of the topic', style: TextStyle(color: subtle, fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          _expanded[i] ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        )
                      ],
                    ),
                  ),
                ),
                if (_expanded[i])
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details for ${_topics[i]}', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Here you can edit, rearrange, or add content associated with this topic. This area is a placeholder for content management UI.',
                          style: TextStyle(color: subtle),
                        ),
                        const SizedBox(height: 8),
                        // placeholder actions
                        Row(
                          children: [
                            TextButton(onPressed: () {}, child: const Text('Edit')),
                            TextButton(onPressed: () {}, child: const Text('Delete')),
                          ],
                        )
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 28),

              // Process PDFs button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing PDFs...")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text("Process The PDF's", style: TextStyle(fontWeight: FontWeight.w600)),
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
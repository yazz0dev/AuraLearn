import 'package:flutter/material.dart';

void main() {
  runApp(const AuraLearnApp());
}

class AuraLearnApp extends StatelessWidget {
  const AuraLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraLearn',
      home: Scaffold(
        body: Center(child: Text('AuraLearn Shell App')),
      ),
    );
  }
}
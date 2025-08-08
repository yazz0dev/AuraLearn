import 'package:flutter/material.dart';
import 'views/landing.dart';

void main() {
  runApp(const AuraLearnApp());
}

class AuraLearnApp extends StatelessWidget {
  const AuraLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraLearn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const KapeaApp());
}

class KapeaApp extends StatelessWidget {
  const KapeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kapea Malware Scanner',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

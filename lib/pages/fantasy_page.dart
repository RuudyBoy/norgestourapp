import 'package:flutter/material.dart';

class FantasyPage extends StatelessWidget {
  const FantasyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fantasy'),
      ),
      body: const Center(
        child: Text(
          'Fantasy Page Content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
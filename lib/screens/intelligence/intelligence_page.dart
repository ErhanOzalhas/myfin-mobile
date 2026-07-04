import 'package:flutter/material.dart';

class IntelligencePage extends StatelessWidget {
  const IntelligencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Intelligence'),
      ),
      body: const Center(
        child: Text(
          'AI Intelligence modülü yeniden bağlanacak.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

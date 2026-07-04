import 'package:flutter/material.dart';

class IntelligenceDivider extends StatelessWidget {
  const IntelligenceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        thickness: 1,
      ),
    );
  }
}
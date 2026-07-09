import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(action!),
          ),
      ],
    );
  }
}
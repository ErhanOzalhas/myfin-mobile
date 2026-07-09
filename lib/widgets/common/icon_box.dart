import 'package:flutter/material.dart';

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(icon, color: color, size: size * .52),
    );
  }
}
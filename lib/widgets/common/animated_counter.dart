import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final int decimalDigits;
  final String prefix;
  final String suffix;
  final TextAlign textAlign;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.decimalDigits = 2,
    this.prefix = '',
    this.suffix = '',
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$prefix${_formatNumber(value)}$suffix',
      textAlign: textAlign,
      style: style ?? Theme.of(context).textTheme.headlineMedium,
    );
  }

  String _formatNumber(double number) {
    final isNegative = number < 0;
    final fixed = number.abs().toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final integerPart = _groupThousands(parts.first);
    final sign = isNegative ? '-' : '';

    if (decimalDigits == 0) return '$sign$integerPart';
    return '$sign$integerPart,${parts.length > 1 ? parts.last : ''}';
  }

  String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

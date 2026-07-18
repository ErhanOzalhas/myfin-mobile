import 'package:flutter/material.dart';

import '../../screens/my_fin_home.dart';
import '../../utils/no_animation_route.dart';

class MyFinBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const MyFinBackButton({super.key, this.onPressed});

  void _handlePressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      noAnimationRoute(builder: (_) => const MyFinHome()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Geri',
      onPressed: () => _handlePressed(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}

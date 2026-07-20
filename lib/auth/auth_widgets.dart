import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBackButton;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF071A36),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthGradientBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  28,
                  22,
                  28 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Theme(
                    data: baseTheme.copyWith(
                      textTheme: baseTheme.textTheme.apply(
                        bodyColor: Colors.white,
                        displayColor: Colors.white,
                      ),
                      colorScheme: baseTheme.colorScheme.copyWith(
                        primary: const Color(0xFF31C6E8),
                        onPrimary: const Color(0xFF071A36),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .10),
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontWeight: FontWeight.w400,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: .48),
                        ),
                        prefixIconColor: Colors.white.withValues(alpha: .78),
                        suffixIconColor: Colors.white.withValues(alpha: .78),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: .24),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFF54D9F3),
                            width: 1.6,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8B8B),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8B8B),
                            width: 1.6,
                          ),
                        ),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8FEAFF),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      filledButtonTheme: FilledButtonThemeData(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF075B78),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: .30,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showBackButton)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: .10,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                        const _AuthLogo(),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.05,
                            letterSpacing: -.7,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .075),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .16),
                                blurRadius: 34,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: children,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Finansını anla. Geleceğini planla.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .58),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGradientBackground extends StatelessWidget {
  const _AuthGradientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071A36), Color(0xFF075B78), Color(0xFF05A8D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .52, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _Glow(size: 330, color: Color(0xFF20D6F5)),
          ),
          Positioned(
            bottom: -160,
            left: -130,
            child: _Glow(size: 380, color: Color(0xFF008DB9)),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .30), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: const Icon(
        Icons.trending_up_rounded,
        color: Colors.white,
        size: 46,
      ),
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  final String message;

  const AuthErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFA0A0).withValues(alpha: .32),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFFD1D1),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class AuthSuccessBox extends StatelessWidget {
  final String message;

  const AuthSuccessBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF5EE6A8).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF9BF4CA).withValues(alpha: .30),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFD7FFEA),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

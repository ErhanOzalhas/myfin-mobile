import 'package:flutter/material.dart';

import '../app/my_fin_app.dart';
import '../services/app_startup_coordinator.dart';

class MyFinLaunchApp extends StatefulWidget {
  const MyFinLaunchApp({super.key});

  @override
  State<MyFinLaunchApp> createState() => _MyFinLaunchAppState();
}

class _MyFinLaunchAppState extends State<MyFinLaunchApp> {
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    _prepareApp();
  }

  Future<void> _prepareApp() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 1400),
    );
    final preload = AppStartupCoordinator.instance
        .prepareCriticalData()
        .timeout(const Duration(milliseconds: 2400), onTimeout: () {});

    await Future.wait([minimumSplash, preload]);

    if (!mounted) return;
    setState(() => _showApp = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showApp ? const MyFinApp() : const _MyFinSplashScreen(),
    );
  }
}

class _MyFinSplashScreen extends StatefulWidget {
  const _MyFinSplashScreen();

  @override
  State<_MyFinSplashScreen> createState() => _MyFinSplashScreenState();
}

class _MyFinSplashScreenState extends State<_MyFinSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _scale = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF071A3D), Color(0xFF008DB9), Color(0xFF0F172A)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44000000),
                              blurRadius: 34,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'MyFin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Finansını anla. Geleceğini planla.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      const _LoadingSteps(),
                      const Spacer(flex: 2),
                      Text(
                        'MyFin Intelligence hazırlanıyor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .70),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSteps extends StatelessWidget {
  const _LoadingSteps();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: const Column(
        children: [
          _StepRow(text: 'Portföy yükleniyor'),
          SizedBox(height: 12),
          _StepRow(text: 'AI analiz motoru hazırlanıyor'),
          SizedBox(height: 12),
          _StepRow(text: 'İçgörüler oluşturuluyor'),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

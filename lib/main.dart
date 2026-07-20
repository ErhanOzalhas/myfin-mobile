import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'screens/splash_page.dart';
import 'services/price_alert_service.dart';
import 'services/portfolio_valuation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _MyFinBootstrapApp());
}

class _MyFinBootstrapApp extends StatefulWidget {
  const _MyFinBootstrapApp();

  @override
  State<_MyFinBootstrapApp> createState() => _MyFinBootstrapAppState();
}

class _MyFinBootstrapAppState extends State<_MyFinBootstrapApp> {
  bool _ready = false;
  bool _loading = true;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _startupError = null;
      });
    }

    try {
      try {
        await dotenv.load(fileName: '.env.client');
      } catch (error) {
        debugPrint('ENV yüklenemedi: $error');
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
      } catch (error) {
        debugPrint('Firestore yerel önbelleği ayarlanamadı: $error');
      }

      await Future.wait([
        _initializeOptionalService(
          'Portföy önbelleği',
          PortfolioValuationService.instance.initialize,
        ),
        _initializeOptionalService(
          'Fiyat alarmları',
          PriceAlertService.instance.initialize,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _ready = true;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Uygulama başlatılamadı: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _startupError = error;
        _loading = false;
      });
    }
  }

  Future<void> _initializeOptionalService(
    String name,
    Future<void> Function() initialize,
  ) async {
    try {
      await initialize().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('$name başlatılamadı, uygulama devam ediyor: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const MyFinLaunchApp();

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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'MyFin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading) ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 18),
                      Text(
                        'Güvenli başlangıç hazırlanıyor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Uygulama başlatılamadı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bağlantını kontrol edip yeniden deneyebilirsin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .75),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _startupError == null ? null : _initialize,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF075B78),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

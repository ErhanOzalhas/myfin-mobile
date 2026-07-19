import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../auth/auth_gate.dart';
import '../theme/app_typography.dart';

class MyFinApp extends StatelessWidget {
  const MyFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFin',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008DB9),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displaySmall: AppTypography.appTitle,
          headlineMedium: AppTypography.pageTitle,
          headlineSmall: AppTypography.sectionTitle,
          titleLarge: AppTypography.cardTitle,
          titleMedium: AppTypography.title,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
          labelLarge: AppTypography.label,
          labelSmall: AppTypography.small,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9FC),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: 64,
          titleSpacing: 0,
          iconTheme: IconThemeData(size: 26),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontFamily: 'Inter',
            fontSize: 27,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 10,
          shadowColor: const Color(0xFF0F172A).withValues(alpha: .16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE8EEF5)),
          ),
          textStyle: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF008DB9).withValues(alpha: .14),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

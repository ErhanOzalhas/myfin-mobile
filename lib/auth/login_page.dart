import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Lütfen email ve şifre alanlarını doldurun.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _authErrorMessage(e);
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Giriş yapılırken beklenmeyen bir hata oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email adresi geçerli değil.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email veya şifre hatalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar deneyin.';
      default:
        return 'Giriş başarısız: ${e.message ?? e.code}';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'MyFin',
      subtitle: 'Hesabına giriş yap',
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          onSubmitted: (_) => isLoading ? null : login(),
          decoration: const InputDecoration(
            labelText: 'Şifre',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (errorMessage != null)
          AuthErrorBox(message: errorMessage!),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : login,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Giriş Yap'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
          child: const Text('Hesabın yok mu? Kayıt ol'),
        ),
      ],
    );
  }
}


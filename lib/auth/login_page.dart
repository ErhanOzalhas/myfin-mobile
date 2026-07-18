import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/main_shell.dart';
import '../utils/no_animation_route.dart';
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
  bool obscurePassword = true;
  bool showVerificationHelp = false;
  String? errorMessage;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => errorMessage = 'Lütfen e-posta ve şifre alanlarını doldurun.',
      );
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
      showVerificationHelp = false;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } on FirebaseAuthException catch (error) {
          if (error.code != 'too-many-requests') rethrow;
        }
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          errorMessage =
              'E-posta adresin henüz doğrulanmamış. Doğrulama bağlantısını yeniden gönderdik; gelen kutunu ve spam klasörünü kontrol et.';
          showVerificationHelp = true;
        });
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        noAnimationRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = _authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => errorMessage = 'Giriş yapılırken beklenmeyen bir hata oluştu.',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = 'Önce geçerli e-posta adresini yaz.';
        showVerificationHelp = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        errorMessage = null;
        showVerificationHelp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifre yenileme bağlantısı e-posta adresine gönderildi.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = _resetErrorMessage(error));
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'E-posta adresi geçerli değil.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı. Şifreni unuttuysan aşağıdaki bağlantıyı kullanabilirsin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';
      case 'network-request-failed':
        return 'İnternet bağlantısı kurulamadı.';
      default:
        return 'Giriş başarısız: ${error.message ?? error.code}';
    }
  }

  String _resetErrorMessage(FirebaseAuthException error) {
    if (error.code == 'too-many-requests') {
      return 'Çok fazla istek gönderildi. Biraz bekleyip tekrar dene.';
    }
    return 'Şifre yenileme bağlantısı gönderilemedi.';
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
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          onSubmitted: (_) => isLoading ? null : login(),
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : _resetPassword,
            child: const Text('Şifremi unuttum'),
          ),
        ),
        if (errorMessage != null) AuthErrorBox(message: errorMessage!),
        if (showVerificationHelp) ...[
          const SizedBox(height: 6),
          const Text(
            'Bağlantı birkaç dakika gecikebilir. Doğruladıktan sonra yeniden giriş yapabilirsin.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
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
              : () => Navigator.of(
                  context,
                ).push(noAnimationRoute(builder: (_) => const RegisterPage())),
          child: const Text('Hesabın yok mu? Kayıt ol'),
        ),
      ],
    );
  }
}

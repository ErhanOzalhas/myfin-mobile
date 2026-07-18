import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

import 'auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> register() async {
    final displayName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final passwordAgain = passwordAgainController.text;

    if (displayName.length < 2 ||
        email.isEmpty ||
        password.isEmpty ||
        passwordAgain.isEmpty) {
      setState(() {
        errorMessage = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }

    if (password != passwordAgain) {
      setState(() {
        errorMessage = 'Şifreler aynı değil.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'Şifre en az 6 karakter olmalı.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        try {
          await FirestoreService.instance.createOrUpdateUserProfile(
            email: user.email ?? '',
            displayName: displayName,
          );
        } catch (error) {
          debugPrint('REGISTER PROFILE WRITE ERROR: $error');
        }
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hesabın oluşturuldu. E-postandaki bağlantıyla hesabını doğruladıktan sonra giriş yapabilirsin.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _authErrorMessage(e);
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Kayıt oluşturulurken beklenmeyen bir hata oluştu.';
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
      case 'email-already-in-use':
        return 'Bu email adresi zaten kayıtlı.';
      case 'invalid-email':
        return 'Email adresi geçerli değil.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      default:
        return 'Kayıt başarısız: ${e.message ?? e.code}';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordAgainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Kayıt Ol',
      subtitle: 'MyFin hesabını oluştur',
      showBackButton: true,
      children: [
        TextField(
          controller: nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Ad soyad',
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
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
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Şifre',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordAgainController,
          obscureText: true,
          onSubmitted: (_) => isLoading ? null : register(),
          decoration: const InputDecoration(
            labelText: 'Şifre tekrar',
            prefixIcon: Icon(Icons.lock_reset_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (errorMessage != null) AuthErrorBox(message: errorMessage!),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : register,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kayıt Ol'),
          ),
        ),
      ],
    );
  }
}

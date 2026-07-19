import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _emailController;
  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Geçerli bir e-posta adresi yaz.';
        _success = null;
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success =
            'Şifre yenileme bağlantısı gönderildi. Gelen kutunu ve spam klasörünü kontrol et.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.code == 'too-many-requests'
            ? 'Çok fazla istek gönderildi. Biraz bekleyip tekrar dene.'
            : 'Bağlantı gönderilemedi. E-posta adresini kontrol et.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Şifreni Yenile',
      subtitle: 'Hesabına yeniden erişmen için bağlantı gönderelim',
      showBackButton: true,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          color: Colors.white,
          size: 38,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sending ? null : _send(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          AuthErrorBox(message: _error!),
        ],
        if (_success != null) ...[
          const SizedBox(height: 14),
          AuthSuccessBox(message: _success!),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Yenileme Bağlantısı Gönder'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Giriş ekranına dön'),
        ),
      ],
    );
  }
}

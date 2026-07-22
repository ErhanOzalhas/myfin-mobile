import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/profile/active_profile_bar.dart';

import '../../services/firestore_service.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_back_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final name = _nameController.text.trim();
      await user.updateDisplayName(name);
      await user.reload();
      await FirestoreService.instance.createOrUpdateUserProfile(
        email: user.email ?? '',
        displayName: name,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'Profil bilgilerin güncellendi.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'Profil güncellenemedi. Lütfen tekrar dene.';
        _messageIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Profilim'),
        bottom: const ActiveProfileBar(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            SurfaceCard(
              color: const Color(0xFFF1F5FF),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFF008DB9),
                    child: Text(
                      _initials(_nameController.text, user?.email),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? 'E-posta bulunamadı',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Standart üyelik',
                    style: TextStyle(
                      color: Color(0xFF008DB9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kişisel bilgiler',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Ad soyad',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.length < 2) {
                          return 'Ad soyad en az 2 karakter olmalı.';
                        }
                        if (name.length > 60) {
                          return 'Ad soyad en fazla 60 karakter olabilir.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        helperText:
                            'E-posta adresi hesap kimliğin olarak kullanılır.',
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _messageIsError
                              ? const Color(0xFFFFEFEF)
                              : const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _messageIsError
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF15803D),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Değişiklikleri Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String? email) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    if (initials.isNotEmpty) return initials;
    final fallback = email?.trim();
    return fallback?.isNotEmpty == true ? fallback![0].toUpperCase() : 'M';
  }
}

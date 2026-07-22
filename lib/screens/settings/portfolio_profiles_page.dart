import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/portfolio_profile.dart';
import '../../services/portfolio_profile_service.dart';
import '../../services/profile_lock_service.dart';
import '../../widgets/navigation/myfin_back_button.dart';

class PortfolioProfilesPage extends StatelessWidget {
  const PortfolioProfilesPage({super.key});

  static const _colors = <int>[
    0xFF0284C7,
    0xFF7C3AED,
    0xFF16A34A,
    0xFFF97316,
    0xFFDB2777,
  ];

  IconData _icon(String key) => switch (key) {
    'family' => Icons.family_restroom_rounded,
    'child' => Icons.child_care_rounded,
    'wallet' => Icons.account_balance_wallet_rounded,
    _ => Icons.person_rounded,
  };

  Future<void> _edit(BuildContext context, {PortfolioProfile? profile}) async {
    var profileName = profile?.name ?? '';
    var colorValue = profile?.colorValue ?? _colors[1];
    var iconKey = profile?.iconKey ?? 'person';
    final canUseBiometrics =
        profile == null && await ProfileLockService.instance.canUseBiometrics();
    if (!context.mounted) return;
    var addLock = false;
    var pin = '';
    var repeatedPin = '';
    var biometricEnabled = canUseBiometrics;
    String? pinError;
    final result = await showModalBottomSheet<_ProfileFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile == null ? 'Yeni portföy profili' : 'Profili düzenle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: profileName,
                  autofocus: true,
                  maxLength: 30,
                  onChanged: (value) => profileName = value,
                  decoration: const InputDecoration(
                    labelText: 'Profil adı',
                    hintText: 'Örn. Eşimin Hesabı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('İkon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final entry in const {
                      'person': Icons.person_rounded,
                      'family': Icons.family_restroom_rounded,
                      'child': Icons.child_care_rounded,
                      'wallet': Icons.account_balance_wallet_rounded,
                    }.entries)
                      ChoiceChip(
                        selected: iconKey == entry.key,
                        label: Icon(entry.value, size: 20),
                        onSelected: (_) =>
                            setSheetState(() => iconKey = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Renk'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final color in _colors)
                      InkWell(
                        onTap: () => setSheetState(() => colorValue = color),
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: colorValue == color
                                ? Border.all(color: Colors.black87, width: 3)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                if (profile == null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Bu profili kilitle'),
                    subtitle: const Text('İsteğe bağlı 6 haneli PIN'),
                    value: addLock,
                    onChanged: (value) => setSheetState(() {
                      addLock = value;
                      pinError = null;
                    }),
                  ),
                  if (addLock) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => pin = value,
                      decoration: const InputDecoration(
                        labelText: '6 haneli PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => repeatedPin = value,
                      decoration: InputDecoration(
                        labelText: 'PIN’i tekrar girin',
                        border: const OutlineInputBorder(),
                        errorText: pinError,
                      ),
                    ),
                    if (canUseBiometrics)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Face ID / Touch ID'),
                        subtitle: const Text('Biyometriyle açmaya izin ver'),
                        value: biometricEnabled,
                        onChanged: (value) =>
                            setSheetState(() => biometricEnabled = value),
                      ),
                  ],
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final name = profileName.trim();
                      if (name.isEmpty) return;
                      if (addLock && (pin.length != 6 || pin != repeatedPin)) {
                        setSheetState(() {
                          pinError = pin.length != 6
                              ? 'PIN 6 haneli olmalıdır.'
                              : 'PIN’ler eşleşmiyor.';
                        });
                        return;
                      }
                      Navigator.pop(
                        context,
                        _ProfileFormResult(
                          name: name,
                          colorValue: colorValue,
                          iconKey: iconKey,
                          pin: addLock ? pin : null,
                          biometricEnabled: addLock && biometricEnabled,
                        ),
                      );
                    },
                    child: Text(profile == null ? 'Profil Oluştur' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      if (profile == null) {
        final id = await PortfolioProfileService.instance.createProfile(
          name: result.name,
          colorValue: result.colorValue,
          iconKey: result.iconKey,
        );
        if (result.pin != null) {
          await ProfileLockService.instance.setLock(
            id,
            result.pin!,
            biometricEnabled: result.biometricEnabled,
          );
        }
        // Aktif profil bildirimini bu route kapanırken göndermek Flutter'ın
        // inherited bağımlılık ağacıyla çakışabiliyor. Seçilecek kimliği üst
        // sayfaya döndür; route tamamen dispose edildikten sonra etkinleştir.
        if (context.mounted) Navigator.pop(context, id);
      } else {
        await PortfolioProfileService.instance.updateProfile(
          profile.id,
          name: result.name,
          colorValue: result.colorValue,
          iconKey: result.iconKey,
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil kaydedilemedi: $error')));
    }
  }

  Future<void> _delete(BuildContext context, PortfolioProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('${profile.name} silinsin mi?'),
        content: const Text(
          'Bu profile ait portföy, işlemler, nakit ve geçmiş verileri silinir. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Profili Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PortfolioProfileService.instance.deleteProfile(profile.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _configureLock(
    BuildContext context,
    PortfolioProfile profile,
  ) async {
    final lockService = ProfileLockService.instance;
    final hasLock = await lockService.hasLock(profile.id);
    if (!context.mounted) return;

    if (hasLock) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text('${profile.name} profil kilidi'),
          content: const Text(
            'PIN’i değiştirebilir veya bu profil için kilidi kaldırabilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'forgot'),
              child: const Text('PIN’i Unuttum'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'remove'),
              child: const Text('Kilidi Kaldır'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'change'),
              child: const Text('PIN’i Değiştir'),
            ),
          ],
        ),
      );
      if (action == null || !context.mounted) return;
      if (action == 'forgot') {
        await _resetForgottenPin(context, profile);
        return;
      }
      if (action == 'remove') {
        final unlocked = await _unlockProfile(context, profile);
        if (!unlocked || !context.mounted) return;
        await lockService.removeLock(profile.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil kilidi kaldırıldı.')),
          );
        }
        return;
      }
      final unlocked = await _unlockProfile(context, profile);
      if (!unlocked || !context.mounted) return;
    }

    final canUseBiometrics = await lockService.canUseBiometrics();
    if (!context.mounted) return;
    var firstPin = '';
    var secondPin = '';
    var useBiometrics = canUseBiometrics;
    String? validationError;
    final result = await showDialog<_PinSetupResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(hasLock ? 'Yeni PIN belirle' : 'Profil kilidi ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${profile.name} için 6 haneli bir PIN belirleyin.',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => firstPin = value,
                decoration: const InputDecoration(
                  labelText: '6 haneli PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => secondPin = value,
                decoration: InputDecoration(
                  labelText: 'PIN’i tekrar girin',
                  border: const OutlineInputBorder(),
                  errorText: validationError,
                ),
              ),
              if (canUseBiometrics)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Face ID / Touch ID'),
                  subtitle: const Text('Biyometriyle açmaya izin ver'),
                  value: useBiometrics,
                  onChanged: (value) =>
                      setDialogState(() => useBiometrics = value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (firstPin.length != 6 || firstPin != secondPin) {
                  setDialogState(() {
                    validationError = firstPin.length != 6
                        ? 'PIN 6 haneli olmalıdır.'
                        : 'PIN’ler eşleşmiyor.';
                  });
                  return;
                }
                Navigator.pop(
                  context,
                  _PinSetupResult(firstPin, useBiometrics),
                );
              },
              child: const Text('Kilidi Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await lockService.setLock(
      profile.id,
      result.pin,
      biometricEnabled: result.biometricEnabled,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil kilidi etkinleştirildi.')),
      );
    }
  }

  Future<bool> _unlockProfile(
    BuildContext context,
    PortfolioProfile profile,
  ) async {
    final lockService = ProfileLockService.instance;
    if (!await lockService.hasLock(profile.id)) return true;
    if (!context.mounted) return false;

    final biometricEnabled =
        await lockService.isBiometricEnabled(profile.id) &&
        await lockService.canUseBiometrics();
    if (biometricEnabled &&
        await lockService.authenticateBiometrically(profile.name)) {
      return true;
    }
    if (!context.mounted) return false;

    var pin = '';
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text('${profile.name} kilitli'),
          content: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => pin = value,
            onFieldSubmitted: (_) async {
              if (await lockService.verifyPin(profile.id, pin) &&
                  context.mounted) {
                Navigator.pop(context, 'verified');
              } else {
                setDialogState(() => errorText = 'PIN hatalı.');
              }
            },
            decoration: InputDecoration(
              labelText: 'Profil PIN’i',
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'forgot'),
              child: const Text('PIN’i Unuttum'),
            ),
            FilledButton(
              onPressed: () async {
                if (await lockService.verifyPin(profile.id, pin)) {
                  if (context.mounted) Navigator.pop(context, 'verified');
                } else {
                  setDialogState(() => errorText = 'PIN hatalı.');
                }
              },
              child: const Text('Profili Aç'),
            ),
          ],
        ),
      ),
    );
    if (result == 'verified') return true;
    if (result == 'forgot' && context.mounted) {
      return _resetForgottenPin(context, profile);
    }
    return false;
  }

  Future<bool> _resetForgottenPin(
    BuildContext context,
    PortfolioProfile profile,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final supportsPassword =
        user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
    if (user == null || email == null || !supportsPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu hesap parola ile giriş yapmıyor. PIN sıfırlama için hesap giriş yöntemiyle yeniden doğrulama gerekir.',
          ),
        ),
      );
      return false;
    }

    var password = '';
    var isVerifying = false;
    String? errorText;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Yönetici hesabını doğrula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$email hesabının giriş şifresini yazın. Doğrulama başarılı olursa ${profile.name} profilinin PIN’i sıfırlanır.',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                autofocus: true,
                obscureText: true,
                enabled: !isVerifying,
                onChanged: (value) => password = value,
                decoration: InputDecoration(
                  labelText: 'Hesap giriş şifresi',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      if (password.isEmpty) {
                        setDialogState(
                          () => errorText = 'Hesap şifresini girin.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isVerifying = true;
                        errorText = null;
                      });
                      try {
                        final credential = EmailAuthProvider.credential(
                          email: email,
                          password: password,
                        );
                        await user.reauthenticateWithCredential(credential);
                        await ProfileLockService.instance.removeLock(
                          profile.id,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } on FirebaseAuthException catch (error) {
                        setDialogState(() {
                          isVerifying = false;
                          errorText = switch (error.code) {
                            'wrong-password' ||
                            'invalid-credential' => 'Hesap şifresi hatalı.',
                            'too-many-requests' =>
                              'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.',
                            'network-request-failed' =>
                              'İnternet bağlantısı kurulamadı.',
                            _ => 'Hesap doğrulanamadı.',
                          };
                        });
                      }
                    },
              child: isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('PIN’i Sıfırla'),
            ),
          ],
        ),
      ),
    );
    if (verified == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN sıfırlandı. Profil kilidi kaldırıldı.'),
        ),
      );
    }
    return verified == true;
  }

  @override
  Widget build(BuildContext context) {
    final service = PortfolioProfileService.instance;
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Portföy Profilleri'),
      ),
      body: StreamBuilder<List<PortfolioProfile>>(
        stream: service.watchProfiles(),
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? const <PortfolioProfile>[];
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<String>(
            valueListenable: service.activeProfileId,
            builder: (context, activeId, child) => ValueListenableBuilder<int>(
              valueListenable: ProfileLockService.instance.lockRevision,
              builder: (context, lockRevision, child) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  const Text(
                    'Her profilin portföyü, nakdi, işlemleri ve analizleri tamamen ayrıdır.',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  for (final profile in profiles)
                    Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            profile.colorValue,
                          ).withValues(alpha: .14),
                          child: Icon(
                            _icon(profile.iconKey),
                            color: Color(profile.colorValue),
                          ),
                        ),
                        title: Text(profile.name),
                        subtitle: Text(
                          profile.id == activeId
                              ? 'Aktif profil'
                              : profile.isDefault
                              ? 'Varsayılan profil'
                              : 'Bağımsız portföy',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<bool>(
                              future: ProfileLockService.instance.hasLock(
                                profile.id,
                              ),
                              builder: (context, snapshot) =>
                                  snapshot.data == true
                                  ? const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (profile.id == activeId)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF16A34A),
                              ),
                            PopupMenuButton<String>(
                              color: Colors.white,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _edit(context, profile: profile);
                                }
                                if (value == 'lock') {
                                  _configureLock(context, profile);
                                }
                                if (value == 'delete') {
                                  _delete(context, profile);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Düzenle'),
                                ),
                                const PopupMenuItem(
                                  value: 'lock',
                                  child: Text('Profil Kilidi'),
                                ),
                                if (!profile.isDefault)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Sil'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: profile.id == activeId
                            ? null
                            : () async {
                                if (await _unlockProfile(context, profile) &&
                                    context.mounted) {
                                  Navigator.pop(context, profile.id);
                                }
                              },
                        onLongPress: () => _edit(context, profile: profile),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni Profil Oluştur'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileFormResult {
  const _ProfileFormResult({
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.pin,
    this.biometricEnabled = false,
  });

  final String name;
  final int colorValue;
  final String iconKey;
  final String? pin;
  final bool biometricEnabled;
}

class _PinSetupResult {
  const _PinSetupResult(this.pin, this.biometricEnabled);

  final String pin;
  final bool biometricEnabled;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/login_page.dart';
import '../../services/price_alert_service.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/no_animation_route.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/navigation/myfin_back_button.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../intelligence/intelligence_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  final bool showBottomNav;

  const SettingsPage({super.key, this.showBottomNav = true});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currency = 'TRY';
  bool _loadingPreferences = true;
  bool _requestingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final currency = await UserPreferencesService.instance.getPrimaryCurrency();
    if (!mounted) return;
    setState(() {
      _currency = currency;
      _loadingPreferences = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (_requestingNotifications) return;
    setState(() => _requestingNotifications = true);
    final allowed = await PriceAlertService.instance.requestPermission();
    if (!mounted) return;
    setState(() => _requestingNotifications = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowed
              ? 'Bildirim izni açık. Fiyat alarmları bildirim gönderebilir.'
              : 'Bildirim izni verilmedi. İzni cihaz ayarlarından açabilirsin.',
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre yenileme'),
        content: Text(
          '$email adresine şifre yenileme bağlantısı gönderilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre yenileme e-postası gönderildi.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-posta gönderilemedi: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _selectCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Ana para birimi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Yeni özet ve raporlarda kullanılacak tercih.'),
            ),
            for (final currency in const ['TRY', 'USD', 'EUR'])
              ListTile(
                leading: Icon(
                  currency == _currency
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: currency == _currency
                      ? const Color(0xFF008DB9)
                      : const Color(0xFF64748B),
                ),
                title: Text(currency),
                subtitle: Text(
                  currency == 'TRY'
                      ? 'Türk Lirası'
                      : currency == 'USD'
                      ? 'ABD Doları'
                      : 'Euro',
                ),
                onTap: () => Navigator.pop(context, currency),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected == null || selected == _currency) return;
    await UserPreferencesService.instance.setPrimaryCurrency(selected);
    if (!mounted) return;
    setState(() => _currency = selected);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Bu cihazdaki oturumun kapatılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      noAnimationRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Ayarlar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            const SectionTitle(title: 'Hesap'),
            const SizedBox(height: 12),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
                final name = user?.displayName?.trim();
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(
                    context,
                  ).push(noAnimationRoute(builder: (_) => const ProfilePage())),
                  child: SurfaceCard(
                    color: const Color(0xFFF1F5FF),
                    child: Row(
                      children: [
                        const IconBox(
                          icon: Icons.person_rounded,
                          color: Color(0xFF008DB9),
                          size: 52,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name?.isNotEmpty == true
                                    ? name!
                                    : 'MyFin kullanıcısı',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'E-posta bağlı değil',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Profili görüntüle ve düzenle',
                                style: TextStyle(
                                  color: Color(0xFF008DB9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Tercihler'),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Ana para birimi',
                    subtitle: _loadingPreferences ? 'Yükleniyor...' : _currency,
                    onTap: _loadingPreferences ? null : _selectCurrency,
                  ),
                  const ThinDivider(),
                  _SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Bildirimler',
                    subtitle: _requestingNotifications
                        ? 'İzin kontrol ediliyor...'
                        : 'Fiyat alarmları için izin ver',
                    onTap: _requestingNotifications
                        ? null
                        : _requestNotificationPermission,
                  ),
                  const ThinDivider(),
                  const _SettingsRow(
                    icon: Icons.palette_outlined,
                    title: 'Görünüm',
                    subtitle: 'Premium açık tema',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Güvenlik ve gizlilik'),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.lock_reset_rounded,
                    title: 'Şifremi yenile',
                    subtitle: 'E-postana güvenli bağlantı gönder',
                    onTap: _sendPasswordReset,
                  ),
                  const ThinDivider(),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik özeti',
                    subtitle: 'Verilerinin nasıl kullanıldığını gör',
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Gizlilik özeti'),
                        content: const Text(
                          'Portföy ve işlem verilerin hesabına bağlı olarak saklanır. '
                          'Fiyat alarmları bu cihazda tutulur. MyFin Intelligence verileri '
                          'yalnızca talep ettiğin analizleri oluşturmak için kullanır.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const ThinDivider(),
                  const _SettingsRow(
                    icon: Icons.delete_forever_outlined,
                    title: 'Hesabı sil',
                    subtitle: 'Güvenli veri silme altyapısıyla yakında',
                    destructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'MyFin'),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'MyFin Intelligence',
                    subtitle: 'AI analiz ve sohbet merkezi',
                    onTap: () => Navigator.of(context).push(
                      noAnimationRoute(
                        builder: (_) => const IntelligencePage(),
                      ),
                    ),
                  ),
                  const ThinDivider(),
                  const _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Uygulama sürümü',
                    subtitle: '1.0.0',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const MyFinBottomNav(selectedIndex: 4)
          : null,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF008DB9);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive ? color : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

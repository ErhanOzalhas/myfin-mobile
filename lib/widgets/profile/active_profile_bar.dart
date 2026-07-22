import 'package:flutter/material.dart';

import '../../models/portfolio_profile.dart';
import '../../screens/settings/portfolio_profiles_page.dart';
import '../../services/portfolio_profile_service.dart';
import '../../utils/no_animation_route.dart';

/// İç sayfalarda aktif portföy profilini sürekli görünür tutan küçük rozet.
class ActiveProfileBar extends StatelessWidget implements PreferredSizeWidget {
  const ActiveProfileBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(30);

  IconData _icon(String? key) => switch (key) {
    'family' => Icons.family_restroom_rounded,
    'child' => Icons.child_care_rounded,
    'wallet' => Icons.account_balance_wallet_rounded,
    _ => Icons.person_rounded,
  };

  Future<void> _selectProfile(BuildContext context) async {
    final selectedProfileId = await Navigator.of(context).push<String>(
      noAnimationRoute(builder: (_) => const PortfolioProfilesPage()),
    );
    if (selectedProfileId != null) {
      await PortfolioProfileService.instance.selectProfile(selectedProfileId);
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PortfolioProfileService.instance;
    return ValueListenableBuilder<String>(
      valueListenable: service.activeProfileId,
      builder: (context, activeId, child) =>
          StreamBuilder<List<PortfolioProfile>>(
            stream: service.watchProfiles(),
            builder: (context, snapshot) {
              PortfolioProfile? activeProfile;
              for (final profile
                  in snapshot.data ?? const <PortfolioProfile>[]) {
                if (profile.id == activeId) activeProfile = profile;
              }

              final color = Color(activeProfile?.colorValue ?? 0xFF0284C7);
              final name = activeProfile?.name ?? 'Kişisel';
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 55, bottom: 25),
                  child: Material(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _selectProfile(context),
                      borderRadius: BorderRadius.circular(5),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _icon(activeProfile?.iconKey),
                                size: 11,
                                color: color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Aktif profil: ',
                                style: TextStyle(
                                  color: color.withValues(alpha: .72),
                                  fontSize: 10,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.expand_more_rounded,
                                size: 12,
                                color: color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}

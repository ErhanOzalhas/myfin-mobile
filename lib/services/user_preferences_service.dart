import 'package:shared_preferences/shared_preferences.dart';

import 'portfolio_profile_service.dart';

class UserPreferencesService {
  UserPreferencesService._();

  static final UserPreferencesService instance = UserPreferencesService._();

  static const _currencyKey = 'myfin_primary_currency';
  static const _biometricKey = 'myfin_biometric_lock';
  String get _profileCurrencyKey =>
      '$_currencyKey::${PortfolioProfileService.instance.activeProfileId.value}';

  Future<String> getPrimaryCurrency() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_profileCurrencyKey) ??
        (PortfolioProfileService.instance.activeProfileId.value ==
                PortfolioProfileService.defaultProfileId
            ? preferences.getString(_currencyKey)
            : null) ??
        'TRY';
  }

  Future<void> setPrimaryCurrency(String currency) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileCurrencyKey, currency);
  }

  Future<bool> getBiometricLock() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_biometricKey) ?? false;
  }

  Future<void> setBiometricLock(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_biometricKey, enabled);
  }
}

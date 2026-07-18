import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  UserPreferencesService._();

  static final UserPreferencesService instance = UserPreferencesService._();

  static const _currencyKey = 'myfin_primary_currency';
  static const _biometricKey = 'myfin_biometric_lock';

  Future<String> getPrimaryCurrency() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_currencyKey) ?? 'TRY';
  }

  Future<void> setPrimaryCurrency(String currency) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currencyKey, currency);
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

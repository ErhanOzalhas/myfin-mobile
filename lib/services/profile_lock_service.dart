import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class ProfileLockService {
  ProfileLockService._();

  static final ProfileLockService instance = ProfileLockService._();

  static const _storage = FlutterSecureStorage();
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final ValueNotifier<int> lockRevision = ValueNotifier(0);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _pinKey(String uid, String profileId) =>
      'myfin_profile_pin::$uid::$profileId';

  String _biometricKey(String uid, String profileId) =>
      'myfin_profile_biometric::$uid::$profileId';

  Future<bool> hasLock(String profileId) async {
    final uid = _uid;
    if (uid == null) return false;
    return (await _storage.read(key: _pinKey(uid, profileId))) != null;
  }

  Future<void> setLock(
    String profileId,
    String pin, {
    required bool biometricEnabled,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Kullanıcı oturumu bulunamadı.');
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN 6 rakamdan oluşmalıdır.');
    }
    await _storage.write(key: _pinKey(uid, profileId), value: pin);
    await _storage.write(
      key: _biometricKey(uid, profileId),
      value: biometricEnabled ? 'true' : 'false',
    );
    lockRevision.value++;
  }

  Future<void> removeLock(String profileId) async {
    final uid = _uid;
    if (uid == null) return;
    await _storage.delete(key: _pinKey(uid, profileId));
    await _storage.delete(key: _biometricKey(uid, profileId));
    lockRevision.value++;
  }

  Future<bool> verifyPin(String profileId, String pin) async {
    final uid = _uid;
    if (uid == null) return false;
    final savedPin = await _storage.read(key: _pinKey(uid, profileId));
    return savedPin != null && savedPin == pin;
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuthentication.isDeviceSupported() &&
          await _localAuthentication.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled(String profileId) async {
    final uid = _uid;
    if (uid == null) return false;
    return await _storage.read(key: _biometricKey(uid, profileId)) == 'true';
  }

  Future<bool> authenticateBiometrically(String profileName) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: '$profileName profilini açmak için doğrulayın.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

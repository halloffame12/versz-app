import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _sessionKey = 'appwrite_session';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _selectedInterestsKey = 'selected_interests';

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<void> savePassword(String password) async {
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: _passwordKey);
  }

  Future<void> saveSession(String session) async {
    await _storage.write(key: _sessionKey, value: session);
  }

  Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _onboardingCompleteKey);
    await _storage.delete(key: _selectedInterestsKey);
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _storage.write(key: _onboardingCompleteKey, value: value ? 'true' : 'false');
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingCompleteKey);
    return value == 'true';
  }

  Future<void> saveSelectedInterests(List<String> interests) async {
    await _storage.write(key: _selectedInterestsKey, value: interests.join(','));
  }

  Future<List<String>> getSelectedInterests() async {
    final value = await _storage.read(key: _selectedInterestsKey);
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((e) => e.trim().isNotEmpty).toList();
  }
}

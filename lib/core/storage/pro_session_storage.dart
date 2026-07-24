import 'package:shared_preferences/shared_preferences.dart';

class ProSessionStorage {
  static const _keyToken = 'pro_access_token';
  static const _keyPhone = 'pro_user_phone';
  static const _keyEmail = 'pro_user_email';
  static const _keyName = 'pro_user_name';
  static const _keyGender = 'pro_user_gender';
  static const _keyUserId = 'pro_user_id';
  static const _keyAuthenticated = 'pro_is_authenticated';
  static const _keyIsOnline = 'pro_is_online';
  static const _keyVerificationStatus = 'pro_verification_status';
  static const _keyCoverageRadiusKm = 'pro_coverage_radius_km';
  static const _keyAge = 'pro_user_age';
  static const _keyServiceArea = 'pro_service_area';
  static const _keyOnboardingComplete = 'pro_is_onboarding_complete';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isAuthenticated => _prefs?.getBool(_keyAuthenticated) ?? false;
  static String? get authToken => _prefs?.getString(_keyToken);
  static String get userPhone => _prefs?.getString(_keyPhone) ?? '';
  static String get userEmail => _prefs?.getString(_keyEmail) ?? '';
  static String get userName => _prefs?.getString(_keyName) ?? 'Professional';
  static String get gender => _prefs?.getString(_keyGender) ?? 'OTHER';
  static String? get userId => _prefs?.getString(_keyUserId);
  static bool get isOnline => _prefs?.getBool(_keyIsOnline) ?? false;
  static String get verificationStatus => _prefs?.getString(_keyVerificationStatus) ?? 'PENDING';
  static double get coverageRadiusKm => _prefs?.getDouble(_keyCoverageRadiusKm) ?? 50.0;
  static int get age => _prefs?.getInt(_keyAge) ?? 0;
  static String get serviceArea => _prefs?.getString(_keyServiceArea) ?? 'Bangalore';
  static bool get isOnboardingComplete => _prefs?.getBool(_keyOnboardingComplete) ?? false;

  static Future<void> setSession({
    required String token,
    required String phone,
    String? email,
    String name = 'Professional',
    String gender = 'OTHER',
    String? userId,
    String verificationStatus = 'PENDING',
    double coverageRadiusKm = 50.0,
    int? age,
    String? serviceArea,
    bool? isOnboardingComplete,
  }) async {
    await _prefs?.setBool(_keyAuthenticated, true);
    await _prefs?.setString(_keyToken, token);
    await _prefs?.setString(_keyPhone, phone);
    if (email != null) await _prefs?.setString(_keyEmail, email);
    await _prefs?.setString(_keyName, name);
    await _prefs?.setString(_keyGender, gender);
    if (userId != null) await _prefs?.setString(_keyUserId, userId);
    await _prefs?.setString(_keyVerificationStatus, verificationStatus);
    await _prefs?.setDouble(_keyCoverageRadiusKm, coverageRadiusKm);
    if (age != null) await _prefs?.setInt(_keyAge, age);
    if (serviceArea != null) await _prefs?.setString(_keyServiceArea, serviceArea);
    if (isOnboardingComplete != null) {
      await _prefs?.setBool(_keyOnboardingComplete, isOnboardingComplete);
    }
  }

  static Future<void> setIsOnboardingComplete(bool complete) async {
    await _prefs?.setBool(_keyOnboardingComplete, complete);
  }

  static Future<void> updateVerificationStatus(String status) async {
    await _prefs?.setString(_keyVerificationStatus, status);
  }

  static Future<void> setOnlineStatus(bool isOnline) async {
    await _prefs?.setBool(_keyIsOnline, isOnline);
  }

  static Future<void> clearSession() async {
    await _prefs?.clear();
  }
}

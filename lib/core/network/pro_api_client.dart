import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/pro_session_storage.dart';

class ProApiClient {
  static String _defaultBaseUrl() {
    return 'http://192.168.1.2:8000';
  }

  static String baseUrl = _defaultBaseUrl();

  static void updateBaseUrl(String url) {
    baseUrl = url.startsWith('http') ? url.trim() : 'http://$url';
  }

  static Map<String, String> get _publicHeaders =>
      {'Content-Type': 'application/json'};

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (ProSessionStorage.authToken != null)
          'Authorization': 'Bearer ${ProSessionStorage.authToken}',
      };

  /// Dynamic fast-fail request handler with multi-host probe sequence
  /// Ensures physical devices (e.g., Samsung on Wi-Fi), emulators, and desktop all resolve cleanly.
  static Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String currentUrl) requestFn,
  ) async {
    final candidateUrls = <String>{
      baseUrl,
      'http://192.168.1.2:8000',
      'http://10.0.2.2:8000',
      'http://127.0.0.1:8000',
      'http://localhost:8000',
      'http://192.168.1.8:8000',
    }.toList();

    Object? lastError;

    for (final candidate in candidateUrls) {
      try {
        final response = await requestFn(candidate).timeout(const Duration(seconds: 3));
        final bodyStr = response.body.trim();
        final isHtml = bodyStr.startsWith('<!DOCTYPE') ||
            bodyStr.startsWith('<html') ||
            (response.headers['content-type']?.contains('text/html') ?? false);

        if (isHtml) {
          lastError = Exception('Received HTML response from $candidate');
          continue;
        }

        baseUrl = candidate; // Retain active working gateway URL
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      if (lastError.toString().contains('Socket') ||
          lastError.toString().contains('No route to host') ||
          lastError.toString().contains('TimeoutException')) {
        throw Exception(
          'Backend API Gateway unreachable at $baseUrl. Ensure ./run-all.sh is running in backend directory and phone is on same Wi-Fi network.',
        );
      }
      throw lastError;
    }

    throw Exception('Connection failed');
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// Register new professional with Email, Password, Mobile, Full Name, Gender
  static Future<Map<String, dynamic>> registerPro({
    required String email,
    required String password,
    required String phoneNumber,
    required String fullName,
    required String gender,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/pro/register'),
          headers: _publicHeaders,
          body: jsonEncode({
            'email': email,
            'password': password,
            'phoneNumber': phoneNumber,
            'fullName': fullName,
            'gender': gender,
          }),
        ));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Registration failed (${res.statusCode})');
  }

  /// Login existing professional with Email & Password
  static Future<Map<String, dynamic>> loginPro({
    required String email,
    required String password,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/pro/login'),
          headers: _publicHeaders,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid email or password');
  }

  /// Send Phone OTP Code
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber, {bool isSignInMode = false}) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/otp/send'),
          headers: _publicHeaders,
          body: jsonEncode({
            'phoneNumber': phoneNumber,
            'checkRegistered': isSignInMode,
            'isSignInMode': isSignInMode,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send OTP');
  }

  /// Verify Phone OTP Code
  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String fullName = 'Professional',
    String gender = 'OTHER',
    bool isSignInMode = false,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/otp/verify'),
          headers: _publicHeaders,
          body: jsonEncode({
            'phoneNumber': phoneNumber,
            'otp': otp,
            'role': 'PROFESSIONAL',
            'fullName': fullName,
            'gender': gender,
            'isSignInMode': isSignInMode,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid OTP code');
  }

  static Future<Map<String, dynamic>> registerProWithPhone({
    required String fullName,
    required String phoneNumber,
    required String serviceArea,
    String? categoryId,
    String? email,
    String gender = 'OTHER',
    int? age,
    String? sex,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/pro/register-phone'),
          headers: _publicHeaders,
          body: jsonEncode({
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'serviceArea': serviceArea,
            'categoryId': categoryId,
            'role': 'PROFESSIONAL',
            if (email != null) 'email': email,
            'gender': gender,
            if (age != null) 'age': age,
            if (sex != null) 'sex': sex,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Failed to register professional profile');
  }

  /// Send Email Code
  static Future<Map<String, dynamic>> sendEmailCode(String email) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/email/send'),
          headers: _publicHeaders,
          body: jsonEncode({'email': email}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send email verification');
  }

  /// Verify Email Code
  static Future<Map<String, dynamic>> verifyEmailCode(String email, String code) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/email/verify'),
          headers: _publicHeaders,
          body: jsonEncode({'email': email, 'code': code}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid email verification code');
  }

  // ─── PROFESSIONAL PROFILE & DOCUMENTS ─────────────────────────────────────

  /// Fetch full professional profile, verification status, and offered services
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/profile'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load profile');
  }

  /// Fetch Account Health & Rating Metrics
  static Future<Map<String, dynamic>> getProHealth() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/health'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load health');
  }

  /// Submit Verification Documents (Govt ID, Police Clearance PDF, Face Selfie)
  /// Triggers re-verification and sets status to PENDING until Admin approves.
  static Future<Map<String, dynamic>> submitDocuments({
    required String govtIdType,
    required String govtIdNumber,
    String? govtIdUrl,
    String? policeVerificationUrl,
    String? faceSelfieUrl,
    List<String>? certifications,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/documents'),
          headers: _authHeaders,
          body: jsonEncode({
            'govtIdType': govtIdType,
            'govtIdNumber': govtIdNumber,
            'govtIdUrl': govtIdUrl,
            'policeVerificationUrl': policeVerificationUrl,
            'faceSelfieUrl': faceSelfieUrl,
            'certifications': certifications ?? [],
          }),
        ));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to submit verification documents');
  }

  /// Save Offered Services & Custom Pricing Rate
  static Future<List<dynamic>> saveOfferedServices(List<Map<String, dynamic>> services) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/offered-services'),
          headers: _authHeaders,
          body: jsonEncode({'services': services}),
        ));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to save offered services');
  }

  static Future<void> updateCustomServicePrice(String serviceId, double customPrice) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/offered-services/update-price'),
          headers: _authHeaders,
          body: jsonEncode({
            'serviceId': serviceId,
            'customPrice': customPrice,
          }),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to update custom price');
    }
  }

  static Future<void> toggleOfferedServiceStatus(String serviceId, bool isActive) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/offered-services/toggle'),
          headers: _authHeaders,
          body: jsonEncode({
            'serviceId': serviceId,
            'isActive': isActive,
          }),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to toggle service status');
    }
  }

  static Future<void> deleteOfferedService(String serviceId) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/offered-services/delete'),
          headers: _authHeaders,
          body: jsonEncode({
            'serviceId': serviceId,
          }),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to delete service');
    }
  }

  static Future<void> toggleCustomServiceStatus(String requestId, bool isActive) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/custom-services/toggle'),
          headers: _authHeaders,
          body: jsonEncode({
            'requestId': requestId,
            'isActive': isActive,
          }),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to toggle custom service status');
    }
  }

  /// Admin Verify / Approve Professional (Used by Super Admin or Demo test action)
  static Future<void> adminVerifyPro(String userId, String status) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/admin/pro/$userId/verify'),
          headers: _authHeaders,
          body: jsonEncode({'status': status, 'notes': 'Approved by verification pipeline audit'}),
        ));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to update verification status');
    }
  }

  // ─── BOOKINGS & JOBS ──────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyJobs() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/bookings/my-bookings'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load jobs');
  }

  static Future<void> acceptJob(String bookingId) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/accept'),
          headers: _authHeaders,
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to accept job');
    }
  }

  static Future<void> verifyStartOtp({
    required String bookingId,
    required String otp,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/start'),
          headers: _authHeaders,
          body: jsonEncode({'otp': otp}),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Invalid Start OTP code');
    }
  }

  static Future<void> verifyEndOtp({
    required String bookingId,
    required String otp,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/complete'),
          headers: _authHeaders,
          body: jsonEncode({'otp': otp}),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Invalid End OTP code');
    }
  }

  // ─── DUTY & LOCATION ──────────────────────────────────────────────────────

  static Future<void> updateOnlineStatus(bool isOnline, {double? latitude, double? longitude}) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/duty-status'),
          headers: _authHeaders,
          body: jsonEncode({
            'isOnline': isOnline,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ));

    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Cannot toggle duty status');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception('Duty status update failed (${res.statusCode})');
      }
    }
  }

  static Future<void> triggerSos({
    required double latitude,
    required double longitude,
    String? bookingId,
    String notes = 'Provider Emergency SOS',
  }) async {
    await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/safety/sos/trigger'),
          headers: _authHeaders,
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'notes': notes,
            if (bookingId != null) 'bookingId': bookingId,
          }),
        ));
  }

  // ─── DOCUMENT UPLOADS ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadDocument({
    required String fileName,
    required String fileData,
    required String docType,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/upload-doc'),
          headers: _authHeaders,
          body: jsonEncode({
            'fileName': fileName,
            'fileData': fileData,
            'docType': docType,
            if (ProSessionStorage.userId != null) 'userId': ProSessionStorage.userId,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to upload document');
  }

  // ─── SERVICES & RATES ──────────────────────────────────────────────────────



  static Future<Map<String, dynamic>> requestCustomService({
    required String serviceName,
    String? description,
    double? suggestedPrice,
    String? categoryId,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/request-service'),
          headers: _authHeaders,
          body: jsonEncode({
            'serviceName': serviceName,
            'description': description,
            if (suggestedPrice != null) 'suggestedPrice': suggestedPrice,
            if (categoryId != null) 'categoryId': categoryId,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return (body['data'] as Map<String, dynamic>?) ?? Map<String, dynamic>.from(body);
    throw Exception(body['message'] ?? body['error']?['message'] ?? 'Failed to submit service request');
  }

  static Future<List<dynamic>> getMyCustomServiceRequests() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/custom-services/my-requests'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    return [];
  }

  static Future<List<dynamic>> getMyServiceRequests() async => getMyCustomServiceRequests();

  static Future<List<dynamic>> getCatalogServices({String? categoryId}) async {
    final res = await _requestWithFallback((url) {
      final uri = categoryId != null
          ? '$url/api/v1/catalog/services?categoryId=$categoryId'
          : '$url/api/v1/catalog/services';
      return http.get(Uri.parse(uri), headers: _publicHeaders);
    });
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load catalog services');
  }
}

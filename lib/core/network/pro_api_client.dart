import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/pro_session_storage.dart';

class ProApiClient {
  static String _defaultBaseUrl() => 'http://192.168.1.2:8000';
  static String baseUrl = _defaultBaseUrl();

  static void updateBaseUrl(String url) {
    baseUrl = url.startsWith('http') ? url.trim() : 'http://$url';
  }

  static Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (ProSessionStorage.authToken != null)
          'Authorization': 'Bearer ${ProSessionStorage.authToken}',
      };

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
        final response = await requestFn(candidate).timeout(const Duration(seconds: 5));
        baseUrl = candidate;
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

  /// Send OTP to mobile number
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/otp/send'),
          headers: _publicHeaders,
          body: jsonEncode({'phoneNumber': phoneNumber}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to send OTP');
  }

  /// Verify OTP (sign in / base user creation)
  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/otp/verify'),
          headers: _publicHeaders,
          body: jsonEncode({
            'phoneNumber': phoneNumber,
            'otp': otp,
            'role': 'PROFESSIONAL',
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid OTP');
  }

  /// Register professional with full profile fields (Step 2)
  static Future<Map<String, dynamic>> registerProWithPhone({
    required String phoneNumber,
    required String fullName,
    required int age,
    required String email,
    required String gender,
    required String serviceArea,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/pro/register-phone'),
          headers: _authHeaders,
          body: jsonEncode({
            'phoneNumber': phoneNumber,
            'fullName': fullName,
            'age': age,
            'email': email,
            'gender': gender,
            'serviceArea': serviceArea,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Registration failed');
  }

  /// Send Email Verification Code
  static Future<Map<String, dynamic>> sendEmailCode(String email) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/email/send'),
          headers: _authHeaders,
          body: jsonEncode({'email': email}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send email code');
  }

  /// Verify Email Code
  static Future<Map<String, dynamic>> verifyEmailCode(String email, String code) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/auth/email/verify'),
          headers: _authHeaders,
          body: jsonEncode({'email': email, 'code': code}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid code');
  }

  // ─── VERIFICATION DOCUMENTS & FILE STORAGE ─────────────────────────────────

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
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to upload document');
  }

  // ─── PROFESSIONAL PROFILE ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/profile'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load profile');
  }

  static Future<Map<String, dynamic>> getProHealth() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/health'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load health metrics');
  }

  static Future<Map<String, dynamic>> submitDocuments({
    required String govtIdType,
    required String govtIdNumber,
    String? govtIdUrl,
    String? policeVerificationUrl,
    String? faceSelfieUrl,
    List<String>? certifications,
    String? location,
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
            'location': location,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to submit documents');
  }

  static Future<Map<String, dynamic>> requestLocationChange({
    required String requestedLocation,
    String? reason,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/location-change-request'),
          headers: _authHeaders,
          body: jsonEncode({
            'requestedLocation': requestedLocation,
            'reason': reason,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Failed to submit location change request');
  }

  static Future<List<dynamic>> saveOfferedServices(List<Map<String, dynamic>> services) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/offered-services'),
          headers: _authHeaders,
          body: jsonEncode({'services': services}),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to save services');
  }

  // ─── CUSTOM SERVICE REQUEST ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> requestCustomService({
    required String serviceName,
    String? description,
    double? suggestedPrice,
    String? categoryId,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/service-request'),
          headers: _authHeaders,
          body: jsonEncode({
            'serviceName': serviceName,
            'description': description,
            'suggestedPrice': suggestedPrice,
            'categoryId': categoryId,
          }),
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to submit service request');
  }

  static Future<List<dynamic>> getMyServiceRequests() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/service-requests'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load service requests');
  }

  // ─── JOBS & INVITES ────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyJobs() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/bookings/my-bookings'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load jobs');
  }

  static Future<List<dynamic>> getJobInvites() async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/pro/job-invites'),
          headers: _authHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load invites');
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

  static Future<void> rejectJob(String bookingId) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/reject'),
          headers: _authHeaders,
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to reject job');
    }
  }

  static Future<void> verifyStartOtp({required String bookingId, required String otp}) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/start'),
          headers: _authHeaders,
          body: jsonEncode({'otp': otp}),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Invalid Start OTP');
    }
  }

  static Future<void> verifyEndOtp({required String bookingId, required String otp}) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/bookings/$bookingId/complete'),
          headers: _authHeaders,
          body: jsonEncode({'otp': otp}),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Invalid End OTP');
    }
  }

  // ─── DUTY & LOCATION ──────────────────────────────────────────────────────

  static Future<void> updateOnlineStatus(bool isOnline, {double? latitude, double? longitude}) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/pro/status'),
          headers: _authHeaders,
          body: jsonEncode({
            'isOnline': isOnline,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Cannot toggle duty status');
    }
  }

  // ─── SAFETY ───────────────────────────────────────────────────────────────

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

  // ─── ADMIN SIMULATION ──────────────────────────────────────────────────────

  static Future<void> adminVerifyPro(String userId, String status) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/pro/verify-audit'),
      headers: _publicHeaders,
      body: jsonEncode({'userId': userId, 'status': status}),
    ));
    if (res.statusCode != 200) {
      // Local fallback OK
    }
  }

  // ─── CATALOG ──────────────────────────────────────────────────────────────

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

  // ─── SETTINGS ─────────────────────────────────────────────────────────────

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final res = await _requestWithFallback((url) => http.post(
          Uri.parse('$url/api/v1/users/change-password'),
          headers: _authHeaders,
          body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
        ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to change password');
    }
  }
}

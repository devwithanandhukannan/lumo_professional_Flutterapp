import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../earnings/pro_earnings_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../onboarding/pro_document_upload_screen.dart';
import '../safety/pro_sos_widget.dart';

class ProDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProDashboardScreen({super.key, required this.onLogout});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  bool _isOnline = false;
  bool _togglingOnline = false;

  Map<String, dynamic>? _health;
  List<dynamic> _jobs = [];
  bool _loadingJobs = true;
  Timer? _pollTimer;
  Map<String, dynamic>? _activeSuspension;
  int _selectedJobTabIndex = 0; // 0: Active & Pending, 1: Expired & History

  @override
  void initState() {
    super.initState();
    _isOnline = ProSessionStorage.isOnline;
    _loadData();
    _checkSuspension();
    _startAutoPolling();
  }

  Future<void> _checkSuspension() async {
    try {
      final profileRes = await ProApiClient.getProfile();
      final pro = profileRes['profile'] ?? profileRes['data']?['profile'] ?? profileRes['data'] ?? {};
      
      final lat = (pro['latitude'] != null) ? double.tryParse(pro['latitude'].toString()) ?? ProSessionStorage.currentLat ?? 12.9716 : ProSessionStorage.currentLat ?? 12.9716;
      final lng = (pro['longitude'] != null) ? double.tryParse(pro['longitude'].toString()) ?? ProSessionStorage.currentLng ?? 77.5946 : ProSessionStorage.currentLng ?? 77.5946;
      final String locName = (pro['assigned_region'] ?? pro['service_area'] ?? pro['address'] ?? ProSessionStorage.serviceArea).toString();
      final String? pincode = pro['pincode']?.toString();

      final suspension = await ProApiClient.checkProServiceSuspension(
        latitude: lat,
        longitude: lng,
        locationName: locName,
        pincode: pincode,
      );
      if (mounted) {
        setState(() => _activeSuspension = suspension);
        if (suspension != null && suspension['severity'] == 'FULL_BLACKOUT' && _isOnline) {
          await ProApiClient.updateOnlineStatus(false);
          await ProSessionStorage.setOnlineStatus(false);
          setState(() => _isOnline = false);
        }
      }
    } catch (_) {
      final lat = ProSessionStorage.currentLat ?? 12.9716;
      final lng = ProSessionStorage.currentLng ?? 77.5946;
      final suspension = await ProApiClient.checkProServiceSuspension(
        latitude: lat,
        longitude: lng,
        locationName: ProSessionStorage.serviceArea,
      );
      if (mounted) {
        setState(() => _activeSuspension = suspension);
        if (suspension != null && suspension['severity'] == 'FULL_BLACKOUT' && _isOnline) {
          await ProApiClient.updateOnlineStatus(false);
          await ProSessionStorage.setOnlineStatus(false);
          setState(() => _isOnline = false);
        }
      }
    }
  }

  void _startAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _isOnline) {
        _pollJobs();
      }
    });
  }

  Future<void> _pollJobs() async {
    try {
      final jobs = await ProApiClient.getMyJobs();
      if (!mounted) return;

      final oldRequestedIds = _jobs
          .where((j) => (j['status']?.toString() ?? '').toUpperCase() == 'REQUESTED')
          .map((j) => j['id']?.toString() ?? '')
          .toSet();

      final newRequestedJobs = jobs
          .where((j) => (j['status']?.toString() ?? '').toUpperCase() == 'REQUESTED' && !oldRequestedIds.contains(j['id']?.toString() ?? ''))
          .toList();

      if (newRequestedJobs.isNotEmpty && _jobs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: ProColors.warningAmber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ NEW INSTANT REQUEST: ${newRequestedJobs.first['service_name'] ?? 'Service Request'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: ProColors.cardBg,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      setState(() {
        _jobs = jobs;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingJobs = true);

    try {
      final profileRes = await ProApiClient.getProfile();
      final pro = profileRes['profile'] ?? profileRes['data']?['profile'] ?? profileRes['data'] ?? {};
      final latestStatus = pro['verification_status']?.toString() ?? profileRes['verificationStatus']?.toString() ?? 'PENDING';
      await ProSessionStorage.updateVerificationStatus(latestStatus);
    } catch (_) {}

    try {
      final health = await ProApiClient.getProHealth();
      if (mounted) setState(() => _health = health);
    } catch (_) {
      if (mounted) {
        setState(() => _health = {
          'accountHealthScore': 100.0,
          'ratingAvg': 5.0,
          'totalJobsCompleted': 0,
          'acceptanceRate': 100.0,
          'verificationStatus': ProSessionStorage.verificationStatus,
          'coverageRadiusKm': ProSessionStorage.coverageRadiusKm,
        });
      }
    }

    try {
      final jobs = await ProApiClient.getMyJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (_) {
      if (mounted) setState(() => _jobs = []);
    } finally {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<void> _toggleOnline(bool val) async {
    setState(() => _togglingOnline = true);

    if (val) {
      await _checkSuspension();
    }

    String currentStatus = ProSessionStorage.verificationStatus;
    try {
      final profileRes = await ProApiClient.getProfile();
      final pro = profileRes['profile'] ?? profileRes['data']?['profile'] ?? profileRes['data'] ?? {};
      if (pro['verification_status'] != null) {
        currentStatus = pro['verification_status'].toString();
        await ProSessionStorage.updateVerificationStatus(currentStatus);
      }
    } catch (_) {}

    if (val && _activeSuspension != null && (_activeSuspension!['severity'] == 'FULL_BLACKOUT' || _activeSuspension!['severity'] == null)) {
      setState(() => _togglingOnline = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ProColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Emergency Service Closure', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeSuspension!['message'] ?? 'Service is currently paused in your area due to emergency blackout rules.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF34D399), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Location: ${_activeSuspension!['areaName'] ?? 'Fenced Blackout Zone'}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: ProColors.warningAmber, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _activeSuspension!['expiresAt'] != null
                                  ? 'Resumption: ${DateTime.parse(_activeSuspension!['expiresAt']).toLocal().toString().substring(0, 16)}'
                                  : 'Resumption: Indefinite / Active Safety Monitoring',
                              style: const TextStyle(color: ProColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK, Got It', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (val && currentStatus != 'APPROVED') {
      setState(() => _togglingOnline = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ProColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock_outlined, color: ProColors.warningAmber, size: 24),
                SizedBox(width: 8),
                Text('Account Verification Required', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Cannot go online. Account verification status is $currentStatus. Super Admin document audit and approval required before starting duty.',
              style: ProText.caption,
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: ProColors.primary, foregroundColor: Colors.white),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      await ProApiClient.updateOnlineStatus(val);
      await ProSessionStorage.setOnlineStatus(val);
      if (mounted) setState(() => _isOnline = val);
    } catch (e) {
      await ProSessionStorage.setOnlineStatus(!val);
      if (mounted) {
        setState(() => _isOnline = !val);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duty status update failed: $e'), backgroundColor: ProColors.emergencyRed),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  Future<void> _acceptJob(String bookingId) async {
    try {
      await ProApiClient.acceptJob(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Job Accepted! Live navigation active.'), backgroundColor: ProColors.primary),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job: ${e.toString()}'), backgroundColor: ProColors.emergencyRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String proName = ProSessionStorage.userName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOnline ? ProColors.primary : ProColors.textMuted,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isOnline) const BoxShadow(color: ProColors.primary, blurRadius: 8, spreadRadius: 2),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner Portal · $proName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_isOnline ? 'ONLINE & RECEIVING JOBS' : 'OFFLINE (ON-DUTY TOGGLE OFF)', style: TextStyle(fontSize: 10, color: _isOnline ? ProColors.primary : ProColors.textMuted, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, color: ProColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProEarningsScreen()),
              );
            },
            tooltip: 'Earnings Ledger',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh Jobs',
          ),
        ],
      ),
      floatingActionButton: null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: ProColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_activeSuspension != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x55EF4444), Color(0x221E1B4B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xAAEF4444), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33EF4444),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  (_activeSuspension!['reasonCategory'] ?? 'EMERGENCY').toString().replaceAll('_', ' '),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activeSuspension!['title'] ?? 'Emergency Regional Closure',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF34D399), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'FENCED LOCATION NAME:',
                                    style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    (_activeSuspension!['areaName'] ?? _activeSuspension!['title'] ?? ProSessionStorage.serviceArea).toString(),
                                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeSuspension!['message'] ?? 'Service is temporarily paused in your region for partner safety.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: ProColors.warningAmber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _activeSuspension!['expiresAt'] != null
                                    ? 'Expected Resumption: ${DateTime.parse(_activeSuspension!['expiresAt']).toLocal().toString().substring(0, 16)}'
                                    : 'Resumption: Indefinite / Active Safety Monitoring',
                                style: const TextStyle(color: ProColors.warningAmber, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 14),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'On-Duty mode is locked in this region to protect partner safety.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if ((_health?['verificationStatus'] ?? ProSessionStorage.verificationStatus) == 'REJECTED') ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x33EF4444), Color(0x1AEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x88EF4444)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x33EF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'APPLICATION RETURNED FOR CORRECTION',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Super Admin requested document re-upload. Please upload clear photos of your Govt ID and Certificate.',
                                  style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProDocumentUploadScreen(
                                  onCompleted: () {
                                    Navigator.pop(context);
                                    _loadData();
                                  },
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('RE-UPLOAD DOCUMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if ((_health?['verificationStatus'] ?? ProSessionStorage.verificationStatus) == 'PENDING') ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ProColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ProColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: ProColors.warningAmber, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFICATION PENDING AUDIT',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your profile details & documents are under review by Super Admin. You will be notified once approved to receive bookings.',
                              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ProColors.cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _isOnline ? ProColors.primary : ProColors.border, width: _isOnline ? 1.5 : 1),
                  boxShadow: [
                    if (_isOnline) const BoxShadow(color: Color(0x3310B981), blurRadius: 18, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isOnline ? ProColors.primarySoft : ProColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                        color: _isOnline ? ProColors.primary : ProColors.textMuted,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'YOU ARE ON-DUTY' : 'YOU ARE OFF-DUTY',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _isOnline ? Colors.white : ProColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline ? 'Broadcast live GPS telemetry to receive nearby job dispatches' : 'Toggle switch ON to start receiving nearby customer bookings',
                            style: ProText.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _togglingOnline
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: ProColors.primary, strokeWidth: 2.5))
                        : Switch(
                            value: _isOnline,
                            activeTrackColor: ProColors.primary,
                            onChanged: _toggleOnline,
                          ),
                  ],
                ),
              ),

              if (_isOnline) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x22EF4444),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x66EF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      const Text(
                        '24/7 SOS MONITORING',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProSosWidget(isFullScreenModal: true),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Color(0x44EF4444), blurRadius: 8)],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.sos_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ProColors.surface, ProColors.cardBg]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProColors.border),
                ),
                child: Builder(
                  builder: (context) {
                    double todayTotal = 0.0;
                    for (final j in _jobs) {
                      if (j['status'] == 'COMPLETED') {
                        todayTotal += (double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0.0);
                      }
                    }
                    final healthScore = (_health?['accountHealthScore'] as num?)?.toInt() ?? (_health?['account_health_score'] as num?)?.toInt() ?? 100;
                    final ratingAvg = _health?['ratingAvg'] ?? _health?['rating_avg'] ?? '5.0';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickSummaryItem(
                          label: "TODAY'S EARNINGS",
                          value: '₹${todayTotal.toStringAsFixed(2)}',
                          icon: Icons.account_balance_wallet,
                          color: ProColors.primary,
                        ),
                        Container(width: 1, height: 36, color: ProColors.border),
                        _QuickSummaryItem(
                          label: 'ACCOUNT HEALTH',
                          value: '$healthScore / 100',
                          icon: Icons.shield_rounded,
                          color: ProColors.accent,
                        ),
                        Container(width: 1, height: 36, color: ProColors.border),
                        _QuickSummaryItem(
                          label: 'AVG RATING',
                          value: '⭐ $ratingAvg',
                          color: ProColors.warningAmber,
                          icon: Icons.star_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('JOB DISPATCHES', style: ProText.label),
                  Text('Live GPS Telemetry Active', style: TextStyle(fontSize: 10, color: ProColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              Builder(builder: (context) {
                final activeJobs = _jobs.where((j) {
                  final st = (j['status'] ?? '').toString().toUpperCase();
                  return ['REQUESTED', 'CONFIRMED', 'NAVIGATING', 'ARRIVED', 'IN_PROGRESS', 'START_OTP_VERIFIED', 'JOB_COMPLETED_PAYMENT_DUE'].contains(st);
                }).toList();

                final expiredJobs = _jobs.where((j) {
                  final st = (j['status'] ?? '').toString().toUpperCase();
                  return ['EXPIRED', 'CANCELLED', 'COMPLETED'].contains(st);
                }).toList();

                final currentDisplayedJobs = _selectedJobTabIndex == 0 ? activeJobs : expiredJobs;

                return Column(
                  children: [
                    // 2-Tab Selector Bar (Active & Pending vs Expired & History)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ProColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedJobTabIndex = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedJobTabIndex == 0 ? ProColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedJobTabIndex == 0
                                      ? [const BoxShadow(color: Color(0x3310B981), blurRadius: 8)]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 14, color: _selectedJobTabIndex == 0 ? Colors.white : ProColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active (${activeJobs.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedJobTabIndex == 0 ? Colors.white : ProColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedJobTabIndex = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedJobTabIndex == 1 ? const Color(0xFF334155) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_rounded, size: 14, color: _selectedJobTabIndex == 1 ? Colors.white : ProColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Expired & Past (${expiredJobs.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedJobTabIndex == 1 ? Colors.white : ProColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (!_isOnline) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ProColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ProColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.portable_wifi_off_rounded, size: 36, color: ProColors.textMuted),
                            SizedBox(height: 12),
                            Text('You are currently Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Toggle On-Duty switch above to start receiving live job requests in your 50km area.', textAlign: TextAlign.center, style: ProText.caption),
                          ],
                        ),
                      ),
                    ] else if (_loadingJobs) ...[
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: ProColors.primary))),
                    ] else if (currentDisplayedJobs.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ProColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ProColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedJobTabIndex == 0 ? Icons.search_rounded : Icons.history_rounded,
                              size: 36,
                              color: _selectedJobTabIndex == 0 ? ProColors.primary : ProColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedJobTabIndex == 0 ? 'No Active Job Dispatches' : 'No Expired or Past Jobs',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedJobTabIndex == 0
                                  ? 'You are online in your coverage region. Incoming active job dispatches will appear here.'
                                  : 'Expired or completed job history will appear in this tab.',
                              textAlign: TextAlign.center,
                              style: ProText.caption,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentDisplayedJobs.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final job = currentDisplayedJobs[index];
                          return _JobCard(
                            job: job,
                            onAccept: () => _acceptJob(job['id']?.toString() ?? ''),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              ).then((_) => _loadData());
                            },
                          );
                        },
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: ProColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;
  final VoidCallback onAccept;

  const _JobCard({required this.job, required this.onTap, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final status = (job['status'] ?? 'REQUESTED').toString().toUpperCase();
    
    // Determine status colors, background gradient & dimming
    final bool isExpiredOrCancelled = status == 'EXPIRED' || status == 'CANCELLED';
    final bool isInProgress = status == 'IN_PROGRESS' || status == 'NAVIGATING' || status == 'ARRIVED';
    final bool isCompleted = status == 'COMPLETED';

    Color statusColor = ProColors.primary;
    Color borderColor = ProColors.primary.withAlpha(120);
    Gradient cardGradient = const LinearGradient(
      colors: [Color(0xFF0F172A), Color(0x2210B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    if (isInProgress) {
      statusColor = ProColors.warningAmber;
      borderColor = ProColors.warningAmber;
      cardGradient = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0x33F59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isCompleted) {
      statusColor = const Color(0xFF3B82F6);
      borderColor = const Color(0xFF3B82F6).withAlpha(150);
      cardGradient = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0x223B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isExpiredOrCancelled) {
      statusColor = const Color(0xFF94A3B8);
      borderColor = const Color(0x4464748B);
      cardGradient = const LinearGradient(
        colors: [Color(0x990F172A), Color(0x770F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    final Color textColor = isExpiredOrCancelled ? const Color(0xFF94A3B8) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isInProgress ? 1.5 : 1.0),
          boxShadow: [
            if (isInProgress)
              const BoxShadow(color: Color(0x33F59E0B), blurRadius: 14, offset: Offset(0, 4))
            else if (!isExpiredOrCancelled)
              BoxShadow(color: statusColor.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpiredOrCancelled ? Icons.timer_off_outlined : Icons.build_circle_outlined,
                      color: isExpiredOrCancelled ? const Color(0xFF64748B) : statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      job['service_name']?.toString() ?? 'Home Service Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 14,
                        decoration: isExpiredOrCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpiredOrCancelled ? const Color(0x2294A3B8) : statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isExpiredOrCancelled ? const Color(0x4494A3B8) : statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: isExpiredOrCancelled ? const Color(0xFF64748B) : ProColors.emergencyRed, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job['address_text']?.toString() ?? job['customer_address']?.toString() ?? job['address']?.toString() ?? 'Thottikkanam, Kerala',
                    style: TextStyle(fontSize: 12, color: isExpiredOrCancelled ? const Color(0xFF64748B) : ProColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹${job['total_amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isExpiredOrCancelled ? const Color(0xFF64748B) : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (status == 'REQUESTED') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ACCEPT JOB REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    isExpiredOrCancelled ? Icons.info_outline_rounded : Icons.arrow_forward_ios,
                    color: isExpiredOrCancelled ? const Color(0xFF64748B) : ProColors.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpiredOrCancelled
                        ? 'Request expired or cancelled. Tap to view job record.'
                        : 'Tap for Live Navigation & Start/End OTP Verification',
                    style: TextStyle(
                      color: isExpiredOrCancelled ? const Color(0xFF64748B) : ProColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

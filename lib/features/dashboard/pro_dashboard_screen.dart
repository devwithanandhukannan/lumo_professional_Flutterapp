import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../financials/pro_earnings_screen.dart';
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

      final lat = (pro['latitude'] != null)
          ? double.tryParse(pro['latitude'].toString()) ?? ProSessionStorage.currentLat ?? 12.9716
          : ProSessionStorage.currentLat ?? 12.9716;
      final lng = (pro['longitude'] != null)
          ? double.tryParse(pro['longitude'].toString()) ?? ProSessionStorage.currentLng ?? 77.5946
          : ProSessionStorage.currentLng ?? 77.5946;
      final String locName =
          (pro['assigned_region'] ?? pro['service_area'] ?? pro['address'] ?? ProSessionStorage.serviceArea).toString();
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
          .where((j) =>
              (j['status']?.toString() ?? '').toUpperCase() == 'REQUESTED' &&
              !oldRequestedIds.contains(j['id']?.toString() ?? ''))
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
            backgroundColor: ProColors.surf(context),
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
      final latestStatus =
          pro['verification_status']?.toString() ?? profileRes['verificationStatus']?.toString() ?? 'PENDING';
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

    if (val &&
        _activeSuspension != null &&
        (_activeSuspension!['severity'] == 'FULL_BLACKOUT' || _activeSuspension!['severity'] == null)) {
      setState(() => _togglingOnline = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ProColors.surf(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: ProColors.emergencyRed, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency Service Closure',
                    style: TextStyle(
                      color: ProColors.txt(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeSuspension!['message'] ??
                      'Service is currently paused in your area due to emergency blackout rules.',
                  style: TextStyle(color: ProColors.txtSec(context), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ProColors.surfHigh(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProColors.emergencyRed.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: ProColors.primaryLight, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Location: ${_activeSuspension!['areaName'] ?? 'Fenced Blackout Zone'}',
                              style: const TextStyle(
                                  color: ProColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
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
                              style: const TextStyle(
                                  color: ProColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
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
            backgroundColor: ProColors.surf(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, color: ProColors.warningAmber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Account Verification Required',
                  style: TextStyle(color: ProColors.txt(context), fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Cannot go online. Account verification status is $currentStatus. Super Admin document audit and approval required before starting duty.',
              style: ProText.captionStyle(context),
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
    final isDark = ProColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isOnline ? ProColors.primaryLight : ProColors.txtMuted(context),
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isOnline)
                    BoxShadow(
                      color: ProColors.primaryLight.withAlpha(160),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Partner Portal · $proName',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ProColors.txt(context),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  _isOnline ? 'ONLINE & RECEIVING JOBS' : 'OFFLINE (ON-DUTY TOGGLE OFF)',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isOnline ? ProColors.primaryAccent(context) : ProColors.txtMuted(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet_rounded, color: ProColors.primaryAccent(context)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProEarningsScreen()),
              );
            },
            tooltip: 'Earnings Ledger',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ProColors.txtMuted(context)),
            onPressed: _loadData,
            tooltip: 'Refresh Jobs',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: ProColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_activeSuspension != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ProColors.emergencyRedBorder, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ProColors.emergencyRed,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  (_activeSuspension!['reasonCategory'] ?? 'EMERGENCY')
                                      .toString()
                                      .replaceAll('_', ' '),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activeSuspension!['title'] ?? 'Emergency Regional Closure',
                              style: TextStyle(
                                  color: ProColors.txt(context), fontWeight: FontWeight.bold, fontSize: 13),
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
                          color: isDark ? Colors.black.withAlpha(120) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ProColors.emergencyRed.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: ProColors.primaryLight, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FENCED LOCATION NAME:',
                                    style: TextStyle(
                                        color: ProColors.txtMuted(context),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5),
                                  ),
                                  Text(
                                    (_activeSuspension!['areaName'] ??
                                            _activeSuspension!['title'] ??
                                            ProSessionStorage.serviceArea)
                                        .toString(),
                                    style: const TextStyle(
                                        color: ProColors.primaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
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
                        _activeSuspension!['message'] ??
                            'Service is temporarily paused in your region for partner safety.',
                        style: TextStyle(color: ProColors.txtSec(context), fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.lock_clock_rounded, color: ProColors.emergencyRed, size: 14),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'On-Duty mode is locked in this region to protect partner safety.',
                              style: TextStyle(
                                  color: ProColors.emergencyRed, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if ((_health?['verificationStatus'] ?? ProSessionStorage.verificationStatus) == 'REJECTED') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ProColors.emergencyRedBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ProColors.emergencyRed.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.error_outline, color: ProColors.emergencyRed, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'APPLICATION RETURNED FOR CORRECTION',
                                  style: TextStyle(
                                      color: ProColors.txt(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Super Admin requested document re-upload. Please upload clear photos of your Govt ID and Certificate.',
                                  style: TextStyle(
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                      fontSize: 11,
                                      height: 1.3),
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
                            backgroundColor: ProColors.emergencyRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('RE-UPLOAD DOCUMENTS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if ((_health?['verificationStatus'] ?? ProSessionStorage.verificationStatus) == 'PENDING') ...[
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: ProColors.warningAmber, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFICATION PENDING AUDIT',
                              style: TextStyle(
                                  color: ProColors.txt(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your profile details & documents are under review by Super Admin. You will be notified once approved to receive bookings.',
                              style: ProText.captionStyle(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Master On-Duty Card ──────────────────────────────────────
              GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                borderColor: _isOnline ? ProColors.primary.withAlpha(120) : Colors.transparent,
                borderWidth: _isOnline ? 1.5 : 0,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isOnline ? ProColors.primarySoft : ProColors.surfHigh(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isOnline
                              ? ProColors.primary.withAlpha(100)
                              : ProColors.brd(context),
                        ),
                      ),
                      child: Icon(
                        _isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                        color: _isOnline ? ProColors.primaryAccent(context) : ProColors.txtMuted(context),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: _isOnline
                                  ? ProColors.primaryAccent(context)
                                  : ProColors.txt(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline
                                ? 'Broadcasting live GPS telemetry for nearby customer job dispatches'
                                : 'Toggle switch ON to start receiving nearby customer bookings',
                            style: ProText.captionStyle(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _togglingOnline
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: ProColors.primary, strokeWidth: 2.5),
                          )
                        : Switch(
                            value: _isOnline,
                            activeTrackColor: ProColors.primary,
                            onChanged: _toggleOnline,
                          ),
                  ],
                ),
              ),

              // ── 24/7 SOS Banner (when online) ────────────────────────────
              if (_isOnline) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x22EF4444) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ProColors.emergencyRedBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: ProColors.emergencyRed, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '24/7 SOS MONITORING ACTIVE',
                        style: TextStyle(
                          color: ProColors.txt(context),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
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
                                decoration: BoxDecoration(
                                  color: ProColors.surf(context),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                              color: ProColors.emergencyRed,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Color(0x44EF4444), blurRadius: 8)],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.sos_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
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
              ],

              const SizedBox(height: 16),

              // ── Summary Metrics Row ──────────────────────────────────────
              GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Builder(
                  builder: (context) {
                    double todayTotal = 0.0;
                    for (final j in _jobs) {
                      if (j['status'] == 'COMPLETED') {
                        todayTotal += (double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0.0);
                      }
                    }
                    final healthScore = (_health?['accountHealthScore'] as num?)?.toInt() ??
                        (_health?['account_health_score'] as num?)?.toInt() ??
                        100;
                    final ratingAvg = _health?['ratingAvg'] ?? _health?['rating_avg'] ?? '5.0';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickSummaryItem(
                          label: "TODAY'S EARNINGS",
                          value: '₹${todayTotal.toStringAsFixed(2)}',
                          icon: Icons.account_balance_wallet_rounded,
                          color: ProColors.primaryAccent(context),
                        ),
                        Container(width: 1, height: 36, color: ProColors.brd(context)),
                        _QuickSummaryItem(
                          label: 'ACCOUNT HEALTH',
                          value: '$healthScore / 100',
                          icon: Icons.shield_rounded,
                          color: ProColors.accent,
                        ),
                        Container(width: 1, height: 36, color: ProColors.brd(context)),
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

              const SizedBox(height: 22),

              // ── Job Dispatches Header ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('JOB DISPATCHES', style: ProText.labelStyle(context)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ProColors.primaryAccent(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live GPS Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: ProColors.primaryAccent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Tab Selector & Job List ──────────────────────────────────
              Builder(builder: (context) {
                final activeJobs = _jobs.where((j) {
                  final st = (j['status'] ?? '').toString().toUpperCase();
                  return [
                    'REQUESTED',
                    'CONFIRMED',
                    'NAVIGATING',
                    'ARRIVED',
                    'IN_PROGRESS',
                    'START_OTP_VERIFIED',
                    'JOB_COMPLETED_PAYMENT_DUE'
                  ].contains(st);
                }).toList();

                final expiredJobs = _jobs.where((j) {
                  final st = (j['status'] ?? '').toString().toUpperCase();
                  return ['EXPIRED', 'CANCELLED', 'COMPLETED'].contains(st);
                }).toList();

                final currentDisplayedJobs = _selectedJobTabIndex == 0 ? activeJobs : expiredJobs;

                return Column(
                  children: [
                    // Segmented Tab Selector Bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ProColors.surfHigh(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProColors.brd(context), width: 0.8),
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
                                  color: _selectedJobTabIndex == 0
                                      ? ProColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedJobTabIndex == 0
                                      ? ProColors.neuAccentGlow(ProColors.primary)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 15,
                                      color: _selectedJobTabIndex == 0
                                          ? Colors.white
                                          : ProColors.txtMuted(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active (${activeJobs.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedJobTabIndex == 0
                                            ? Colors.white
                                            : ProColors.txtMuted(context),
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
                                  color: _selectedJobTabIndex == 1
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 15,
                                      color: _selectedJobTabIndex == 1
                                          ? ProColors.txt(context)
                                          : ProColors.txtMuted(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Expired & Past (${expiredJobs.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedJobTabIndex == 1
                                            ? ProColors.txt(context)
                                            : ProColors.txtMuted(context),
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
                      GlassCard(
                        padding: const EdgeInsets.all(28),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ProColors.surfHigh(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.portable_wifi_off_rounded,
                                  size: 28, color: ProColors.txtMuted(context)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'You are currently Offline',
                              style: TextStyle(
                                color: ProColors.txt(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toggle On-Duty switch above to start receiving live job requests in your 50km area.',
                              textAlign: TextAlign.center,
                              style: ProText.captionStyle(context),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_loadingJobs) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: ProColors.primary),
                        ),
                      ),
                    ] else if (currentDisplayedJobs.isEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(28),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Icon(
                              _selectedJobTabIndex == 0 ? Icons.search_rounded : Icons.history_rounded,
                              size: 36,
                              color: _selectedJobTabIndex == 0
                                  ? ProColors.primaryAccent(context)
                                  : ProColors.txtMuted(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedJobTabIndex == 0 ? 'No Active Job Dispatches' : 'No Expired or Past Jobs',
                              style: TextStyle(
                                color: ProColors.txt(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedJobTabIndex == 0
                                  ? 'You are online in your coverage region. Incoming active job dispatches will appear here in real time.'
                                  : 'Expired or completed job history will appear in this tab.',
                              textAlign: TextAlign.center,
                              style: ProText.captionStyle(context),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentDisplayedJobs.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
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
              const SizedBox(height: 20),
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
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: ProColors.txt(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: ProColors.txtMuted(context),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
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

    final bool isExpiredOrCancelled = status == 'EXPIRED' || status == 'CANCELLED';
    final bool isInProgress = status == 'IN_PROGRESS' || status == 'NAVIGATING' || status == 'ARRIVED';
    final bool isCompleted = status == 'COMPLETED';

    Color statusColor = ProColors.primaryAccent(context);
    if (isInProgress) {
      statusColor = ProColors.warningAmber;
    } else if (isCompleted) {
      statusColor = ProColors.accent;
    } else if (isExpiredOrCancelled) {
      statusColor = ProColors.txtMuted(context);
    }

    final Color textColor = isExpiredOrCancelled
        ? ProColors.txtMuted(context)
        : ProColors.txt(context);

    return GlassCard(
      onTap: onTap,
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      borderColor: isInProgress ? ProColors.warningAmber.withAlpha(140) : Colors.transparent,
      borderWidth: isInProgress ? 1.5 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isExpiredOrCancelled ? Icons.timer_off_outlined : Icons.build_circle_outlined,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job['service_name']?.toString() ?? 'Home Service Request',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          fontSize: 14,
                          decoration: isExpiredOrCancelled ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(80), width: 0.8),
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
              Icon(Icons.location_on,
                  color: isExpiredOrCancelled ? ProColors.txtMuted(context) : ProColors.emergencyRed,
                  size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job['address_text']?.toString() ??
                      job['customer_address']?.toString() ??
                      job['address']?.toString() ??
                      'Thottikkanam, Kerala',
                  style: TextStyle(
                    fontSize: 12,
                    color: ProColors.txtSec(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${job['total_amount']}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isExpiredOrCancelled
                      ? ProColors.txtMuted(context)
                      : ProColors.primaryAccent(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (status == 'REQUESTED') ...[
            const SizedBox(height: 14),
            GradientButton(
              height: 42,
              label: 'ACCEPT JOB REQUEST',
              onTap: onAccept,
              icon: Icons.check_circle_outline,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isExpiredOrCancelled ? Icons.info_outline_rounded : Icons.arrow_forward_ios,
                  color: statusColor,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExpiredOrCancelled
                        ? 'Request expired or cancelled. Tap to view job record.'
                        : 'Tap for Live Navigation & Start/End OTP Verification',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

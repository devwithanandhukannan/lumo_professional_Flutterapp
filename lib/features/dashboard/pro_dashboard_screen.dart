import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../jobs/job_detail_screen.dart';
import '../safety/pro_sos_widget.dart';

import '../onboarding/pro_document_upload_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _isOnline = ProSessionStorage.isOnline;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingJobs = true);
    try {
      final health = await ProApiClient.getProHealth();
      if (mounted) {
        setState(() => _health = health);
        if (health['verificationStatus'] != null) {
          ProSessionStorage.updateVerificationStatus(health['verificationStatus']);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _health = {
          'accountHealthScore': 98.5,
          'ratingAvg': 4.92,
          'totalJobsCompleted': 142,
          'acceptanceRate': 95.0,
          'verificationStatus': ProSessionStorage.verificationStatus,
          'coverageRadiusKm': ProSessionStorage.coverageRadiusKm,
        });
      }
    }

    try {
      final jobs = await ProApiClient.getMyJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (_) {
      if (mounted) setState(() => _jobs = _demoJobs);
    } finally {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<void> _toggleOnline(bool val) async {
    final status = _health?['verificationStatus'] ?? ProSessionStorage.verificationStatus;
    if (val && status != 'APPROVED') {
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
            'Cannot go online. Account verification status is $status. Super Admin document audit and approval required before starting duty.',
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
      return;
    }

    setState(() {
      _isOnline = val;
      _togglingOnline = true;
    });

    try {
      await ProApiClient.updateOnlineStatus(val, latitude: 12.9716, longitude: 77.5946);
      await ProSessionStorage.setOnlineStatus(val);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duty status update failed: $e'), backgroundColor: ProColors.emergencyRed),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  Widget _buildVerificationStatusBanner() {
    final status = (_health?['verificationStatus'] ?? ProSessionStorage.verificationStatus)?.toString().toUpperCase();
    final notes = _health?['verificationNotes']?.toString() ?? 'Documents require correction or re-submission.';

    if (status == 'PENDING') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1FFAE8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProColors.warningAmber.withAlpha(150)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ProColors.warningAmber.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: ProColors.warningAmber, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VERIFICATION PENDING',
                    style: TextStyle(color: ProColors.warningAmber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin audit in progress. App features are unlocked in read-only mode until approved.',
                    style: TextStyle(color: ProColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'REJECTED') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x22EF4444),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProColors.emergencyRed.withAlpha(180)),
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
                  child: const Icon(Icons.cancel_outlined, color: ProColors.emergencyRed, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REGISTRATION REJECTED',
                        style: TextStyle(color: ProColors.emergencyRed, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reason: $notes',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('REAPPLY / FIX DOCUMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProDocumentUploadScreen(
                        onCompleted: () {
                          _loadData();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final String proName = ProSessionStorage.userName;

    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh Jobs',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: ProColors.cardBg,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProSosWidget(),
              ],
            ),
          ),
        ),
        backgroundColor: ProColors.emergencyRed,
        child: const Icon(Icons.sos, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: ProColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Verification Status Banner
              _buildVerificationStatusBanner(),

              // 1. On-Duty Glowing Toggle Card
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

              const SizedBox(height: 20),

              // 2. Earnings & Health Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ProColors.surface, ProColors.cardBg]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _QuickSummaryItem(
                      label: "TODAY'S EARNINGS",
                      value: '₹2,100.00',
                      icon: Icons.account_balance_wallet,
                      color: ProColors.primary,
                    ),
                    Container(width: 1, height: 36, color: ProColors.border),
                    _QuickSummaryItem(
                      label: 'ACCOUNT HEALTH',
                      value: '${(_health?['accountHealthScore'] as num?)?.toInt() ?? 98} / 100',
                      icon: Icons.shield_rounded,
                      color: ProColors.accent,
                    ),
                    Container(width: 1, height: 36, color: ProColors.border),
                    _QuickSummaryItem(
                      label: 'AVG RATING',
                      value: '⭐ ${_health?['ratingAvg'] ?? 4.92}',
                      icon: Icons.star_rounded,
                      color: ProColors.warningAmber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Incoming Job Requests Section
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ACTIVE JOB DISPATCHES', style: ProText.label),
                  Text('Live GPS Telemetry Active', style: TextStyle(fontSize: 10, color: ProColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

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
              ] else if (_jobs.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ProColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ProColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.search_rounded, size: 36, color: ProColors.primary),
                      SizedBox(height: 12),
                      Text('Searching Nearby Bookings...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('You are online in Bangalore region. Incoming job dispatches will appear here automatically.', textAlign: TextAlign.center, style: ProText.caption),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _jobs.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return _JobCard(
                      job: job,
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

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = (job['status'] ?? 'REQUESTED').toString().toUpperCase();
    Color statusColor = ProColors.primary;
    if (status == 'ACCEPTED' || status == 'NAVIGATING') statusColor = ProColors.accent;
    if (status == 'IN_PROGRESS') statusColor = ProColors.warningAmber;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withAlpha(120)),
          boxShadow: [
            BoxShadow(color: statusColor.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4)),
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
                    const Icon(Icons.build_circle_outlined, color: ProColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      job['service_name']?.toString() ?? 'Home Service Request',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                  child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: ProColors.emergencyRed, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job['customer_address']?.toString() ?? 'Indiranagar, Bangalore',
                    style: ProText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('₹${job['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.arrow_forward_ios, color: ProColors.primary, size: 12),
                const SizedBox(width: 6),
                Text(
                  status == 'REQUESTED' ? 'Tap to View Request Details & Accept' : 'Tap for Live Navigation & Start/End OTP Verification',
                  style: const TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _demoJobs = [
  {
    'id': 'bk-9901',
    'status': 'REQUESTED',
    'service_name': 'Home Deep Cleaning',
    'customer_name': 'Ananya Sharma',
    'customer_phone': '+919812345678',
    'customer_address': 'Flat 402, Lotus Apartments, Indiranagar, Bangalore',
    'scheduled_at': 'Today, 03:00 PM',
    'total_amount': '1250.00',
    'otp_start': '4821',
    'otp_end': '9940',
  },
  {
    'id': 'bk-9902',
    'status': 'NAVIGATING',
    'service_name': 'Switch & Socket Repair',
    'customer_name': 'Rahul Verma',
    'customer_phone': '+919876501234',
    'customer_address': '7th Cross, Koramangala 4th Block, Bangalore',
    'scheduled_at': 'Today, 04:30 PM',
    'total_amount': '499.00',
    'otp_start': '1092',
    'otp_end': '5512',
  },
];

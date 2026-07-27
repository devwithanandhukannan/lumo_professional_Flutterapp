import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _isOnline = ProSessionStorage.isOnline;
    _loadData();
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

    String currentStatus = ProSessionStorage.verificationStatus;
    try {
      final profileRes = await ProApiClient.getProfile();
      final pro = profileRes['profile'] ?? profileRes['data']?['profile'] ?? profileRes['data'] ?? {};
      if (pro['verification_status'] != null) {
        currentStatus = pro['verification_status'].toString();
        await ProSessionStorage.updateVerificationStatus(currentStatus);
      }
    } catch (_) {}

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
      await ProApiClient.updateOnlineStatus(val, latitude: 12.9716, longitude: 77.5946);
      await ProSessionStorage.setOnlineStatus(val);
      if (mounted) setState(() => _isOnline = val);
    } catch (e) {
      if (mounted) {
        setState(() => _isOnline = !val);
        await ProSessionStorage.setOnlineStatus(!val);
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x33EF4444), Color(0x1AEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xAAEF4444), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33EF4444), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x44EF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SAFETY PROTOCOL ACTIVE',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '24/7 SOS emergency monitoring enabled. Tap SOS below in any critical situation.',
                                  style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const ProSosWidget(),
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
                  const Icon(Icons.arrow_forward_ios, color: ProColors.primary, size: 12),
                  const SizedBox(width: 6),
                  const Text(
                    'Tap for Live Navigation & Start/End OTP Verification',
                    style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
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

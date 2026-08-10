import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import '../../core/services/pro_haptic_service.dart';
import 'job_detail_screen.dart';

class ProInstantRequestsScreen extends StatefulWidget {
  const ProInstantRequestsScreen({super.key});

  @override
  State<ProInstantRequestsScreen> createState() => _ProInstantRequestsScreenState();
}

class _ProInstantRequestsScreenState extends State<ProInstantRequestsScreen> {
  bool _loading = true;
  List<dynamic> _requestedJobs = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadRequests(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final jobs = await ProApiClient.getMyJobs();
      final requested =
          jobs.where((j) => (j['status']?.toString() ?? '').toUpperCase() == 'REQUESTED').toList();

      if (requested.length > _requestedJobs.length) {
        ProHapticService.incomingJobRequest();
      }

      if (mounted) {
        setState(() {
          _requestedJobs = requested;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _acceptRequest(String bookingId) async {
    ProHapticService.jobAccepted();
    try {
      await ProApiClient.acceptJob(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚡ Instant Job Accepted! Live navigation active.'),
            backgroundColor: ProColors.primary),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Accept failed: ${e.toString()}'),
            backgroundColor: ProColors.emergencyRed),
      );
    }
  }

  Future<void> _cancelRequest(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Decline Request',
            style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to decline / cancel this job request?',
          style: TextStyle(color: ProColors.txtSec(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: TextStyle(color: ProColors.txtMuted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProApiClient.cancelBooking(bookingId, reason: 'Declined by Professional');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job request declined'), backgroundColor: ProColors.emergencyRed),
        );
        _loadRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Decline failed: ${e.toString()}'),
              backgroundColor: ProColors.emergencyRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: ProColors.warningAmber, size: 22),
            const SizedBox(width: 8),
            Text(
              'Instant Customer Requests',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: ProColors.txt(context),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ProColors.txtMuted(context)),
            onPressed: _loadRequests,
            tooltip: 'Refresh Feed',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ProColors.primary))
          : RefreshIndicator(
              onRefresh: _loadRequests,
              color: ProColors.primary,
              child: _requestedJobs.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ProColors.surfHigh(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_paused_outlined,
                              size: 36, color: ProColors.txtMuted(context)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Instant Requests Right Now',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ProColors.txt(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep your duty toggle ON to receive instant customer dispatch alerts within your 50km radius.',
                          textAlign: TextAlign.center,
                          style: ProText.captionStyle(context),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _requestedJobs.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final job = _requestedJobs[idx];
                        final id = job['id']?.toString() ?? '';
                        final serviceName = job['service_name']?.toString() ?? 'Home Service';
                        final address = job['customer_address']?.toString() ?? 'Service Location';
                        final amount = job['total_amount']?.toString() ?? '499';
                        final dist = job['travel_distance_km']?.toString() ?? '3.2';

                        return GlassCard(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(18),
                          borderColor: ProColors.warningAmber.withAlpha(100),
                          borderWidth: 1.2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ProColors.warningAmberSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.timer_outlined, color: ProColors.warningAmber, size: 13),
                                        SizedBox(width: 3),
                                        Text('5 MIN TIMER',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: ProColors.warningAmber)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Builder(builder: (ctx) {
                                    final totalVal = double.tryParse(amount) ?? 0.0;
                                    final platformFeeVal =
                                        double.tryParse(job['platform_fee']?.toString() ?? '50') ?? 50.0;
                                    final netPayoutVal = (totalVal - platformFeeVal) > 0
                                        ? (totalVal - platformFeeVal)
                                        : totalVal;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ProColors.primarySoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.account_balance_wallet_rounded,
                                              color: ProColors.primary, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            'YOU GET ₹${netPayoutVal.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: ProColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Spacer(),
                                  Text(
                                    '₹$amount',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: ProColors.primaryAccent(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      serviceName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ProColors.txt(context),
                                      ),
                                    ),
                                  ),
                                  Builder(builder: (ctx) {
                                    final customerSex = job['customer_sex']?.toString() ?? '';
                                    if (customerSex.isEmpty) return const SizedBox.shrink();
                                    final isFemale = customerSex.toUpperCase() == 'FEMALE';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isFemale ? const Color(0x1AEC4899) : const Color(0x1A3B82F6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isFemale
                                                ? const Color(0x80EC4899)
                                                : const Color(0x803B82F6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(isFemale ? '👩' : '👨', style: const TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            isFemale ? 'Female' : 'Male',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isFemale
                                                  ? const Color(0xFFEC4899)
                                                  : const Color(0xFF3B82F6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: ProColors.emergencyRed, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: TextStyle(color: ProColors.txtSec(context), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.navigation_outlined, color: ProColors.primary, size: 14),
                                  const SizedBox(width: 6),
                                  Builder(builder: (ctx) {
                                    final distKm = job['distance_km']?.toString() ?? dist;
                                    final travelCharge = job['travel_charge'];
                                    final basePrice = job['base_price'] ?? job['total_amount'];
                                    if (travelCharge != null) {
                                      return Text(
                                        '$distKm km · Base ₹$basePrice + Travel ₹$travelCharge',
                                        style: TextStyle(
                                          color: ProColors.primaryAccent(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }
                                    return Text(
                                      'Distance: $distKm km',
                                      style: TextStyle(
                                        color: ProColors.primaryAccent(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _cancelRequest(id),
                                    icon: const Icon(Icons.cancel_outlined, color: ProColors.emergencyRed),
                                    tooltip: 'Decline',
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: ProColors.txt(context),
                                        side: BorderSide(color: ProColors.brd(context)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text('DETAILS',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _acceptRequest(id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ProColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.bolt, size: 18),
                                      label: const Text('ACCEPT',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

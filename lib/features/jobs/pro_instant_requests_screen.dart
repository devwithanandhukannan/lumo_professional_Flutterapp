import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import 'job_detail_screen.dart';

class ProInstantRequestsScreen extends StatefulWidget {
  const ProInstantRequestsScreen({super.key});

  @override
  State<ProInstantRequestsScreen> createState() => _ProInstantRequestsScreenState();
}

class _ProInstantRequestsScreenState extends State<ProInstantRequestsScreen> {
  bool _loading = true;
  List<dynamic> _requestedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final jobs = await ProApiClient.getMyJobs();
      final requested = jobs.where((j) => (j['status']?.toString() ?? '').toUpperCase() == 'REQUESTED').toList();
      if (mounted) {
        setState(() {
          _requestedJobs = requested;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptRequest(String bookingId) async {
    try {
      await ProApiClient.acceptJob(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ Instant Job Accepted! Live navigation active.'), backgroundColor: ProColors.primary),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accept failed: ${e.toString()}'), backgroundColor: ProColors.emergencyRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: ProColors.warningAmber, size: 20),
            SizedBox(width: 8),
            Text('Instant Customer Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
            tooltip: 'Refresh Feed',
          ),
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
                        const SizedBox(height: 60),
                        Icon(Icons.notifications_paused_outlined, size: 56, color: ProColors.textMuted.withAlpha(120)),
                        const SizedBox(height: 16),
                        const Text(
                          'No Instant Requests Right Now',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep your duty toggle ON to receive instant customer dispatch alerts within your 50km radius.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ProColors.textMuted, fontSize: 12),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requestedJobs.length,
                      itemBuilder: (ctx, idx) {
                        final job = _requestedJobs[idx];
                        final id = job['id']?.toString() ?? '';
                        final serviceName = job['service_name']?.toString() ?? 'Home Service';
                        final address = job['customer_address']?.toString() ?? 'Service Location';
                        final amount = job['total_amount']?.toString() ?? '499';
                        final dist = job['travel_distance_km']?.toString() ?? '3.2';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ProColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ProColors.warningAmber.withAlpha(120)),
                            boxShadow: [
                              BoxShadow(color: ProColors.warningAmber.withAlpha(20), blurRadius: 12, spreadRadius: 1),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: ProColors.warningAmberSoft, borderRadius: BorderRadius.circular(12)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.timer_outlined, color: ProColors.warningAmber, size: 14),
                                        SizedBox(width: 4),
                                        Text('5 MIN ACCEPTANCE TIMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProColors.warningAmber)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('₹$amount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: Text(serviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                                  // Update 5: Customer sex badge
                                  Builder(builder: (ctx) {
                                    final customerSex = job['customer_sex']?.toString() ?? '';
                                    if (customerSex.isEmpty) return const SizedBox.shrink();
                                    final isFemale = customerSex.toUpperCase() == 'FEMALE';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isFemale ? const Color(0x1AEC4899) : const Color(0x1A3B82F6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isFemale ? const Color(0x80EC4899) : const Color(0x803B82F6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(isFemale ? '👩' : '👨', style: const TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(isFemale ? 'Female' : 'Male', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6))),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: ProColors.emergencyRed, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(address, style: const TextStyle(color: ProColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                                      return Text('$distKm km · Base ₹$basePrice + Travel ₹$travelCharge', style: const TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.w600));
                                    }
                                    return Text('Distance: $distKm km', style: const TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.w600));
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: ProColors.border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text('VIEW DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                      label: const Text('ACCEPT REQUEST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
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

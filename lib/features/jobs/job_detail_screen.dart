import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import '../navigation/pro_map_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _startOtpCtrl = TextEditingController();
  final _endOtpCtrl = TextEditingController();

  String _jobState = 'NAVIGATING';
  bool _verifyingOtp = false;
  Map<String, dynamic>? _liveJobData;

  @override
  void initState() {
    super.initState();
    final status = (widget.job['status'] as String? ?? '').toUpperCase();
    if (status == 'IN_PROGRESS') {
      _jobState = 'IN_PROGRESS';
    } else if (status == 'COMPLETED') {
      _jobState = 'COMPLETED';
    } else if (status == 'ACCEPTED' || status == 'NAVIGATING') {
      _jobState = 'NAVIGATING';
    } else {
      _jobState = status.isNotEmpty ? status : 'REQUESTED';
    }
    _loadLiveJobData();
  }

  Future<void> _loadLiveJobData() async {
    try {
      final bookingId = widget.job['id']?.toString() ?? '';
      if (bookingId.isNotEmpty) {
        final data = await ProApiClient.getJobById(bookingId);
        if (data.isNotEmpty && mounted) {
          setState(() {
            _liveJobData = data;
            final st = (data['status'] as String? ?? '').toUpperCase();
            if (st.isNotEmpty) _jobState = st;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _startOtpCtrl.dispose();
    _endOtpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyStartOtp() async {
    final code = _startOtpCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _verifyingOtp = true);

    try {
      await ProApiClient.verifyStartOtp(
        bookingId: widget.job['id']?.toString() ?? '',
        otp: code,
      );
      if (mounted) {
        setState(() => _jobState = 'IN_PROGRESS');
        Navigator.pop(context);
        _showSnackBar('✅ START OTP VERIFIED! Service in progress.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ ${e.toString().replaceAll('Exception: ', '')}', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _verifyEndOtp() async {
    final code = _endOtpCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _verifyingOtp = true);

    try {
      await ProApiClient.verifyEndOtp(
        bookingId: widget.job['id']?.toString() ?? '',
        otp: code,
      );
      if (mounted) {
        setState(() => _jobState = 'COMPLETED');
        Navigator.pop(context);
        _showSnackBar('🎉 JOB COMPLETED! Payout ₹${widget.job['total_amount']} credited.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ ${e.toString().replaceAll('Exception: ', '')}', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  void _showSnackBar(String msg, {required bool isSuccess}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isSuccess ? ProColors.primary : ProColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );
    }
  }

  void _showStartOtpDialog() {
    _startOtpCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Start Job OTP',
          style: TextStyle(color: ProColors.txt(context), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask the customer to share their START OTP code.',
              style: TextStyle(color: ProColors.txtMuted(context), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _startOtpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w900, color: ProColors.txt(context)),
              decoration: proInputDecoration(hint: '· · · ·', context: context).copyWith(counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ProColors.txtMuted(context))),
          ),
          ElevatedButton(
            onPressed: _verifyingOtp ? null : () async {
              Navigator.pop(ctx);
              await _verifyStartOtp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VERIFY & START', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptJob() async {
    setState(() => _verifyingOtp = true);
    try {
      await ProApiClient.acceptJob(widget.job['id']?.toString() ?? '');
      if (mounted) {
        setState(() {
          _jobState = 'NAVIGATING';
          _verifyingOtp = false;
        });
        _showSnackBar('✅ Job Accepted! Live navigation active.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verifyingOtp = false);
        _showSnackBar('Failed to accept job: ${e.toString()}', isSuccess: false);
      }
    }
  }

  void _showEndOtpDialog() {
    _endOtpCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter End Job OTP',
          style: TextStyle(color: ProColors.txt(context), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask the customer to share their END OTP code to complete the job.',
              style: TextStyle(color: ProColors.txtMuted(context), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _endOtpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w900, color: ProColors.txt(context)),
              decoration: proInputDecoration(hint: '· · · ·', context: context).copyWith(counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ProColors.txtMuted(context))),
          ),
          ElevatedButton(
            onPressed: _verifyingOtp ? null : () async {
              Navigator.pop(ctx);
              await _verifyEndOtp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VERIFY & COMPLETE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobMap = _liveJobData ?? widget.job;
    final amount = jobMap['total_amount']?.toString() ?? '0';
    final serviceName = jobMap['service_name']?.toString() ?? 'Service';
    final address = jobMap['address_text']?.toString() ?? jobMap['customer_address']?.toString() ?? jobMap['address']?.toString() ?? 'Thottikkanam, Kerala';
    final bookingId = jobMap['id']?.toString() ?? '';
    final customerName = jobMap['customer_name']?.toString() ?? 'Customer';
    final customerPhone = jobMap['customer_phone']?.toString() ?? '+91 98765 43210';
    final isDark = ProColors.isDark(context);

    return Scaffold(
      backgroundColor: ProColors.bg(context),
      appBar: AppBar(
        backgroundColor: ProColors.bg(context),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Dispatch Detail',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ProColors.txt(context)),
            ),
            Text(
              bookingId,
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: ProColors.txtMuted(context)),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: ProColors.txt(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Pricing Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: ProColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ProColors.primary.withAlpha(80)),
                        ),
                        child: Text(
                          _jobState,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ProColors.primary),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$amount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: ProColors.txt(context),
                            ),
                          ),
                          const Text(
                            'Base + Travel Fee',
                            style: TextStyle(fontSize: 9, color: ProColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    serviceName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ProColors.txt(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: ProColors.emergencyRed, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: ProText.captionStyle(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Net Earnings Payout Card
            Builder(builder: (ctx) {
              final totalVal = double.tryParse(amount) ?? 0.0;
              final platformFeeVal = double.tryParse(jobMap['platform_fee']?.toString() ?? '50') ?? 50.0;
              final netPayoutVal = (totalVal - platformFeeVal) > 0 ? (totalVal - platformFeeVal) : totalVal;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? ProColors.primarySoft : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProColors.primary.withAlpha(70), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer Booking Total',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.txtSec(context)),
                        ),
                        Text(
                          '₹${totalVal.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ProColors.txt(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Platform Fee Split Deduction',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ProColors.txtSec(context)),
                        ),
                        Text(
                          '- ₹${platformFeeVal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ProColors.warningAmber),
                        ),
                      ],
                    ),
                    Divider(
                      color: isDark ? const Color(0xFF1A2A40) : const Color(0xFFDCFCE7),
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: ProColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'YOUR NET EARNINGS PAYOUT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ProColors.primary, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        Text(
                          '₹${netPayoutVal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ProColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Customer Contact Privacy Card
            Builder(builder: (ctx) {
              final isPlatformFeePaid = jobMap['platform_fee_paid'] == true ||
                  ['CONFIRMED', 'NAVIGATING', 'ARRIVED', 'IN_PROGRESS', 'START_OTP_VERIFIED', 'JOB_COMPLETED_PAYMENT_DUE', 'COMPLETED'].contains(_jobState.toUpperCase());

              return GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                borderColor: isPlatformFeePaid ? Colors.transparent : ProColors.warningAmber.withAlpha(100),
                borderWidth: isPlatformFeePaid ? 0 : 1.2,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPlatformFeePaid ? ProColors.accentSoft : ProColors.warningAmberSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPlatformFeePaid ? Icons.person : Icons.lock_rounded,
                        color: isPlatformFeePaid ? ProColors.accent : ProColors.warningAmber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPlatformFeePaid ? customerName : 'Customer Contact Locked 🔒',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ProColors.txt(context),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPlatformFeePaid ? customerPhone : 'Waiting for Customer Platform Fee Payment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPlatformFeePaid ? ProColors.txtMuted(context) : ProColors.warningAmber,
                              fontFamily: isPlatformFeePaid ? 'monospace' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPlatformFeePaid)
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: ProColors.primary),
                        onPressed: () {
                          _showSnackBar('Calling customer $customerPhone...', isSuccess: true);
                        },
                        tooltip: 'Call Customer',
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.lock_clock_outlined, color: ProColors.txtMuted(context)),
                        onPressed: () {
                          _showSnackBar('Customer contact details will unlock automatically as soon as the customer pays the Platform Fee.', isSuccess: false);
                        },
                        tooltip: 'Contact Details Locked',
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Open Live Google Maps Navigation Button
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProMapScreen(job: widget.job))),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? Colors.transparent : Colors.white,
                  side: const BorderSide(color: ProColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.map_rounded, color: ProColors.primary),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('OPEN LIVE GOOGLE MAPS ROUTE & ETA', style: TextStyle(color: ProColors.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // OTP State Machine Execution Button
            if (_jobState == 'REQUESTED') ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _verifyingOtp ? null : _acceptJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _verifyingOtp
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ACCEPT CUSTOMER JOB REQUEST', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ),
            ] else if (_jobState == 'ACCEPTED_PAYMENT_PENDING') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ProColors.warningAmberSoft : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.warningAmber.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: ProColors.warningAmber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Accepted! Awaiting Customer Platform Fee',
                            style: TextStyle(fontWeight: FontWeight.w800, color: ProColors.txt(context), fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Navigation unlocks automatically as soon as customer pays Platform Fee.',
                            style: TextStyle(color: ProColors.warningAmber, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_jobState == 'ACCEPTED' || _jobState == 'NAVIGATING' || _jobState == 'CONFIRMED' || _jobState == 'ARRIVED') ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showStartOtpDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.key_rounded, color: Colors.white),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('ARRIVED AT LOCATION — ENTER START OTP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ),
            ] else if (_jobState == 'IN_PROGRESS') ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showEndOtpDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('WORK COMPLETE — ENTER END OTP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ),
            ] else if (_jobState == 'JOB_COMPLETED_PAYMENT_DUE') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ProColors.warningAmberSoft : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.warningAmber.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_rounded, color: ProColors.warningAmber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End OTP Verified! Awaiting Customer Balance',
                            style: TextStyle(fontWeight: FontWeight.w800, color: ProColors.txt(context), fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your earnings will be credited into your wallet as soon as customer pays balance.',
                            style: TextStyle(color: ProColors.warningAmber, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_jobState == 'COMPLETED') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ProColors.primarySoft : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.primary.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: ProColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Completed & Payment Received!',
                            style: TextStyle(fontWeight: FontWeight.w800, color: ProColors.txt(context), fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '100% of your service price has been credited to your withdrawable wallet.',
                            style: TextStyle(color: ProColors.primary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

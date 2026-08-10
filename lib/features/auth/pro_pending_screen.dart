import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../onboarding/pro_document_upload_screen.dart';

class ProPendingScreen extends StatefulWidget {
  final VoidCallback onApproved;
  final VoidCallback onLogout;

  const ProPendingScreen({
    super.key,
    required this.onApproved,
    required this.onLogout,
  });

  @override
  State<ProPendingScreen> createState() => _ProPendingScreenState();
}

class _ProPendingScreenState extends State<ProPendingScreen> {
  bool _isChecking = false;
  bool _isSimulating = false;
  String _status = ProSessionStorage.verificationStatus;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final health = await ProApiClient.getProHealth();
      final status = health['verificationStatus']?.toString() ?? 'PENDING';

      await ProSessionStorage.updateVerificationStatus(status);
      if (mounted) setState(() => _status = status);

      if (status == 'APPROVED') {
        widget.onApproved();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _simulateAdminApproval() async {
    setState(() => _isSimulating = true);
    try {
      final userId = ProSessionStorage.userId;
      if (userId != null && userId.isNotEmpty) {
        await ProApiClient.adminVerifyPro(userId, 'APPROVED');
      }
      await ProSessionStorage.updateVerificationStatus('APPROVED');
      if (mounted) {
        setState(() => _status = 'APPROVED');
        widget.onApproved();
      }
    } catch (_) {
      // Fallback local update if offline
      await ProSessionStorage.updateVerificationStatus('APPROVED');
      if (mounted) {
        setState(() => _status = 'APPROVED');
        widget.onApproved();
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: ProColors.emergencyRed),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step progress bar (all complete)
              Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: ProColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              // Status Banner
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _status == 'SUSPENDED' || _status == 'REJECTED'
                        ? ProColors.emergencyRedSoft
                        : ProColors.warningAmberSoft,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _status == 'SUSPENDED' || _status == 'REJECTED'
                          ? ProColors.emergencyRed
                          : ProColors.warningAmber,
                    ),
                  ),
                  child: Icon(
                    _status == 'SUSPENDED' || _status == 'REJECTED'
                        ? Icons.lock_clock_outlined
                        : Icons.hourglass_top_rounded,
                    size: 42,
                    color: _status == 'SUSPENDED' || _status == 'REJECTED'
                        ? ProColors.emergencyRed
                        : ProColors.warningAmber,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _status == 'SUSPENDED' || _status == 'REJECTED'
                    ? 'Account Temporarily Suspended'
                    : 'Step 4 of 4: Admin Verification Audit Pending',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),

              Text(
                _status == 'SUSPENDED' || _status == 'REJECTED'
                    ? 'Your account has been suspended or rejected by Admin audit due to document updates. Please re-upload verified documents.'
                    : 'Your profile details and verification documents (Government ID, Police Clearance, Face Selfie) have been submitted. Super Admin review is required before your profile is listed to customers.',
                textAlign: TextAlign.center,
                style: ProText.caption.copyWith(fontSize: 13, height: 1.5),
              ),

              const SizedBox(height: 28),

              // Audit Checklist
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ProColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STIBE PIPELINE VERIFICATION CHECKLIST', style: ProText.label),
                    const SizedBox(height: 14),
                    const _CheckItem(
                      label: 'Step 1: Account Credentials & Gender Gate',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    const _CheckItem(
                      label: 'Step 2: Offered Services & Custom Pricing Rates',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    const _CheckItem(
                      label: 'Step 3: Govt ID, Police PDF & Face Selfie Vault',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    _CheckItem(
                      label: 'Step 4: Super Admin Approval & Customer Listing',
                      isCompleted: _status == 'APPROVED',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isChecking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('REFRESH AUDIT STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Demo / Test Action: Simulate Admin Approval
              OutlinedButton.icon(
                onPressed: _isSimulating ? null : _simulateAdminApproval,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: ProColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSimulating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: ProColors.primary, strokeWidth: 2))
                    : const Icon(Icons.verified, size: 18, color: ProColors.primary),
                label: const Text(
                  'Simulate Admin Approval (Approve & List to Customers)',
                  style: TextStyle(color: ProColors.primary, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProDocumentUploadScreen(onCompleted: _checkStatus),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 16, color: ProColors.accent),
                label: const Text('Update Verification Documents', style: TextStyle(color: ProColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool isCompleted;

  const _CheckItem({required this.label, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? ProColors.primary : ProColors.textMuted,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w400,
              color: isCompleted ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

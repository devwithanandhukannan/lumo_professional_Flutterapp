import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../auth/pro_pending_screen.dart';

class ProSelfieScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const ProSelfieScreen({super.key, required this.onCompleted});

  @override
  State<ProSelfieScreen> createState() => _ProSelfieScreenState();
}

class _ProSelfieScreenState extends State<ProSelfieScreen>
    with TickerProviderStateMixin {
  bool _selfieCapturing = false;
  bool _selfieCaptured = false;
  bool _isSubmitting = false;
  String? _error;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie() async {
    setState(() => _selfieCapturing = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _selfieCapturing = false;
        _selfieCaptured = true;
      });
    }
  }

  Future<void> _submitAndFinish() async {
    if (!_selfieCaptured) {
      setState(() => _error = 'Please capture your live selfie first');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });

    try {
      await ProApiClient.submitDocuments(
        govtIdType: 'DRIVING_LICENSE',
        govtIdNumber: 'UPLOADED',
        faceSelfieUrl: 'https://lumo-vault.s3.amazonaws.com/uploads/face_selfie.jpg',
      );
      await ProSessionStorage.setIsOnboardingComplete(true);
      await ProSessionStorage.updateVerificationStatus('PENDING');
    } catch (_) {
      await ProSessionStorage.setIsOnboardingComplete(true);
      await ProSessionStorage.updateVerificationStatus('PENDING');
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProPendingScreen(
            onApproved: widget.onCompleted,
            onLogout: () {
              ProSessionStorage.clearSession();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _selfieCaptured ? ProColors.primary.withAlpha(40) : ProColors.accent.withAlpha(30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step bar
                    _buildStepBar(),
                    const SizedBox(height: 28),

                    const Text('STEP 4 OF 4 (Part 2)', style: ProText.label),
                    const SizedBox(height: 6),
                    const Text('Live Face Verification', style: ProText.heading1),
                    const SizedBox(height: 6),
                    const Text('We need a real-time selfie to verify your identity. Make sure you\'re in good lighting, face clearly visible.', style: ProText.body),

                    const SizedBox(height: 40),

                    // Selfie frame
                    Center(
                      child: ScaleTransition(
                        scale: _selfieCaptured ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
                        child: GestureDetector(
                          onTap: _selfieCaptured || _selfieCapturing ? null : _captureSelfie,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 220, height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _selfieCaptured
                                    ? [ProColors.primary.withAlpha(40), ProColors.primaryDark.withAlpha(20)]
                                    : [ProColors.accent.withAlpha(30), ProColors.accentSoft.withAlpha(10)],
                              ),
                              border: Border.all(
                                color: _selfieCaptured ? ProColors.primary : ProColors.accent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_selfieCaptured ? ProColors.primary : ProColors.accent).withAlpha(60),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selfieCapturing) ...[
                                  const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                  const SizedBox(height: 12),
                                  const Text('Capturing...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ] else if (_selfieCaptured) ...[
                                  const Icon(Icons.check_circle_rounded, color: ProColors.primary, size: 64),
                                  const SizedBox(height: 8),
                                  const Text('Selfie Ready ✓', style: TextStyle(color: ProColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                                ] else ...[
                                  const Icon(Icons.camera_front_rounded, color: Colors.white, size: 56),
                                  const SizedBox(height: 8),
                                  const Text('Tap to Capture', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Guidelines
                    GlassCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _guideline(Icons.wb_sunny_outlined, 'Good lighting — face clearly visible'),
                          _guideline(Icons.face_outlined, 'No masks, glasses or hats'),
                          _guideline(Icons.center_focus_strong_outlined, 'Look directly into the camera'),
                        ],
                      ),
                    ),

                    const Spacer(),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ProColors.emergencyRedSoft,
                          border: Border.all(color: ProColors.emergencyRedBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    GradientButton(
                      label: 'SUBMIT FOR ADMIN REVIEW',
                      onTap: _submitAndFinish,
                      isLoading: _isSubmitting,
                      icon: Icons.send_rounded,
                      colors: [ProColors.primary, ProColors.primaryDark],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideline(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: ProColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 12, color: ProColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStepBar() => Row(
    children: List.generate(4, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
        height: 4,
        decoration: BoxDecoration(
          color: i < 3 ? ProColors.primary : ProColors.primary.withAlpha(160),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}

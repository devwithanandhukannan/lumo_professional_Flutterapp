import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';
import '../../core/network/pro_api_client.dart';

class ProAccountHealthScreen extends StatefulWidget {
  const ProAccountHealthScreen({super.key});

  @override
  State<ProAccountHealthScreen> createState() => _ProAccountHealthScreenState();
}

class _ProAccountHealthScreenState extends State<ProAccountHealthScreen> {
  final double _healthScore = 96.0; // 0 - 100
  final double _ratingAvg = 4.92;
  final int _completedJobs = 142;
  final double _acceptanceRate = 98.5; // %
  final double _cancellationRate = 1.2; // %

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = _healthScore >= 80;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Health & Compliance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ProApiClient.getProHealth();
            if (mounted) setState(() {});
          } catch (_) {}
        },
        color: ProColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gauge & Score Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ProColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHealthy ? ProColors.primary : ProColors.warningAmber,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHealthy ? const Color(0x3310B981) : const Color(0x33F59E0B),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: _healthScore / 100,
                          strokeWidth: 10,
                                            color: isHealthy ? ProColors.primary : ProColors.warningAmber,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_healthScore.toInt()}',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '/ 100',
                            style: TextStyle(fontSize: 12, color: ProColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isHealthy ? 'EXCELLENT ACCOUNT HEALTH' : 'NEEDS ATTENTION',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isHealthy ? ProColors.primary : ProColors.warningAmber,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your account health score is calculated based on customer ratings, job acceptance rate, low cancellation rates, and safety protocol adherence.',
                    textAlign: TextAlign.center,
                    style: ProText.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Performance Grid Metrics
            const Text('PERFORMANCE METRICS', style: ProText.label),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _MetricTile(
                  label: 'AVERAGE RATING',
                  value: '⭐ $_ratingAvg',
                  subtitle: 'From 142 Reviews',
                  color: ProColors.warningAmber,
                ),
                _MetricTile(
                  label: 'JOBS COMPLETED',
                  value: '$_completedJobs',
                  subtitle: '100% Safety Verified',
                  color: ProColors.primary,
                ),
                _MetricTile(
                  label: 'ACCEPTANCE RATE',
                  value: '$_acceptanceRate%',
                  subtitle: 'Target: > 90%',
                  color: ProColors.accent,
                ),
                _MetricTile(
                  label: 'CANCELLATION RATE',
                  value: '$_cancellationRate%',
                  subtitle: 'Target: < 5%',
                  color: ProColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Compliance Badges Checklist
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ProColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLATFORM COMPLIANCE BADGES', style: ProText.label),
                  SizedBox(height: 14),
                  _BadgeTile(
                    title: 'Background Check Verified',
                    description: 'Government ID & Police Clearance PDF passed',
                    icon: Icons.shield_rounded,
                    color: ProColors.primary,
                  ),
                  SizedBox(height: 10),
                  _BadgeTile(
                    title: 'Face Verification Selfie Match',
                    description: 'Live face verification matched with Govt ID photo',
                    icon: Icons.face_retouching_natural,
                    color: ProColors.accent,
                  ),
                  SizedBox(height: 10),
                  _BadgeTile(
                    title: 'Women Safety Certified',
                    description: 'Completed LUMO Safety & Misconduct Protocol Module',
                    icon: Icons.verified_user_rounded,
                    color: Colors.pinkAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tips to Maintain High Score
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ProColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: ProColors.warningAmber, size: 20),
                      SizedBox(width: 8),
                      Text('HOW TO KEEP A 95+ HEALTH SCORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('• Always verify customer Start OTP before beginning work.', style: ProText.caption),
                  SizedBox(height: 4),
                  Text('• Arrive on time at customer location within the estimated ETA.', style: ProText.caption),
                  SizedBox(height: 4),
                  Text('• Maintain mandatory safety protocol and wear LUMO partner badge.', style: ProText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: ProText.label.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: ProText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _BadgeTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
              Text(description, style: ProText.caption),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: color, size: 18),
      ],
    );
  }
}

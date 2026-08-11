import 'package:flutter/material.dart';
import '../../../core/theme/pro_theme.dart';

class OnboardingStepperHeader extends StatelessWidget {
  final int currentStep; // 1 to 4
  final int totalSteps;

  const OnboardingStepperHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  static const List<Map<String, String>> steps = [
    {'title': 'Basic Auth', 'subtitle': 'Account & Profile'},
    {'title': 'Services', 'subtitle': 'Catalog & Pricing'},
    {'title': 'Doc Vault', 'subtitle': 'ID & Clearance'},
    {'title': 'Admin Audit', 'subtitle': 'Approval & Listing'},
  ];

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    final isDark = ProColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProColors.brd(context)),
        boxShadow: ProColors.cardShadow(context, elevation: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Number & Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? ProColors.primarySoft : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? ProColors.primary : const Color(0xFF10B981), width: 1),
                    ),
                    child: Text(
                      'STEP $currentStep OF $totalSteps',
                      style: TextStyle(
                        color: isDark ? ProColors.primary : const Color(0xFF047857),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    steps[(currentStep - 1).clamp(0, totalSteps - 1)]['title'] ?? '',
                    style: TextStyle(
                      color: ProColors.txt(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}% Done',
                style: TextStyle(
                  color: ProColors.txtMuted(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? ProColors.surfaceHigh : const Color(0xFFE2E8F0),
              color: ProColors.primary,
            ),
          ),

          const SizedBox(height: 14),

          // 4-Step Nodes Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isCompleted = stepNum < currentStep;
              final isCurrent = stepNum == currentStep;

              final Color nodeColor = isCompleted
                  ? ProColors.primary
                  : (isCurrent ? (isDark ? ProColors.accent : const Color(0xFF2563EB)) : ProColors.brd(context));

              final Color iconColor = isCompleted
                  ? Colors.white
                  : (isCurrent
                      ? (isDark ? Colors.white : const Color(0xFF1D4ED8))
                      : (isDark ? ProColors.textMuted : const Color(0xFF64748B)));

              final Color nodeBg = isCompleted
                  ? ProColors.primary
                  : (isCurrent
                      ? (isDark ? ProColors.accentSoft : const Color(0xFFDBEAFE))
                      : (isDark ? ProColors.card(context) : const Color(0xFFF1F5F9)));

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: nodeBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: nodeColor,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: iconColor,
                                ),
                              ),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? ProColors.primary : ProColors.brd(context),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

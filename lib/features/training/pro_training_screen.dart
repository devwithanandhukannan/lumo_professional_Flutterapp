import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';

class ProTrainingScreen extends StatefulWidget {
  const ProTrainingScreen({super.key});

  @override
  State<ProTrainingScreen> createState() => _ProTrainingScreenState();
}

class _ProTrainingScreenState extends State<ProTrainingScreen> {
  final List<Map<String, dynamic>> _modules = [
    {
      'id': 'tr-01',
      'title': 'Safety Guidelines & Emergency SOS Protocol',
      'category': 'SAFETY MANDATE',
      'duration': '10 mins',
      'completed': true,
      'score': '100%',
      'icon': Icons.shield_rounded,
      'color': ProColors.primary,
    },
    {
      'id': 'tr-02',
      'title': 'Professional Behavior & Gender Sensitivity',
      'category': 'BEHAVIOR',
      'duration': '15 mins',
      'completed': true,
      'score': '95%',
      'icon': Icons.record_voice_over_rounded,
      'color': ProColors.accent,
    },
    {
      'id': 'tr-03',
      'title': 'OTP Verification & Fraud Prevention',
      'category': 'SECURITY',
      'duration': '8 mins',
      'completed': true,
      'score': '100%',
      'icon': Icons.lock_person_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'id': 'tr-04',
      'title': 'Service Quality Standards & Customer Rating',
      'category': 'QUALITY',
      'duration': '12 mins',
      'completed': false,
      'score': 'Pending',
      'icon': Icons.star_rounded,
      'color': ProColors.warningAmber,
    },
  ];

  void _startModuleQuiz(Map<String, dynamic> module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(module['icon'] as IconData, color: module['color'] as Color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                module['title'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${module['category']}', style: ProText.label),
            const SizedBox(height: 10),
            const Text(
              'This training module covers mandatory safety protocols, customer respect policies, and verification steps. Complete the 5-question quiz to earn your certification badge.',
              style: ProText.body,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ProColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ProColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: ProColors.primary, size: 20),
                  SizedBox(width: 10),
                  Text('Passing Score: 80% or higher', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: ProColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                module['completed'] = true;
                module['score'] = '100%';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Module "${module['title']}" passed! Certification badge awarded.'),
                  backgroundColor: ProColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('START QUIZ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = _modules.where((m) => m['completed'] == true).length;
    final double completionPct = completedCount / _modules.length;

    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: const Text('Compliance & Safety Academy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Training Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ProColors.surface, ProColors.cardBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ProColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TRAINING PROGRESS', style: ProText.label),
                      Text(
                        '$completedCount of ${_modules.length} Modules Passed',
                        style: const TextStyle(color: ProColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: completionPct,
                      minHeight: 8,
                      backgroundColor: ProColors.background,
                      color: ProColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All service providers are required to complete mandatory safety & conduct training to maintain active provider status on LUMO.',
                    style: ProText.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('MANDATORY TRAINING MODULES', style: ProText.label),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _modules.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = _modules[index];
                final bool isCompleted = module['completed'] as bool;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted ? ProColors.primarySoft : ProColors.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCompleted ? ProColors.primary : ProColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (module['color'] as Color).withAlpha(35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(module['icon'] as IconData, color: module['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ProColors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                module['category'] as String,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ProColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              module['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text('Duration: ${module['duration']} • Score: ${module['score']}', style: ProText.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                          color: isCompleted ? ProColors.primary : ProColors.accent,
                          size: 28,
                        ),
                        onPressed: () => _startModuleQuiz(module),
                        tooltip: isCompleted ? 'Passed' : 'Start Module',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

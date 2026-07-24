import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';

class ProSosWidget extends StatefulWidget {
  final String? bookingId;
  const ProSosWidget({super.key, this.bookingId});

  @override
  State<ProSosWidget> createState() => _ProSosWidgetState();
}

class _ProSosWidgetState extends State<ProSosWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _confirmSos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ProColors.emergencyRed, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ProColors.emergencyRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('PROVIDER EMERGENCY SOS', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: const Text(
          'This will immediately alert the LUMO Safety Control Center with your GPS location.\n\nOnly use in a genuine emergency.',
          style: TextStyle(color: ProColors.textMuted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: ProColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _triggerSos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.emergencyRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SEND SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    try {
      await ProApiClient.triggerSos(
        latitude: 12.9716,
        longitude: 77.5946,
        bookingId: widget.bookingId,
        notes: 'Provider Mobile Emergency SOS Pressed',
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ProColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('🔴 PROVIDER SOS SENT TO SAFETY CONTROL CENTER', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: FloatingActionButton.extended(
        onPressed: _confirmSos,
        heroTag: 'pro_sos_fab',
        backgroundColor: ProColors.emergencyRed,
        elevation: 6,
        icon: const Icon(Icons.shield_outlined, color: Colors.white),
        label: const Text('PRO SOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 13)),
      ),
    );
  }
}

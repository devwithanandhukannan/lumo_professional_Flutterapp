import 'package:flutter/services.dart';

class ProHapticService {
  /// Urgent repeating vibration alert sequence when a new customer booking request pops up
  static Future<void> incomingJobRequest() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Medium tactile click vibration when the Pro accepts a job request
  static Future<void> jobAccepted() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light tactile vibration for general pro app interactions
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}

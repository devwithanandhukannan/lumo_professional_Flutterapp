import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_service_setup_screen.dart';
import 'widgets/onboarding_stepper_header.dart';
import 'widgets/pro_location_picker_modal.dart';

class ProRegistrationBasicsScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onCompleted;

  const ProRegistrationBasicsScreen({
    super.key,
    required this.phoneNumber,
    required this.onCompleted,
  });

  @override
  State<ProRegistrationBasicsScreen> createState() => _ProRegistrationBasicsScreenState();
}

class _ProRegistrationBasicsScreenState extends State<ProRegistrationBasicsScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController(text: 'Kochi');

  String _selectedGender = 'MALE';
  bool _isLoading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;

  final List<Map<String, dynamic>> _genders = [
    {'value': 'MALE', 'label': 'Male', 'icon': Icons.male_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': 'FEMALE', 'label': 'Female', 'icon': Icons.female_rounded, 'color': const Color(0xFFEC4899)},
    {'value': 'OTHER', 'label': 'Other', 'icon': Icons.person_outline_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    if (ProSessionStorage.userName != 'Professional') {
      _nameCtrl.text = ProSessionStorage.userName;
    }
    if (ProSessionStorage.userEmail.isNotEmpty) {
      _emailCtrl.text = ProSessionStorage.userEmail;
    }
    if (ProSessionStorage.age > 0) {
      _ageCtrl.text = ProSessionStorage.age.toString();
    }
    if (ProSessionStorage.serviceArea.isNotEmpty) {
      _serviceAreaCtrl.text = ProSessionStorage.serviceArea;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _emailCtrl.dispose();
    _serviceAreaCtrl.dispose();
    super.dispose();
  }

  double? _selectedLat;
  double? _selectedLng;

  Future<void> _openGoogleMapPicker() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProLocationPickerModal(
        initialAddress: _serviceAreaCtrl.text.isNotEmpty ? _serviceAreaCtrl.text : 'Kochi, Kerala',
      ),
    );

    if (result != null) {
      if (result is Map) {
        setState(() {
          _serviceAreaCtrl.text = (result['cityName'] ?? result['address'] ?? 'Kochi').toString();
          if (result['latitude'] != null) _selectedLat = (result['latitude'] as num).toDouble();
          if (result['longitude'] != null) _selectedLng = (result['longitude'] as num).toDouble();
        });
      } else if (result is String && result.isNotEmpty) {
        setState(() {
          _serviceAreaCtrl.text = result;
        });
      }
    }
  }

  Future<void> _proceed() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final email = _emailCtrl.text.trim();
    final area = _serviceAreaCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (age == null || age < 18 || age > 65) {
      setState(() => _error = 'Age must be between 18 and 65');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final phone = widget.phoneNumber.isNotEmpty ? widget.phoneNumber : ProSessionStorage.userPhone;

    double? lat = _selectedLat;
    double? lng = _selectedLng;

    if ((lat == null || lng == null) && area.isNotEmpty) {
      try {
        final geocodeUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(area)}&key=AIzaSyD9r59vIxUjLj3hiICvy9CYbXYbmil0Xb4',
        );
        final geoRes = await http.get(geocodeUrl).timeout(const Duration(seconds: 4));
        final geoData = jsonDecode(geoRes.body);
        if (geoData['status'] == 'OK' && (geoData['results'] as List).isNotEmpty) {
          final loc = geoData['results'][0]['geometry']['location'];
          lat = (loc['lat'] as num).toDouble();
          lng = (loc['lng'] as num).toDouble();
        }
      } catch (_) {}
    }

    try {
      final res = await ProApiClient.registerProWithPhone(
        phoneNumber: phone,
        fullName: name,
        age: age,
        email: email,
        gender: _selectedGender,
        serviceArea: area.isEmpty ? 'Kochi' : area,
        latitude: lat,
        longitude: lng,
      );

      final data = res['data'] ?? res;
      final user = data['user'] ?? {};

      await ProSessionStorage.setSession(
        token: ProSessionStorage.authToken ?? '',
        phone: phone,
        email: email.isEmpty ? null : email,
        name: name,
        gender: _selectedGender,
        userId: user['id']?.toString() ?? ProSessionStorage.userId,
        verificationStatus: data['verificationStatus']?.toString() ?? 'PENDING',
        age: age,
        serviceArea: area.isEmpty ? 'Kochi' : area,
        isOnboardingComplete: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProServiceSetupScreen(onCompleted: widget.onCompleted),
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ProColors.isDark(context);

    return Scaffold(
      backgroundColor: ProColors.bg(context),
      body: Stack(
        children: [
          _buildBgBlobs(),
          SafeArea(
            child: FadeTransition(
              opacity: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: ProColors.txt(context)),
                      onPressed: () async {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          await ProSessionStorage.clearSession();
                          widget.onCompleted();
                        }
                      },
                    ),
                    title: Text('Basic Profile Details', style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.bold)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const OnboardingStepperHeader(currentStep: 1),
                        const SizedBox(height: 4),

                        Text('Tell Us About Yourself', style: ProText.heading1Style(context)),
                        const SizedBox(height: 6),
                        Text('Basic information to create your professional profile.', style: ProText.bodyStyle(context)),
                        const SizedBox(height: 24),

                        if (_error != null) _errorBanner(_error!),

                        GlassCard(
                          borderRadius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('FULL NAME *', style: ProText.labelStyle(context)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: TextStyle(color: ProColors.txt(context), fontSize: 16),
                                decoration: proInputDecoration(
                                  hint: 'Your Full Name',
                                  prefix: const Icon(Icons.person_rounded, color: ProColors.primary, size: 20),
                                  context: context,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('AGE *', style: ProText.labelStyle(context)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _ageCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          maxLength: 2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: ProColors.txt(context), fontSize: 16, fontWeight: FontWeight.w700),
                                          decoration: proInputDecoration(hint: '25', context: context).copyWith(
                                            counterText: '',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('EMAIL', style: ProText.labelStyle(context)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _emailCtrl,
                                          keyboardType: TextInputType.emailAddress,
                                          style: TextStyle(color: ProColors.txt(context), fontSize: 14),
                                          decoration: proInputDecoration(
                                            hint: 'name@email.com',
                                            prefix: const Icon(Icons.email_outlined, color: ProColors.primary, size: 18),
                                            context: context,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Text('GENDER *', style: ProText.labelStyle(context)),
                              const SizedBox(height: 8),
                              Row(
                                children: _genders.map((g) {
                                  final selected = _selectedGender == g['value'];
                                  final color = g['color'] as Color;
                                  final Color selectedBg = isDark
                                      ? color.withAlpha(35)
                                      : (g['value'] == 'MALE'
                                          ? const Color(0xFFEFF6FF)
                                          : (g['value'] == 'FEMALE' ? const Color(0xFFFDF2F8) : const Color(0xFFF0FDF4)));
                                  final Color unselectedBg = isDark ? const Color(0x0AFFFFFF) : const Color(0xFFF8FAFC);
                                  final Color unselectedBorder = isDark ? ProColors.glassBorder : const Color(0xFFE2E8F0);
                                  final Color textColor = selected ? color : ProColors.txtMuted(context);

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedGender = g['value']),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: selected ? selectedBg : unselectedBg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: selected ? color : unselectedBorder,
                                            width: selected ? 1.5 : 1,
                                          ),
                                          boxShadow: selected && !isDark
                                              ? [BoxShadow(color: color.withAlpha(25), blurRadius: 6, offset: const Offset(0, 2))]
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(g['icon'] as IconData, color: textColor, size: 22),
                                            const SizedBox(height: 5),
                                            Text(
                                              g['label'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('SERVICE AREA / CITY *', style: ProText.labelStyle(context)),
                                  GestureDetector(
                                    onTap: _openGoogleMapPicker,
                                    child: const Row(
                                      children: [
                                        Icon(Icons.map_rounded, color: ProColors.primary, size: 14),
                                        SizedBox(width: 4),
                                        Text('Select on Google Map', style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serviceAreaCtrl,
                                style: TextStyle(color: ProColors.txt(context), fontSize: 16),
                                decoration: proInputDecoration(
                                  hint: 'e.g. Kochi, Bangalore',
                                  prefix: const Icon(Icons.location_city_rounded, color: ProColors.primary, size: 20),
                                  suffix: IconButton(
                                    icon: const Icon(Icons.pin_drop_rounded, color: ProColors.primary),
                                    onPressed: _openGoogleMapPicker,
                                    tooltip: 'Open Google Map Location Picker',
                                  ),
                                  context: context,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('You can accept jobs within the admin-set radius (default 50km) of this area.', style: ProText.captionStyle(context)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        GradientButton(
                          label: 'NEXT: SELECT SERVICES',
                          onTap: _proceed,
                          isLoading: _isLoading,
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBgBlobs() {
    return Positioned(
      top: -60, left: -60,
      child: Container(
        width: 250, height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [ProColors.primary.withAlpha(30), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.emergencyRedSoft,
        border: Border.all(color: ProColors.emergencyRedBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ProColors.emergencyRed, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 13))),
        ],
      ),
    );
  }
}

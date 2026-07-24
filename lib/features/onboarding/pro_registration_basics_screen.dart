import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_service_setup_screen.dart';
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

  Future<void> _openGoogleMapPicker() async {
    final selectedCity = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProLocationPickerModal(
        initialAddress: _serviceAreaCtrl.text.isNotEmpty ? _serviceAreaCtrl.text : 'Kochi, Kerala',
      ),
    );

    if (selectedCity != null && selectedCity.isNotEmpty) {
      setState(() {
        _serviceAreaCtrl.text = selectedCity;
      });
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

    try {
      final res = await ProApiClient.registerProWithPhone(
        phoneNumber: phone,
        fullName: name,
        age: age,
        email: email,
        gender: _selectedGender,
        serviceArea: area.isEmpty ? 'Kochi' : area,
      );

      final data = res['data'] ?? res;
      final user = data['user'] ?? {};

      await ProSessionStorage.setSession(
        token: ProSessionStorage.authToken ?? 'mock-token',
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
    } catch (_) {
      // Local fallback save so onboarding user is not blocked
      await ProSessionStorage.setSession(
        token: ProSessionStorage.authToken ?? 'mock-token',
        phone: phone,
        email: email.isEmpty ? null : email,
        name: name,
        gender: _selectedGender,
        verificationStatus: 'PENDING',
        age: age,
        serviceArea: area.isEmpty ? 'Kochi' : area,
        isOnboardingComplete: false,
      );
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
    return Scaffold(
      backgroundColor: ProColors.background,
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
                    leading: const BackButton(color: ProColors.textMuted),
                    title: const Text('Basic Profile Details'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStepIndicator(),
                        const SizedBox(height: 20),

                        const Text('STEP 2 OF 4', style: ProText.label),
                        const SizedBox(height: 4),
                        const Text('Tell Us About Yourself', style: ProText.heading1),
                        const SizedBox(height: 6),
                        const Text('Basic information to create your professional profile.', style: ProText.body),
                        const SizedBox(height: 24),

                        if (_error != null) _errorBanner(_error!),

                        GlassCard(
                          borderRadius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('FULL NAME *', style: ProText.label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: ProColors.textPrimary, fontSize: 16),
                                decoration: proInputDecoration(
                                  hint: 'Your Full Name',
                                  prefix: const Icon(Icons.person_rounded, color: ProColors.primary, size: 20),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('AGE *', style: ProText.label),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _ageCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          maxLength: 2,
                                          style: const TextStyle(color: ProColors.textPrimary, fontSize: 16),
                                          decoration: proInputDecoration(hint: 'e.g. 25').copyWith(counterText: ''),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('EMAIL', style: ProText.label),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _emailCtrl,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: ProColors.textPrimary, fontSize: 14),
                                          decoration: proInputDecoration(hint: 'name@email.com'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              const Text('GENDER *', style: ProText.label),
                              const SizedBox(height: 8),
                              Row(
                                children: _genders.map((g) {
                                  final selected = _selectedGender == g['value'];
                                  final color = g['color'] as Color;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedGender = g['value']),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: selected ? color.withAlpha(30) : const Color(0x0AFFFFFF),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: selected ? color : ProColors.glassBorder, width: selected ? 1.5 : 1),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(g['icon'] as IconData, color: selected ? color : ProColors.textMuted, size: 20),
                                            const SizedBox(height: 4),
                                            Text(g['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? color : ProColors.textMuted)),
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
                                  const Text('SERVICE AREA / CITY *', style: ProText.label),
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
                                style: const TextStyle(color: ProColors.textPrimary, fontSize: 16),
                                decoration: proInputDecoration(
                                  hint: 'e.g. Kochi, Bangalore',
                                  prefix: const Icon(Icons.location_city_rounded, color: ProColors.primary, size: 20),
                                  suffix: IconButton(
                                    icon: const Icon(Icons.pin_drop_rounded, color: ProColors.primary),
                                    onPressed: _openGoogleMapPicker,
                                    tooltip: 'Open Google Map Location Picker',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('You can accept jobs within the admin-set radius (default 50km) of this area.', style: ProText.caption),
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

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(4, (i) {
        final active = i == 1;
        final done = i == 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? ProColors.primary
                  : active
                      ? ProColors.primary.withAlpha(180)
                      : ProColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_document_upload_screen.dart';
import 'widgets/onboarding_stepper_header.dart';

class ProServiceSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isStandaloneManagement;

  const ProServiceSetupScreen({
    super.key,
    required this.onCompleted,
    this.isStandaloneManagement = false,
  });

  @override
  State<ProServiceSetupScreen> createState() => _ProServiceSetupScreenState();
}

class _ProServiceSetupScreenState extends State<ProServiceSetupScreen> {
  List<Map<String, dynamic>> _catalogServices = [];
  final Map<String, bool> _selected = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _kmChargeControllers = {};
  List<Map<String, dynamic>> _myServiceRequests = [];

  bool _loadingServices = true;
  bool _isSaving = false;
  bool _showCustomServiceForm = false;
  String? _error;

  final _customNameCtrl = TextEditingController();
  final _customDescCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  bool _submittingCustom = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _customDescCtrl.dispose();
    _customPriceCtrl.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _kmChargeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final svcs = await ProApiClient.getCatalogServices();
      final list = svcs.map((s) => Map<String, dynamic>.from(s)).toList();
      _initServices(list);
    } catch (_) {
      _initServices([]);
    }

    try {
      final profileRes = await ProApiClient.getProfile();
      final offered = (profileRes['offeredServices'] as List?) ??
          (profileRes['data']?['offeredServices'] as List?) ??
          [];
      if (mounted) {
        setState(() {
          for (final o in offered) {
            final sId = o['service_id']?.toString() ?? o['id']?.toString();
            if (sId != null && o['is_active'] != false) {
              _selected[sId] = true;
              if (o['custom_price'] != null && _priceControllers.containsKey(sId)) {
                _priceControllers[sId]?.text = o['custom_price'].toString();
              }
            }
          }
        });
      }
    } catch (_) {}

    try {
      final reqs = await ProApiClient.getMyServiceRequests();
      if (mounted) {
        setState(() {
          _myServiceRequests = reqs.map((r) => Map<String, dynamic>.from(r)).toList();
        });
      }
    } catch (_) {}
  }

  void _initServices(List<Map<String, dynamic>> services) {
    for (final s in services) {
      final id = s['id'].toString();
      _priceControllers[id] = TextEditingController(text: s['base_price']?.toString() ?? '');
      _kmChargeControllers[id] = TextEditingController(text: '15');
    }
    if (mounted) {
      setState(() {
        _catalogServices = services;
        _loadingServices = false;
      });
    }
  }

  Future<void> _submitCustomService() async {
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _submittingCustom = true);
    try {
      final result = await ProApiClient.requestCustomService(
        serviceName: name,
        description: _customDescCtrl.text.trim(),
        suggestedPrice: double.tryParse(_customPriceCtrl.text.trim()),
      );
      if (mounted) {
        setState(() {
          _myServiceRequests.insert(0, result);
          _showCustomServiceForm = false;
          _customNameCtrl.clear();
          _customDescCtrl.clear();
          _customPriceCtrl.clear();
        });
        _showSnack('Service request submitted! Admin will review soon.');
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submittingCustom = false);
    }
  }

  Future<void> _saveServices() async {
    final selectedItems = <Map<String, dynamic>>[];
    for (final s in _catalogServices) {
      final id = s['id'].toString();
      if (_selected[id] == true) {
        final price = double.tryParse(_priceControllers[id]?.text.trim() ?? '') ??
            double.tryParse(s['base_price']?.toString() ?? '0') ??
            0;
        final kmCharge = double.tryParse(_kmChargeControllers[id]?.text.trim() ?? '15') ?? 15.0;
        selectedItems.add({'serviceId': id, 'customPrice': price, 'kmCharge': kmCharge});
      }
    }

    if (selectedItems.isEmpty && _myServiceRequests.isEmpty) {
      setState(() => _error = 'Please select at least one service you offer');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ProApiClient.saveOfferedServices(selectedItems);
      if (mounted) {
        if (widget.isStandaloneManagement) {
          _showSnack('Offered services updated successfully');
          Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProDocumentUploadScreen(onCompleted: widget.onCompleted),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (widget.isStandaloneManagement) {
          Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProDocumentUploadScreen(onCompleted: widget.onCompleted),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? ProColors.emergencyRed : ProColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ProColors.isDark(context);

    return Scaffold(
      backgroundColor: ProColors.bg(context),
      appBar: AppBar(
        title: Text(widget.isStandaloneManagement ? 'Manage Offered Services' : 'Service Configuration'),
        automaticallyImplyLeading: widget.isStandaloneManagement,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isStandaloneManagement) ...[
              const OnboardingStepperHeader(currentStep: 2),
              const SizedBox(height: 4),
            ],

            Text('Your Services & Rates', style: ProText.heading1Style(context)),
            const SizedBox(height: 6),
            Text(
              widget.isStandaloneManagement
                  ? 'Select the admin services you offer and set your custom pricing rates.'
                  : 'Select services you offer. Set your custom rates and travel fee per km.',
              style: ProText.bodyStyle(context),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ProColors.emergencyRedSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProColors.emergencyRedBorder),
                ),
                child: Text(_error!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12)),
              ),
              const SizedBox(height: 16),
            ],

            // Services list
            if (_loadingServices)
              const Center(child: CircularProgressIndicator(color: ProColors.primary))
            else if (_catalogServices.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ProColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProColors.brd(context)),
                  boxShadow: ProColors.cardShadow(context, elevation: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ProColors.txtMuted(context), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'No Admin Services Available Yet',
                      style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use "+ Request Custom Service" below to suggest a new service for Admin approval.',
                      style: ProText.captionStyle(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _catalogServices.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = _catalogServices[index];
                  final id = service['id'].toString();
                  final isChecked = _selected[id] == true;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? (isDark ? ProColors.primarySoft : const Color(0xFFF0FDF4))
                          : ProColors.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isChecked ? ProColors.primary : ProColors.brd(context),
                        width: isChecked ? 1.5 : 1,
                      ),
                      boxShadow: ProColors.cardShadow(context, elevation: isChecked ? 1.0 : 0.5),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selected[id] = !isChecked),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  activeColor: ProColors.primary,
                                  onChanged: (val) => setState(() => _selected[id] = val ?? false),
                                ),
                                Text(service['icon']?.toString() ?? '🔧', style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['name']?.toString() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ProColors.txt(context),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text('Base Price: ₹${service['base_price']}', style: ProText.captionStyle(context)),
                                    ],
                                  ),
                                ),
                                if (isChecked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? ProColors.primarySoft : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: ProColors.primary.withAlpha(80)),
                                    ),
                                    child: const Text(
                                      'SELECTED',
                                      style: TextStyle(color: ProColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (isChecked) ...[
                          Divider(color: isDark ? ProColors.border : const Color(0xFFDCFCE7), height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('YOUR CUSTOM RATE (₹)', style: TextStyle(color: ProColors.txtMuted(context), fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _priceControllers[id],
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.bold, fontSize: 14),
                                        decoration: proInputDecoration(context: context, hint: '₹ Rate').copyWith(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          prefixIcon: const Icon(Icons.currency_rupee, color: ProColors.accent, size: 16),
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
                                      const Text('TRAVEL FEE (₹/KM)', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _kmChargeControllers[id],
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.bold, fontSize: 14),
                                        decoration: proInputDecoration(context: context, hint: '₹/km').copyWith(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          prefixIcon: const Icon(Icons.directions_car_rounded, color: Color(0xFFD97706), size: 16),
                                        ),
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
                  );
                },
              ),

            const SizedBox(height: 20),

            // Custom service requests list
            if (_myServiceRequests.isNotEmpty) ...[
              Text('MY CUSTOM SERVICE REQUESTS', style: ProText.labelStyle(context)),
              const SizedBox(height: 10),
              ..._myServiceRequests.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ProColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ProColors.brd(context)),
                  boxShadow: ProColors.cardShadow(context, elevation: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['service_name']?.toString() ?? '', style: TextStyle(color: ProColors.txt(context), fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(r['status']?.toString() ?? 'PENDING', style: const TextStyle(color: Color(0xFFD97706), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Add Custom Service Section
            InkWell(
              onTap: () => setState(() => _showCustomServiceForm = !_showCustomServiceForm),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ProColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.primary.withAlpha(80)),
                  boxShadow: ProColors.cardShadow(context, elevation: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_circle_outline_rounded, color: ProColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request a New Service', style: TextStyle(fontWeight: FontWeight.w700, color: ProColors.txt(context), fontSize: 13)),
                          Text('Not in the list? Request — admin will review & add it.', style: ProText.captionStyle(context)),
                        ],
                      ),
                    ),
                    Icon(_showCustomServiceForm ? Icons.expand_less : Icons.expand_more, color: ProColors.txtMuted(context)),
                  ],
                ),
              ),
            ),

            if (_showCustomServiceForm) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.brd(context)),
                  boxShadow: ProColors.cardShadow(context, elevation: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('SERVICE NAME *', style: ProText.labelStyle(context)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customNameCtrl,
                      style: TextStyle(color: ProColors.txt(context), fontSize: 13),
                      decoration: proInputDecoration(context: context, hint: 'e.g. CCTV Installation'),
                    ),
                    const SizedBox(height: 10),
                    Text('DESCRIPTION', style: ProText.labelStyle(context)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customDescCtrl,
                      maxLines: 2,
                      style: TextStyle(color: ProColors.txt(context), fontSize: 13),
                      decoration: proInputDecoration(context: context, hint: 'Brief description'),
                    ),
                    const SizedBox(height: 10),
                    Text('SUGGESTED PRICE (₹)', style: ProText.labelStyle(context)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: TextStyle(color: ProColors.txt(context), fontSize: 13),
                      decoration: proInputDecoration(context: context, hint: '499'),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: _submittingCustom ? 'SUBMITTING TO ADMIN...' : 'SUBMIT FOR ADMIN REVIEW',
                      icon: Icons.send_rounded,
                      onTap: _submittingCustom ? null : _submitCustomService,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            GradientButton(
              label: widget.isStandaloneManagement
                  ? 'SAVE OFFERED SERVICES'
                  : 'PROCEED TO STEP 3 (DOCUMENT VAULT)',
              icon: Icons.arrow_forward_rounded,
              onTap: _isSaving ? null : _saveServices,
            ),
          ],
        ),
      ),
    );
  }
}

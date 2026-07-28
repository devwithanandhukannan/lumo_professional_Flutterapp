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
    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
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
              const Text('Step 2 of 4: Professional Catalog & Rates', style: ProText.label),
              const SizedBox(height: 4),
            ],

            const Text('Your Services & Rates', style: ProText.heading2),
            const SizedBox(height: 6),
            Text(
              widget.isStandaloneManagement
                  ? 'Select the admin services you offer and set your custom pricing rates.'
                  : 'Select services you offer. Set your custom rates (base price shown for reference, commission is handled by admin).',
              style: ProText.caption,
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
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProColors.glassBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ProColors.textMuted, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'No Admin Services Available Yet',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use "+ Request Custom Service" below to suggest a new service for Admin approval.',
                      style: TextStyle(color: ProColors.textMuted, fontSize: 12),
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
                separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final service = _catalogServices[index];
                  final id = service['id'].toString();
                  final isChecked = _selected[id] == true;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isChecked ? ProColors.primarySoft : ProColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isChecked ? ProColors.primary : ProColors.border),
                    ),
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
                              Text(service['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                              Text('Base: ₹${service['base_price']}', style: ProText.caption),
                            ],
                          ),
                        ),
                        if (isChecked) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: TextField(
                              controller: _priceControllers[id],
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: proInputDecoration(hint: '₹ Rate').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 72,
                            child: TextField(
                              controller: _kmChargeControllers[id],
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: proInputDecoration(hint: '₹/km').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                hintStyle: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                              ),
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
              const Text('MY CUSTOM SERVICE REQUESTS', style: ProText.label),
              const SizedBox(height: 10),
              ..._myServiceRequests.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ProColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['service_name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(r['status']?.toString() ?? 'PENDING', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
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
                  color: ProColors.purpleSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x338B5CF6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: ProColors.purple, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request a New Service', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                          Text('Not in the list? Request — admin will review & add it.', style: ProText.caption),
                        ],
                      ),
                    ),
                    Icon(_showCustomServiceForm ? Icons.expand_less : Icons.expand_more, color: ProColors.textMuted),
                  ],
                ),
              ),
            ),

            if (_showCustomServiceForm) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('SERVICE NAME *', style: ProText.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customNameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: proInputDecoration(hint: 'e.g. CCTV Installation'),
                    ),
                    const SizedBox(height: 10),
                    const Text('DESCRIPTION', style: ProText.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customDescCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: proInputDecoration(hint: 'Brief description'),
                    ),
                    const SizedBox(height: 10),
                    const Text('SUGGESTED PRICE (₹)', style: ProText.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: proInputDecoration(hint: '499'),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _submittingCustom ? null : _submitCustomService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submittingCustom
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SUBMIT FOR ADMIN REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.isStandaloneManagement
                              ? 'SAVE OFFERED SERVICES'
                              : 'PROCEED TO STEP 3 (DOCUMENT VAULT)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

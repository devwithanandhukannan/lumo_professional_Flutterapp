import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_document_upload_screen.dart';

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

class _ProServiceSetupScreenState extends State<ProServiceSetupScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _catalogServices = [];
  final Map<String, bool> _selected = {};
  final Map<String, TextEditingController> _priceControllers = {};
  List<Map<String, dynamic>> _myServiceRequests = [];

  bool _loadingServices = true;
  bool _isSaving = false;
  bool _showCustomServiceForm = false;
  String? _error;

  // Custom service form
  final _customNameCtrl = TextEditingController();
  final _customDescCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  bool _submittingCustom = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static final List<Map<String, dynamic>> _fallbackServices = [
    {'id': 'srv-clean-01', 'name': 'Home Deep Cleaning', 'base_price': '499', 'icon': '🧹'},
    {'id': 'srv-clean-02', 'name': 'Kitchen Cleaning', 'base_price': '349', 'icon': '🍽️'},
    {'id': 'srv-elec-01', 'name': 'Switch & Socket Repair', 'base_price': '199', 'icon': '⚡'},
    {'id': 'srv-elec-02', 'name': 'Fan Repair', 'base_price': '249', 'icon': '💨'},
    {'id': 'srv-plumb-01', 'name': 'Tap Leak Fix', 'base_price': '249', 'icon': '🔧'},
    {'id': 'srv-plumb-02', 'name': 'Pipe Leak Repair', 'base_price': '349', 'icon': '🪠'},
    {'id': 'srv-salon-01', 'name': 'Home Haircut', 'base_price': '499', 'icon': '✂️'},
    {'id': 'srv-ac-01', 'name': 'AC Servicing', 'base_price': '699', 'icon': '❄️'},
    {'id': 'srv-safe-01', 'name': 'Safety Escort', 'base_price': '999', 'icon': '🛡️'},
    {'id': 'srv-carpenter-01', 'name': 'Furniture Assembly', 'base_price': '449', 'icon': '🪑'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadServices();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _customNameCtrl.dispose();
    _customDescCtrl.dispose();
    _customPriceCtrl.dispose();
    for (final c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final svcs = await ProApiClient.getCatalogServices();
      final list = svcs.isNotEmpty ? svcs.map((s) => Map<String, dynamic>.from(s)).toList() : _fallbackServices;
      _initServices(list);
    } catch (_) {
      _initServices(_fallbackServices);
    }
    try {
      final profileRes = await ProApiClient.getProfile();
      final offered = (profileRes['offeredServices'] as List?) ?? (profileRes['data']?['offeredServices'] as List?) ?? [];
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
      if (mounted) setState(() => _myServiceRequests = reqs.map((r) => Map<String, dynamic>.from(r)).toList());
    } catch (_) {}
  }

  void _initServices(List<Map<String, dynamic>> services) {
    for (final s in services) {
      final id = s['id'].toString();
      _priceControllers[id] = TextEditingController(text: s['base_price']?.toString() ?? '');
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

  Future<void> _saveAndProceed() async {
    final selectedItems = <Map<String, dynamic>>[];
    for (final s in _catalogServices) {
      final id = s['id'].toString();
      if (_selected[id] == true) {
        final price = double.tryParse(_priceControllers[id]?.text.trim() ?? '') ??
            double.tryParse(s['base_price']?.toString() ?? '0') ?? 0;
        selectedItems.add({'serviceId': id, 'customPrice': price});
      }
    }

    for (final req in _myServiceRequests) {
      final id = req['id']?.toString() ?? '';
      if (id.isNotEmpty && _selected[id] == true) {
        final price = double.tryParse(req['suggested_price']?.toString() ?? '0') ?? 0;
        if (!selectedItems.any((item) => item['serviceId'] == id)) {
          selectedItems.add({'serviceId': id, 'customPrice': price});
        }
      }
    }

    if (selectedItems.isEmpty) {
      setState(() => _error = 'Select at least one service you offer');
      return;
    }

    setState(() { _isSaving = true; _error = null; });
    try {
      await ProApiClient.saveOfferedServices(selectedItems);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to save services: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
        return;
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      if (widget.isStandaloneManagement) {
        _showSnack('Offered services updated successfully! ✓');
        widget.onCompleted();
        Navigator.pop(context);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProDocumentUploadScreen(onCompleted: widget.onCompleted)),
      );
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
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [ProColors.primary.withAlpha(25), Colors.transparent])),
          )),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: const BackButton(color: ProColors.textMuted),
                    title: Text(widget.isStandaloneManagement ? 'Select Admin Services' : 'Service Configuration'),
                    automaticallyImplyLeading: widget.isStandaloneManagement,
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (!widget.isStandaloneManagement) ...[
                          // Step indicator
                          _buildStepBar(2),
                          const SizedBox(height: 20),
                          const Text('STEP 3 OF 4', style: ProText.label),
                          const SizedBox(height: 6),
                        ],
                        const Text('Your Services & Rates', style: ProText.heading1),
                        const SizedBox(height: 6),
                        Text(
                          widget.isStandaloneManagement
                              ? 'Toggle ON the admin services you offer and customize your pricing rates.'
                              : 'Select services you offer. Set your custom rates (base price shown for reference, commission is handled by admin).',
                          style: ProText.body,
                        ),
                        const SizedBox(height: 20),

                        if (_error != null) _errorBanner(_error!),

                        // Services list
                        if (_loadingServices)
                          const Center(child: CircularProgressIndicator(color: ProColors.primary))
                        else ...[
                          ..._catalogServices.asMap().entries.map((entry) {
                            final s = entry.value;
                            final id = s['id'].toString();
                            final checked = _selected[id] == true;
                            return _ServiceCard(
                              service: s,
                              isSelected: checked,
                              priceController: _priceControllers[id],
                              onToggle: () => setState(() => _selected[id] = !checked),
                            );
                          }),
                        ],

                        const SizedBox(height: 20),

                        // Custom service requests
                        if (_myServiceRequests.isNotEmpty) ...[
                          const Text('MY CUSTOM SERVICE REQUESTS', style: ProText.label),
                          const SizedBox(height: 10),
                          ..._myServiceRequests.map((r) => _PendingServiceTile(request: r)),
                          const SizedBox(height: 16),
                        ],

                        // Add custom service toggle
                        GlassCard(
                          borderRadius: 18,
                          onTap: () => setState(() => _showCustomServiceForm = !_showCustomServiceForm),
                          gradientColors: [const Color(0x1A8B5CF6), const Color(0x0A8B5CF6)],
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ProColors.purpleSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add_circle_outline_rounded, color: ProColors.purple, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Request a New Service', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                                    Text('Not in the list? Request — admin will review & add it.', style: ProText.caption),
                                  ],
                                ),
                              ),
                              Icon(_showCustomServiceForm ? Icons.expand_less : Icons.expand_more, color: ProColors.textMuted),
                            ],
                          ),
                        ),

                        if (_showCustomServiceForm) ...[
                          const SizedBox(height: 12),
                          GlassCard(
                            borderRadius: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('SERVICE NAME *', style: ProText.label),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customNameCtrl,
                                  style: const TextStyle(color: ProColors.textPrimary),
                                  decoration: proInputDecoration(hint: 'e.g. CCTV Installation'),
                                ),
                                const SizedBox(height: 12),
                                const Text('DESCRIPTION', style: ProText.label),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customDescCtrl,
                                  maxLines: 2,
                                  style: const TextStyle(color: ProColors.textPrimary, fontSize: 13),
                                  decoration: proInputDecoration(hint: 'Brief description of the service'),
                                ),
                                const SizedBox(height: 12),
                                const Text('SUGGESTED PRICE (₹)', style: ProText.label),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  style: const TextStyle(color: ProColors.textPrimary),
                                  decoration: proInputDecoration(hint: '499'),
                                ),
                                const SizedBox(height: 16),
                                GradientButton(
                                  label: 'SUBMIT FOR ADMIN REVIEW',
                                  onTap: _submitCustomService,
                                  isLoading: _submittingCustom,
                                  colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        GradientButton(
                          label: widget.isStandaloneManagement ? 'SAVE OFFERED SERVICES' : 'NEXT: UPLOAD DOCUMENTS',
                          onTap: _saveAndProceed,
                          isLoading: _isSaving,
                          icon: widget.isStandaloneManagement ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
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

  Widget _buildStepBar(int current) {
    return Row(
      children: List.generate(4, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done ? ProColors.primary : active ? ProColors.primary.withAlpha(160) : ProColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: ProColors.emergencyRedSoft, border: Border.all(color: ProColors.emergencyRedBorder), borderRadius: BorderRadius.circular(12)),
    child: Text(msg, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 13)),
  );
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isSelected;
  final TextEditingController? priceController;
  final VoidCallback onToggle;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.priceController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0x2010B981), Color(0x0A10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? ProColors.primary : ProColors.glassBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(service['icon']?.toString() ?? '🔧', style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                  Text('Base: ₹${service['base_price']}', style: ProText.caption),
                ],
              ),
            ),
            if (isSelected && priceController != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  onTap: () {},
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: proInputDecoration(hint: '₹').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ),
            ],
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isSelected ? ProColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? ProColors.primary : ProColors.textMuted, width: 1.5),
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingServiceTile extends StatelessWidget {
  final Map<String, dynamic> request;
  const _PendingServiceTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status']?.toString() ?? 'PENDING_ADMIN_APPROVAL';
    final isApproved = status == 'APPROVED';
    final color = isApproved ? ProColors.primary : ProColors.warningAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(isApproved ? Icons.check_circle_outline : Icons.schedule_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request['service_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                Text(isApproved ? 'Approved by Admin' : 'Pending Admin Review', style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to add getCatalogServices to ProApiClient
extension CatalogExtension on ProApiClient {
}

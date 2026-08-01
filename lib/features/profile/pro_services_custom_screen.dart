import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import '../onboarding/pro_service_setup_screen.dart';

class ProServicesCustomScreen extends StatefulWidget {
  const ProServicesCustomScreen({super.key});

  @override
  State<ProServicesCustomScreen> createState() => _ProServicesCustomScreenState();
}

class _ProServicesCustomScreenState extends State<ProServicesCustomScreen> {
  List<dynamic> _offeredServices = [];
  List<dynamic> _customRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profileRes = await ProApiClient.getProfile();
      final services = profileRes['offeredServices'] ?? profileRes['services'] ?? profileRes['data']?['offeredServices'] ?? profileRes['data']?['services'] ?? [];
      final requests = await ProApiClient.getMyCustomServiceRequests();

      if (mounted) {
        setState(() {
          _offeredServices = services;
          _customRequests = requests;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offeredServices = [];
          _customRequests = [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleServiceActive(Map<String, dynamic> srv, bool newActive) async {
    final srvId = srv['service_id']?.toString() ?? srv['id']?.toString() ?? '';
    if (srvId.isEmpty) return;
    try {
      await ProApiClient.toggleOfferedServiceStatus(srvId, newActive);
      setState(() {
        srv['is_active'] = newActive;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Service enabled ✓' : 'Service toggled OFF ✓'),
            backgroundColor: newActive ? ProColors.primary : ProColors.warningAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: ProColors.emergencyRed),
        );
      }
    }
  }

  Future<void> _deleteService(Map<String, dynamic> srv) async {
    final srvId = srv['service_id']?.toString() ?? srv['id']?.toString() ?? '';
    final srvName = srv['service_name']?.toString() ?? 'Service';
    if (srvId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        title: const Text('Delete Offered Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "$srvName" from your offered services?', style: const TextStyle(color: ProColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: ProColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ProColors.emergencyRed),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProApiClient.deleteOfferedService(srvId);
      if (mounted) {
        setState(() {
          _offeredServices.removeWhere((item) => (item['service_id']?.toString() ?? item['id']?.toString()) == srvId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully! ✓'), backgroundColor: ProColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: ProColors.emergencyRed),
        );
      }
    }
  }

  Future<void> _toggleCustomServiceActive(Map<String, dynamic> req, bool newActive) async {
    final reqId = req['id']?.toString() ?? '';
    if (reqId.isEmpty) return;
    try {
      await ProApiClient.toggleCustomServiceStatus(reqId, newActive);
      setState(() {
        req['is_active'] = newActive;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Custom service activated ✓' : 'Custom service deactivated (hidden from customers) ✓'),
            backgroundColor: newActive ? ProColors.primary : ProColors.warningAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: ProColors.emergencyRed),
        );
      }
    }
  }

  // 1. Instant Price Edit Modal (No Admin Approval Required)
  Future<void> _openInstantPriceEditModal(Map<String, dynamic> service) async {
    final srvId = service['service_id']?.toString() ?? service['id']?.toString() ?? '';
    final srvName = service['service_name']?.toString() ?? 'Service';
    final currentCustom = service['custom_price'] ?? service['base_price'] ?? 499;
    final priceCtrl = TextEditingController(text: currentCustom.toString());
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_note_rounded, color: ProColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Custom Rate (Instant)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(srvName, style: const TextStyle(color: ProColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: ProColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x1A10B981), borderRadius: BorderRadius.circular(12), border: Border.all(color: ProColors.primary.withAlpha(80))),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: ProColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Rate updates take effect instantly for customer bookings! No Admin approval needed.', style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('YOUR CUSTOM RATE (₹)', style: ProText.label),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: ProColors.accent),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: isSaving ? 'SAVING...' : 'SAVE RATE INSTANTLY',
                icon: Icons.check_circle_rounded,
                onTap: isSaving
                    ? null
                    : () async {
                        final val = double.tryParse(priceCtrl.text.trim());
                        if (val == null || val <= 0) return;
                        setModalState(() => isSaving = true);
                        try {
                          await ProApiClient.updateCustomServicePrice(srvId, val);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Custom rate updated instantly! ✓'), backgroundColor: ProColors.primary),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: ProColors.emergencyRed),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Create or Edit Custom Service Name/Description (Requires Admin Approval)
  Future<void> _openCustomServiceModal([Map<String, dynamic>? existingReq]) async {
    final isEditing = existingReq != null;
    final nameCtrl = TextEditingController(text: existingReq?['service_name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existingReq?['description']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: existingReq?['suggested_price']?.toString() ?? '');
    String? modalError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_task_rounded, color: ProColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Custom Service Details' : 'Create Custom Service',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Changing service name or scope requires Admin approval',
                          style: TextStyle(color: ProColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: ProColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: ProColors.border, height: 1),
              const SizedBox(height: 16),

              if (modalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0x22EF4444), borderRadius: BorderRadius.circular(10), border: Border.all(color: ProColors.emergencyRed)),
                  child: Text(modalError!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
              ],

              const Text('CUSTOM SERVICE NAME', style: ProText.label),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Full Villa AC Duct Sanitation',
                  hintStyle: const TextStyle(color: ProColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.build_rounded, color: ProColors.primary, size: 18),
                ),
              ),

              const SizedBox(height: 14),
              const Text('PROPOSED RATE (₹)', style: ProText.label),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 799',
                  hintStyle: const TextStyle(color: ProColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: ProColors.accent, size: 18),
                ),
              ),

              const SizedBox(height: 14),
              const Text('WORK DESCRIPTION / SCOPE', style: ProText.label),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe equipment, materials, and scope of work included...',
                  hintStyle: const TextStyle(color: ProColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 20),
              GradientButton(
                label: isSubmitting ? 'SUBMITTING TO ADMIN...' : 'SUBMIT FOR ADMIN APPROVAL',
                icon: Icons.send_rounded,
                onTap: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final priceStr = priceCtrl.text.trim();
                        if (name.isEmpty) {
                          setModalState(() => modalError = 'Please enter service name');
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          modalError = null;
                        });

                        try {
                          await ProApiClient.requestCustomService(
                            serviceName: name,
                            description: descCtrl.text.trim(),
                            suggestedPrice: double.tryParse(priceStr),
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Custom service submitted for Admin review! ✓'), backgroundColor: ProColors.primary),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isSubmitting = false;
                            modalError = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: const Text('My Services & Rates'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ProColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: ProColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row buttons: Select Admin Services & Create Custom
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProServiceSetupScreen(
                                  isStandaloneManagement: true,
                                  onCompleted: () {
                                    _loadData();
                                  },
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ProColors.primary,
                            side: const BorderSide(color: ProColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.playlist_add_rounded, size: 18),
                          label: const Text('+ ADMIN SERVICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openCustomServiceModal(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('+ CUSTOM SERVICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Standard Active Offered Services & Instant Price Edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MY OFFERED SERVICES', style: ProText.label),
                      if (_offeredServices.isNotEmpty)
                        Text('${_offeredServices.length} total', style: const TextStyle(color: ProColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_offeredServices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: ProColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ProColors.border)),
                      child: const Center(
                        child: Text('No services configured yet.\nTap "+ ADMIN SERVICES" above to select services.', textAlign: TextAlign.center, style: TextStyle(color: ProColors.textMuted, fontSize: 12)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _offeredServices.length,
                      itemBuilder: (ctx, idx) {
                        final srv = _offeredServices[idx];
                        final isActive = srv['is_active'] != false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ProColors.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: isActive ? ProColors.border : ProColors.border.withAlpha(50)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive ? ProColors.primarySoft : ProColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.handyman_rounded, color: isActive ? ProColors.primary : ProColors.textMuted, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(srv['service_name'] ?? 'Service Name', style: TextStyle(color: isActive ? Colors.white : ProColors.textMuted, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (isActive ? ProColors.primary : ProColors.textMuted).withAlpha(30),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isActive ? 'ACTIVE' : 'DEACTIVATED',
                                                style: TextStyle(
                                                  color: isActive ? ProColors.primary : ProColors.textMuted,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('Base Rate: ₹${srv['base_price'] ?? 499}', style: const TextStyle(color: ProColors.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: ProColors.primary,
                                    onChanged: (val) => _toggleServiceActive(srv, val),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: ProColors.emergencyRed, size: 20),
                                    tooltip: 'Delete service',
                                    onPressed: () => _deleteService(srv),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: ProColors.border, height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Your Rate: ', style: TextStyle(color: ProColors.textMuted, fontSize: 12)),
                                      Text('₹${srv['custom_price'] ?? srv['base_price'] ?? 499}', style: const TextStyle(color: ProColors.accent, fontWeight: FontWeight.w900, fontSize: 15)),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _openInstantPriceEditModal(srv),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, color: ProColors.primary, size: 12),
                                          SizedBox(width: 4),
                                          Text('Edit Rate', style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Submitted Custom Service Requests & Admin Status
                  const Text('MY CUSTOM REQUESTS', style: ProText.label),
                  const SizedBox(height: 10),

                  if (_customRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: ProColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ProColors.border)),
                      child: const Center(
                        child: Text('No custom service requests submitted yet.\nTap "+ CUSTOM SERVICE" to request a new service.', textAlign: TextAlign.center, style: TextStyle(color: ProColors.textMuted, fontSize: 12)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customRequests.length,
                      itemBuilder: (ctx, idx) {
                        final req = _customRequests[idx];
                        final reqStatus = req['status']?.toString().toUpperCase() ?? 'PENDING_ADMIN_APPROVAL';
                        final isApprovedReq = reqStatus == 'APPROVED';
                        final isRejectedReq = reqStatus == 'REJECTED';

                        Color badgeColor = ProColors.warningAmber;
                        String badgeText = 'PENDING APPROVAL';
                        if (isApprovedReq) {
                          badgeColor = ProColors.primary;
                          badgeText = 'APPROVED';
                        } else if (isRejectedReq) {
                          badgeColor = ProColors.emergencyRed;
                          badgeText = 'REJECTED';
                        }

                        final isReqActive = req['is_active'] != false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ProColors.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: badgeColor.withAlpha(100)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(req['service_name'] ?? 'Custom Service', style: TextStyle(color: isReqActive ? Colors.white : ProColors.textMuted, fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: badgeColor.withAlpha(30), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withAlpha(120))),
                                              child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900)),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (isReqActive ? ProColors.primary : ProColors.textMuted).withAlpha(30),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isReqActive ? 'ACTIVE' : 'DEACTIVATED',
                                                style: TextStyle(
                                                  color: isReqActive ? ProColors.primary : ProColors.textMuted,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isReqActive,
                                    activeThumbColor: ProColors.primary,
                                    onChanged: (val) => _toggleCustomServiceActive(req, val),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: ProColors.border, height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Proposed Rate: ', style: TextStyle(color: ProColors.textMuted, fontSize: 12)),
                                  Text('₹${req['suggested_price'] ?? 499}', style: const TextStyle(color: ProColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _openCustomServiceModal(req),
                                    icon: const Icon(Icons.edit_note, size: 14, color: ProColors.primary),
                                    label: const Text('Edit Details', style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              if (req['admin_notes'] != null && req['admin_notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Admin Note: ${req['admin_notes']}', style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }
}

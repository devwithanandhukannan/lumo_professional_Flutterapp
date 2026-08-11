import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';
import '../../core/network/pro_api_client.dart';

class ProEarningsScreen extends StatefulWidget {
  const ProEarningsScreen({super.key});

  @override
  State<ProEarningsScreen> createState() => _ProEarningsScreenState();
}

class _ProEarningsScreenState extends State<ProEarningsScreen> {
  double _walletBalance = 0.00;
  double _todayEarnings = 0.00;
  int _todayJobsCount = 0;
  double _thisWeekEarnings = 0.00;
  int _thisWeekJobsCount = 0;
  bool _loading = true;

  List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Mon', 'amount': 0.0},
    {'day': 'Tue', 'amount': 0.0},
    {'day': 'Wed', 'amount': 0.0},
    {'day': 'Thu', 'amount': 0.0},
    {'day': 'Fri', 'amount': 0.0},
    {'day': 'Sat', 'amount': 0.0},
    {'day': 'Sun', 'amount': 0.0},
  ];

  List<Map<String, dynamic>> _transactions = [];
  List<dynamic> _savedPayoutMethods = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final results = await Future.wait([
        ProApiClient.getProWalletSummary().catchError((_) => <String, dynamic>{}),
        ProApiClient.getWalletTransactions().catchError((_) => <dynamic>[]),
        ProApiClient.getPayoutMethods().catchError((_) => <dynamic>[]),
      ]);

      final walletData = results[0] as Map<String, dynamic>;
      final txList = (results[1] as List).cast<Map<String, dynamic>>();
      final methods = results[2] as List;

      if (mounted) {
        setState(() {
          if (walletData.isNotEmpty) {
            _walletBalance = (walletData['walletBalance'] as num?)?.toDouble() ?? 0.0;
            _todayEarnings = (walletData['todayEarnings'] as num?)?.toDouble() ?? 0.0;
            _todayJobsCount = (walletData['todayJobsCount'] as num?)?.toInt() ?? 0;
            _thisWeekEarnings = (walletData['thisWeekEarnings'] as num?)?.toDouble() ?? 0.0;
            _thisWeekJobsCount = (walletData['thisWeekJobsCount'] as num?)?.toInt() ?? 0;
            if (walletData['weeklyData'] is List) {
              _weeklyData = (walletData['weeklyData'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          }
          _transactions = txList;
          _savedPayoutMethods = methods;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showWithdrawalModal() {
    final amountCtrl = TextEditingController(
      text: _walletBalance >= 100 ? (_walletBalance > 2000 ? '2000' : _walletBalance.toStringAsFixed(0)) : '100',
    );
    final upiCtrl = TextEditingController(text: 'pro@upi');
    final acctNumCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final acctNameCtrl = TextEditingController();

    // Check if we have a saved primary method
    if (_savedPayoutMethods.isNotEmpty) {
      final primary = _savedPayoutMethods.firstWhere(
        (m) => m['is_primary'] == true,
        orElse: () => _savedPayoutMethods.first,
      );
      if (primary['type'] == 'UPI' && primary['upi_id'] != null) {
        upiCtrl.text = primary['upi_id'];
      } else if (primary['type'] == 'BANK_ACCOUNT') {
        acctNumCtrl.text = primary['account_number'] ?? '';
        ifscCtrl.text = primary['ifsc_code'] ?? '';
        acctNameCtrl.text = primary['account_holder_name'] ?? '';
      }
    }

    String selectedType = 'UPI'; // 'UPI' or 'BANK'
    bool isSubmitting = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Withdraw to Bank / UPI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ProColors.txt(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ProColors.txtMuted(context)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 14, color: ProColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Available to Withdraw: ₹${_walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ProColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (modalError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ProColors.emergencyRedSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ProColors.emergencyRedBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: ProColors.emergencyRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              modalError!,
                              style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quick Amount Selector
                  Text('WITHDRAWAL AMOUNT (₹)', style: ProText.labelStyle(context)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ProColors.txt(context)),
                    decoration: proInputDecoration(
                      hint: 'Min ₹100',
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ProColors.primary)),
                      ),
                      context: context,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Amount Chips
                  Wrap(
                    spacing: 8,
                    children: [500, 1000, 2000, 5000].map((amt) {
                      return ChoiceChip(
                        label: Text('₹$amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: amountCtrl.text == amt.toString(),
                        selectedColor: ProColors.primarySoft,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              amountCtrl.text = amt.toString();
                              modalError = null;
                            });
                          }
                        },
                      );
                    }).toList()
                      ..add(
                        ChoiceChip(
                          label: const Text('ALL BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProColors.primary)),
                          selected: amountCtrl.text == _walletBalance.toStringAsFixed(0),
                          selectedColor: ProColors.primarySoft,
                          onSelected: (selected) {
                            if (selected && _walletBalance > 0) {
                              setModalState(() {
                                amountCtrl.text = _walletBalance.toStringAsFixed(0);
                                modalError = null;
                              });
                            }
                          },
                        ),
                      ),
                  ),
                  const SizedBox(height: 16),

                  // Payout Method Switcher (UPI vs Bank)
                  Text('DISBURSEMENT DESTINATION', style: ProText.labelStyle(context)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedType = 'UPI'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'UPI' ? ProColors.primarySoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == 'UPI' ? ProColors.primary : ProColors.brd(context),
                                width: selectedType == 'UPI' ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt_rounded, size: 16, color: selectedType == 'UPI' ? ProColors.primary : ProColors.txtMuted(context)),
                                const SizedBox(width: 4),
                                Text(
                                  'Instant UPI (VPA)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedType == 'UPI' ? ProColors.primary : ProColors.txtMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedType = 'BANK'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'BANK' ? ProColors.primarySoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == 'BANK' ? ProColors.primary : ProColors.brd(context),
                                width: selectedType == 'BANK' ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_rounded, size: 16, color: selectedType == 'BANK' ? ProColors.primary : ProColors.txtMuted(context)),
                                const SizedBox(width: 4),
                                Text(
                                  'Bank IMPS / NEFT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedType == 'BANK' ? ProColors.primary : ProColors.txtMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (selectedType == 'UPI') ...[
                    TextField(
                      controller: upiCtrl,
                      style: TextStyle(fontSize: 14, color: ProColors.txt(context)),
                      decoration: proInputDecoration(
                        hint: 'e.g. yourname@okicici, mobile@upi',
                        prefix: const Icon(Icons.alternate_email_rounded, color: ProColors.primary, size: 18),
                        context: context,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Direct instant settlement to your UPI Virtual Payment Address.', style: ProText.captionStyle(context)),
                  ] else ...[
                    TextField(
                      controller: acctNameCtrl,
                      style: TextStyle(fontSize: 14, color: ProColors.txt(context)),
                      decoration: proInputDecoration(
                        hint: 'Account Holder Name',
                        prefix: const Icon(Icons.person_outline, color: ProColors.primary, size: 18),
                        context: context,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: acctNumCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14, color: ProColors.txt(context)),
                      decoration: proInputDecoration(
                        hint: 'Bank Account Number',
                        prefix: const Icon(Icons.numbers, color: ProColors.primary, size: 18),
                        context: context,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(fontSize: 14, color: ProColors.txt(context)),
                      decoration: proInputDecoration(
                        hint: 'Bank IFSC Code (e.g. SBIN0001234)',
                        prefix: const Icon(Icons.domain, color: ProColors.primary, size: 18),
                        context: context,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final val = double.tryParse(amountCtrl.text.trim()) ?? 0;
                              if (val < 100) {
                                setModalState(() => modalError = 'Minimum withdrawal amount is ₹100.00');
                                return;
                              }
                              if (val > _walletBalance) {
                                setModalState(() => modalError = 'Amount exceeds your available balance of ₹${_walletBalance.toStringAsFixed(2)}');
                                return;
                              }

                              if (selectedType == 'UPI' && (!upiCtrl.text.contains('@') || upiCtrl.text.trim().length < 4)) {
                                setModalState(() => modalError = 'Please enter a valid UPI ID (e.g. mobile@upi)');
                                return;
                              }

                              if (selectedType == 'BANK') {
                                if (acctNumCtrl.text.trim().length < 8 || ifscCtrl.text.trim().length < 5) {
                                  setModalState(() => modalError = 'Please enter valid Bank Account Number and IFSC Code');
                                  return;
                                }
                              }

                              setModalState(() {
                                isSubmitting = true;
                                modalError = null;
                              });

                              try {
                                if (selectedType == 'UPI') {
                                  await ProApiClient.requestWithdrawal(
                                    amount: val,
                                    customUpi: upiCtrl.text.trim(),
                                  );
                                } else {
                                  await ProApiClient.requestWithdrawal(
                                    amount: val,
                                    customBank: {
                                      'accountHolderName': acctNameCtrl.text.trim(),
                                      'accountNumber': acctNumCtrl.text.trim(),
                                      'ifscCode': ifscCtrl.text.trim().toUpperCase(),
                                    },
                                  );
                                }

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Disbursement of ₹${val.toStringAsFixed(2)} initiated successfully!'),
                                      backgroundColor: ProColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _loadEarnings();
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  modalError = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'CONFIRM DISBURSEMENT',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWeekly = _weeklyData.fold(
        0.0,
        (max, item) => (item['amount'] as num) > max
            ? (item['amount'] as num).toDouble()
            : max);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Financials & Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: ProColors.txt(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet_outlined, color: ProColors.primaryAccent(context)),
            onPressed: _showWithdrawalModal,
            tooltip: 'Payout',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ProColors.primary))
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              color: ProColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wallet Balance Card
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 24,
                      borderColor: ProColors.primary.withAlpha(100),
                      borderWidth: 1.2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('WITHDRAWABLE BALANCE', style: ProText.labelStyle(context)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ProColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ProColors.primary),
                                ),
                                child: const Text(
                                  'INSTANT PAYOUT',
                                  style: TextStyle(
                                    color: ProColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${_walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: ProColors.txt(context),
                            ),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            height: 48,
                            label: 'WITHDRAW TO BANK / UPI',
                            onTap: _showWithdrawalModal,
                            icon: Icons.send_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: "TODAY'S EARNINGS",
                            value: '₹${_todayEarnings.toStringAsFixed(2)}',
                            subtitle: '$_todayJobsCount Jobs Completed',
                            icon: Icons.today_rounded,
                            accentColor: ProColors.primaryAccent(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'THIS WEEK',
                            value: '₹${_thisWeekEarnings.toStringAsFixed(2)}',
                            subtitle: '$_thisWeekJobsCount Jobs Completed',
                            icon: Icons.date_range_rounded,
                            accentColor: ProColors.accent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Weekly Chart Section
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('WEEKLY EARNINGS TREND', style: ProText.labelStyle(context)),
                              Text(
                                'Avg: ₹${(_thisWeekEarnings / 7).toStringAsFixed(0)} / day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ProColors.primaryAccent(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _weeklyData.map((item) {
                                final double amount = (item['amount'] as num).toDouble();
                                final double heightPct = (amount / maxWeekly).clamp(0.15, 1.0);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('₹${(amount / 1000).toStringAsFixed(1)}k',
                                        style: TextStyle(fontSize: 10, color: ProColors.txtMuted(context))),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 24,
                                      height: 90 * heightPct,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: amount > 2000
                                              ? [ProColors.primary, ProColors.primaryDark]
                                              : [ProColors.accent, ProColors.surfHigh(context)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['day'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ProColors.txt(context),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent Transactions Ledger
                    Text('RECENT PAYOUT LEDGER', style: ProText.labelStyle(context)),
                    const SizedBox(height: 10),

                    if (_transactions.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 36, color: ProColors.txtMuted(context)),
                            const SizedBox(height: 12),
                            Text(
                              'No Payout Transactions Yet',
                              style: TextStyle(
                                color: ProColors.txt(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed customer jobs and wallet payouts will appear here in real time.',
                              textAlign: TextAlign.center,
                              style: ProText.captionStyle(context),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final bool isCredit = tx['isCredit'] as bool;

                          return GlassCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCredit
                                        ? ProColors.primarySoft
                                        : ProColors.emergencyRedSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                    color: isCredit
                                        ? ProColors.primary
                                        : ProColors.emergencyRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['title'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ProColors.txt(context),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(tx['service'] as String,
                                          style: ProText.captionStyle(context)),
                                      Text(tx['date'] as String,
                                          style: TextStyle(
                                              fontSize: 10, color: ProColors.txtMuted(context))),
                                    ],
                                  ),
                                ),
                                Text(
                                  tx['amount'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: isCredit
                                        ? ProColors.primary
                                        : ProColors.emergencyRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: ProText.labelStyle(context)),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: ProColors.txt(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: ProText.captionStyle(context)),
        ],
      ),
    );
  }
}

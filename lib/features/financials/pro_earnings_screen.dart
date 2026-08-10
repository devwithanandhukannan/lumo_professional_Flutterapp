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

  final List<Map<String, dynamic>> _weeklyData = const [
    {'day': 'Mon', 'amount': 0},
    {'day': 'Tue', 'amount': 0},
    {'day': 'Wed', 'amount': 0},
    {'day': 'Thu', 'amount': 0},
    {'day': 'Fri', 'amount': 0},
    {'day': 'Sat', 'amount': 0},
    {'day': 'Sun', 'amount': 0},
  ];

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final jobs = await ProApiClient.getMyJobs();
      double totalWallet = 0.0;
      double todayTotal = 0.0;
      int todayCount = 0;
      double weekTotal = 0.0;
      int weekCount = 0;
      final txs = <Map<String, dynamic>>[];

      for (final j in jobs) {
        if (j['status'] == 'COMPLETED') {
          final amt = (double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0.0);
          totalWallet += amt;
          todayTotal += amt;
          todayCount++;
          weekTotal += amt;
          weekCount++;

          txs.add({
            'id': j['id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}',
            'title': 'Job Completion #${j['id'] ?? 'BK'}',
            'service': j['service_name'] ?? 'Service Job',
            'amount': '+ ₹${amt.toStringAsFixed(2)}',
            'date': 'Completed',
            'isCredit': true,
          });
        }
      }

      if (mounted) {
        setState(() {
          _walletBalance = totalWallet;
          _todayEarnings = todayTotal;
          _todayJobsCount = todayCount;
          _thisWeekEarnings = weekTotal;
          _thisWeekJobsCount = weekCount;
          _transactions = txs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showWithdrawalModal() {
    final amountCtrl = TextEditingController(text: '2000');
    final upiCtrl = TextEditingController(text: 'priya@upi');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Instant Wallet Payout', style: ProText.heading2),
                IconButton(
                  icon: const Icon(Icons.close, color: ProColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Available Balance: ₹${_walletBalance.toStringAsFixed(2)}', style: ProText.caption),
            const SizedBox(height: 20),

            const Text('WITHDRAWAL AMOUNT (₹)', style: ProText.label),
            const SizedBox(height: 6),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: proInputDecoration(hint: 'Enter amount'),
            ),
            const SizedBox(height: 14),

            const Text('UPI ID / BANK ACCOUNT', style: ProText.label),
            const SizedBox(height: 6),
            TextField(
              controller: upiCtrl,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: proInputDecoration(hint: 'mobile@upi'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (val > 0 && val <= _walletBalance) {
                    setState(() {
                      _walletBalance -= val;
                      _transactions.insert(0, {
                        'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
                        'title': 'Instant Wallet Payout',
                        'service': 'Transfer to ${upiCtrl.text.trim()}',
                        'amount': '- ₹${val.toStringAsFixed(2)}',
                        'date': 'Just now',
                        'isCredit': false,
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payout of ₹${val.toStringAsFixed(2)} initiated successfully!'),
                        backgroundColor: ProColors.primary,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('CONFIRM INSTANT PAYOUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWeekly = _weeklyData.fold(0.0, (max, item) => (item['amount'] as num) > max ? (item['amount'] as num).toDouble() : max);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financials & Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: ProColors.primary),
            onPressed: _showWithdrawalModal,
            tooltip: 'Payout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ProColors.primary))
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              color: ProColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wallet Balance Card
                    // Wallet Balance Card
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 24,
                      borderColor: ProColors.primary.withAlpha(100),
                      gradientColors: const [Color(0x3310B981), Color(0x0C10B981)],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('WITHDRAWABLE BALANCE', style: ProText.label),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ProColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ProColors.primary),
                                ),
                                child: const Text('INSTANT PAYOUT', style: TextStyle(color: ProColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('₹${_walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
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

                    const SizedBox(height: 24),

                    // Summary Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: "TODAY'S EARNINGS",
                            value: '₹${_todayEarnings.toStringAsFixed(2)}',
                            subtitle: '$_todayJobsCount Jobs Completed',
                            icon: Icons.today,
                            accentColor: ProColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'THIS WEEK',
                            value: '₹${_thisWeekEarnings.toStringAsFixed(2)}',
                            subtitle: '$_thisWeekJobsCount Jobs Completed',
                            icon: Icons.date_range,
                            accentColor: ProColors.accent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                              const Text('WEEKLY EARNINGS TREND', style: ProText.label),
                              Text('Avg: ₹${(_thisWeekEarnings / 7).toStringAsFixed(0)} / day', style: ProText.caption.copyWith(color: ProColors.primary)),
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
                                    Text('₹${(amount / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10, color: ProColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 24,
                                      height: 90 * heightPct,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: amount > 2000
                                              ? [ProColors.primary, ProColors.primaryDark]
                                              : [ProColors.accent, ProColors.surface],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(item['day'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Transactions Ledger
                    const Text('RECENT PAYOUT LEDGER', style: ProText.label),
                    const SizedBox(height: 12),

                    if (_transactions.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 20,
                        child: const Column(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 36, color: ProColors.textMuted),
                            SizedBox(height: 12),
                            Text('No Payout Transactions Yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Completed customer jobs and wallet payouts will appear here in real time.', textAlign: TextAlign.center, style: ProText.caption),
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
                                    color: isCredit ? ProColors.primarySoft : ProColors.emergencyRedSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                    color: isCredit ? ProColors.primary : ProColors.emergencyRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(tx['service'] as String, style: ProText.caption),
                                      Text(tx['date'] as String, style: const TextStyle(fontSize: 10, color: ProColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(
                                  tx['amount'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: isCredit ? ProColors.primary : ProColors.emergencyRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
              Text(title, style: ProText.label),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle, style: ProText.caption),
        ],
      ),
    );
  }
}

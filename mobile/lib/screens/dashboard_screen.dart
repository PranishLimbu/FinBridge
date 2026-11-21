import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'cash_transaction_screen.dart';
import 'eod_screen.dart';
import 'onboarding_screen.dart';
import 'receipt_screen.dart';

/// Counter dashboard (Figure 7): cash drawer, today's totals, alerts and operations.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  final void Function(int tab) onOpenTab;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await context.read<Session>().api.get('/dashboard') as Map<String, dynamic>;
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<Session>().agent!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नमस्ते, ${agent.name}', style: const TextStyle(fontSize: 18)),
            Text('${agent.id} • ${agent.location}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: Column(
        children: [
          const SimulatedBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading && _data == null) const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  if (_error != null) MessageBox(_error!),
                  if (_data != null) ..._content(_data!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> d) {
    final f = Float.fromJson(d['float'] as Map<String, dynamic>);
    final today = d['today'] as Map<String, dynamic>;
    final alerts = (d['alerts'] as List).cast<Map<String, dynamic>>();
    final recent = (d['recent'] as List).map((t) => Txn.fromJson(t as Map<String, dynamic>)).toList();

    return [
      // Cash drawer
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: FbColors.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CASH DRAWER (physical float)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(formatNpr(f.cash), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (f.utilisation / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: const Color(0xFF6EE7B7),
              ),
            ),
            const SizedBox(height: 6),
            Text('Min reserve ${formatNpr(f.minReserve)} • Limit ${formatNpr(f.limit)} • ${f.utilisation}% used',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _stat('Opening', formatNpr(f.opening), FbColors.textMuted)),
        const SizedBox(width: 8),
        Expanded(child: _stat('In (${today['inflowCount']})', '+${formatNpr(today['inflows'] as num)}', FbColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _stat('Out (${today['outflowCount']})', '-${formatNpr(today['outflows'] as num)}', FbColors.danger)),
      ]),
      const SizedBox(height: 16),
      const Text('Counter operations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          _op(Icons.south_west, 'Cash deposit', 'Cash in', () => _open(const CashTransactionScreen(type: 'deposit'))),
          _op(Icons.north_east, 'Cash withdrawal', 'Cash out with OTP', () => _open(const CashTransactionScreen(type: 'withdrawal'))),
          _op(Icons.person_add_alt, 'New customer', 'Onboarding (KYC)', () => _open(const OnboardingScreen())),
          _op(Icons.person_search, 'Customer search', 'Mobile / A/C / citizenship', () => widget.onOpenTab(1)),
        ],
      ),
      const SizedBox(height: 16),
      if (alerts.isNotEmpty) ...[
        const Text('Notices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        for (final a in alerts) _alert(a),
        const SizedBox(height: 8),
      ],
      Row(
        children: [
          const Expanded(child: Text('Today’s journal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          TextButton(onPressed: () => widget.onOpenTab(2), child: const Text('See all')),
        ],
      ),
      if (recent.isEmpty) const Text('No transactions yet today.', style: TextStyle(color: FbColors.textMuted)),
      for (final t in recent) TxnTile(t, onTap: () => _open(ReceiptScreen(transactionId: t.id))),
    ];
  }

  Widget _stat(String label, String value, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color))),
            ],
          ),
        ),
      );

  Widget _op(IconData icon, String title, String sub, VoidCallback onTap) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: FbColors.primaryLight,
                  child: Icon(icon, color: FbColors.primary),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: FbColors.primary)),
                    Text(sub, style: const TextStyle(fontSize: 12, color: FbColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _alert(Map<String, dynamic> a) {
    final type = a['type'] as String;
    final isEod = type == 'eod_due';
    final warn = type == 'low_float' || type == 'high_float' || type == 'pending_otp';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: warn ? FbColors.warningBg : FbColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(isEod ? Icons.schedule : Icons.info_outline, color: warn ? FbColors.warning : FbColors.primary),
          title: Text(a['message'] as String),
          trailing: isEod ? const Icon(Icons.chevron_right) : null,
          onTap: isEod ? () => _open(const EodScreen()) : null,
        ),
      ),
    );
  }
}

class TxnTile extends StatelessWidget {
  const TxnTile(this.t, {super.key, this.onTap});

  final Txn t;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: t.isDeposit ? FbColors.successBg : FbColors.dangerBg,
            child: Icon(t.isDeposit ? Icons.south_west : Icons.north_east,
                color: t.isDeposit ? FbColors.success : FbColors.danger),
          ),
          title: Text(t.customerName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${t.reference}\n${formatNepalTime(t.createdAt)}', style: const TextStyle(fontSize: 12)),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${t.isDeposit ? '+' : '-'}${formatNpr(t.amount)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.isDeposit ? FbColors.success : FbColors.danger)),
              const SizedBox(height: 4),
              StatusChip(t.status),
            ],
          ),
        ),
      ),
    );
  }
}

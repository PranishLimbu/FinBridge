import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'cash_transaction_screen.dart';
import 'eod_screen.dart';
import 'onboarding_screen.dart';
import 'receipt_screen.dart';
import 'terminal_screen.dart';

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
      if (mounted) setState(() => _error = context.l10n.error(e));
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
        title: const FbLogo(compact: true),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh), tooltip: context.l10n.refresh)],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading && _data == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            _greeting(agent),
            const SizedBox(height: 16),
            if (_error != null) MessageBox(_error!),
            if (_data != null) ..._content(_data!),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> d) {
    final l10n = context.l10n;
    final f = Float.fromJson(d['float'] as Map<String, dynamic>);
    final today = d['today'] as Map<String, dynamic>;
    final alerts = (d['alerts'] as List).cast<Map<String, dynamic>>();
    final recent = (d['recent'] as List).map((t) => Txn.fromJson(t as Map<String, dynamic>)).toList();

    return [
      _cashCard(f),
      const SizedBox(height: 16),
      if (alerts.isNotEmpty) ...[
        for (final a in alerts) _alert(a),
        const SizedBox(height: 8),
      ],
      _Heading(l10n.todaysCash),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: _ledgerTile(Icons.south_west, l10n.cashReceived, today['inflows'] as num,
              today['inflowCount'] as int, FbColors.success, FbColors.successBg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ledgerTile(Icons.north_east, l10n.cashPaidOut, today['outflows'] as num,
              today['outflowCount'] as int, FbColors.danger, FbColors.dangerBg),
        ),
      ]),
      const SizedBox(height: 20),
      _Heading(l10n.services),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          _op(Icons.south_west, l10n.cashDeposit, l10n.cashDepositSub,
              () => _open(const CashTransactionScreen(type: 'deposit'))),
          _op(Icons.north_east, l10n.cashWithdrawal, l10n.cashWithdrawalSub,
              () => _open(const CashTransactionScreen(type: 'withdrawal'))),
          _op(Icons.person_add_alt, l10n.newCustomer, l10n.newCustomerSub, () => _open(const OnboardingScreen())),
          _op(Icons.person_search, l10n.findCustomer, l10n.findCustomerSub, () => widget.onOpenTab(1)),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(child: _Heading(l10n.todaysTransactions)),
          TextButton(onPressed: () => widget.onOpenTab(2), child: Text(l10n.seeAll)),
        ],
      ),
      if (recent.isEmpty) Text(l10n.noTransactionsToday, style: const TextStyle(color: FbColors.textMuted)),
      for (final t in recent) TxnTile(t, onTap: () => _open(ReceiptScreen(transactionId: t.id))),
    ];
  }

  /// "नमस्ते, Sita Sharma" with the agent ID chip, location and today's BS and AD date.
  Widget _greeting(Agent agent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(context.l10n.greeting(agent.name),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: FbColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: FbColors.successBg, borderRadius: BorderRadius.circular(20)),
                child: Text(agent.id,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FbColors.accentDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.place_outlined, size: 16, color: FbColors.textMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(agent.location, style: const TextStyle(color: FbColors.textMuted))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: FbColors.primary),
              const SizedBox(width: 6),
              Text(todayBsAndAd(bsMonths: context.l10n.bsMonths),
                  style: const TextStyle(fontSize: 13, color: FbColors.primary)),
            ]),
          ),
        ],
      );

  /// Navy card with the cash in hand, how full the drawer is, and a rebalance button.
  Widget _cashCard(Float f) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: FbColors.primary, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.payments_outlined, color: FbColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.l10n.cashInHand,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
              Text(context.l10n.openingAmount(formatNpr(f.opening)),
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(formatNpr(f.cash),
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            ),
            Text(amountInWords(f.cash),
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Text(context.l10n.usedPercent('${f.utilisation}'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Text(context.l10n.limitAmount(formatNpr(f.limit)),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (f.utilisation / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: FbColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Text(context.l10n.minReserveAmount(formatNpr(f.minReserve)),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: FbColors.accent,
                  foregroundColor: FbColors.primary,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => TerminalScreen.rebalance(context),
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Text(context.l10n.rebalance),
              ),
            ]),
          ],
        ),
      );

  Widget _ledgerTile(IconData icon, String label, num amount, int count, Color fg, Color bg) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: fg, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(context.l10n.txnCount(count),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontSize: 13, color: FbColors.textMuted)),
              const SizedBox(height: 2),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(formatNpr(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
              ),
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

  /// A notice card, with a button for the thing the agent should do about it.
  Widget _alert(Map<String, dynamic> a) {
    final l10n = context.l10n;
    final type = a['type'] as String;
    final count = (a['count'] as num?)?.toInt() ?? 0;
    final warn = type == 'low_float' || type == 'high_float' || type == 'pending_otp';
    final message = switch (type) {
      'kyc_pending' => l10n.alertKycPending(count),
      'eod_due' => l10n.alertEodDue,
      'pending_otp' => l10n.alertPendingOtp(count),
      'low_float' => l10n.alertLowFloat,
      'high_float' => l10n.alertHighFloat,
      _ => a['message'] as String? ?? '',
    };
    final (icon, action, onAction) = switch (type) {
      'eod_due' => (Icons.schedule, l10n.startEod, () => _open(const EodScreen())),
      'low_float' || 'high_float' => (Icons.account_balance_wallet_outlined, l10n.rebalance,
          () => TerminalScreen.rebalance(context)),
      'pending_otp' => (Icons.sms_outlined, l10n.view, () => widget.onOpenTab(2)),
      _ => (Icons.assignment_outlined, null, null),
    };
    final fg = warn ? FbColors.warning : FbColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: warn ? FbColors.warningBg : FbColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ),
          if (action != null)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: fg,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: onAction,
              child: Text(action),
            ),
        ]),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: FbColors.primary));
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
          subtitle: Text('${t.reference}\n${formatBsDateTime(t.createdAt, bsMonths: context.l10n.bsMonths)}',
              style: const TextStyle(fontSize: 12)),
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

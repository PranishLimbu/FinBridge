import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// UC6 Receipt (Figure 11). Can be opened right after a transaction or from the journal.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.transactionId, this.initial});

  final String transactionId;
  final Txn? initial;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Txn? _t;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _t = widget.initial;
    if (_t == null || _t!.raw['service'] == null) _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get('/transactions/${widget.transactionId}') as Map<String, dynamic>;
      if (mounted) setState(() => _t = Txn.fromJson(res));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _sms() async {
    try {
      await context.read<Session>().api.post('/transactions/${widget.transactionId}/receipt/sms');
      setState(() => _notice = 'Receipt sent to the customer by SMS.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  void _print() {
    // No printer integration in the prototype (report Table 3): show what would print.
    setState(() => _notice = 'Printing is simulated in this prototype. Send the SMS receipt instead.');
  }

  Future<void> _dispute() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a problem'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'What does the customer say went wrong?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send to supervisor')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.post('/transactions/${widget.transactionId}/disputes', {'reason': reason.text});
      setState(() => _notice = 'Dispute sent to your bank supervisor.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Column(
        children: [
          const SimulatedBanner(),
          Expanded(
            child: t == null
                ? Center(child: _error != null ? MessageBox(_error!) : const CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (t.status == 'confirmed')
                        const MessageBox('Transaction confirmed', error: false)
                      else
                        MessageBox('Transaction ${t.statusLabel.toLowerCase()}'
                            '${t.failureReason != null ? ' (${t.failureReason})' : ''}'),
                      const SizedBox(height: 12),
                      SectionCard(
                        child: Column(
                          children: [
                            const Text('FinBridge Agent Banking',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FbColors.primary)),
                            if (t.partnerBank.isNotEmpty)
                              Text('Partner bank: ${t.partnerBank}', style: const TextStyle(color: FbColors.success, fontSize: 12)),
                            Text('Agent: ${t.agent['name'] ?? ''} (${t.agent['agentId'] ?? ''})',
                                style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                            Text('${t.agent['location'] ?? ''}',
                                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                            const SizedBox(height: 8),
                            StatusChip(t.status),
                            const Divider(height: 24),
                            InfoRow('Reference', t.reference),
                            InfoRow('Date / time', formatNepalTime(t.confirmedAt ?? t.createdAt)),
                            InfoRow('Service', t.service),
                            InfoRow('Customer', t.customerName),
                            InfoRow('Account', t.accountMasked),
                            const Divider(height: 24),
                            InfoRow(t.isDeposit ? 'Cash deposited' : 'Cash paid out', formatNpr(t.amount)),
                            InfoRow('Service fee', formatNpr(t.fee)),
                            InfoRow(t.totalLabel, formatNpr(t.total), bold: true),
                            const SizedBox(height: 4),
                            Text('In words: ${t.amountInWords}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: FbColors.success, fontStyle: FontStyle.italic, fontSize: 12)),
                            const Divider(height: 24),
                            const Text('Simulated receipt for an academic prototype. Not a real bank voucher.',
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: FbColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_notice != null) ...[MessageBox(_notice!, error: false), const SizedBox(height: 12)],
                      if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                      if (t.status == 'confirmed') ...[
                        FilledButton.icon(onPressed: _print, icon: const Icon(Icons.print_outlined), label: const Text('Print receipt')),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(onPressed: _sms, icon: const Icon(Icons.sms_outlined), label: const Text('Send SMS receipt')),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _dispute,
                          icon: const Icon(Icons.report_gmailerrorred, color: FbColors.danger),
                          label: const Text('Report a problem with this transaction', style: TextStyle(color: FbColors.danger)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

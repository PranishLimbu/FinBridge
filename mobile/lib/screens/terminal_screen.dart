import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'eod_screen.dart';

/// Terminal tab: agent profile, end of day, float rebalance, change PIN, logout.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final a = session.agent!;
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: Column(
        children: [
          const SimulatedBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: a.name,
                  child: Column(children: [
                    InfoRow('Agent ID', a.id),
                    InfoRow('Location', a.location),
                    InfoRow('Terminal', a.terminalId ?? '-'),
                    InfoRow('Partner bank', a.partnerBank),
                    InfoRow('Server', AppConfig.apiUrl),
                  ]),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined, color: FbColors.primary),
                      title: const Text('End-of-day cash count'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EodScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.swap_vert, color: FbColors.primary),
                      title: const Text('Request float rebalance'),
                      subtitle: const Text('Hand cash to the bank, or ask for more'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _rebalance(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.password, color: FbColors.primary),
                      title: const Text('Change PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _changePin(context),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: FbColors.danger),
                  onPressed: () => session.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FinBridge is an academic prototype. All banks, people, accounts and money are fictional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: FbColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final api = context.read<Session>().api;
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Change PIN'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final (c, l) in [(current, 'Current PIN'), (next, 'New PIN'), (confirm, 'Confirm new PIN')])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: c,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l, counterText: ''),
                  ),
                ),
              if (error != null) Text(error!, style: const TextStyle(color: FbColors.danger)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (next.text != confirm.text) {
                    setState(() => error = 'The new PINs do not match');
                    return;
                  }
                  if (!RegExp(r'^\d{6}$').hasMatch(next.text)) {
                    setState(() => error = 'PIN must be 6 digits');
                    return;
                  }
                  try {
                    await api.post('/auth/change-pin', {'currentPin': current.text, 'newPin': next.text});
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(const SnackBar(content: Text('PIN changed')));
                  } on ApiException catch (e) {
                    setState(() => error = e.message);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rebalance(BuildContext context) async {
    final amount = TextEditingController();
    final api = context.read<Session>().api;
    final messenger = ScaffoldMessenger.of(context);
    var direction = 'cash_to_bank';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Float rebalance'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              RadioListTile<String>(
                value: 'cash_to_bank',
                groupValue: direction,
                onChanged: (v) => setState(() => direction = v!),
                title: const Text('Hand excess cash to the bank'),
              ),
              RadioListTile<String>(
                value: 'cash_from_bank',
                groupValue: direction,
                onChanged: (v) => setState(() => direction = v!),
                title: const Text('Request more cash from the bank'),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (Rs)'),
              ),
              if (error != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: FbColors.danger)),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final v = double.tryParse(amount.text);
                  if (v == null || v <= 0) {
                    setState(() => error = 'Enter an amount');
                    return;
                  }
                  try {
                    await api.post('/float/rebalance', {'direction': direction, 'amount': v});
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(const SnackBar(content: Text('Request sent to your supervisor')));
                  } on ApiException catch (e) {
                    setState(() => error = e.message);
                  }
                },
                child: const Text('Send request'),
              ),
            ],
          ),
        );
      },
    );
  }
}

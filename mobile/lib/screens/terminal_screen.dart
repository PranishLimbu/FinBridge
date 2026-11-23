import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/language_switch.dart';
import 'eod_screen.dart';

/// Terminal tab: agent profile, language, end of day, cash rebalance, change PIN, logout.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<Session>();
    final a = session.agent!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.terminalTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: a.name,
            child: Column(children: [
              InfoRow(l10n.agentId, a.id),
              InfoRow(l10n.location, a.location),
              InfoRow(l10n.terminal, a.terminalName ?? a.terminalId ?? '-'),
              InfoRow(l10n.partnerBank, a.partnerBank),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.translate, color: FbColors.primary),
                title: Text(l10n.language),
                trailing: const LanguageSwitch(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined, color: FbColors.primary),
                title: Text(l10n.eodTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EodScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_vert, color: FbColors.primary),
                title: Text(l10n.rebalanceCash),
                subtitle: Text(l10n.rebalanceSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => rebalance(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.password, color: FbColors.primary),
                title: Text(l10n.changePin),
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
            label: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    final l10n = context.l10n;
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
            title: Text(l10n.changePin),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final (c, l) in [(current, l10n.currentPin), (next, l10n.newPin), (confirm, l10n.confirmNewPin)])
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  if (next.text != confirm.text) {
                    setState(() => error = l10n.pinsDontMatch);
                    return;
                  }
                  if (!RegExp(r'^\d{6}$').hasMatch(next.text)) {
                    setState(() => error = l10n.pinSixDigits);
                    return;
                  }
                  try {
                    await api.post('/auth/change-pin', {'currentPin': current.text, 'newPin': next.text});
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(content: Text(l10n.pinChanged)));
                  } on ApiException catch (e) {
                    setState(() => error = l10n.error(e));
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Asks the supervisor to take extra cash to the bank, or to send more. Also used by the dashboard.
  static Future<void> rebalance(BuildContext context) async {
    final l10n = context.l10n;
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
            title: Text(l10n.rebalanceCash),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              RadioListTile<String>(
                value: 'cash_to_bank',
                groupValue: direction,
                onChanged: (v) => setState(() => direction = v!),
                title: Text(l10n.sendExtraCash),
              ),
              RadioListTile<String>(
                value: 'cash_from_bank',
                groupValue: direction,
                onChanged: (v) => setState(() => direction = v!),
                title: Text(l10n.askMoreCash),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.amountRs),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: FbColors.danger)),
                ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  final v = double.tryParse(amount.text);
                  if (v == null || v <= 0) {
                    setState(() => error = l10n.enterAnAmount);
                    return;
                  }
                  try {
                    await api.post('/float/rebalance', {'direction': direction, 'amount': v});
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(content: Text(l10n.requestSent)));
                  } on ApiException catch (e) {
                    setState(() => error = l10n.error(e));
                  }
                },
                child: Text(l10n.sendRequest),
              ),
            ],
          ),
        );
      },
    );
  }
}

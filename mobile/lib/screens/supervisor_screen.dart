import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Home screen for the bank supervisor: approve onboarding (KYC), decide float
/// rebalance requests and unlock agents locked out by wrong PINs.
class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;

  ApiClient get _api => context.read<Session>().api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _api.get('/supervisor/overview') as Map<String, dynamic>;
      if (mounted) setState(() { _data = d; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Runs a supervisor action, shows its outcome and reloads the overview.
  Future<void> _act(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: FbColors.danger));
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  void _kyc(String id, String name, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await _askReason(name);
      if (reason == null) return;
    }
    await _act(
      () => _api.post('/supervisor/customers/$id/kyc', {
        'decision': approve ? 'approve' : 'reject',
        if (reason != null) 'reason': reason,
      }),
      approve ? '$name approved: account is now active' : '$name rejected',
    );
  }

  Future<String?> _askReason(String name) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Reject $name'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 300,
              decoration: InputDecoration(labelText: 'Reason', errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: FbColors.danger),
                onPressed: () {
                  if (ctrl.text.trim().length < 5) {
                    setState(() => error = 'At least 5 characters');
                    return;
                  }
                  Navigator.pop(ctx, ctrl.text.trim());
                },
                child: const Text('Reject'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final me = session.agent!;
    final d = _data;
    final kyc = (d?['pendingKyc'] as List?) ?? [];
    final floats = (d?['floatRequests'] as List?) ?? [];
    final agents = (d?['agents'] as List?) ?? [];
    final locked = agents.where((a) => a['status'] == 'locked').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Log out', onPressed: () => session.logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          const SimulatedBanner(),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('${me.name} • ${me.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(me.location, style: const TextStyle(color: FbColors.textMuted)),
                  const SizedBox(height: 16),
                  if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                  if (d == null && _error == null)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                  if (d != null) ...[
                    SectionCard(
                      title: 'Customer applications (${kyc.length})',
                      child: kyc.isEmpty
                          ? const _Empty('No applications waiting for review')
                          : Column(children: [
                              for (final c in kyc)
                                _Item(
                                  title: c['name'] as String,
                                  subtitle: 'By ${c['createdByAgent']} • ${formatNepalTime(c['createdAt'] as String?)}',
                                  onApprove: _busy ? null : () => _kyc(c['customerId'] as String, c['name'] as String, true),
                                  onReject: _busy ? null : () => _kyc(c['customerId'] as String, c['name'] as String, false),
                                ),
                            ]),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: 'Float rebalance requests (${floats.length})',
                      child: floats.isEmpty
                          ? const _Empty('No pending requests')
                          : Column(children: [
                              for (final r in floats)
                                _Item(
                                  title: '${formatNpr(r['amount'] as num)} • '
                                      '${r['direction'] == 'cash_to_bank' ? 'cash to bank' : 'cash from bank'}',
                                  subtitle: '${r['agentId']} • ${formatNepalTime(r['createdAt'] as String?)}',
                                  onApprove: _busy ? null : () => _act(
                                      () => _api.post('/supervisor/float-requests/${r['id']}', {'approve': true}),
                                      'Float request approved'),
                                  onReject: _busy ? null : () => _act(
                                      () => _api.post('/supervisor/float-requests/${r['id']}', {'approve': false}),
                                      'Float request rejected'),
                                ),
                            ]),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: 'Locked agents (${locked.length})',
                      child: locked.isEmpty
                          ? const _Empty('No agents are locked out')
                          : Column(children: [
                              for (final a in locked)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${a['name']} • ${a['agentId']}'),
                                  subtitle: Text(a['location'] as String? ?? ''),
                                  trailing: FilledButton(
                                    style: _rowButton,
                                    onPressed: _busy ? null : () => _act(
                                        () => _api.post('/supervisor/agents/${a['agentId']}/unlock'),
                                        '${a['name']} unlocked'),
                                    child: const Text('Unlock'),
                                  ),
                                ),
                            ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app theme makes buttons full width; buttons inside a row need a normal size.
final _rowButton = FilledButton.styleFrom(minimumSize: const Size(0, 40));

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.subtitle, this.onApprove, this.onReject});

  final String title, subtitle;
  final VoidCallback? onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
          ]),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: FbColors.danger, minimumSize: const Size(0, 40)),
          onPressed: onReject,
          child: const Text('Reject'),
        ),
        const SizedBox(width: 4),
        FilledButton(style: _rowButton, onPressed: onApprove, child: const Text('Approve')),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: FbColors.textMuted));
}

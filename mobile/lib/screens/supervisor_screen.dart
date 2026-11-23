import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/language_switch.dart';
import 'customer_details_screen.dart';

/// Home screen for the bank supervisor: approve onboarding (KYC), decide cash rebalance
/// requests and unlock agents locked out by wrong PINs.
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
      if (mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    }
  }

  /// Runs a supervisor action, shows its outcome and reloads the overview.
  Future<void> _act(Future<void> Function() action, String done) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.error(e)), backgroundColor: FbColors.danger));
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  /// Opens the application. Approve and reject live on that page, after the customer's
  /// details and documents; it returns the outcome message once a decision is made.
  Future<void> _review(String customerId) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customerId: customerId, review: true)),
    );
    if (outcome != null) messenger.showSnackBar(SnackBar(content: Text(outcome)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<Session>();
    final me = session.agent!;
    final d = _data;
    final kyc = (d?['pendingKyc'] as List?) ?? [];
    final floats = (d?['floatRequests'] as List?) ?? [];
    final agents = (d?['agents'] as List?) ?? [];
    final locked = agents.where((a) => a['status'] == 'locked').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supervisorTitle),
        actions: [
          IconButton(tooltip: l10n.refresh, onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: l10n.logOut, onPressed: () => session.logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${me.name} • ${me.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(me.location, style: const TextStyle(color: FbColors.textMuted)),
                      ]),
                    ),
                    const LanguageSwitch(),
                  ]),
                  const SizedBox(height: 16),
                  if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                  if (d == null && _error == null)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                  if (d != null) ...[
                    SectionCard(
                      title: l10n.customerApplications(kyc.length),
                      child: kyc.isEmpty
                          ? _Empty(l10n.noApplications)
                          : Column(children: [
                              for (final c in kyc)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      l10n.byAgentAt(
                                          '${c['createdByAgent']}', formatNepalTime(c['createdAt'] as String?)),
                                      style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                                  trailing: FilledButton(
                                    style: _rowButton,
                                    onPressed: _busy ? null : () => _review(c['customerId'] as String),
                                    child: Text(l10n.reviewApplication),
                                  ),
                                ),
                            ]),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l10n.rebalanceRequests(floats.length),
                      child: floats.isEmpty
                          ? _Empty(l10n.noPendingRequests)
                          : Column(children: [
                              for (final r in floats)
                                _Item(
                                  title: '${formatNpr(r['amount'] as num)} • '
                                      '${r['direction'] == 'cash_to_bank' ? l10n.cashToBank : l10n.cashFromBank}',
                                  subtitle: '${r['agentId']} • ${formatNepalTime(r['createdAt'] as String?)}',
                                  onApprove: _busy
                                      ? null
                                      : () => _act(
                                          () => _api.post('/supervisor/float-requests/${r['id']}', {'approve': true}),
                                          l10n.requestApproved),
                                  onReject: _busy
                                      ? null
                                      : () => _act(
                                          () => _api.post('/supervisor/float-requests/${r['id']}', {'approve': false}),
                                          l10n.requestRejected),
                                ),
                            ]),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l10n.lockedAgents(locked.length),
                      child: locked.isEmpty
                          ? _Empty(l10n.noLockedAgents)
                          : Column(children: [
                              for (final a in locked)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${a['name']} • ${a['agentId']}'),
                                  subtitle: Text(a['location'] as String? ?? ''),
                                  trailing: FilledButton(
                                    style: _rowButton,
                                    onPressed: _busy
                                        ? null
                                        : () => _act(() => _api.post('/supervisor/agents/${a['agentId']}/unlock'),
                                            l10n.unlockedName('${a['name']}')),
                                    child: Text(l10n.unlock),
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
    final l10n = context.l10n;
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
          child: Text(l10n.reject),
        ),
        const SizedBox(width: 4),
        FilledButton(style: _rowButton, onPressed: onApprove, child: Text(l10n.approve)),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: FbColors.textMuted));
}

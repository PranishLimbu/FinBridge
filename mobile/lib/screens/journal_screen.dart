import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart' show TxnTile;
import 'receipt_screen.dart';

/// UC6 Transaction history with filters and search.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => JournalScreenState();
}

class JournalScreenState extends State<JournalScreen> {
  String? _type;
  String? _status;
  final _q = TextEditingController();
  List<Txn> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<Session>().api.get('/transactions', query: {
        if (_type != null) 'type': _type!,
        if (_status != null) 'status': _status!,
        if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
        'limit': '100',
      }) as Map<String, dynamic>;
      setState(() => _items = (res['results'] as List).map((t) => Txn.fromJson(t as Map<String, dynamic>)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _chip(String label, String? value, String? group, void Function(String?) onSet) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: group == value,
          onSelected: (_) {
            onSet(value);
            _load();
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.journalTitle), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: l10n.refresh),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _q,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: l10n.journalSearchHint),
              onSubmitted: (_) => _load(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _chip(l10n.filterAll, null, _type, (v) => setState(() => _type = v)),
              _chip(l10n.filterDeposits, 'deposit', _type, (v) => setState(() => _type = v)),
              _chip(l10n.filterWithdrawals, 'withdrawal', _type, (v) => setState(() => _type = v)),
              const SizedBox(width: 12),
              _chip(l10n.filterAnyStatus, null, _status, (v) => setState(() => _status = v)),
              _chip(l10n.statusConfirmed, 'confirmed', _status, (v) => setState(() => _status = v)),
              _chip(l10n.statusPendingOtp, 'awaiting_otp', _status, (v) => setState(() => _status = v)),
              _chip(l10n.statusCancelled, 'cancelled', _status, (v) => setState(() => _status = v)),
            ]),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.all(16), child: MessageBox(_error!)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty && !_loading
                  ? ListView(children: [
                      Padding(
                          padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.noTransactionsMatch))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => TxnTile(
                        _items[i],
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ReceiptScreen(transactionId: _items[i].id)));
                          _load();
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// UC7 End-of-day reconciliation: compare counted cash with the expected cash in hand.
class EodScreen extends StatefulWidget {
  const EodScreen({super.key});

  @override
  State<EodScreen> createState() => _EodScreenState();
}

class _EodScreenState extends State<EodScreen> {
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _result;
  final _counted = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _counted.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await context.read<Session>().api.get('/eod/preview') as Map<String, dynamic>;
      if (mounted) setState(() => _preview = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    }
  }

  double? get _countedValue => double.tryParse(_counted.text.replaceAll(',', ''));

  Future<void> _submit() async {
    final l10n = context.l10n;
    final counted = _countedValue;
    if (counted == null || counted < 0) {
      setState(() => _error = l10n.enterCountedCash);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await context.read<Session>().api.post('/eod', {
        'countedCash': counted,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      }) as Map<String, dynamic>;
      setState(() => _result = r);
    } on ApiException catch (e) {
      setState(() => _error = l10n.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The outcome in the app's language, built from the report's status and difference.
  String _resultMessage(Map<String, dynamic> r) {
    final l10n = context.l10n;
    final diff = (r['difference'] as num?)?.toDouble() ?? 0;
    if (diff == 0) return l10n.eodBalanced;
    return diff > 0 ? l10n.eodOver(formatNpr(diff.abs())) : l10n.eodShort(formatNpr(diff.abs()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _preview;
    final expected = (p?['expectedCash'] as num?)?.toDouble();
    final diff = (expected != null && _countedValue != null) ? _countedValue! - expected : null;
    final pending = (p?['pending'] as List?)?.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eodTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: p == null
          ? Center(child: _error != null ? MessageBox(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: l10n.today,
                  child: Column(children: [
                    InfoRow(l10n.openingCash, formatNpr(p['openingFloat'] as num)),
                    InfoRow(l10n.cashInCount(p['inflowCount'] as int), '+${formatNpr(p['inflows'] as num)}'),
                    InfoRow(l10n.cashOutCount(p['outflowCount'] as int), '-${formatNpr(p['outflows'] as num)}'),
                    const Divider(),
                    InfoRow(l10n.expectedCash, formatNpr(expected!), bold: true),
                  ]),
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 12),
                  MessageBox(l10n.eodPendingOtp(pending)),
                ],
                const SizedBox(height: 12),
                if (_result == null) ...[
                  TextField(
                    controller: _counted,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.countedCash, prefixText: l10n.currencyPrefix),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (diff != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      diff == 0
                          ? l10n.matchesExpected
                          : diff > 0
                              ? l10n.differenceOver(formatNpr(diff.abs()))
                              : l10n.differenceShort(formatNpr(diff.abs())),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: diff == 0 ? FbColors.success : FbColors.danger),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.notesForSupervisor),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? l10n.submitting : l10n.submitEod),
                  ),
                ] else ...[
                  MessageBox(_resultMessage(_result!), error: _result!['status'] != 'balanced'),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: StatusChip(_result!['status'] as String)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.done)),
                ],
              ],
            ),
    );
  }
}

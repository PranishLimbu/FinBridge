import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// UC7 End-of-day reconciliation: compare counted cash with the expected float.
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
      if (mounted) setState(() => _error = e.message);
    }
  }

  double? get _countedValue => double.tryParse(_counted.text.replaceAll(',', ''));

  Future<void> _submit() async {
    final counted = _countedValue;
    if (counted == null || counted < 0) {
      setState(() => _error = 'Enter the cash you counted');
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
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    final expected = (p?['expectedCash'] as num?)?.toDouble();
    final diff = (expected != null && _countedValue != null) ? _countedValue! - expected : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('End-of-day cash count'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const SimulatedBanner(),
          Expanded(
            child: p == null
                ? Center(child: _error != null ? MessageBox(_error!) : const CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionCard(
                        title: 'Today',
                        child: Column(children: [
                          InfoRow('Opening float', formatNpr(p['openingFloat'] as num)),
                          InfoRow('Cash in (${p['inflowCount']})', '+${formatNpr(p['inflows'] as num)}'),
                          InfoRow('Cash out (${p['outflowCount']})', '-${formatNpr(p['outflows'] as num)}'),
                          const Divider(),
                          InfoRow('Expected cash in drawer', formatNpr(expected!), bold: true),
                        ]),
                      ),
                      if ((p['pending'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        MessageBox('${(p['pending'] as List).length} withdrawal(s) still waiting for an OTP. '
                            'No cash should have been paid out for them.'),
                      ],
                      const SizedBox(height: 12),
                      if (_result == null) ...[
                        TextField(
                          controller: _counted,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cash you counted (Rs)', prefixText: 'Rs. '),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (diff != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            diff == 0
                                ? 'Matches the expected amount.'
                                : 'Difference: ${formatNpr(diff.abs())} ${diff > 0 ? 'over' : 'short'}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: diff == 0 ? FbColors.success : FbColors.danger),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notes,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Notes for supervisor (optional)'),
                        ),
                        const SizedBox(height: 12),
                        if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(_busy ? 'Submitting…' : 'Submit end-of-day report'),
                        ),
                      ] else ...[
                        MessageBox(_result!['message'] as String, error: _result!['status'] != 'balanced'),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: StatusChip(_result!['status'] as String)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

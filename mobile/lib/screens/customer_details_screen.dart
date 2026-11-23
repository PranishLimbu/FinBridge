import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Everything captured when the customer was set up: personal details, identity, family,
/// address, documents and accounts.
///
/// With [review] set, a supervisor is deciding the customer's application. Opening the page
/// records that they looked at it, and approve and reject sit at the bottom, after the details
/// and documents, behind an "I have checked" tick. The page pops with the outcome message.
class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customerId, this.review = false});

  final String customerId;
  final bool review;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _checked = false;
  bool _busy = false;

  ApiClient get _api => context.read<Session>().api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      // A supervisor's review goes through its own route, which records that they opened it.
      final path = widget.review ? '/supervisor/customers/${widget.customerId}' : '/customers/${widget.customerId}';
      final res = await _api.get(path) as Map<String, dynamic>;
      if (mounted) setState(() => _data = res);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    }
  }

  Future<void> _decide(bool approve, String name) async {
    final l10n = context.l10n;
    String? reason;
    if (!approve) {
      reason = await _askReason(name);
      if (reason == null || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.post('/supervisor/customers/${widget.customerId}/kyc', {
        'decision': approve ? 'approve' : 'reject',
        if (reason != null) 'reason': reason,
      });
      if (mounted) Navigator.of(context).pop(approve ? l10n.approvedActive(name) : l10n.rejectedName(name));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l10n.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String name) {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(l10n.rejectName(name)),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 300,
              decoration: InputDecoration(labelText: l10n.reason, errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: FbColors.danger, minimumSize: const Size(0, 40)),
                onPressed: () {
                  if (ctrl.text.trim().length < 5) {
                    setState(() => error = l10n.atLeastFiveChars);
                    return;
                  }
                  Navigator.pop(ctx, ctrl.text.trim());
                },
                child: Text(l10n.reject),
              ),
            ],
          ),
        );
      },
    );
  }

  String _v(dynamic x) {
    final s = x?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  /// Gender and marital status are stored as codes ('male', 'married', ...); show them in the app's language.
  String _gender(AppLocalizations l10n, dynamic code) => switch (code) {
        'male' => l10n.male,
        'female' => l10n.female,
        'other' => l10n.otherGender,
        _ => _v(code),
      };

  String _marital(AppLocalizations l10n, dynamic code) => switch (code) {
        'single' => l10n.single,
        'married' => l10n.married,
        'widowed' => l10n.widowed,
        'divorced' => l10n.divorced,
        _ => _v(code),
      };

  Widget _section(String title, List<Widget> rows) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...rows,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: Text(widget.review ? l10n.reviewApplicationTitle : l10n.customerDetailsTitle)),
      body: d == null
          ? (_error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    MessageBox(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
                  ]),
                )
              : const Center(child: CircularProgressIndicator()))
          : _details(l10n, d),
    );
  }

  Widget _details(AppLocalizations l10n, Map<String, dynamic> d) {
    final c = CustomerSummary.fromJson(d);
    final family = (d['family'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addr = (d['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final docs = (d['documents'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addressLine = [
      addr['tole'],
      addr['ward'] != null ? l10n.wardNumber('${addr['ward']}') : null,
      addr['municipality'],
      addr['district'],
      addr['province'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    final pending = c.kycStatus == 'pending_review';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: FbColors.primaryLight,
            child: Text(c.name.isNotEmpty ? c.name[0] : '?',
                style: const TextStyle(color: FbColors.primary, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(c.id, style: const TextStyle(color: FbColors.textMuted)),
            ]),
          ),
          StatusChip(c.kycStatus),
        ]),
        if (widget.review) ...[
          const SizedBox(height: 8),
          Text(l10n.byAgentAt(_v(d['createdByAgent']), formatNepalTime(d['createdAt'] as String?)),
              style: const TextStyle(color: FbColors.textMuted)),
        ],
        const SizedBox(height: 16),
        _section(l10n.personalInformation, [
          InfoRow(l10n.firstName, _v(d['firstName'])),
          InfoRow(l10n.middleName, _v(d['middleName'])),
          InfoRow(l10n.lastName, _v(d['lastName'])),
          InfoRow(l10n.gender, _gender(l10n, d['gender'])),
          InfoRow(l10n.maritalStatus, _marital(l10n, d['maritalStatus'])),
          InfoRow(l10n.dobBs, _v(d['dobBs'])),
          InfoRow(l10n.dobAd, _v(d['dobAd'])),
          InfoRow(l10n.occupation, _v(d['occupation'])),
          InfoRow(l10n.mobile, _v(c.mobileMasked)),
        ]),
        const SizedBox(height: 12),
        _section(l10n.identity, [
          InfoRow(l10n.citizenshipNo, _v(c.citizenshipMasked)),
          InfoRow(l10n.issueDateBs, _v(d['citizenshipIssueDateBs'])),
          InfoRow(l10n.issueDistrict, _v(d['citizenshipIssueDistrict'])),
          InfoRow(l10n.pan, _v(d['pan'])),
        ]),
        const SizedBox(height: 12),
        _section(l10n.stepFamily, [
          InfoRow(l10n.father, _v(family['fatherName'])),
          InfoRow(l10n.mother, _v(family['motherName'])),
          InfoRow(l10n.grandfather, _v(family['grandfatherName'])),
          InfoRow(l10n.spouse, _v(family['spouseName'])),
        ]),
        const SizedBox(height: 12),
        _section(l10n.stepAddress, [
          InfoRow(l10n.province, _v(addr['province'])),
          InfoRow(l10n.district, _v(addr['district'])),
          InfoRow(l10n.municipality, _v(addr['municipality'])),
          InfoRow(l10n.ward, _v(addr['ward'])),
          InfoRow(l10n.tole, _v(addr['tole'])),
          if (addressLine.isNotEmpty) InfoRow(l10n.fullAddress, addressLine),
        ]),
        const SizedBox(height: 12),
        _section(l10n.documents, [
          _DocumentTile(l10n.citizenshipFront, docs['citizenshipFront']),
          _DocumentTile(l10n.citizenshipBack, docs['citizenshipBack']),
          _DocumentTile(l10n.customerPhoto, docs['photo']),
        ]),
        const SizedBox(height: 12),
        _section(l10n.accounts, [
          if (c.accounts.isEmpty) Text(l10n.noAccounts, style: const TextStyle(color: FbColors.textMuted)),
          for (final a in c.accounts) InfoRow(a.productName, '${a.masked} (${l10n.status(a.status)})'),
        ]),
        if (!pending && d['kycRejectReason'] != null) ...[
          const SizedBox(height: 12),
          MessageBox('${l10n.reason}: ${d['kycRejectReason']}'),
        ],
        if (widget.review && pending) ...[
          const SizedBox(height: 12),
          _decision(l10n, c.name),
        ],
        if (_error != null) ...[const SizedBox(height: 12), MessageBox(_error!)],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Approve and reject, enabled once the supervisor confirms they checked everything above.
  Widget _decision(AppLocalizations l10n, String name) => _section(l10n.decision, [
        Text(l10n.reviewCheckFirst, style: const TextStyle(color: FbColors.textMuted)),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _checked,
          onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false),
          title: Text(l10n.reviewChecked),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: FbColors.danger, side: const BorderSide(color: FbColors.danger)),
              onPressed: _checked && !_busy ? () => _decide(false, name) : null,
              child: Text(l10n.reject),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _checked && !_busy ? () => _decide(true, name) : null,
              child: Text(l10n.approve),
            ),
          ),
        ]),
      ]);
}

/// One onboarding document: the uploaded scan when there is one, otherwise whether the agent
/// ticked it as checked.
class _DocumentTile extends StatelessWidget {
  const _DocumentTile(this.label, this.record);

  final String label;
  final dynamic record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = record is Map ? record as Map : const {};
    final url = r['url'] as String?;
    final captured = r['captured'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(captured ? Icons.check_circle : Icons.error_outline,
              size: 18, color: captured ? FbColors.success : FbColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        if (url != null)
          InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(child: Image.network(url, errorBuilder: (_, __, ___) => _loadError(l10n))),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: label,
                errorBuilder: (_, __, ___) => _loadError(l10n),
              ),
            ),
          )
        else
          Text(captured ? l10n.docNoFile : l10n.docMissing,
              style: TextStyle(fontSize: 12, color: captured ? FbColors.textMuted : FbColors.danger)),
      ]),
    );
  }

  Widget _loadError(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(l10n.docLoadError, style: const TextStyle(color: FbColors.danger)),
      );
}

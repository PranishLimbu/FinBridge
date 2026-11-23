import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Read-only view of everything captured when the customer was set up.
class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});

  final CustomerSummary customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await context.read<Session>().api.get('/customers/${widget.customer.id}') as Map<String, dynamic>;
      if (mounted) setState(() => _data = res);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    }
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
    final c = widget.customer;
    final d = _data;
    final family = (d?['family'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addr = (d?['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addressLine = [
      addr['tole'],
      addr['ward'] != null ? l10n.wardNumber('${addr['ward']}') : null,
      addr['municipality'],
      addr['district'],
      addr['province'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerDetailsTitle)),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                MessageBox(_error!),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
              ]),
            )
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
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
                    _section(l10n.accounts, [
                      if (c.accounts.isEmpty) Text(l10n.noAccounts, style: const TextStyle(color: FbColors.textMuted)),
                      for (final a in c.accounts) InfoRow(a.productName, '${a.masked} (${l10n.status(a.status)})'),
                    ]),
                  ],
                ),
    );
  }
}

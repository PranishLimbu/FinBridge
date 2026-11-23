import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
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
      if (mounted) setState(() => _error = e.message);
    }
  }

  String _v(dynamic x) {
    final s = x?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

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
    final c = widget.customer;
    final d = _data;
    final family = (d?['family'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addr = (d?['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final addressLine = [addr['tole'], addr['ward'] != null ? 'Ward ${addr['ward']}' : null, addr['municipality'], addr['district'], addr['province']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Customer details')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                MessageBox(_error!),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
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
                    _section('Personal information', [
                      InfoRow('First name', _v(d['firstName'])),
                      InfoRow('Middle name', _v(d['middleName'])),
                      InfoRow('Last name', _v(d['lastName'])),
                      InfoRow('Gender', _v(d['gender'])),
                      InfoRow('Marital status', _v(d['maritalStatus'])),
                      InfoRow('Date of birth (BS)', _v(d['dobBs'])),
                      InfoRow('Date of birth (AD)', _v(d['dobAd'])),
                      InfoRow('Occupation', _v(d['occupation'])),
                      InfoRow('Mobile', _v(c.mobileMasked)),
                    ]),
                    const SizedBox(height: 12),
                    _section('Identity', [
                      InfoRow('Citizenship no.', _v(c.citizenshipMasked)),
                      InfoRow('Issue date (BS)', _v(d['citizenshipIssueDateBs'])),
                      InfoRow('Issue district', _v(d['citizenshipIssueDistrict'])),
                      InfoRow('PAN', _v(d['pan'])),
                    ]),
                    const SizedBox(height: 12),
                    _section('Family', [
                      InfoRow('Father', _v(family['fatherName'])),
                      InfoRow('Mother', _v(family['motherName'])),
                      InfoRow('Grandfather', _v(family['grandfatherName'])),
                      InfoRow('Spouse', _v(family['spouseName'])),
                    ]),
                    const SizedBox(height: 12),
                    _section('Address', [
                      InfoRow('Province', _v(addr['province'])),
                      InfoRow('District', _v(addr['district'])),
                      InfoRow('Municipality', _v(addr['municipality'])),
                      InfoRow('Ward', _v(addr['ward'])),
                      InfoRow('Tole', _v(addr['tole'])),
                      if (addressLine.isNotEmpty) InfoRow('Full address', addressLine),
                    ]),
                    const SizedBox(height: 12),
                    _section('Accounts', [
                      if (c.accounts.isEmpty) const Text('No accounts', style: TextStyle(color: FbColors.textMuted)),
                      for (final a in c.accounts) InfoRow(a.productName, '${a.masked} (${a.status})'),
                    ]),
                  ],
                ),
    );
  }
}

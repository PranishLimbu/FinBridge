import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cash_transaction_screen.dart';
import 'onboarding_screen.dart';

/// UC2 Look up customer. Used as the Customers tab, and as a picker when [pickMode] is true
/// (then tapping a customer returns it with Navigator.pop).
class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<CustomerSummary> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<Session>().api.get('/customers', query: {'q': q}) as Map<String, dynamic>;
      setState(() {
        _results = (res['results'] as List).map((c) => CustomerSummary.fromJson(c as Map<String, dynamic>)).toList();
        _searched = true;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tap(CustomerSummary c) {
    if (widget.pickMode) {
      Navigator.of(context).pop(c);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${c.id} • ${c.mobileMasked} • Citizenship ${c.citizenshipMasked}',
                  style: const TextStyle(color: FbColors.textMuted)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: StatusChip(c.kycStatus)),
              const SizedBox(height: 8),
              for (final a in c.accounts) InfoRow(a.productName, '${a.masked} (${a.status})'),
              const SizedBox(height: 12),
              if (!c.verified)
                const MessageBox('This customer’s KYC is not verified yet, so cash transactions are not allowed.')
              else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.south_west),
                  label: const Text('Cash deposit'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CashTransactionScreen(type: 'deposit', customer: c)));
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.north_east),
                  label: const Text('Cash withdrawal'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CashTransactionScreen(type: 'withdrawal', customer: c)));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? 'Step 1: Find customer' : 'Customers')),
      floatingActionButton: widget.pickMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: FbColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('New customer'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            ),
      body: Column(
        children: [
          const SimulatedBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              autofocus: widget.pickMode,
              onChanged: _onChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Mobile, account, citizenship no. or name',
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () {
                          _query.clear();
                          _search();
                        },
                      ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: MessageBox(_error!)),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _searched
                            ? 'No customer found. Check the number, or register them as a new customer.'
                            : 'Search by the customer’s 10-digit mobile number, account number, citizenship number or name.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: FbColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _results[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _tap(c),
                          leading: CircleAvatar(
                            backgroundColor: FbColors.primaryLight,
                            child: Text(c.name.isNotEmpty ? c.name[0] : '?',
                                style: const TextStyle(color: FbColors.primary, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(c.name),
                          subtitle: Text('${c.mobileMasked} • ${c.accounts.map((a) => a.masked).join(', ')}'),
                          trailing: StatusChip(c.kycStatus),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

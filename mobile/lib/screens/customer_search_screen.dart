import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cash_transaction_screen.dart';
import 'customer_details_screen.dart';
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
    final l10n = context.l10n;
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
      setState(() => _error = l10n.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tap(CustomerSummary c) {
    if (widget.pickMode) {
      Navigator.of(context).pop(c);
      return;
    }
    final l10n = context.l10n;
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
              Row(
                children: [
                  Expanded(child: Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: 'View details',
                    color: FbColors.primary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: c)));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${c.id} • ${c.mobileMasked} • ${l10n.citizenshipMasked(c.citizenshipMasked)}',
                  style: const TextStyle(color: FbColors.textMuted)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: StatusChip(c.kycStatus)),
              const SizedBox(height: 8),
              for (final a in c.accounts) InfoRow(a.productName, '${a.masked} (${l10n.status(a.status)})'),
              const SizedBox(height: 12),
              if (!c.verified)
                MessageBox(l10n.kycNotVerified)
              else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.south_west),
                  label: Text(l10n.cashDeposit),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CashTransactionScreen(type: 'deposit', customer: c)));
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.north_east),
                  label: Text(l10n.cashWithdrawal),
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? l10n.findCustomerStepTitle : l10n.customersTitle),
        leading: widget.pickMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      floatingActionButton: widget.pickMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: FbColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.newCustomer),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              autofocus: widget.pickMode,
              onChanged: _onChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchHint,
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.clear,
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
                        _searched ? l10n.noCustomerFound : l10n.searchPrompt,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'customer_search_screen.dart';
import 'otp_screen.dart';
import 'receipt_screen.dart';

/// UC4 Cash deposit and UC5 Cash withdrawal (Figure 10 shows step 3).
/// Steps: 1 Customer, 2 Account, 3 Amount, 4 Review.
class CashTransactionScreen extends StatefulWidget {
  const CashTransactionScreen({super.key, required this.type, this.customer});

  final String type; // 'deposit' | 'withdrawal'
  final CustomerSummary? customer;

  @override
  State<CashTransactionScreen> createState() => _CashTransactionScreenState();
}

class _CashTransactionScreenState extends State<CashTransactionScreen> {
  CustomerSummary? _customer;
  Account? _account;
  String _digits = '';
  int _step = 0;
  double? _floatCash;
  bool _busy = false;
  String? _error;
  bool _outcomeUnknown = false;

  /// One key per attempt. Kept for retries so a network drop can never cause a double transaction.
  String? _idempotencyKey;

  bool get _isDeposit => widget.type == 'deposit';
  double get _amount => double.tryParse(_digits) ?? 0;
  double get _fee => _isDeposit ? AppConfig.depositFee : AppConfig.withdrawalFee;
  double get _total => _isDeposit ? _amount - _fee : _amount + _fee;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) _selectCustomer(widget.customer!);
    _loadFloat();
  }

  Future<void> _loadFloat() async {
    try {
      final d = await context.read<Session>().api.get('/dashboard') as Map<String, dynamic>;
      if (mounted) setState(() => _floatCash = ((d['float'] as Map)['cash'] as num).toDouble());
    } catch (_) {/* float impact is informational only */}
  }

  void _selectCustomer(CustomerSummary c) {
    _customer = c;
    final active = c.accounts.where((a) => a.isActive).toList();
    _account = active.length == 1 ? active.first : null;
    _step = active.length == 1 ? 2 : 1;
  }

  Future<void> _pickCustomer() async {
    final c = await Navigator.of(context).push<CustomerSummary>(
      MaterialPageRoute(builder: (_) => const CustomerSearchScreen(pickMode: true)),
    );
    if (c != null) setState(() => _selectCustomer(c));
  }

  String? get _amountError {
    if (_digits.isEmpty) return null;
    if (_amount < AppConfig.minAmount) return 'Minimum is ${formatNpr(AppConfig.minAmount)}';
    if (_amount > AppConfig.maxAmount) return 'Maximum is ${formatNpr(AppConfig.maxAmount)} per transaction';
    return null;
  }

  void _key(String k) {
    setState(() {
      if (k == 'C') {
        _digits = '';
      } else if (k == '<') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else if (_digits.length < 6 && !(_digits.isEmpty && k == '0')) {
        _digits += k;
      }
    });
  }

  void _toReview() {
    setState(() {
      _step = 3;
      _error = null;
      _outcomeUnknown = false;
      _idempotencyKey = newIdempotencyKey();
    });
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = context.read<Session>().api;
    final body = {
      'customerId': _customer!.id,
      'accountNo': _account!.accountNo,
      'amount': _amount,
      'idempotencyKey': _idempotencyKey,
    };
    try {
      if (_isDeposit) {
        final res = await api.post('/transactions/deposits', body) as Map<String, dynamic>;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ReceiptScreen(transactionId: res['id'] as String, initial: Txn.fromJson(res))));
      } else {
        final res = await api.post('/transactions/withdrawals', body) as Map<String, dynamic>;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OtpScreen(
            transaction: Txn.fromJson(res['transaction'] as Map<String, dynamic>),
            devOtp: res['devOtp'] as String?,
          ),
        ));
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _outcomeUnknown = e.isNetwork;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stepBack() {
    if (_busy) return;
    if (_step > 0) {
      setState(() {
        if (_step == 2 && _customer != null && _customer!.accounts.where((a) => a.isActive).length == 1) {
          _step = 0;
        } else {
          _step--;
        }
        _error = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isDeposit ? 'Cash deposit' : 'Cash withdrawal';
    return PopScope(
      canPop: !_busy && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stepBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _stepBack,
          ),
        ),
        body: Column(
          children: [
            const SimulatedBanner(),
            _progress(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: switch (_step) {
                  0 => _stepCustomer(),
                  1 => _stepAccount(),
                  2 => _stepAmount(),
                  _ => _stepReview(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "③ Step 3 of 4: Amount", a four-part bar, and the step names underneath.
  Widget _progress() {
    const labels = ['Customer', 'Account', 'Amount', 'Review'];
    return Container(
      color: FbColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: FbColors.primary,
              child: Text('${_step + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('Step ${_step + 1} of 4: ${labels[_step]}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: FbColors.primary)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i < _step
                              ? FbColors.accentDark
                              : i == _step
                                  ? FbColors.primary
                                  : FbColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${i + 1}. ${labels[i]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                            color: i <= _step ? FbColors.primary : FbColors.textMuted,
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerCard() => SectionCard(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: FbColors.primaryLight,
                  child: Text(_customer!.name[0],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: FbColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_customer!.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: FbColors.primary)),
                      Text('${_customer!.id} • ${_customer!.mobileMasked}',
                          style: const TextStyle(color: FbColors.textMuted)),
                    ],
                  ),
                ),
                StatusChip(_customer!.kycStatus),
              ],
            ),
            if (_account != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: FbColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_isDeposit ? 'DEPOSIT TO' : 'WITHDRAW FROM',
                          style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: FbColors.textMuted)),
                      Text(_account!.productName,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: FbColors.primary)),
                    ]),
                  ),
                  Text(_account!.masked, style: const TextStyle(color: FbColors.textMuted)),
                ]),
              ),
            ],
          ],
        ),
      );

  List<Widget> _stepCustomer() => [
        const Text('Search for the customer.'),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _pickCustomer, icon: const Icon(Icons.person_search), label: const Text('Search customer')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ];

  List<Widget> _stepAccount() {
    final c = _customer!;
    return [
      _customerCard(),
      const SizedBox(height: 16),
      if (!c.verified) const MessageBox('KYC not verified yet. Cash transactions are not allowed.'),
      const Text('Choose the account', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (final a in c.accounts)
        Card(
          child: ListTile(
            enabled: a.isActive && c.verified,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(a.productName),
            subtitle: Text(a.masked),
            trailing: StatusChip(a.status),
            onTap: () => setState(() {
              _account = a;
              _step = 2;
            }),
          ),
        ),
      const SizedBox(height: 12),
      TextButton(onPressed: _pickCustomer, child: const Text('Choose a different customer')),
    ];
  }

  List<Widget> _stepAmount() {
    final floatAfter = _floatCash == null ? null : (_isDeposit ? _floatCash! + _amount : _floatCash! - _amount);
    return [
      _customerCard(),
      const SizedBox(height: 12),
      SectionCard(
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('TYPE', style: TextStyle(fontSize: 12, letterSpacing: 1, color: FbColors.textMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isDeposit ? FbColors.successBg : FbColors.dangerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_isDeposit ? 'CASH IN' : 'CASH OUT',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isDeposit ? FbColors.accentDark : FbColors.danger)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(formatNpr(_amount).replaceAll('.00', ''),
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: FbColors.primary)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('NPR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FbColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Amount in words lets agent and customer check for keying errors (FR-6).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text(_amount > 0 ? amountInWords(_amount) : 'Enter the amount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FbColors.accentDark, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.info_outline, size: 14, color: FbColors.textMuted),
              const SizedBox(width: 4),
              Text('Min ${formatNpr(AppConfig.minAmount)} • Max ${formatNpr(AppConfig.maxAmount)}',
                  style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
            ]),
            if (_amountError != null) ...[const SizedBox(height: 8), MessageBox(_amountError!)],
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text('QUICK ADD', style: TextStyle(fontSize: 12, letterSpacing: 1, color: FbColors.textMuted)),
      const SizedBox(height: 6),
      Row(
        children: [
          for (final v in [1000, 2000, 5000, 10000])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: FbColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _digits = (_amount + v).toInt().toString()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('+${formatNpr(v).replaceAll('.00', '')}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: FbColors.primary)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      SectionCard(
        child: Column(children: [
          Row(children: const [
            Icon(Icons.receipt_long_outlined, size: 18, color: FbColors.primary),
            SizedBox(width: 6),
            Text('Fees', style: TextStyle(fontWeight: FontWeight.w700, color: FbColors.primary)),
          ]),
          const SizedBox(height: 8),
          InfoRow(_isDeposit ? 'Deposit amount' : 'Cash to hand over', formatNpr(_amount)),
          InfoRow('Service fee', _fee == 0 ? 'Free' : formatNpr(_fee)),
          const Divider(),
          InfoRow(_isDeposit ? 'Total credited' : 'Total debited', formatNpr(_total), bold: true),
          if (floatAfter != null && _floatCash != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: FbColors.primary, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.point_of_sale, color: FbColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('CASH IN HAND',
                        style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: formatNpr(_floatCash!),
                          style: const TextStyle(
                              color: Colors.white60, decoration: TextDecoration.lineThrough)),
                      const TextSpan(text: '  →  ', style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: formatNpr(floatAfter),
                          style: const TextStyle(color: FbColors.accent, fontWeight: FontWeight.w700)),
                    ])),
                  ]),
                ),
              ]),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      AmountKeypad(onKey: _key),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _amount > 0 && _amountError == null ? _toReview : null,
        child: const Text('Continue to review'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _stepBack,
        child: const Text('Back'),
      ),
    ];
  }

  List<Widget> _stepReview() => [
        const MessageBox('Confirm the details with the customer.', error: false),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Review',
          child: Column(children: [
            InfoRow('Service', _isDeposit ? 'Cash deposit' : 'Cash withdrawal'),
            InfoRow('Customer', _customer!.name),
            InfoRow('Account', '${_account!.productName} ${_account!.masked}'),
            InfoRow('Amount', formatNpr(_amount), bold: true),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(amountInWords(_amount),
                  textAlign: TextAlign.right, style: const TextStyle(color: FbColors.success, fontStyle: FontStyle.italic)),
            ),
            InfoRow('Fee', formatNpr(_fee)),
            InfoRow(_isDeposit ? 'Total credited' : 'Total debited', formatNpr(_total), bold: true),
          ]),
        ),
        const SizedBox(height: 12),
        if (!_isDeposit)
          const Text('The customer will get an OTP by SMS.', style: TextStyle(color: FbColors.textMuted)),
        if (_isDeposit)
          const Text('Count the cash before you confirm.', style: TextStyle(color: FbColors.textMuted)),
        const SizedBox(height: 12),
        if (_error != null) ...[
          MessageBox(_outcomeUnknown
              ? '$_error\nRetry is safe: it won’t create a second transaction.'
              : _error!),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_busy
              ? 'Processing…'
              : _outcomeUnknown
                  ? 'Retry'
                  : _isDeposit
                      ? 'Confirm deposit'
                      : 'Send OTP to customer'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : () => setState(() => _step = 2),
          child: const Text('Back: change amount'),
        ),
      ];
}

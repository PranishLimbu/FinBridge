import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config.dart';
import '../l10n/l10n.dart';
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
  final _amountCtl = TextEditingController();
  int _step = 0;
  int _firstStep = 0;
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
    if (widget.customer != null) {
      _selectCustomer(widget.customer!);
      // Opened from a customer's profile: back from the first step leaves this screen.
      _firstStep = _step;
    }
    _loadFloat();
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _loadFloat() async {
    try {
      final d = await context.read<Session>().api.get('/dashboard') as Map<String, dynamic>;
      if (mounted) setState(() => _floatCash = ((d['float'] as Map)['cash'] as num).toDouble());
    } catch (_) {/* cash-in-hand impact is informational only */}
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

  String? _amountError(AppLocalizations l10n) {
    if (_digits.isEmpty) return null;
    if (_amount < AppConfig.minAmount) return l10n.amountMinimum(formatNpr(AppConfig.minAmount));
    if (_amount > AppConfig.maxAmount) return l10n.amountMaximum(formatNpr(AppConfig.maxAmount));
    return null;
  }

  void _onAmountChanged(String v) {
    setState(() {
      // No leading zeros.
      _digits = v.replaceFirst(RegExp(r'^0+'), '');
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
    final l10n = context.l10n;
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
        _error = l10n.error(e);
        _outcomeUnknown = e.isNetwork;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stepBack() {
    if (_busy) return;
    if (_step > _firstStep) {
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
    final l10n = context.l10n;
    return PopScope(
      canPop: !_busy && _step <= _firstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stepBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isDeposit ? l10n.cashDeposit : l10n.cashWithdrawal),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.back,
            onPressed: _stepBack,
          ),
        ),
        body: Column(
          children: [
            _progress(l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: switch (_step) {
                  0 => _stepCustomer(l10n),
                  1 => _stepAccount(l10n),
                  2 => _stepAmount(l10n),
                  _ => _stepReview(l10n),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "③ Step 3 of 4: Amount", a four-part bar, and the step names underneath.
  Widget _progress(AppLocalizations l10n) {
    final labels = [l10n.stepCustomer, l10n.stepAccount, l10n.stepAmount, l10n.stepReview];
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
            Text(l10n.stepOfFour(_step + 1, labels[_step]),
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
                      Text(l10n.numberedStep(i + 1, labels[i]),
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

  Widget _customerCard(AppLocalizations l10n) => SectionCard(
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
                      Text(_isDeposit ? l10n.depositTo : l10n.withdrawFrom,
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

  List<Widget> _stepCustomer(AppLocalizations l10n) => [
        Text(l10n.searchForCustomer),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: _pickCustomer, icon: const Icon(Icons.person_search), label: Text(l10n.searchCustomer)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
      ];

  List<Widget> _stepAccount(AppLocalizations l10n) {
    final c = _customer!;
    return [
      _customerCard(l10n),
      const SizedBox(height: 16),
      if (!c.verified) MessageBox(l10n.kycNotVerified),
      Text(l10n.chooseAccount, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      TextButton(onPressed: _pickCustomer, child: Text(l10n.chooseDifferentCustomer)),
    ];
  }

  List<Widget> _stepAmount(AppLocalizations l10n) {
    final floatAfter = _floatCash == null ? null : (_isDeposit ? _floatCash! + _amount : _floatCash! - _amount);
    final amountError = _amountError(l10n);
    return [
      _customerCard(l10n),
      const SizedBox(height: 12),
      SectionCard(
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(l10n.typeLabel, style: const TextStyle(fontSize: 12, letterSpacing: 1, color: FbColors.textMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isDeposit ? FbColors.successBg : FbColors.dangerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_isDeposit ? l10n.cashInTag : l10n.cashOutTag,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isDeposit ? FbColors.accentDark : FbColors.danger)),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtl,
              onChanged: _onAmountChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: FbColors.primary),
              decoration: InputDecoration(labelText: '${l10n.amount} (${l10n.currencyCode})', hintText: '0', prefixText: 'Rs '),
              onSubmitted: (_) {
                if (_amount > 0 && amountError == null) _toReview();
              },
            ),
            const SizedBox(height: 8),
            // Amount in words lets agent and customer check for keying errors (FR-6).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text(_amount > 0 ? amountInWords(_amount) : l10n.enterTheAmount,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FbColors.accentDark, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.info_outline, size: 14, color: FbColors.textMuted),
              const SizedBox(width: 4),
              Text(l10n.minMax(formatNpr(AppConfig.minAmount), formatNpr(AppConfig.maxAmount)),
                  style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
            ]),
            if (amountError != null) ...[const SizedBox(height: 8), MessageBox(amountError)],
          ],
        ),
      ),
      const SizedBox(height: 14),
      SectionCard(
        child: Column(children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 18, color: FbColors.primary),
            const SizedBox(width: 6),
            Text(l10n.fees, style: const TextStyle(fontWeight: FontWeight.w700, color: FbColors.primary)),
          ]),
          const SizedBox(height: 8),
          InfoRow(_isDeposit ? l10n.depositAmount : l10n.cashToHandOver, formatNpr(_amount)),
          InfoRow(l10n.serviceFee, _fee == 0 ? l10n.free : formatNpr(_fee)),
          const Divider(),
          InfoRow(_isDeposit ? l10n.totalCredited : l10n.totalDebited, formatNpr(_total), bold: true),
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
                    Text(l10n.cashInHand,
                        style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: formatNpr(_floatCash!),
                          style: const TextStyle(color: Colors.white60, decoration: TextDecoration.lineThrough)),
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
      FilledButton(
        onPressed: _amount > 0 && amountError == null ? _toReview : null,
        child: Text(l10n.continueToReview),
      ),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _stepBack, child: Text(l10n.back)),
    ];
  }

  List<Widget> _stepReview(AppLocalizations l10n) => [
        MessageBox(l10n.confirmWithCustomer, error: false),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.review,
          child: Column(children: [
            InfoRow(l10n.service, _isDeposit ? l10n.cashDeposit : l10n.cashWithdrawal),
            InfoRow(l10n.customer, _customer!.name),
            InfoRow(l10n.account, '${_account!.productName} ${_account!.masked}'),
            InfoRow(l10n.amount, formatNpr(_amount), bold: true),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(amountInWords(_amount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: FbColors.success, fontStyle: FontStyle.italic)),
            ),
            InfoRow(l10n.fee, formatNpr(_fee)),
            InfoRow(_isDeposit ? l10n.totalCredited : l10n.totalDebited, formatNpr(_total), bold: true),
          ]),
        ),
        const SizedBox(height: 12),
        Text(_isDeposit ? l10n.countCashFirst : l10n.otpWillBeSent, style: const TextStyle(color: FbColors.textMuted)),
        const SizedBox(height: 12),
        if (_error != null) ...[
          MessageBox(_outcomeUnknown ? l10n.retrySafe(_error!) : _error!),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_busy
              ? l10n.processing
              : _outcomeUnknown
                  ? l10n.retry
                  : _isDeposit
                      ? l10n.confirmDeposit
                      : l10n.sendOtpToCustomer),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : () => setState(() => _step = 2),
          child: Text(l10n.backChangeAmount),
        ),
      ];
}

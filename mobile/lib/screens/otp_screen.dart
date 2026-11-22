import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'receipt_screen.dart';

/// UC5 step: the customer reads out the OTP sent to their phone; nothing moves until it is correct.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.transaction, this.devOtp});

  final Txn transaction;

  /// Shown only in the demo build, because there is no real SMS gateway.
  final String? devOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  late DateTime _expires;
  late DateTime _canResendAt;
  Timer? _ticker;
  String? _devOtp;
  String? _error;
  bool _busy = false;
  bool _closed = false; // cancelled or expired

  Txn get t => widget.transaction;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _expires = DateTime.tryParse(t.raw['otpExpiresAt'] as String? ?? '') ?? DateTime.now().add(const Duration(minutes: 5));
    _canResendAt = DateTime.now().add(const Duration(seconds: 60));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otp.dispose();
    super.dispose();
  }

  Duration get _left {
    final d = _expires.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> _confirm() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_otp.text)) {
      setState(() => _error = 'The OTP has 6 digits');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await context.read<Session>().api.post('/transactions/${t.id}/confirm-otp', {'otp': _otp.text})
          as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ReceiptScreen(transactionId: t.id, initial: Txn.fromJson(res))));
    } on ApiException catch (e) {
      final left = e.details?['attemptsRemaining'];
      setState(() {
        _error = left != null ? '${e.message}. $left attempt(s) left.' : e.message;
        _closed = const {'OTP_EXPIRED', 'OTP_ATTEMPTS_EXCEEDED', 'NOT_AWAITING_OTP', 'INSUFFICIENT_FLOAT', 'INSUFFICIENT_BALANCE', 'ACCOUNT_INACTIVE'}
            .contains(e.code);
      });
      _otp.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final res = await context.read<Session>().api.post('/transactions/${t.id}/resend-otp') as Map<String, dynamic>?;
      setState(() {
        _devOtp = res?['devOtp'] as String? ?? _devOtp;
        _expires = DateTime.now().add(const Duration(minutes: 5));
        _canResendAt = DateTime.now().add(const Duration(seconds: 60));
        _error = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _cancel() async {
    try {
      await context.read<Session>().api.post('/transactions/${t.id}/cancel');
    } on ApiException catch (_) {/* may already be cancelled */}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final resendIn = _canResendAt.difference(DateTime.now()).inSeconds;
    return PopScope(
      canPop: _closed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer OTP'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: _closed ? 'Back' : 'Cancel & Back',
            onPressed: () {
              if (_closed) {
                Navigator.of(context).pop();
              } else {
                _cancel();
              }
            },
          ),
        ),
        body: Column(
          children: [
            const SimulatedBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionCard(
                    child: Column(children: [
                      InfoRow('Customer', t.customerName),
                      InfoRow('Account', t.accountMasked),
                      InfoRow('Cash to hand over', formatNpr(t.amount), bold: true),
                      InfoRow('Fee', formatNpr(t.fee)),
                      InfoRow('Total debited', formatNpr(t.total)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ask the customer for the 6-digit OTP sent to their registered mobile.',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_left == Duration.zero ? 'OTP expired' : 'Expires in $mm:$ss',
                      style: TextStyle(color: _left.inSeconds < 60 ? FbColors.danger : FbColors.textMuted)),
                  if (_devOtp != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: FbColors.warningBg, borderRadius: BorderRadius.circular(8)),
                      child: Text('Demo only (no real SMS): OTP is $_devOtp',
                          style: const TextStyle(color: FbColors.warning, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otp,
                    enabled: !_closed,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    decoration: const InputDecoration(counterText: '', hintText: '••••••'),
                    onSubmitted: (_) => _confirm(),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                  if (!_closed) ...[
                    FilledButton(
                      onPressed: _busy || _left == Duration.zero ? null : _confirm,
                      child: Text(_busy ? 'Checking…' : 'Verify OTP and confirm'),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: resendIn > 0 ? null : _resend,
                          child: Text(resendIn > 0 ? 'Resend in ${resendIn}s' : 'Resend OTP'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _cancel,
                          style: OutlinedButton.styleFrom(foregroundColor: FbColors.danger),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ]),
                  ] else
                    FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to counter')),
                  const SizedBox(height: 16),
                  const Text('Do not hand over any cash until the next screen says “Confirmed”.',
                      style: TextStyle(color: FbColors.danger, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

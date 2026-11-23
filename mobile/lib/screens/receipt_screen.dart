import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/receipt_pdf.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// UC6 Receipt (Figure 11). Can be opened right after a transaction or from the journal.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.transactionId, this.initial});

  final String transactionId;
  final Txn? initial;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Txn? _t;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _t = widget.initial;
    if (_t == null || _t!.raw['service'] == null) _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get('/transactions/${widget.transactionId}') as Map<String, dynamic>;
      if (mounted) setState(() => _t = Txn.fromJson(res));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = context.l10n.error(e));
    }
  }

  Future<void> _sms() async {
    final l10n = context.l10n;
    try {
      await context.read<Session>().api.post('/transactions/${widget.transactionId}/receipt/sms');
      setState(() => _notice = l10n.receiptSmsSent);
    } on ApiException catch (e) {
      setState(() => _error = l10n.error(e));
    }
  }

  Future<void> _print() async {
    final l10n = context.l10n;
    final t = _t;
    if (t == null) return;
    try {
      // Opens the system print dialog (printer or Save as PDF); the browser's dialog on web.
      await Printing.layoutPdf(
        name: 'Receipt-${t.reference}',
        format: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
        onLayout: (_) => buildReceiptPdf(t),
      );
    } catch (e) {
      if (mounted) setState(() => _error = l10n.printError('$e'));
    }
  }

  Future<void> _dispute() async {
    final l10n = context.l10n;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reportProblem),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.reportProblemHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.sendToSupervisor)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.post('/transactions/${widget.transactionId}/disputes', {'reason': reason.text});
      setState(() => _notice = l10n.disputeSent);
    } on ApiException catch (e) {
      setState(() => _error = l10n.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = _t;
    void goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeShell(key: ValueKey(context.read<Session>().agent!.id))),
        );
      }
    }

    final when = t?.confirmedAt ?? t?.createdAt;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: goBack,
        ),
      ),
      body: t == null
          ? Center(child: _error != null ? MessageBox(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (t.status == 'confirmed')
                  _confirmedBanner(t)
                else
                  MessageBox(l10n.transactionStatus(l10n.status(t.status).toLowerCase())),
                const SizedBox(height: 12),
                ClipPath(
                  clipper: _ZigZagClipper(),
                  child: Container(
                    color: FbColors.surface,
                    padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
                    child: Column(
                      children: [
                        const FbLogo(),
                        const SizedBox(height: 8),
                        if (t.partnerBank.isNotEmpty)
                          Text(l10n.partnerBankLine(t.partnerBank),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: FbColors.accentDark, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                            l10n.receiptAgentLine('${t.agent['location'] ?? ''}', '${t.agent['name'] ?? ''}',
                                '${t.agent['agentId'] ?? ''}'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                        const SizedBox(height: 14),
                        _stamp(t),
                        const SizedBox(height: 14),
                        const _DashedLine(),
                        const SizedBox(height: 10),
                        InfoRow(l10n.reference, t.reference),
                        InfoRow(l10n.dateBs, formatBsDateTime(when, bsMonths: l10n.bsMonths)),
                        InfoRow(l10n.dateAd, formatNepalTime(when)),
                        InfoRow(l10n.service,
                            t.isDeposit ? l10n.serviceDepositBranchless : l10n.serviceWithdrawalBranchless),
                        InfoRow(l10n.customer, t.customerName),
                        InfoRow(l10n.account, t.accountMasked),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration:
                              BoxDecoration(color: FbColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                          child: Column(children: [
                            InfoRow(t.isDeposit ? l10n.cashDeposited : l10n.cashPaidOut, formatNpr(t.amount)),
                            InfoRow(l10n.serviceFee, t.fee == 0 ? l10n.free : formatNpr(t.fee)),
                            const Divider(height: 18),
                            Row(children: [
                              Expanded(
                                child: Text(t.isDeposit ? l10n.totalCredited : l10n.totalDebited,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 16, color: FbColors.primary)),
                              ),
                              Text(formatNpr(t.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 22, color: FbColors.primary)),
                            ]),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(l10n.inWords(t.amountInWords),
                                  style: const TextStyle(
                                      color: FbColors.accentDark, fontStyle: FontStyle.italic, fontSize: 12)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        const _DashedLine(),
                        const SizedBox(height: 10),
                        if (t.status == 'confirmed')
                          Text(l10n.smsReceiptSentNote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_notice != null) ...[MessageBox(_notice!, error: false), const SizedBox(height: 12)],
                if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                if (t.status == 'confirmed') ...[
                  FilledButton.icon(
                      onPressed: _print, icon: const Icon(Icons.print_outlined), label: Text(l10n.printReceipt)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                      onPressed: _sms, icon: const Icon(Icons.sms_outlined), label: Text(l10n.sendSmsReceipt)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _dispute,
                    icon: const Icon(Icons.report_gmailerrorred, color: FbColors.danger),
                    label: Text(l10n.reportProblem, style: const TextStyle(color: FbColors.danger)),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton(onPressed: goBack, child: Text(l10n.done)),
              ],
            ),
    );
  }

  Widget _confirmedBanner(Txn t) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: FbColors.accent, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: FbColors.primary,
            child: Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.transactionConfirmed,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FbColors.primary)),
              Text(t.reference, style: const TextStyle(color: FbColors.primary)),
            ]),
          ),
        ]),
      );

  Widget _stamp(Txn t) {
    final ok = t.status == 'confirmed';
    final color = ok ? FbColors.accentDark : FbColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? FbColors.successBg : FbColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined, color: color),
        const SizedBox(width: 6),
        Text(context.l10n.status(t.status).toUpperCase(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1, color: color)),
      ]),
    );
  }
}

/// Paper-receipt edges: small zig-zags along the top and bottom.
class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tooth = 8.0;
    final path = Path()..moveTo(0, tooth);
    for (var x = 0.0; x < size.width; x += tooth * 2) {
      path
        ..lineTo(x + tooth, 0)
        ..lineTo(x + tooth * 2, tooth);
    }
    path.lineTo(size.width, size.height - tooth);
    for (var x = size.width; x > 0; x -= tooth * 2) {
      path
        ..lineTo(x - tooth, size.height)
        ..lineTo(x - tooth * 2, size.height - tooth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => Row(
          children: [
            for (var i = 0; i < c.maxWidth ~/ 8; i++)
              Container(width: 4, height: 1.2, margin: const EdgeInsets.only(right: 4), color: FbColors.border),
          ],
        ),
      );
}

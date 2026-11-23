import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/widgets.dart' show Locale;

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

/// 80 mm till-roll page: 80 mm wide with 4 mm side margins. Height grows with the content.
const _rollFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

/// Builds the printable receipt for a confirmed transaction. Always English: the monospace
/// receipt-printer font has no Devanagari letters. Text comes from lib/l10n/app_en.arb.
Future<Uint8List> buildReceiptPdf(Txn t) async {
  final s = lookupAppLocalizations(const Locale('en'));
  final regular = pw.Font.courier();
  final bold = pw.Font.courierBold();
  pw.TextStyle style({bool isBold = false, double size = 9}) =>
      pw.TextStyle(font: isBold ? bold : regular, fontSize: size);

  pw.Widget center(String text, {bool isBold = false, double size = 9}) =>
      pw.Center(child: pw.Text(text, textAlign: pw.TextAlign.center, style: style(isBold: isBold, size: size)));

  pw.Widget row(String label, String value, {bool isBold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$label ', style: style(isBold: isBold)),
            pw.Expanded(child: pw.Text(value, textAlign: pw.TextAlign.right, style: style(isBold: isBold))),
          ],
        ),
      );

  pw.Widget rule({bool dashed = true}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Divider(
          height: 1,
          thickness: 0.6,
          borderStyle: dashed ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
        ),
      );

  final agent = t.agent;
  final title = t.isDeposit ? s.pdfCashDeposit : s.pdfCashWithdrawal;
  final location = '${agent['location'] ?? ''}';

  final doc = pw.Document(title: s.pdfTitle(t.reference), author: s.logoName);
  doc.addPage(
    pw.Page(
      pageFormat: _rollFormat,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          center(s.pdfHeader, isBold: true, size: 12),
          if (t.partnerBank.isNotEmpty) center(t.partnerBank),
          if (location.isNotEmpty) center(location, size: 8),
          rule(dashed: false),
          center(title, isBold: true, size: 11),
          pw.SizedBox(height: 3),
          center(formatNpr(t.total), isBold: true, size: 15),
          rule(),
          row(s.pdfCustomer, t.customerName),
          row(s.pdfAccount, t.accountMasked.replaceAll('•', '*')),
          rule(),
          row(s.pdfDate, formatNepalTime(t.confirmedAt ?? t.createdAt)),
          row(s.pdfAgent, '${agent['name'] ?? ''}'),
          row(s.pdfAgentId, '${agent['agentId'] ?? ''}'),
          row(s.pdfReference, t.reference),
          rule(),
          center(t.isDeposit ? s.pdfDepositDetails : s.pdfWithdrawalDetails, isBold: true),
          pw.SizedBox(height: 2),
          row(t.isDeposit ? s.pdfCashDeposited : s.pdfCashPaidOut, formatNpr(t.amount)),
          row(s.pdfServiceFee, formatNpr(t.fee)),
          row(t.isDeposit ? s.pdfTotalCredited : s.pdfTotalDebited, formatNpr(t.total), isBold: true),
          pw.SizedBox(height: 2),
          pw.Text(s.inWords(t.amountInWords), style: style(size: 8)),
          if (t.balanceBefore != null && t.balanceAfter != null) ...[
            rule(),
            row(s.pdfPriorBalance, formatNpr(t.balanceBefore!), isBold: true),
            row(s.pdfNewBalance, formatNpr(t.balanceAfter!), isBold: true),
          ],
          rule(),
          center(s.pdfFooter, size: 7),
          pw.SizedBox(height: 4),
          center(s.pdfThankYou, size: 8),
        ],
      ),
    ),
  );
  return doc.save();
}

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../api/models.dart';
import 'format.dart';

/// 80 mm till-roll page: 80 mm wide with 4 mm side margins. Height grows with the content.
const _rollFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

/// Builds the printable receipt (English, monospace) for a confirmed transaction.
Future<Uint8List> buildReceiptPdf(Txn t) async {
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
  final title = t.isDeposit ? 'CASH DEPOSIT' : 'CASH WITHDRAWAL';
  final location = '${agent['location'] ?? ''}';

  final doc = pw.Document(title: 'Receipt ${t.reference}', author: 'FinBridge');
  doc.addPage(
    pw.Page(
      pageFormat: _rollFormat,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          center('FINBRIDGE AGENT BANKING', isBold: true, size: 12),
          if (t.partnerBank.isNotEmpty) center(t.partnerBank),
          if (location.isNotEmpty) center(location, size: 8),
          rule(dashed: false),
          center(title, isBold: true, size: 11),
          pw.SizedBox(height: 3),
          center(formatNpr(t.total), isBold: true, size: 15),
          rule(),
          row('Customer:', t.customerName),
          row('Account:', t.accountMasked.replaceAll('•', '*')),
          rule(),
          row('Date:', formatNepalTime(t.confirmedAt ?? t.createdAt)),
          row('Agent:', '${agent['name'] ?? ''}'),
          row('Agent ID:', '${agent['agentId'] ?? ''}'),
          row('Ref #:', t.reference),
          rule(),
          center('${title.split(' ').last} DETAILS', isBold: true),
          pw.SizedBox(height: 2),
          row(t.isDeposit ? 'Cash deposited:' : 'Cash paid out:', formatNpr(t.amount)),
          row('Service fee:', formatNpr(t.fee)),
          row('${t.totalLabel}:', formatNpr(t.total), isBold: true),
          pw.SizedBox(height: 2),
          pw.Text('In words: ${t.amountInWords}', style: style(size: 8)),
          if (t.balanceBefore != null && t.balanceAfter != null) ...[
            rule(),
            row('Prior Balance:', formatNpr(t.balanceBefore!), isBold: true),
            row('New Balance:', formatNpr(t.balanceAfter!), isBold: true),
          ],
          rule(),
          center('Simulated receipt for an academic', size: 7),
          center('prototype. Not a real bank voucher.', size: 7),
          pw.SizedBox(height: 4),
          center('Thank you', size: 8),
        ],
      ),
    ),
  );
  return doc.save();
}

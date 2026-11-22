import 'package:finbridge_agent/api/models.dart';
import 'package:finbridge_agent/utils/receipt_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> json(String type) => {
        'id': 'x',
        'reference': 'TXN-1',
        'type': type,
        'status': 'confirmed',
        'customerName': 'Hari Bahadur Thapa',
        'accountMasked': '****4092',
        'amount': 500,
        'fee': type == 'deposit' ? 0 : 10,
        'total': type == 'deposit' ? 500 : 510,
        'amountInWords': 'Five Hundred Nepalese Rupees Only',
        'createdAt': '2026-11-22T03:36:00.000Z',
        'agent': {'name': 'Sita Sharma', 'agentId': 'AGT-98412', 'location': 'Kathmandu'},
        'balanceBefore': 1000,
        'balanceAfter': 1500,
      };

  for (final type in ['deposit', 'withdrawal']) {
    test('builds $type receipt pdf', () async {
      final bytes = await buildReceiptPdf(Txn.fromJson(json(type)));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  }
}

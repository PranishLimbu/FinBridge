import 'package:finbridge_agent/api/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rupees and paisa convert without rounding errors', () {
    expect(rupeesToPaisa(0.1 + 0.2), 30);
    expect(rupeesToPaisa(25000), 2500000);
    expect(paisaToRupees(1050), 10.5);
    expect(hasTwoDecimals(10.25), isTrue);
    expect(hasTwoDecimals(10.255), isFalse);
  });

  test('amounts use Nepali digit grouping', () {
    expect(formatNpr(0), 'Rs. 0.00');
    expect(formatNpr(12345), 'Rs. 123.45');
    expect(formatNpr(10000000), 'Rs. 1,00,000.00');
    expect(formatNpr(1234567890), 'Rs. 1,23,45,678.90');
    expect(formatNpr(-50000), '-Rs. 500.00');
  });

  test('amounts in words use lakh and crore', () {
    expect(amountInWords(250000), 'Two Thousand Five Hundred Nepalese Rupees Only');
    expect(amountInWords(15000050), 'One Lakh Fifty Thousand Nepalese Rupees and Fifty Paisa Only');
    expect(amountInWords(1000000000), 'One Crore Nepalese Rupees Only');
  });
}

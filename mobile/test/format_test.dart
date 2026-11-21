import 'package:finbridge_agent/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NPR uses Nepali digit grouping', () {
    expect(formatNpr(100000), 'Rs. 1,00,000.00');
    expect(formatNpr(5000), 'Rs. 5,000.00');
    expect(formatNpr(12345678.5), 'Rs. 1,23,45,678.50');
  });

  test('amount in words matches the server', () {
    expect(amountInWords(5000), 'Five Thousand Nepalese Rupees Only');
    expect(amountInWords(123456.78),
        'One Lakh Twenty Three Thousand Four Hundred Fifty Six Nepalese Rupees and Seventy Eight Paisa Only');
  });

  test('idempotency keys are unique 32-character hex strings', () {
    final a = newIdempotencyKey();
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newIdempotencyKey(), isNot(a));
  });
}

import 'dart:math';

/// Rs. 1,00,000.00 (Nepali digit grouping).
String formatNpr(num amount) {
  final negative = amount < 0;
  final paisa = (amount.abs() * 100).round();
  final rupees = (paisa ~/ 100).toString();
  final decimals = (paisa % 100).toString().padLeft(2, '0');
  String grouped;
  if (rupees.length <= 3) {
    grouped = rupees;
  } else {
    final last3 = rupees.substring(rupees.length - 3);
    var rest = rupees.substring(0, rupees.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${negative ? '-' : ''}Rs. $grouped.$decimals';
}

const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
  'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
  'Eighteen', 'Nineteen',
];
const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

String _two(int n) {
  if (n < 20) return _ones[n];
  final rest = n % 10;
  return '${_tens[n ~/ 10]}${rest > 0 ? ' ${_ones[rest]}' : ''}';
}

String _three(int n) {
  final h = n ~/ 100;
  final r = n % 100;
  return [if (h > 0) '${_ones[h]} Hundred', if (r > 0) _two(r)].join(' ');
}

String _words(int n) {
  if (n == 0) return 'Zero';
  final parts = <String>[];
  final crore = n ~/ 10000000;
  final lakh = (n % 10000000) ~/ 100000;
  final thousand = (n % 100000) ~/ 1000;
  final rest = n % 1000;
  if (crore > 0) parts.add('${_words(crore)} Crore');
  if (lakh > 0) parts.add('${_two(lakh)} Lakh');
  if (thousand > 0) parts.add('${_two(thousand)} Thousand');
  if (rest > 0) parts.add(_three(rest));
  return parts.join(' ');
}

/// "Five Thousand Nepalese Rupees Only" – matches the server's wording.
String amountInWords(num amount) {
  final paisa = (amount * 100).round();
  var text = '${_words(paisa ~/ 100)} Nepalese Rupees';
  if (paisa % 100 > 0) text += ' and ${_two(paisa % 100)} Paisa';
  return '$text Only';
}

/// Converts an ISO time to Nepal Time (UTC+05:45) and formats it, e.g. 24 Nov 2026, 11:42.
String formatNepalTime(String? iso) {
  if (iso == null) return '-';
  final utc = DateTime.tryParse(iso);
  if (utc == null) return iso;
  final t = utc.toUtc().add(const Duration(hours: 5, minutes: 45));
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]} ${t.year}, ${two(t.hour)}:${two(t.minute)} NPT';
}

final _rng = Random.secure();

/// A fresh key for each transaction attempt. Re-sending the same request with the same key
/// (for example after a network drop) can never create a second transaction.
String newIdempotencyKey() =>
    List.generate(16, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

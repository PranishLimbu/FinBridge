// Money helpers. Amounts are stored as whole paisa (1 rupee = 100 paisa) so no rounding errors
// creep into balances. Ported from backend/src/utils/money.js.

int rupeesToPaisa(num rupees) => (rupees * 100).round();
double paisaToRupees(num paisa) => paisa / 100;

/// True when [rupees] has at most two decimal places.
bool hasTwoDecimals(num rupees) => ((rupees * 100) - (rupees * 100).round()).abs() < 1e-6;

/// Nepali digit grouping: Rs. 1,00,000.00
String formatNpr(int paisa) {
  final negative = paisa < 0;
  final abs = paisa.abs();
  final rupees = (abs ~/ 100).toString();
  final decimals = (abs % 100).toString().padLeft(2, '0');
  final last3 = rupees.length > 3 ? rupees.substring(rupees.length - 3) : rupees;
  var rest = rupees.length > 3 ? rupees.substring(0, rupees.length - 3) : '';
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  final grouped = groups.isEmpty ? last3 : '${groups.join(',')},$last3';
  return '${negative ? '-' : ''}Rs. $grouped.$decimals';
}

const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve',
  'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
];
const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

String _twoDigits(int n) => n < 20 ? _ones[n] : '${_tens[n ~/ 10]}${n % 10 != 0 ? ' ${_ones[n % 10]}' : ''}';

String _threeDigits(int n) {
  final h = n ~/ 100, r = n % 100;
  return [if (h > 0) '${_ones[h]} Hundred', if (r > 0) _twoDigits(r)].join(' ');
}

/// Words in the South Asian system: crore, lakh, thousand.
String _integerToWords(int n) {
  if (n == 0) return 'Zero';
  final crore = n ~/ 10000000, lakh = (n % 10000000) ~/ 100000, thousand = (n % 100000) ~/ 1000, rest = n % 1000;
  return [
    if (crore > 0) '${_integerToWords(crore)} Crore',
    if (lakh > 0) '${_twoDigits(lakh)} Lakh',
    if (thousand > 0) '${_twoDigits(thousand)} Thousand',
    if (rest > 0) _threeDigits(rest),
  ].join(' ');
}

String amountInWords(int paisa) {
  final ps = paisa % 100;
  var words = '${_integerToWords(paisa ~/ 100)} Nepalese Rupees';
  if (ps > 0) words += ' and ${_twoDigits(ps)} Paisa';
  return '$words Only';
}

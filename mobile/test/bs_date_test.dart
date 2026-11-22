import 'package:finbridge_agent/utils/bs_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_utils/nepali_utils.dart';

List<int> ymd(DateTime d) => [d.year, d.month, d.day];

void main() {
  test('Nepali New Year dates convert both ways', () {
    // BS 1 Baisakh fell on these AD dates.
    final newYears = {2080: DateTime(2023, 4, 14), 2081: DateTime(2024, 4, 13), 2082: DateTime(2025, 4, 14)};
    newYears.forEach((bsYear, ad) {
      expect(ymd(adToBs(ad)), [bsYear, 1, 1], reason: 'AD $ad');
      expect(ymd(bsToAd(NepaliDateTime(bsYear))), ymd(ad), reason: 'BS $bsYear-01-01');
      // The day before New Year is the last day of Chaitra.
      final eve = adToBs(ad.subtract(const Duration(days: 1)));
      expect([eve.year, eve.month], [bsYear - 1, 12]);
    });
  });

  test('every day from 1918 to 2040 converts to BS and back unchanged', () {
    var d = DateTime.utc(1918, 4, 13);
    NepaliDateTime? previous;
    while (d.year < 2040) {
      final bs = adToBs(d);
      expect(ymd(bsToAd(bs)), ymd(d), reason: 'AD $d -> BS ${formatBs(bs)}');
      if (previous != null) expect(bs.isAfter(previous), isTrue, reason: 'BS dates must increase');
      previous = bs;
      d = d.add(const Duration(days: 1));
    }
  });

  test('Nepali months have their real lengths', () {
    expect(NepaliDateTime(2081, 1).totalDays, 31); // Baisakh 2081
    expect(NepaliDateTime(2081, 2).totalDays, 32); // Jestha 2081: 14 May - 14 Jun 2024
    expect(NepaliDateTime(2081, 3).totalDays, 31); // Asar 2081
  });

  test('BS dates are written as YYYY-MM-DD', () {
    expect(formatBs(NepaliDateTime(2047, 1, 5)), '2047-01-05');
  });
}

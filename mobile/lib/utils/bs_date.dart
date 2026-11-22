import 'package:nepali_utils/nepali_utils.dart';

// Bikram Sambat (BS) <-> Gregorian (AD) conversion for calendar dates (no time of day).
//
// Uses nepali_utils for the BS calendar table and for BS -> AD, which is correct. Its
// AD -> BS (`DateTime.toNepaliDateTime()`) is NOT used: on devices set to Nepal time it
// adds an extra day (a workaround for an old Dart behaviour), so 13 Apr 2024 became
// 2081-01-02 instead of 2081-01-01. adToBs() below counts days from the BS new year instead.

/// The AD date (local midnight) for a BS date.
DateTime bsToAd(NepaliDateTime bs) {
  final d = NepaliDateTime(bs.year, bs.month, bs.day).toDateTime();
  return DateTime(d.year, d.month, d.day);
}

DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// The BS date for an AD calendar date.
NepaliDateTime adToBs(DateTime ad) {
  final day = _utcDay(ad);
  // The BS year starts in mid-April, 56 or 57 years ahead of AD.
  var year = ad.year + 57;
  while (_utcDay(bsToAd(NepaliDateTime(year))).isAfter(day)) {
    year--;
  }
  var remaining = day.difference(_utcDay(bsToAd(NepaliDateTime(year)))).inDays; // exact: UTC has no DST
  var month = 1;
  while (remaining >= NepaliDateTime(year, month).totalDays) {
    remaining -= NepaliDateTime(year, month).totalDays;
    month++;
  }
  return NepaliDateTime(year, month, remaining + 1);
}

/// Today's date in BS.
NepaliDateTime todayBs() => adToBs(DateTime.now());

/// "2081-01-05"
String formatBs(NepaliDateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

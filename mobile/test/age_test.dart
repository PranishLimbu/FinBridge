import 'package:finbridge_agent/utils/age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('age goes up on the birthday itself', () {
    final dob = DateTime(2010, 11, 23);
    expect(ageInYears(dob, DateTime(2026, 11, 22)), 15);
    expect(ageInYears(dob, DateTime(2026, 11, 23)), 16);
  });

  test('someone born on 29 February turns older on 1 March', () {
    final dob = DateTime(2008, 2, 29);
    expect(ageInYears(dob, DateTime(2024, 2, 28)), 15);
    expect(ageInYears(dob, DateTime(2024, 2, 29)), 16);
    expect(ageInYears(dob, DateTime(2025, 2, 28)), 16);
  });

  test('the 16th birthday counts in Nepal time, not UTC', () {
    // 19:00 UTC on 22 Nov is already 00:45 on 23 Nov in Nepal.
    final now = DateTime.utc(2026, 11, 22, 19);
    expect(nepalToday(now), DateTime(2026, 11, 23));
    expect(oldEnoughToOnboard(DateTime(2010, 11, 23), now), isTrue);
    expect(oldEnoughToOnboard(DateTime(2010, 11, 24), now), isFalse);
  });
}

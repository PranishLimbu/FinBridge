/// Age rules for opening an account. The form and the data layer both use these, and
/// backend/firestore.rules makes the same check, so a customer under 16 cannot be created.
library;

/// Youngest age at which a customer may open an account.
const minCustomerAge = 16;

/// Today's calendar date in Nepal (UTC+5:45), whatever the device's time zone.
DateTime nepalToday([DateTime? now]) {
  final t = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 45));
  return DateTime(t.year, t.month, t.day);
}

/// Completed years between [dob] and [today], by calendar date: the age goes up on the birthday
/// itself. Someone born on 29 February turns a year older on 1 March in non-leap years.
int ageInYears(DateTime dob, DateTime today) {
  var age = today.year - dob.year;
  if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
  return age;
}

/// True when someone born on [dob] is at least [minCustomerAge] today in Nepal.
bool oldEnoughToOnboard(DateTime dob, [DateTime? now]) => ageInYears(dob, nepalToday(now)) >= minCustomerAge;

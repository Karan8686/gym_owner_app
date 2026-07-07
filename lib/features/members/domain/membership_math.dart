/// Pure business logic for membership date math.
/// Exists in domain layer to be testable and separate from UI.
class MembershipMath {
  /// Calculate the new due date when renewing or starting a membership.
  ///
  /// Rule: Extending due_date by the selected duration from the current due_date
  /// if not yet expired, or from today/startDate if already expired.
  static DateTime calculateNewDueDate({
    required DateTime currentDueDate,
    required int durationMonths,
    required DateTime baseRenewalDate, // usually today/now or custom start date
  }) {
    // If current due date is in the future (not expired), extend from current due date.
    // Otherwise (expired), start renewal from the base renewal date.
    final DateTime startFrom =
        currentDueDate.isAfter(baseRenewalDate) ? currentDueDate : baseRenewalDate;

    return addMonths(startFrom, durationMonths);
  }

  /// Helper to add a specific number of months to a DateTime, correctly handling
  /// month and year roll-over as well as end-of-month day overflows.
  static DateTime addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    while (newMonth > 12) {
      newYear += 1;
      newMonth -= 12;
    }
    while (newMonth < 1) {
      newYear -= 1;
      newMonth += 12;
    }

    int newDay = date.day;
    // Find the last day of the target month
    final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > lastDayOfTargetMonth) {
      newDay = lastDayOfTargetMonth;
    }

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}

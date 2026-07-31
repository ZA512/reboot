/// A day of the civil week using ISO-8601 numbering.
enum Weekday {
  /// Monday, ISO weekday 1.
  monday(DateTime.monday),

  /// Tuesday, ISO weekday 2.
  tuesday(DateTime.tuesday),

  /// Wednesday, ISO weekday 3.
  wednesday(DateTime.wednesday),

  /// Thursday, ISO weekday 4.
  thursday(DateTime.thursday),

  /// Friday, ISO weekday 5.
  friday(DateTime.friday),

  /// Saturday, ISO weekday 6.
  saturday(DateTime.saturday),

  /// Sunday, ISO weekday 7.
  sunday(DateTime.sunday);

  const Weekday(this.isoNumber);

  /// ISO-8601 weekday number from 1 for Monday to 7 for Sunday.
  final int isoNumber;

  /// Returns the weekday matching an ISO-8601 [number].
  static Weekday fromIsoNumber(int number) {
    return values.firstWhere(
      (weekday) => weekday.isoNumber == number,
      orElse: () => throw RangeError.range(number, 1, 7, 'number'),
    );
  }
}

/// An immutable Gregorian calendar date without a time or time zone.
///
/// Calendar arithmetic uses UTC internally only to avoid daylight-saving
/// transitions. A [LocalDate] never represents an instant.
final class LocalDate implements Comparable<LocalDate> {
  /// Creates a validated proleptic Gregorian date.
  factory LocalDate(int year, int month, int day) {
    if (year < 1 || year > 9999) {
      throw RangeError.range(year, 1, 9999, 'year');
    }
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    if (day < 1 || day > 31) {
      throw RangeError.range(day, 1, 31, 'day');
    }

    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw ArgumentError.value(
        '$year-${_twoDigits(month)}-${_twoDigits(day)}',
        'date',
        'Invalid Gregorian calendar date',
      );
    }

    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// Creates a date from the civil components visible in [dateTime].
  ///
  /// The caller must first convert an instant to the household time zone.
  factory LocalDate.fromDateTime(DateTime dateTime) {
    return LocalDate(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Four-digit Gregorian year.
  final int year;

  /// Month from 1 to 12.
  final int month;

  /// Day of month.
  final int day;

  /// ISO-8601 weekday.
  Weekday get weekday => Weekday.fromIsoNumber(_asUtcDate.weekday);

  DateTime get _asUtcDate => DateTime.utc(year, month, day);

  /// Returns a new civil date [dayCount] dates away.
  LocalDate addDays(int dayCount) {
    final result = _asUtcDate.add(Duration(days: dayCount));
    if (result.year < 1 || result.year > 9999) {
      throw RangeError('Date arithmetic exceeded the supported year range.');
    }
    return LocalDate(result.year, result.month, result.day);
  }

  /// Returns the signed number of civil dates from this date to [other].
  int daysUntil(LocalDate other) {
    return other._asUtcDate.difference(_asUtcDate).inDays;
  }

  /// Finds the closest [target] weekday on or before this date.
  LocalDate weekdayOnOrBefore(Weekday target) {
    final distance = (weekday.isoNumber - target.isoNumber) % 7;
    return addDays(-distance);
  }

  /// Finds the closest [target] weekday on or after this date.
  LocalDate weekdayOnOrAfter(Weekday target) {
    final distance = (target.isoNumber - weekday.isoNumber) % 7;
    return addDays(distance);
  }

  @override
  int compareTo(LocalDate other) {
    return _asUtcDate.compareTo(other._asUtcDate);
  }

  /// Whether this date is before [other].
  bool isBefore(LocalDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        year == other.year &&
        month == other.month &&
        day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() {
    return '${year.toString().padLeft(4, '0')}-'
        '${_twoDigits(month)}-${_twoDigits(day)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

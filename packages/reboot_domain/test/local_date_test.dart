import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LocalDate', () {
    test('validates Gregorian calendar dates', () {
      expect(LocalDate(2024, 2, 29).toString(), '2024-02-29');
      expect(() => LocalDate(2023, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsRangeError);
      expect(() => LocalDate(0, 1, 1), throwsRangeError);
    });

    test('performs civil arithmetic across leap day', () {
      final february28 = LocalDate(2024, 2, 28);

      expect(february28.addDays(1), LocalDate(2024, 2, 29));
      expect(february28.addDays(2), LocalDate(2024, 3, 1));
      expect(february28.daysUntil(LocalDate(2024, 3, 1)), 2);
    });

    test('finds anchor weekdays without using elapsed hours', () {
      final wednesday = LocalDate(2026, 4, 1);

      expect(wednesday.weekday, Weekday.wednesday);
      expect(
        wednesday.weekdayOnOrBefore(Weekday.saturday),
        LocalDate(2026, 3, 28),
      );
      expect(
        wednesday.weekdayOnOrAfter(Weekday.saturday),
        LocalDate(2026, 4, 4),
      );
    });

    test('uses the visible components of an already localized DateTime', () {
      final local = DateTime(2026, 7, 31, 23, 59);

      expect(LocalDate.fromDateTime(local), LocalDate(2026, 7, 31));
    });
  });

  group('Weekday', () {
    test('uses ISO-8601 numbering', () {
      expect(Weekday.monday.isoNumber, DateTime.monday);
      expect(Weekday.sunday.isoNumber, DateTime.sunday);
      expect(Weekday.fromIsoNumber(6), Weekday.saturday);
      expect(() => Weekday.fromIsoNumber(0), throwsRangeError);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/chore.dart';

void main() {
  group('Chore scheduling', () {
    test('uses desired interval for the next due date', () {
      final chore = Chore(
        id: 'chore1',
        title: 'Vacuum',
        description: '',
        intervalDesiredDays: 7,
        intervalMaxDays: 14,
        intervalUnit: IntervalUnits.days,
        season: 'All',
        created: DateTime(2026),
      );

      final nextDue = chore.nextDueDate(DateTime(2026, 5, 1), 'Spring');

      expect(nextDue, DateTime(2026, 5, 8));
    });

    test('season override replaces desired interval for active season', () {
      final chore = Chore(
        id: 'chore1',
        title: 'Water garden',
        description: '',
        intervalDesiredDays: 7,
        intervalMaxDays: 14,
        intervalUnit: IntervalUnits.days,
        season: 'All',
        created: DateTime(2026),
        seasonSummerOverride: 2,
      );

      final nextDue = chore.nextDueDate(DateTime(2026, 7, 1), 'Summer');

      expect(nextDue, DateTime(2026, 7, 3));
    });

    test('max due date uses the hard deadline interval', () {
      final chore = Chore(
        id: 'chore1',
        title: 'Clean filters',
        description: '',
        intervalDesiredDays: 1,
        intervalMaxDays: 2,
        intervalUnit: IntervalUnits.months,
        season: 'All',
        created: DateTime(2026),
      );

      final maxDue = chore.maxDueDate(DateTime(2026, 5, 10));

      expect(maxDue, DateTime(2026, 7, 10));
    });
  });
}

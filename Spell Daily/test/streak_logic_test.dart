import 'package:flutter_test/flutter_test.dart';
import 'package:spell_daily/models/streak_data.dart';
import 'package:spell_daily/services/streak_service.dart';
import 'package:spell_daily/utils/date_utils.dart';

void main() {
  group('StreakService.processGameCompletion', () {
    test('First game should start streak at 1', () {
      final initial = StreakData.initial();
      final result = StreakService.processGameCompletion(initial);

      expect(result.streakData.streakCount, 1);
      expect(result.streakData.hasCompletedFirstGame, isTrue);
      expect(result.streakData.lastPlayedDate, isNotNull);
      expect(result.streakUpdated, isTrue);
      expect(DateUtils.isToday(result.streakData.lastPlayedDate), isTrue);
    });

    test('Consecutive day should increment streak', () {
      final today = DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));

      final first = StreakService.processGameCompletion(
        StreakData.initial(),
        referenceDate: yesterday,
      ).streakData;

      final result = StreakService.processGameCompletion(
        first,
        referenceDate: today,
      );

      expect(result.streakData.streakCount, 2);
      expect(result.streakUpdated, isTrue);
      expect(result.streakData.lastPlayedDate, today);
    });

    test('Same day should not increment streak', () {
      final today = DateUtils.getToday();
      final first = StreakService.processGameCompletion(
        StreakData.initial(),
        referenceDate: today,
      ).streakData;

      final result = StreakService.processGameCompletion(
        first,
        referenceDate: today,
      );

      expect(result.streakData.streakCount, 1);
      expect(result.streakUpdated, isFalse);
    });

    test('Gap in days should reset streak to 1', () {
      final today = DateUtils.getToday();
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      final existing = StreakData.initial().copyWith(
        streakCount: 5,
        lastPlayedDate: fourDaysAgo,
        hasCompletedFirstGame: true,
      );

      final result = StreakService.processGameCompletion(
        existing,
        referenceDate: today,
      );

      expect(result.streakData.streakCount, 1);
      expect(result.streakUpdated, isTrue);
      expect(result.streakData.lastPlayedDate, today);
    });

    test('Week progress should update for current day', () {
      final today = DateUtils.getToday();
      final result = StreakService.processGameCompletion(
        StreakData.initial(),
        referenceDate: today,
      );

      final dayIndex = DateUtils.getDayIndex(today);
      if (dayIndex >= 0 && dayIndex < 7) {
        expect(result.streakData.weekProgress[dayIndex], isTrue);
      }
    });
  });

  group('StreakService helpers', () {
    test('resetWeekProgressIfNeeded clears progress when week changed', () {
      final lastWeek = DateUtils.getToday().subtract(const Duration(days: 7));
      final data = StreakData.initial().copyWith(
        lastPlayedDate: lastWeek,
        weekProgress: List<bool>.filled(7, true),
      );

      final updated = StreakService.resetWeekProgressIfNeeded(data);
      expect(updated.weekProgress.where((b) => b).length, 0);
    });

    test('hasActivityInPast7Days detects recent activity', () {
      final today = DateUtils.getToday();
      final recent = StreakData.initial().copyWith(lastPlayedDate: today);
      final old = StreakData.initial().copyWith(
        lastPlayedDate: today.subtract(const Duration(days: 10)),
        hasCompletedFirstGame: true,
      );

      expect(StreakService.hasActivityInPast7Days(recent), isTrue);
      expect(StreakService.hasActivityInPast7Days(old), isFalse);
    });

    test('determineWidgetState maps streak data to widget state', () {
      final today = DateTime.now();
      final tenMinutesAgo = today.subtract(const Duration(minutes: 10));

      expect(
        StreakService.determineWidgetState(StreakData.initial()),
        'state1',
      );

      expect(
        StreakService.determineWidgetState(
          StreakData.initial().copyWith(
            hasCompletedFirstGame: true,
            streakCount: 3,
            lastPlayedDate: today,
          ),
        ),
        'state2',
      );

      expect(
        StreakService.determineWidgetState(
          StreakData.initial().copyWith(
            hasCompletedFirstGame: true,
            streakCount: 3,
            lastPlayedDate: tenMinutesAgo,
          ),
        ),
        'state3',
      );

      expect(
        StreakService.determineWidgetState(
          StreakData.initial().copyWith(
            hasCompletedFirstGame: true,
            streakCount: 3,
            lastPlayedDate: today.subtract(const Duration(days: 2)),
          ),
        ),
        'state4',
      );
    });
  });

  group('Date Utils', () {
    test('getDayIndex should return correct index for Monday', () {
      final monday = DateUtils.getMondayOfWeek(DateUtils.getToday());
      final dayIndex = DateUtils.getDayIndex(monday);
      expect(dayIndex, 0);
      expect(DateUtils.getDayAbbreviation(dayIndex), 'MON');
    });

    test('getDayAbbreviation should return correct abbreviations', () {
      expect(DateUtils.getDayAbbreviation(0), 'MON');
      expect(DateUtils.getDayAbbreviation(1), 'TUE');
      expect(DateUtils.getDayAbbreviation(2), 'WED');
      expect(DateUtils.getDayAbbreviation(3), 'THU');
      expect(DateUtils.getDayAbbreviation(4), 'FRI');
      expect(DateUtils.getDayAbbreviation(5), 'SAT');
      expect(DateUtils.getDayAbbreviation(6), 'SUN');
    });

    test('isInCurrentWeek should return true for today', () {
      final today = DateUtils.getToday();
      expect(DateUtils.isInCurrentWeek(today), isTrue);
    });
  });
}

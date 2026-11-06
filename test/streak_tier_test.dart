import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/domain/today_logic.dart';

void main() {
  group('streakTier', () {
    test('0 天與負數為 0 級', () {
      expect(streakTier(0), 0);
      expect(streakTier(-3), 0);
    });

    test('1~6 天為 1 級', () {
      expect(streakTier(1), 1);
      expect(streakTier(6), 1);
    });

    test('7~29 天為 2 級', () {
      expect(streakTier(7), 2);
      expect(streakTier(29), 2);
    });

    test('30~99 天為 3 級', () {
      expect(streakTier(30), 3);
      expect(streakTier(99), 3);
    });

    test('100 天以上為 4 級', () {
      expect(streakTier(100), 4);
      expect(streakTier(365), 4);
    });

    test('等級邊界與 kMilestones 一致', () {
      for (final m in kMilestones) {
        expect(streakTier(m), greaterThan(streakTier(m - 1)));
      }
    });
  });
}

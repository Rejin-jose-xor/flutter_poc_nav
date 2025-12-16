import 'package:flutter_riverpod/flutter_riverpod.dart';

const int maxPastWeeks = 4; // ~30 days

class WeekNavigatorNotifier extends Notifier<int> {
  @override
  int build() => 0; // 0 = current week

  bool get canGoNext => state > 0;
  bool get canGoPrevious => state < maxPastWeeks;

  void goPrevious() {
    if (!canGoPrevious) return;
    state = state + 1;
  }

  void goNext() {
    if (!canGoNext) return;
    state = state - 1;
  }

  void reset() => state = 0;
}

final currentWeekProvider =
    NotifierProvider<WeekNavigatorNotifier, int>(
  WeekNavigatorNotifier.new,
);

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/pomodoro/application/menu_bar_pomodoro_presenter.dart';
import 'package:flow_tomato/features/pomodoro/domain/pomodoro_state.dart';

void main() {
  group('MenuBarPomodoroSnapshot', () {
    test('formats a running focus session with progress bars', () {
      final snapshot = MenuBarPomodoroSnapshot.fromState(
        const PomodoroState(
          stage: PomodoroStage.focus,
          status: PomodoroStatus.running,
          remaining: Duration(minutes: 18, seconds: 42),
          total: Duration(minutes: 25),
          taskTitle: 'Draft menu bar support',
        ),
      );

      expect(snapshot.statusLabel, 'Focusing');
      expect(snapshot.timeLabel, '18:42');
      expect(snapshot.detailLabel, 'Draft menu bar support');
      expect(snapshot.progress, closeTo(0.252, 0.001));
      expect(snapshot.menuBarTitle, '18:42 [##--------]');
      expect(snapshot.canPause, isTrue);
      expect(snapshot.canResume, isFalse);
      expect(snapshot.canReset, isTrue);
    });

    test('formats paused and idle sessions with matching actions', () {
      final paused = MenuBarPomodoroSnapshot.fromState(
        const PomodoroState(
          stage: PomodoroStage.focus,
          status: PomodoroStatus.paused,
          remaining: Duration(minutes: 7),
          total: Duration(minutes: 25),
        ),
      );
      final idle = MenuBarPomodoroSnapshot.fromState(
        const PomodoroState(
          stage: PomodoroStage.focus,
          status: PomodoroStatus.idle,
          remaining: Duration(minutes: 25),
          total: Duration(minutes: 25),
        ),
      );

      expect(paused.statusLabel, 'Paused');
      expect(paused.menuBarTitle, 'Paused 07:00');
      expect(paused.canPause, isFalse);
      expect(paused.canResume, isTrue);
      expect(paused.canReset, isTrue);

      expect(idle.statusLabel, 'Ready');
      expect(idle.menuBarTitle, 'FlowTomato');
      expect(idle.canPause, isFalse);
      expect(idle.canResume, isFalse);
      expect(idle.canReset, isFalse);
    });
  });
}

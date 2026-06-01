import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/pomodoro/application/pomodoro_controller.dart';
import 'package:flow_tomato/features/pomodoro/domain/pomodoro_state.dart';

void main() {
  group('PomodoroController', () {
    test('start, pause, resume, and reset update timer state', () {
      final controller = PomodoroController(
        focusDuration: const Duration(seconds: 3),
      );

      controller.startFocus(taskId: 'task-1', taskTitle: 'Deep work');
      expect(controller.state.status, PomodoroStatus.running);
      expect(controller.state.taskId, 'task-1');

      controller.tick(const Duration(seconds: 1));
      expect(controller.state.remaining, const Duration(seconds: 2));

      controller.pause();
      controller.tick(const Duration(seconds: 1));
      expect(controller.state.remaining, const Duration(seconds: 2));

      controller.resume();
      controller.tick(const Duration(seconds: 1));
      expect(controller.state.remaining, const Duration(seconds: 1));

      controller.reset();
      expect(controller.state.status, PomodoroStatus.idle);
      expect(controller.state.remaining, const Duration(seconds: 3));
    });

    test('finishing focus creates a completed session snapshot', () {
      final controller = PomodoroController(
        focusDuration: const Duration(seconds: 2),
      );

      controller.startFocus(
        taskId: 'task-1',
        taskTitle: 'Draft implementation',
      );
      controller.tick(const Duration(seconds: 2));

      expect(controller.state.status, PomodoroStatus.completed);
      expect(controller.completedSessions, hasLength(1));
      expect(controller.completedSessions.single.taskId, 'task-1');
      expect(controller.completedSessions.single.stage, PomodoroStage.focus);
      expect(
        controller.completedSessions.single.actualDuration,
        const Duration(seconds: 2),
      );
    });
  });
}

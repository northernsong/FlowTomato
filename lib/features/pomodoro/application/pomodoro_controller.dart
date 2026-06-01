import 'package:flutter/foundation.dart';

import '../domain/pomodoro_state.dart';

class PomodoroController extends ChangeNotifier {
  PomodoroController({
    this.focusDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
  }) : state = PomodoroState(
         stage: PomodoroStage.focus,
         status: PomodoroStatus.idle,
         remaining: focusDuration,
         total: focusDuration,
       );

  final Duration focusDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;

  PomodoroState state;
  DateTime? _startedAt;
  final List<PomodoroSession> _completedSessions = [];

  List<PomodoroSession> get completedSessions =>
      List.unmodifiable(_completedSessions);

  void startFocus({String? taskId, String? taskTitle}) {
    _start(PomodoroStage.focus, focusDuration, taskId, taskTitle);
  }

  void startShortBreak() {
    _start(PomodoroStage.shortBreak, shortBreakDuration, null, null);
  }

  void pause() {
    if (state.status != PomodoroStatus.running) {
      return;
    }
    state = state.copyWith(status: PomodoroStatus.paused);
    notifyListeners();
  }

  void resume() {
    if (state.status != PomodoroStatus.paused) {
      return;
    }
    state = state.copyWith(status: PomodoroStatus.running);
    notifyListeners();
  }

  void reset() {
    state = PomodoroState(
      stage: state.stage,
      status: PomodoroStatus.idle,
      remaining: state.total,
      total: state.total,
    );
    _startedAt = null;
    notifyListeners();
  }

  void tick(Duration elapsed) {
    if (state.status != PomodoroStatus.running) {
      return;
    }
    final remaining = state.remaining - elapsed;
    if (remaining > Duration.zero) {
      state = state.copyWith(remaining: remaining);
    } else {
      _complete();
    }
    notifyListeners();
  }

  void _start(
    PomodoroStage stage,
    Duration duration,
    String? taskId,
    String? taskTitle,
  ) {
    _startedAt = DateTime.now();
    state = PomodoroState(
      stage: stage,
      status: PomodoroStatus.running,
      remaining: duration,
      total: duration,
      taskId: taskId,
      taskTitle: taskTitle,
    );
    notifyListeners();
  }

  void _complete() {
    final endedAt = DateTime.now();
    _completedSessions.add(
      PomodoroSession(
        taskId: state.taskId,
        taskTitle: state.taskTitle,
        stage: state.stage,
        plannedDuration: state.total,
        actualDuration: state.total,
        startedAt: _startedAt ?? endedAt.subtract(state.total),
        endedAt: endedAt,
      ),
    );
    state = state.copyWith(
      status: PomodoroStatus.completed,
      remaining: Duration.zero,
    );
  }
}

enum PomodoroStage { focus, shortBreak, longBreak }

enum PomodoroStatus { idle, running, paused, completed }

class PomodoroState {
  const PomodoroState({
    required this.stage,
    required this.status,
    required this.remaining,
    required this.total,
    this.taskId,
    this.taskTitle,
  });

  final PomodoroStage stage;
  final PomodoroStatus status;
  final Duration remaining;
  final Duration total;
  final String? taskId;
  final String? taskTitle;

  PomodoroState copyWith({
    PomodoroStage? stage,
    PomodoroStatus? status,
    Duration? remaining,
    Duration? total,
    String? taskId,
    String? taskTitle,
  }) {
    return PomodoroState(
      stage: stage ?? this.stage,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
    );
  }
}

class PomodoroSession {
  const PomodoroSession({
    required this.taskId,
    required this.taskTitle,
    required this.stage,
    required this.plannedDuration,
    required this.actualDuration,
    required this.startedAt,
    required this.endedAt,
  });

  final String? taskId;
  final String? taskTitle;
  final PomodoroStage stage;
  final Duration plannedDuration;
  final Duration actualDuration;
  final DateTime startedAt;
  final DateTime endedAt;
}

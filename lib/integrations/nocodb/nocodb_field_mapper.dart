import '../../features/pomodoro/domain/pomodoro_state.dart';
import '../../features/tasks/domain/task.dart';

class NocoDBFieldMapper {
  static Map<String, Object?> taskFields(FlowTask task) {
    return {
      'Local ID': task.id,
      'Title': task.title,
      'Note': task.note ?? '',
      'Status': task.status.name,
      'Priority': task.priority.name,
      'Planned Pomodoros': task.plannedPomodoros,
      'Completed Pomodoros': task.completedPomodoros,
      'Sort Order': task.sortOrder,
      'Date': _date(task.date),
      'Created At': _dateTime(task.createdAt),
      'Updated At': _dateTime(task.updatedAt),
      if (task.completedAt != null)
        'Completed At': _dateTime(task.completedAt!),
      'Sync Status': task.syncStatus.name,
    };
  }

  static Map<String, Object?> pomodoroFields(
    PomodoroSession session, {
    required String localId,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    return {
      'Local ID': localId,
      'Task ID': session.taskId ?? '',
      'Task Title': session.taskTitle ?? '',
      'Type': session.stage.name,
      'Duration Minutes': session.plannedDuration.inMinutes,
      'Actual Minutes': session.actualDuration.inMinutes,
      'Status': 'completed',
      'Started At': _dateTime(session.startedAt),
      'Ended At': _dateTime(session.endedAt),
      'Date': _date(session.startedAt),
      'Sync Status': syncStatus.name,
    };
  }

  static String formatDate(DateTime value) => _date(value);

  static String _date(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    return utc.toIso8601String().substring(0, 10);
  }

  static String _dateTime(DateTime value) => value.toUtc().toIso8601String();
}

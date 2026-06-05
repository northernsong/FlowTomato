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

  static FlowTask taskFromRecord({
    required String recordId,
    required Map<String, Object?> fields,
  }) {
    final createdAt = _parseDateTime(fields['Created At']) ?? DateTime.now();
    final updatedAt = _parseDateTime(fields['Updated At']) ?? createdAt;
    final date =
        _parseDate(fields['Date']) ??
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    return FlowTask(
      id: _string(fields['Local ID']).isNotEmpty
          ? _string(fields['Local ID'])
          : 'nocodb-$recordId',
      title: _string(fields['Title']).isNotEmpty
          ? _string(fields['Title'])
          : 'Untitled task',
      note: _emptyToNull(_string(fields['Note'])),
      status:
          _enumByName(TaskStatus.values, _string(fields['Status'])) ??
          TaskStatus.todo,
      priority:
          _enumByName(TaskPriority.values, _string(fields['Priority'])) ??
          TaskPriority.medium,
      plannedPomodoros: _int(fields['Planned Pomodoros'], fallback: 1),
      completedPomodoros: _int(fields['Completed Pomodoros']),
      sortOrder: _int(fields['Sort Order']),
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: _parseDateTime(fields['Completed At']),
      syncStatus:
          _enumByName(SyncStatus.values, _string(fields['Sync Status'])) ??
          SyncStatus.synced,
    );
  }

  static String _date(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    return utc.toIso8601String().substring(0, 10);
  }

  static String _dateTime(DateTime value) => value.toUtc().toIso8601String();

  static String _string(Object? value) => value == null ? '' : '$value';

  static String? _emptyToNull(String value) => value.isEmpty ? null : value;

  static int _int(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_string(value)) ?? fallback;
  }

  static DateTime? _parseDate(Object? value) {
    final text = _string(value);
    if (text.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseDateTime(Object? value) {
    final text = _string(value);
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}

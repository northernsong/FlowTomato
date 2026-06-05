import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/pomodoro/domain/pomodoro_state.dart';
import 'package:flow_tomato/features/tasks/domain/task.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_field_mapper.dart';

void main() {
  group('NocoDBFieldMapper', () {
    test('taskFields maps FlowTask values to NocoDB field names', () {
      final task = FlowTask(
        id: 'task-1',
        title: 'Write sync',
        note: 'PAT first',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        plannedPomodoros: 3,
        completedPomodoros: 1,
        sortOrder: 7,
        date: DateTime.utc(2026, 6, 1),
        createdAt: DateTime.utc(2026, 6, 1, 8, 30),
        updatedAt: DateTime.utc(2026, 6, 1, 9),
        syncStatus: SyncStatus.pending,
      );

      final fields = NocoDBFieldMapper.taskFields(task);

      expect(fields['Local ID'], 'task-1');
      expect(fields['Title'], 'Write sync');
      expect(fields['Note'], 'PAT first');
      expect(fields['Status'], 'todo');
      expect(fields['Priority'], 'high');
      expect(fields['Planned Pomodoros'], 3);
      expect(fields['Completed Pomodoros'], 1);
      expect(fields['Sort Order'], 7);
      expect(fields['Date'], '2026-06-01');
      expect(fields['Created At'], '2026-06-01T08:30:00.000Z');
      expect(fields['Updated At'], '2026-06-01T09:00:00.000Z');
      expect(fields['Sync Status'], 'pending');
    });

    test('pomodoroFields maps completed session values', () {
      final session = PomodoroSession(
        taskId: 'task-1',
        taskTitle: 'Write sync',
        stage: PomodoroStage.focus,
        plannedDuration: Duration(minutes: 25),
        actualDuration: Duration(minutes: 24),
        startedAt: DateTime.utc(2026, 6, 1, 8),
        endedAt: DateTime.utc(2026, 6, 1, 8, 24),
      );

      final fields = NocoDBFieldMapper.pomodoroFields(
        session,
        localId: 'pomo-1',
        syncStatus: SyncStatus.pending,
      );

      expect(fields['Local ID'], 'pomo-1');
      expect(fields['Task ID'], 'task-1');
      expect(fields['Task Title'], 'Write sync');
      expect(fields['Type'], 'focus');
      expect(fields['Duration Minutes'], 25);
      expect(fields['Actual Minutes'], 24);
      expect(fields['Status'], 'completed');
      expect(fields['Started At'], '2026-06-01T08:00:00.000Z');
      expect(fields['Ended At'], '2026-06-01T08:24:00.000Z');
      expect(fields['Date'], '2026-06-01');
      expect(fields['Sync Status'], 'pending');
    });

    test('taskFromRecord maps NocoDB record fields to FlowTask values', () {
      final task = NocoDBFieldMapper.taskFromRecord(
        recordId: '42',
        fields: {
          'Local ID': 'task-remote-1',
          'Title': 'Loaded from NocoDB',
          'Note': 'Remote note',
          'Status': 'now',
          'Priority': 'high',
          'Planned Pomodoros': 4,
          'Completed Pomodoros': 2,
          'Sort Order': 3,
          'Date': '2026-06-05',
          'Created At': '2026-06-05T01:00:00.000Z',
          'Updated At': '2026-06-05T02:00:00.000Z',
          'Completed At': null,
          'Sync Status': 'synced',
        },
      );

      expect(task.id, 'task-remote-1');
      expect(task.title, 'Loaded from NocoDB');
      expect(task.note, 'Remote note');
      expect(task.status, TaskStatus.now);
      expect(task.priority, TaskPriority.high);
      expect(task.plannedPomodoros, 4);
      expect(task.completedPomodoros, 2);
      expect(task.sortOrder, 3);
      expect(task.date, DateTime.utc(2026, 6, 5));
      expect(task.createdAt, DateTime.utc(2026, 6, 5, 1));
      expect(task.updatedAt, DateTime.utc(2026, 6, 5, 2));
      expect(task.syncStatus, SyncStatus.synced);
    });
  });
}

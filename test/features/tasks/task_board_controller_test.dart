import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/tasks/application/task_board_controller.dart';
import 'package:flow_tomato/features/tasks/application/task_sync_service.dart';
import 'package:flow_tomato/features/tasks/domain/task.dart';

void main() {
  group('TaskBoardController', () {
    test('starts with no local fake tasks by default', () {
      final controller = TaskBoardController();

      expect(controller.tasks, isEmpty);
      expect(controller.todoTasks, isEmpty);
      expect(controller.nowTask, isNull);
    });

    test('setting a task as now moves any existing now task back to todo', () {
      final controller = TaskBoardController(
        initialTasks: [
          FlowTask.create(title: 'Write PRD').copyWith(status: TaskStatus.now),
          FlowTask.create(title: 'Build Flutter UI'),
        ],
      );

      final nextNowId = controller.tasks
          .firstWhere((task) => task.title == 'Build Flutter UI')
          .id;

      controller.setNow(nextNowId);

      expect(controller.nowTask?.title, 'Build Flutter UI');
      expect(
        controller.tasks.firstWhere((task) => task.title == 'Write PRD').status,
        TaskStatus.todo,
      );
    });

    test('completing the now task moves it to done and clears now', () {
      final task = FlowTask.create(title: 'Ship MVP');
      final controller = TaskBoardController(initialTasks: [task]);

      controller.setNow(task.id);
      controller.completeTask(task.id);

      expect(controller.nowTask, isNull);
      expect(controller.doneTasks.single.title, 'Ship MVP');
      expect(controller.todoTasks, isEmpty);
    });

    test('recording a focus session increments the task pomodoro count', () {
      final task = FlowTask.create(title: 'Design timer');
      final controller = TaskBoardController(initialTasks: [task]);

      controller.recordCompletedPomodoro(task.id);

      expect(controller.tasks.single.completedPomodoros, 1);
    });

    test('loads today tasks from the configured sync service', () async {
      final remoteTask = FlowTask.create(
        title: 'Remote task',
      ).copyWith(id: 'remote-local-id', syncStatus: SyncStatus.synced);
      final sync = _FakeTaskSyncService(
        loadedTasks: [SyncedTask(recordId: '17', task: remoteTask)],
      );
      final controller = TaskBoardController(syncService: sync);

      await controller.loadTodayTasks(date: DateTime.utc(2026, 6, 5));

      expect(controller.tasks.single.title, 'Remote task');
      expect(controller.tasks.single.syncStatus, SyncStatus.synced);
      expect(sync.loadedDate, DateTime.utc(2026, 6, 5));
    });

    test('creating a task syncs it to the remote task table', () async {
      final sync = _FakeTaskSyncService(createdRecordId: '23');
      final controller = TaskBoardController(syncService: sync);

      final task = controller.addTask('Write remote task');
      await controller.waitForPendingSyncs();

      expect(sync.createdTasks.single.title, 'Write remote task');
      expect(sync.createdTasks.single.syncStatus, SyncStatus.synced);
      expect(controller.tasks.single.id, task.id);
      expect(controller.tasks.single.syncStatus, SyncStatus.synced);
    });

    test('failed create keeps the local task and marks sync failed', () async {
      final sync = _FakeTaskSyncService(createError: StateError('offline'));
      final controller = TaskBoardController(syncService: sync);

      controller.addTask('Keep local task');
      await controller.waitForPendingSyncs();

      expect(controller.tasks.single.title, 'Keep local task');
      expect(controller.tasks.single.syncStatus, SyncStatus.failed);
    });
  });
}

class _FakeTaskSyncService implements TaskSyncService {
  _FakeTaskSyncService({
    this.loadedTasks = const [],
    this.createdRecordId = 'record-1',
    this.createError,
  });

  final List<SyncedTask> loadedTasks;
  final String createdRecordId;
  final Object? createError;
  final List<FlowTask> createdTasks = [];
  DateTime? loadedDate;

  @override
  Future<List<SyncedTask>> loadTodayTasks(DateTime date) async {
    loadedDate = date;
    return loadedTasks;
  }

  @override
  Future<String> createTask(FlowTask task) async {
    createdTasks.add(task);
    final error = createError;
    if (error != null) {
      throw error;
    }
    return createdRecordId;
  }

  @override
  Future<void> updateTask({required String recordId, required FlowTask task}) {
    return Future<void>.value();
  }

  @override
  Future<void> deleteTask({required String recordId}) {
    return Future<void>.value();
  }
}

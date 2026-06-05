import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/task.dart';
import 'task_sync_service.dart';

class TaskBoardController extends ChangeNotifier {
  TaskBoardController({
    List<FlowTask>? initialTasks,
    TaskSyncService? syncService,
    DateTime Function()? clock,
  }) : _tasks = List<FlowTask>.from(initialTasks ?? const []),
       _syncService = syncService,
       _clock = clock ?? DateTime.now;

  final List<FlowTask> _tasks;
  final DateTime Function() _clock;
  final Map<String, String> _remoteRecordIdsByTaskId = {};
  final List<Future<void>> _pendingSyncs = [];
  TaskSyncService? _syncService;

  List<FlowTask> get tasks => List.unmodifiable(_tasks);

  List<FlowTask> get todoTasks =>
      _tasks.where((task) => task.status == TaskStatus.todo).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<FlowTask> get doneTasks =>
      _tasks.where((task) => task.status == TaskStatus.done).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  FlowTask? get nowTask {
    for (final task in _tasks) {
      if (task.status == TaskStatus.now) {
        return task;
      }
    }
    return null;
  }

  int get completedPomodoroCount {
    return _tasks.fold(0, (sum, task) => sum + task.completedPomodoros);
  }

  int get completedTaskCount => doneTasks.length;

  int get focusMinutes => completedPomodoroCount * 25;

  void setSyncService(TaskSyncService syncService) {
    _syncService = syncService;
  }

  Future<void> loadTodayTasks({DateTime? date}) async {
    final syncService = _syncService;
    if (syncService == null) {
      return;
    }
    final today = date ?? _today(_clock());
    final syncedTasks = await syncService.loadTodayTasks(today);
    _tasks
      ..clear()
      ..addAll(
        syncedTasks.map(
          (syncedTask) => syncedTask.task.copyWith(
            date: _today(syncedTask.task.date),
            syncStatus: SyncStatus.synced,
          ),
        ),
      );
    _remoteRecordIdsByTaskId
      ..clear()
      ..addEntries(
        syncedTasks.map(
          (syncedTask) => MapEntry(syncedTask.task.id, syncedTask.recordId),
        ),
      );
    notifyListeners();
  }

  Future<void> waitForPendingSyncs() async {
    while (_pendingSyncs.isNotEmpty) {
      await Future.wait(List<Future<void>>.from(_pendingSyncs));
    }
  }

  FlowTask addTask(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }
    final syncService = _syncService;
    final task = FlowTask.create(title: trimmedTitle, plannedPomodoros: 1)
        .copyWith(
          sortOrder: _tasks.length,
          syncStatus: syncService == null
              ? SyncStatus.localOnly
              : SyncStatus.pending,
        );
    _tasks.add(task);
    notifyListeners();
    if (syncService != null) {
      _trackSync(_syncCreatedTask(syncService, task.id));
    }
    return task;
  }

  void setNow(String taskId) {
    final now = DateTime.now();
    final changedTaskIds = <String>[];
    for (var index = 0; index < _tasks.length; index += 1) {
      final task = _tasks[index];
      if (task.id == taskId) {
        _tasks[index] = task.copyWith(
          status: TaskStatus.now,
          updatedAt: now,
          syncStatus: _nextMutationSyncStatus(task),
        );
        changedTaskIds.add(task.id);
      } else if (task.status == TaskStatus.now) {
        _tasks[index] = task.copyWith(
          status: TaskStatus.todo,
          updatedAt: now,
          syncStatus: _nextMutationSyncStatus(task),
        );
        changedTaskIds.add(task.id);
      }
    }
    notifyListeners();
    for (final changedTaskId in changedTaskIds) {
      _syncUpdatedTask(changedTaskId);
    }
  }

  void completeTask(String taskId) {
    _replaceTask(
      taskId,
      (task) => task.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void restoreTask(String taskId) {
    _replaceTask(
      taskId,
      (task) =>
          task.copyWith(status: TaskStatus.todo, updatedAt: DateTime.now()),
    );
  }

  void deleteTask(String taskId) {
    final recordId = _remoteRecordIdsByTaskId.remove(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
    final syncService = _syncService;
    if (syncService != null && recordId != null) {
      _trackSync(_deleteRemoteTask(syncService, recordId));
    }
  }

  void recordCompletedPomodoro(String taskId) {
    _replaceTask(
      taskId,
      (task) => task.copyWith(
        completedPomodoros: task.completedPomodoros + 1,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _replaceTask(String taskId, FlowTask Function(FlowTask task) update) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    _tasks[index] = update(
      _tasks[index],
    ).copyWith(syncStatus: _nextMutationSyncStatus(_tasks[index]));
    notifyListeners();
    _syncUpdatedTask(taskId);
  }

  Future<void> _syncCreatedTask(
    TaskSyncService syncService,
    String taskId,
  ) async {
    final task = _taskById(taskId);
    if (task == null) {
      return;
    }
    try {
      final recordId = await syncService.createTask(
        task.copyWith(syncStatus: SyncStatus.synced),
      );
      _remoteRecordIdsByTaskId[taskId] = recordId;
      _replaceTaskWithoutSync(taskId, (task) {
        return task.copyWith(syncStatus: SyncStatus.synced);
      });
    } catch (_) {
      _replaceTaskWithoutSync(taskId, (task) {
        return task.copyWith(syncStatus: SyncStatus.failed);
      });
    }
  }

  void _syncUpdatedTask(String taskId) {
    final syncService = _syncService;
    final recordId = _remoteRecordIdsByTaskId[taskId];
    final task = _taskById(taskId);
    if (syncService == null || recordId == null || task == null) {
      return;
    }
    _trackSync(_syncExistingTask(syncService, recordId, taskId));
  }

  Future<void> _syncExistingTask(
    TaskSyncService syncService,
    String recordId,
    String taskId,
  ) async {
    final task = _taskById(taskId);
    if (task == null) {
      return;
    }
    try {
      await syncService.updateTask(
        recordId: recordId,
        task: task.copyWith(syncStatus: SyncStatus.synced),
      );
      _replaceTaskWithoutSync(taskId, (task) {
        return task.copyWith(syncStatus: SyncStatus.synced);
      });
    } catch (_) {
      _replaceTaskWithoutSync(taskId, (task) {
        return task.copyWith(syncStatus: SyncStatus.failed);
      });
    }
  }

  Future<void> _deleteRemoteTask(
    TaskSyncService syncService,
    String recordId,
  ) async {
    try {
      await syncService.deleteTask(recordId: recordId);
    } catch (_) {
      // Deletion has already happened locally; a later sync queue can reconcile.
    }
  }

  void _trackSync(Future<void> sync) {
    _pendingSyncs.add(sync);
    unawaited(sync.whenComplete(() => _pendingSyncs.remove(sync)));
  }

  FlowTask? _taskById(String taskId) {
    for (final task in _tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  void _replaceTaskWithoutSync(
    String taskId,
    FlowTask Function(FlowTask task) update,
  ) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    _tasks[index] = update(_tasks[index]);
    notifyListeners();
  }

  SyncStatus _nextMutationSyncStatus(FlowTask task) {
    if (_syncService == null) {
      return task.syncStatus;
    }
    return _remoteRecordIdsByTaskId.containsKey(task.id)
        ? SyncStatus.pending
        : task.syncStatus;
  }

  DateTime _today(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

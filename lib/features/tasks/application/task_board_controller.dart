import 'package:flutter/foundation.dart';

import '../domain/task.dart';

class TaskBoardController extends ChangeNotifier {
  TaskBoardController({List<FlowTask>? initialTasks})
    : _tasks = List<FlowTask>.from(initialTasks ?? _defaultTasks());

  final List<FlowTask> _tasks;

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

  FlowTask addTask(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }
    final task = FlowTask.create(
      title: trimmedTitle,
      plannedPomodoros: 1,
    ).copyWith(sortOrder: _tasks.length);
    _tasks.add(task);
    notifyListeners();
    return task;
  }

  void setNow(String taskId) {
    final now = DateTime.now();
    for (var index = 0; index < _tasks.length; index += 1) {
      final task = _tasks[index];
      if (task.id == taskId) {
        _tasks[index] = task.copyWith(status: TaskStatus.now, updatedAt: now);
      } else if (task.status == TaskStatus.now) {
        _tasks[index] = task.copyWith(status: TaskStatus.todo, updatedAt: now);
      }
    }
    notifyListeners();
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
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
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
    _tasks[index] = update(_tasks[index]);
    notifyListeners();
  }

  static List<FlowTask> _defaultTasks() {
    return [
      FlowTask.create(
        title: 'Implement Flutter shell',
        note: 'Build the first Now / Todo / Done workbench.',
        priority: TaskPriority.high,
        plannedPomodoros: 2,
      ),
      FlowTask.create(
        title: 'Design Pomodoro state',
        note: 'Keep timer rules testable outside widgets.',
        priority: TaskPriority.medium,
        plannedPomodoros: 1,
      ),
      FlowTask.create(
        title: 'Review Feishu Base fields',
        note: 'Prepare for the sync phase after local UI lands.',
        priority: TaskPriority.low,
        plannedPomodoros: 1,
      ),
    ];
  }
}

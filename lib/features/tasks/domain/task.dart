enum TaskStatus { todo, now, done }

enum TaskPriority { high, medium, low }

enum SyncStatus { localOnly, pending, synced, failed }

class FlowTask {
  FlowTask({
    required this.id,
    required this.title,
    this.note,
    required this.status,
    required this.priority,
    required this.plannedPomodoros,
    required this.completedPomodoros,
    required this.sortOrder,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.syncStatus,
  });

  factory FlowTask.create({
    required String title,
    String? note,
    TaskPriority priority = TaskPriority.medium,
    int plannedPomodoros = 1,
  }) {
    final now = DateTime.now();
    return FlowTask(
      id: 'task-${now.microsecondsSinceEpoch}-${_nextId++}',
      title: title,
      note: note,
      status: TaskStatus.todo,
      priority: priority,
      plannedPomodoros: plannedPomodoros,
      completedPomodoros: 0,
      sortOrder: _nextId,
      date: DateTime(now.year, now.month, now.day),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.localOnly,
    );
  }

  static int _nextId = 0;

  final String id;
  final String title;
  final String? note;
  final TaskStatus status;
  final TaskPriority priority;
  final int plannedPomodoros;
  final int completedPomodoros;
  final int sortOrder;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final SyncStatus syncStatus;

  FlowTask copyWith({
    String? id,
    String? title,
    String? note,
    TaskStatus? status,
    TaskPriority? priority,
    int? plannedPomodoros,
    int? completedPomodoros,
    int? sortOrder,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    SyncStatus? syncStatus,
  }) {
    return FlowTask(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      plannedPomodoros: plannedPomodoros ?? this.plannedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      sortOrder: sortOrder ?? this.sortOrder,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

import '../domain/task.dart';

class SyncedTask {
  const SyncedTask({required this.recordId, required this.task});

  final String recordId;
  final FlowTask task;
}

abstract class TaskSyncService {
  Future<List<SyncedTask>> loadTodayTasks(DateTime date);

  Future<String> createTask(FlowTask task);

  Future<void> updateTask({required String recordId, required FlowTask task});

  Future<void> deleteTask({required String recordId});
}

import '../../features/tasks/domain/task.dart';
import 'nocodb_base_api_client.dart';
import 'nocodb_field_mapper.dart';
import 'nocodb_models.dart';

class NocoDBSyncService {
  const NocoDBSyncService({required this.apiClient, required this.workspace});

  final NocoDBApiClient apiClient;
  final NocoDBWorkspaceConfig workspace;

  Future<List<NocoDBRecord>> searchTodayTasks({required DateTime date}) {
    final formattedDate = NocoDBFieldMapper.formatDate(date);
    return apiClient.listRecords(
      apiToken: workspace.apiToken,
      tableId: workspace.tasksTableId,
      where: '(Date,eq,$formattedDate)',
    );
  }

  Future<String> createTask({required FlowTask task}) {
    return apiClient.createRecord(
      apiToken: workspace.apiToken,
      tableId: workspace.tasksTableId,
      fields: NocoDBFieldMapper.taskFields(task),
    );
  }

  Future<void> updateTask({required String recordId, required FlowTask task}) {
    return apiClient.updateRecord(
      apiToken: workspace.apiToken,
      tableId: workspace.tasksTableId,
      recordId: recordId,
      fields: NocoDBFieldMapper.taskFields(task),
    );
  }
}

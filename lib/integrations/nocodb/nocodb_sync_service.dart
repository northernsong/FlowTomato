import '../../features/tasks/domain/task.dart';
import '../../features/tasks/application/task_sync_service.dart';
import 'nocodb_base_api_client.dart';
import 'nocodb_field_mapper.dart';
import 'nocodb_models.dart';

class NocoDBSyncService implements TaskSyncService {
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

  @override
  Future<List<SyncedTask>> loadTodayTasks(DateTime date) async {
    final records = await searchTodayTasks(date: date);
    return records
        .map(
          (record) => SyncedTask(
            recordId: record.recordId,
            task: NocoDBFieldMapper.taskFromRecord(
              recordId: record.recordId,
              fields: record.fields,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> createTask(FlowTask task) async {
    final fields = NocoDBFieldMapper.taskFields(task);
    try {
      return await apiClient.createRecord(
        apiToken: workspace.apiToken,
        tableId: workspace.tasksTableId,
        fields: fields,
      );
    } on NocoDBApiException catch (error) {
      if (!_isInvalidSingleSelectOption(error)) {
        rethrow;
      }
      return apiClient.createRecord(
        apiToken: workspace.apiToken,
        tableId: workspace.tasksTableId,
        fields: _withoutEnumFields(fields),
      );
    }
  }

  @override
  Future<void> updateTask({
    required String recordId,
    required FlowTask task,
  }) async {
    final fields = NocoDBFieldMapper.taskFields(task);
    try {
      await apiClient.updateRecord(
        apiToken: workspace.apiToken,
        tableId: workspace.tasksTableId,
        recordId: recordId,
        fields: fields,
      );
    } on NocoDBApiException catch (error) {
      if (!_isInvalidSingleSelectOption(error)) {
        rethrow;
      }
      await apiClient.updateRecord(
        apiToken: workspace.apiToken,
        tableId: workspace.tasksTableId,
        recordId: recordId,
        fields: _withoutEnumFields(fields),
      );
    }
  }

  @override
  Future<void> deleteTask({required String recordId}) {
    return apiClient.deleteRecord(
      apiToken: workspace.apiToken,
      tableId: workspace.tasksTableId,
      recordId: recordId,
    );
  }

  bool _isInvalidSingleSelectOption(NocoDBApiException error) {
    return error.message.contains('Invalid option(s)');
  }

  Map<String, Object?> _withoutEnumFields(Map<String, Object?> fields) {
    return Map<String, Object?>.from(fields)
      ..remove('Status')
      ..remove('Priority')
      ..remove('Sync Status');
  }
}

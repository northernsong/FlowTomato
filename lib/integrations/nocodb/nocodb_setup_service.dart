import 'nocodb_base_api_client.dart';
import 'nocodb_models.dart';

class NocoDBSetupService {
  const NocoDBSetupService({required this.apiClient});

  static const baseTitle = 'FlowTomato';
  static const tasksTableTitle = 'Tasks';
  static const pomodoroTableTitle = 'Pomodoro';
  static const dailySummaryTableTitle = 'DailySummary';

  final NocoDBApiClient apiClient;

  Future<NocoDBWorkspaceConfig?> findWorkspace({
    required String baseUrl,
    required String apiToken,
  }) async {
    final bases = await apiClient.listBases(apiToken: apiToken);
    final base = _findByTitle(bases, baseTitle);
    if (base == null) {
      return null;
    }
    final tables = await apiClient.listTables(
      apiToken: apiToken,
      baseId: base.id,
    );
    return _workspaceFromTables(
      baseUrl: baseUrl,
      apiToken: apiToken,
      base: base,
      tables: tables,
    );
  }

  Future<NocoDBWorkspaceConfig> initializeWorkspace({
    required String baseUrl,
    required String apiToken,
  }) async {
    final bases = await apiClient.listBases(apiToken: apiToken);
    var base = _findByTitle(bases, baseTitle);
    base ??= await apiClient.createBase(apiToken: apiToken, title: baseTitle);
    final existingTables = await apiClient.listTables(
      apiToken: apiToken,
      baseId: base.id,
    );
    final sourceId = base.sourceId ?? _firstSourceId(existingTables);
    if (sourceId == null || sourceId.isEmpty) {
      throw const NocoDBApiException(
        'Cannot determine NocoDB source id for table creation.',
      );
    }
    final existingTasks = _findByTitle(existingTables, tasksTableTitle);
    final existingPomodoro = _findByTitle(existingTables, pomodoroTableTitle);
    final existingDailySummary = _findByTitle(
      existingTables,
      dailySummaryTableTitle,
    );
    final tasksTable =
        existingTasks ??
        await apiClient.createTable(
          apiToken: apiToken,
          baseId: base.id,
          sourceId: sourceId,
          title: tasksTableTitle,
          columns: _tasksColumns,
        );
    final pomodoroTable =
        existingPomodoro ??
        await apiClient.createTable(
          apiToken: apiToken,
          baseId: base.id,
          sourceId: sourceId,
          title: pomodoroTableTitle,
          columns: _pomodoroColumns,
        );
    final dailySummaryTable =
        existingDailySummary ??
        await apiClient.createTable(
          apiToken: apiToken,
          baseId: base.id,
          sourceId: sourceId,
          title: dailySummaryTableTitle,
          columns: _dailySummaryColumns,
        );
    return NocoDBWorkspaceConfig(
      baseUrl: baseUrl,
      apiToken: apiToken,
      baseId: base.id,
      sourceId: sourceId,
      tasksTableId: tasksTable.id,
      pomodoroTableId: pomodoroTable.id,
      dailySummaryTableId: dailySummaryTable.id,
    );
  }

  Future<NocoDBWorkspaceConfig> validateWorkspace(
    NocoDBWorkspaceConfig workspace,
  ) async {
    await apiClient.validateTable(
      apiToken: workspace.apiToken,
      tableId: workspace.tasksTableId,
    );
    await apiClient.validateTable(
      apiToken: workspace.apiToken,
      tableId: workspace.pomodoroTableId,
    );
    await apiClient.validateTable(
      apiToken: workspace.apiToken,
      tableId: workspace.dailySummaryTableId,
    );
    return workspace;
  }

  NocoDBWorkspaceConfig? _workspaceFromTables({
    required String baseUrl,
    required String apiToken,
    required NocoDBBase base,
    required List<NocoDBTable> tables,
  }) {
    final tasks = _findByTitle(tables, tasksTableTitle);
    final pomodoro = _findByTitle(tables, pomodoroTableTitle);
    final dailySummary = _findByTitle(tables, dailySummaryTableTitle);
    if (tasks == null || pomodoro == null || dailySummary == null) {
      return null;
    }
    return NocoDBWorkspaceConfig(
      baseUrl: baseUrl,
      apiToken: apiToken,
      baseId: base.id,
      sourceId: base.sourceId ?? _firstSourceId(tables) ?? '',
      tasksTableId: tasks.id,
      pomodoroTableId: pomodoro.id,
      dailySummaryTableId: dailySummary.id,
    );
  }

  T? _findByTitle<T>(List<T> items, String title) {
    for (final item in items) {
      final itemTitle = switch (item) {
        NocoDBBase(:final title) => title,
        NocoDBTable(:final title) => title,
        _ => '',
      };
      if (itemTitle == title) {
        return item;
      }
    }
    return null;
  }

  String? _firstSourceId(List<NocoDBTable> tables) {
    for (final table in tables) {
      final sourceId = table.sourceId;
      if (sourceId != null && sourceId.isNotEmpty) {
        return sourceId;
      }
    }
    return null;
  }

  static const _tasksColumns = [
    NocoDBColumnSchema(
      title: 'Title',
      type: 'SingleLineText',
      primary: true,
      required: true,
    ),
    NocoDBColumnSchema(title: 'Local ID', type: 'SingleLineText'),
    NocoDBColumnSchema(title: 'Note', type: 'LongText'),
    NocoDBColumnSchema(title: 'Status', type: 'SingleSelect'),
    NocoDBColumnSchema(title: 'Priority', type: 'SingleSelect'),
    NocoDBColumnSchema(title: 'Planned Pomodoros', type: 'Number'),
    NocoDBColumnSchema(title: 'Completed Pomodoros', type: 'Number'),
    NocoDBColumnSchema(title: 'Sort Order', type: 'Number'),
    NocoDBColumnSchema(title: 'Date', type: 'Date'),
    NocoDBColumnSchema(title: 'Created At', type: 'DateTime'),
    NocoDBColumnSchema(title: 'Updated At', type: 'DateTime'),
    NocoDBColumnSchema(title: 'Completed At', type: 'DateTime'),
    NocoDBColumnSchema(title: 'Sync Status', type: 'SingleSelect'),
  ];

  static const _pomodoroColumns = [
    NocoDBColumnSchema(
      title: 'Local ID',
      type: 'SingleLineText',
      primary: true,
      required: true,
    ),
    NocoDBColumnSchema(title: 'Task ID', type: 'SingleLineText'),
    NocoDBColumnSchema(title: 'Task Title', type: 'SingleLineText'),
    NocoDBColumnSchema(title: 'Type', type: 'SingleSelect'),
    NocoDBColumnSchema(title: 'Duration Minutes', type: 'Number'),
    NocoDBColumnSchema(title: 'Actual Minutes', type: 'Number'),
    NocoDBColumnSchema(title: 'Status', type: 'SingleSelect'),
    NocoDBColumnSchema(title: 'Started At', type: 'DateTime'),
    NocoDBColumnSchema(title: 'Ended At', type: 'DateTime'),
    NocoDBColumnSchema(title: 'Date', type: 'Date'),
    NocoDBColumnSchema(title: 'Sync Status', type: 'SingleSelect'),
  ];

  static const _dailySummaryColumns = [
    NocoDBColumnSchema(
      title: 'Date',
      type: 'Date',
      primary: true,
      required: true,
    ),
    NocoDBColumnSchema(title: 'Completed Task Count', type: 'Number'),
    NocoDBColumnSchema(title: 'Completed Pomodoro Count', type: 'Number'),
    NocoDBColumnSchema(title: 'Focus Minutes', type: 'Number'),
    NocoDBColumnSchema(title: 'Updated At', type: 'DateTime'),
  ];
}

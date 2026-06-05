import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/tasks/domain/task.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_base_api_client.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_http.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_models.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_sync_service.dart';

import 'nocodb_test_utils.dart';

void main() {
  group('NocoDBSyncService', () {
    const workspace = NocoDBWorkspaceConfig(
      baseUrl: 'http://127.0.0.1:8080',
      apiToken: 'nc_pat_test',
      baseId: 'p_flow',
      sourceId: 'ds_default',
      tasksTableId: 'tbl_tasks',
      pomodoroTableId: 'tbl_pomo',
      dailySummaryTableId: 'tbl_summary',
    );

    test(
      'loadTodayTasks uses the configured Tasks table and maps records',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: [
            const NocoDBHttpResponse(
              statusCode: 200,
              body: {
                'list': [
                  {
                    'Id': 7,
                    'Local ID': 'task-7',
                    'Title': 'Search me',
                    'Status': 'todo',
                    'Priority': 'medium',
                    'Planned Pomodoros': 1,
                    'Completed Pomodoros': 0,
                    'Sort Order': 0,
                    'Date': '2026-06-01',
                    'Created At': '2026-06-01T08:00:00.000Z',
                    'Updated At': '2026-06-01T08:00:00.000Z',
                    'Sync Status': 'synced',
                  },
                ],
              },
            ),
          ],
        );
        final service = NocoDBSyncService(
          apiClient: NocoDBApiClient(http: http),
          workspace: workspace,
        );

        final tasks = await service.loadTodayTasks(DateTime.utc(2026, 6, 1));

        expect(tasks.single.recordId, '7');
        expect(tasks.single.task.id, 'task-7');
        expect(tasks.single.task.title, 'Search me');
        expect(http.requests.single.path, '/api/v2/tables/tbl_tasks/records');
        expect(
          http.requests.single.queryParameters['where'],
          '(Date,eq,2026-06-01)',
        );
      },
    );

    test('createTask maps task fields and creates a record', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {'Id': 8, 'Title': 'Sync this'},
          ),
        ],
      );
      final service = NocoDBSyncService(
        apiClient: NocoDBApiClient(http: http),
        workspace: workspace,
      );

      final task = FlowTask.create(title: 'Sync this');
      final recordId = await service.createTask(task);

      expect(recordId, '8');
      expect(http.requests.single.body, containsPair('Title', 'Sync this'));
      expect(http.requests.single.path, contains('/tables/tbl_tasks/records'));
    });

    test(
      'createTask retries without enum fields when NocoDB single-select options are missing',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: [
            const NocoDBHttpResponse(
              statusCode: 400,
              body: {
                'msg':
                    'Invalid option(s) "todo" provided for column "Status". Valid options are ""',
              },
            ),
            const NocoDBHttpResponse(
              statusCode: 200,
              body: {'Id': 10, 'Title': 'Fallback sync'},
            ),
          ],
        );
        final service = NocoDBSyncService(
          apiClient: NocoDBApiClient(http: http),
          workspace: workspace,
        );

        final recordId = await service.createTask(
          FlowTask.create(title: 'Fallback sync'),
        );

        expect(recordId, '10');
        expect(http.requests, hasLength(2));
        expect(http.requests.first.body, contains('Status'));
        expect(http.requests.last.body, isNot(contains('Status')));
        expect(http.requests.last.body, isNot(contains('Priority')));
        expect(http.requests.last.body, isNot(contains('Sync Status')));
        expect(http.requests.last.body, containsPair('Title', 'Fallback sync'));
      },
    );

    test('updateTask maps task fields and updates the record id', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {'Id': 9, 'Status': 'done'},
          ),
        ],
      );
      final service = NocoDBSyncService(
        apiClient: NocoDBApiClient(http: http),
        workspace: workspace,
      );

      final task = FlowTask.create(
        title: 'Complete this',
      ).copyWith(status: TaskStatus.done);
      await service.updateTask(recordId: '9', task: task);

      expect(http.requests.single.method, NocoDBHttpMethod.patch);
      expect(http.requests.single.body, containsPair('Id', 9));
      expect(http.requests.single.body, containsPair('Status', 'done'));
      expect(http.requests.single.path, endsWith('/records'));
    });

    test(
      'updateTask retries without enum fields when NocoDB single-select options are missing',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: [
            const NocoDBHttpResponse(
              statusCode: 400,
              body: {
                'msg':
                    'Invalid option(s) "done" provided for column "Status". Valid options are ""',
              },
            ),
            const NocoDBHttpResponse(
              statusCode: 200,
              body: {'Id': 11, 'Title': 'Fallback update'},
            ),
          ],
        );
        final service = NocoDBSyncService(
          apiClient: NocoDBApiClient(http: http),
          workspace: workspace,
        );

        await service.updateTask(
          recordId: '11',
          task: FlowTask.create(
            title: 'Fallback update',
          ).copyWith(status: TaskStatus.done),
        );

        expect(http.requests, hasLength(2));
        expect(http.requests.first.body, contains('Status'));
        expect(http.requests.last.body, isNot(contains('Status')));
        expect(http.requests.last.body, isNot(contains('Priority')));
        expect(http.requests.last.body, isNot(contains('Sync Status')));
        expect(http.requests.last.body, containsPair('Id', 11));
      },
    );
  });
}

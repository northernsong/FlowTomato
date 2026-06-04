import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_base_api_client.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_http.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_setup_service.dart';

import 'nocodb_test_utils.dart';

void main() {
  group('NocoDBSetupService', () {
    test('findWorkspace returns existing FlowTomato table ids', () async {
      final http = RecordingNocoDBHttpClient(
        responses: const [
          NocoDBHttpResponse(
            statusCode: 200,
            body: {
              'list': [
                {
                  'id': 'p_flow',
                  'title': 'FlowTomato',
                  'sources': [
                    {'id': 'ds_default'},
                  ],
                },
              ],
            },
          ),
          NocoDBHttpResponse(
            statusCode: 200,
            body: {
              'list': [
                {'id': 'tbl_tasks', 'title': 'Tasks'},
                {'id': 'tbl_pomo', 'title': 'Pomodoro'},
                {'id': 'tbl_summary', 'title': 'DailySummary'},
              ],
            },
          ),
        ],
      );
      final service = NocoDBSetupService(
        apiClient: NocoDBApiClient(http: http),
      );

      final workspace = await service.findWorkspace(
        baseUrl: 'http://127.0.0.1:8080',
        apiToken: 'nc_pat_test',
      );

      expect(workspace, isNotNull);
      expect(workspace!.baseId, 'p_flow');
      expect(workspace.sourceId, 'ds_default');
      expect(workspace.tasksTableId, 'tbl_tasks');
      expect(workspace.pomodoroTableId, 'tbl_pomo');
      expect(workspace.dailySummaryTableId, 'tbl_summary');
      expect(http.requests.map((request) => request.path), [
        '/api/v2/meta/bases/',
        '/api/v2/meta/bases/p_flow/tables',
      ]);
    });

    test(
      'findWorkspace accepts an existing complete base without source data',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: const [
            NocoDBHttpResponse(
              statusCode: 200,
              body: {
                'list': [
                  {'id': 'p_flow', 'title': 'FlowTomato'},
                ],
              },
            ),
            NocoDBHttpResponse(
              statusCode: 200,
              body: {
                'list': [
                  {'id': 'tbl_tasks', 'title': 'Tasks'},
                  {'id': 'tbl_pomo', 'title': 'Pomodoro'},
                  {'id': 'tbl_summary', 'title': 'DailySummary'},
                ],
              },
            ),
          ],
        );
        final service = NocoDBSetupService(
          apiClient: NocoDBApiClient(http: http),
        );

        final workspace = await service.findWorkspace(
          baseUrl: 'http://127.0.0.1:8080',
          apiToken: 'nc_pat_test',
        );

        expect(workspace, isNotNull);
        expect(workspace!.sourceId, '');
        expect(workspace.tasksTableId, 'tbl_tasks');
        expect(workspace.pomodoroTableId, 'tbl_pomo');
        expect(workspace.dailySummaryTableId, 'tbl_summary');
      },
    );

    test(
      'initializeWorkspace creates missing FlowTomato base and tables',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: const [
            NocoDBHttpResponse(statusCode: 200, body: {'list': []}),
            NocoDBHttpResponse(
              statusCode: 200,
              body: {
                'id': 'p_flow',
                'title': 'FlowTomato',
                'sources': [
                  {'id': 'ds_default'},
                ],
              },
            ),
            NocoDBHttpResponse(statusCode: 200, body: {'list': []}),
            NocoDBHttpResponse(statusCode: 200, body: {'id': 'tbl_tasks'}),
            NocoDBHttpResponse(statusCode: 200, body: {'id': 'tbl_pomo'}),
            NocoDBHttpResponse(statusCode: 200, body: {'id': 'tbl_summary'}),
          ],
        );
        final service = NocoDBSetupService(
          apiClient: NocoDBApiClient(http: http),
        );

        final workspace = await service.initializeWorkspace(
          baseUrl: 'http://127.0.0.1:8080',
          apiToken: 'nc_pat_test',
        );

        expect(workspace.baseId, 'p_flow');
        expect(workspace.tasksTableId, 'tbl_tasks');
        expect(workspace.pomodoroTableId, 'tbl_pomo');
        expect(workspace.dailySummaryTableId, 'tbl_summary');
        expect(http.requests.map((request) => request.path), [
          '/api/v2/meta/bases/',
          '/api/v2/meta/bases/',
          '/api/v2/meta/bases/p_flow/tables',
          '/api/v2/meta/bases/p_flow/ds_default/tables',
          '/api/v2/meta/bases/p_flow/ds_default/tables',
          '/api/v2/meta/bases/p_flow/ds_default/tables',
        ]);
      },
    );
  });
}

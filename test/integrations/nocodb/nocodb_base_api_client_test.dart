import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_base_api_client.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_http.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_models.dart';

import 'nocodb_test_utils.dart';

void main() {
  group('NocoDBApiClient', () {
    test('listBases parses base metadata', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
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
        ],
      );
      final client = NocoDBApiClient(http: http);

      final bases = await client.listBases(apiToken: 'nc_pat_test');

      expect(bases.single.id, 'p_flow');
      expect(bases.single.title, 'FlowTomato');
      expect(bases.single.sourceId, 'ds_default');
      expect(http.requests.single.method, NocoDBHttpMethod.get);
      expect(http.requests.single.path, '/api/v2/meta/bases/');
      expect(http.requests.single.headers['xc-token'], 'nc_pat_test');
    });

    test('listBases accepts base metadata without source details', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {
              'list': [
                {'id': 'p_flow', 'title': 'FlowTomato'},
              ],
            },
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      final bases = await client.listBases(apiToken: 'nc_pat_test');

      expect(bases.single.id, 'p_flow');
      expect(bases.single.title, 'FlowTomato');
      expect(bases.single.sourceId, isNull);
    });

    test('listTables parses tables for a base', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {
              'list': [
                {
                  'id': 'tbl_tasks',
                  'title': 'Tasks',
                  'source_id': 'ds_default',
                },
              ],
            },
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      final tables = await client.listTables(
        apiToken: 'nc_pat_test',
        baseId: 'p_flow',
      );

      expect(tables.single.id, 'tbl_tasks');
      expect(tables.single.title, 'Tasks');
      expect(tables.single.sourceId, 'ds_default');
      expect(http.requests.single.path, '/api/v2/meta/bases/p_flow/tables');
    });

    test('createBase and createTable send meta API requests', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {
              'id': 'p_flow',
              'title': 'FlowTomato',
              'sources': [
                {'id': 'ds_default'},
              ],
            },
          ),
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {'id': 'tbl_tasks', 'title': 'Tasks'},
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      final base = await client.createBase(
        apiToken: 'nc_pat_test',
        title: 'FlowTomato',
      );
      final table = await client.createTable(
        apiToken: 'nc_pat_test',
        baseId: base.id,
        sourceId: base.sourceId!,
        title: 'Tasks',
        columns: const [
          NocoDBColumnSchema(
            title: 'Title',
            type: 'SingleLineText',
            primary: true,
          ),
        ],
      );

      expect(base.id, 'p_flow');
      expect(table.id, 'tbl_tasks');
      expect(http.requests.first.path, '/api/v2/meta/bases/');
      expect(http.requests.first.body['title'], 'FlowTomato');
      expect(
        http.requests.last.path,
        '/api/v2/meta/bases/p_flow/ds_default/tables',
      );
      expect(http.requests.last.body['title'], 'Tasks');
    });

    test(
      'listRecords sends PAT header and parses NocoDB list records',
      () async {
        final http = RecordingNocoDBHttpClient(
          responses: [
            const NocoDBHttpResponse(
              statusCode: 200,
              body: {
                'list': [
                  {'Id': 1, 'Title': 'Draft'},
                ],
              },
            ),
          ],
        );
        final client = NocoDBApiClient(http: http);

        final records = await client.listRecords(
          apiToken: 'nc_pat_test',
          tableId: 'tbl_tasks',
          where: '(Date,eq,2026-06-01)',
        );

        expect(records.single.recordId, '1');
        expect(records.single.fields['Title'], 'Draft');
        expect(http.requests.single.method, NocoDBHttpMethod.get);
        expect(http.requests.single.path, '/api/v2/tables/tbl_tasks/records');
        expect(http.requests.single.headers['xc-token'], 'nc_pat_test');
        expect(
          http.requests.single.queryParameters['where'],
          '(Date,eq,2026-06-01)',
        );
      },
    );

    test('createRecord posts fields and parses record id', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {'Id': 42, 'Title': 'Ship'},
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      final recordId = await client.createRecord(
        apiToken: 'nc_pat_test',
        tableId: 'tbl_tasks',
        fields: const {'Title': 'Ship'},
      );

      expect(recordId, '42');
      expect(http.requests.single.method, NocoDBHttpMethod.post);
      expect(http.requests.single.path, '/api/v2/tables/tbl_tasks/records');
      expect(http.requests.single.body, {'Title': 'Ship'});
    });

    test('updateRecord patches fields to target record id', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 200,
            body: {'Id': 42, 'Status': 'done'},
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      await client.updateRecord(
        apiToken: 'nc_pat_test',
        tableId: 'tbl_tasks',
        recordId: '42',
        fields: const {'Status': 'done'},
      );

      expect(http.requests.single.method, NocoDBHttpMethod.patch);
      expect(http.requests.single.path, '/api/v2/tables/tbl_tasks/records');
      expect(http.requests.single.body, {'Id': 42, 'Status': 'done'});
    });

    test('failed requests include NocoDB message in the exception', () async {
      final http = RecordingNocoDBHttpClient(
        responses: [
          const NocoDBHttpResponse(
            statusCode: 401,
            body: {'msg': 'Invalid token'},
          ),
        ],
      );
      final client = NocoDBApiClient(http: http);

      await expectLater(
        client.listRecords(apiToken: 'bad-token', tableId: 'tbl_tasks'),
        throwsA(
          isA<NocoDBApiException>().having(
            (error) => error.message,
            'message',
            contains('Invalid token'),
          ),
        ),
      );
    });
  });
}

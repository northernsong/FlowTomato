import 'nocodb_http.dart';
import 'nocodb_models.dart';

class NocoDBApiClient {
  const NocoDBApiClient({required this.http});

  final NocoDBHttpClient http;

  Future<List<NocoDBBase>> listBases({required String apiToken}) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.get,
      path: '/api/v2/meta/bases/',
    );
    final items = data['list'] ?? data['bases'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) => _baseFrom(item))
        .toList(growable: false);
  }

  Future<NocoDBBase> createBase({
    required String apiToken,
    required String title,
  }) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.post,
      path: '/api/v2/meta/bases/',
      body: {'title': title},
    );
    return _baseFrom(data);
  }

  Future<List<NocoDBTable>> listTables({
    required String apiToken,
    required String baseId,
  }) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.get,
      path: '/api/v2/meta/bases/$baseId/tables',
    );
    final items = data['list'] ?? data['tables'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) => _tableFrom(item))
        .toList(growable: false);
  }

  Future<NocoDBTable> createTable({
    required String apiToken,
    required String baseId,
    required String sourceId,
    required String title,
    required List<NocoDBColumnSchema> columns,
  }) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.post,
      path: '/api/v2/meta/bases/$baseId/$sourceId/tables',
      body: {
        'title': title,
        'table_name': title,
        'columns': columns.map((column) => column.toJson()).toList(),
      },
    );
    return _tableFrom(data);
  }

  Future<List<NocoDBRecord>> listRecords({
    required String apiToken,
    required String tableId,
    String? where,
    int limit = 100,
  }) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.get,
      path: '/api/v2/tables/$tableId/records',
      queryParameters: {
        'limit': '$limit',
        if (where != null && where.isNotEmpty) 'where': where,
      },
    );
    final items = data['list'] ?? data['records'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) {
          final recordId = item['Id'] ?? item['id'];
          if (recordId == null) {
            throw const NocoDBApiException('Unexpected record response shape.');
          }
          return NocoDBRecord(
            recordId: '$recordId',
            fields: Map<String, Object?>.from(item),
          );
        })
        .toList(growable: false);
  }

  Future<String> createRecord({
    required String apiToken,
    required String tableId,
    required Map<String, Object?> fields,
  }) async {
    final data = await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.post,
      path: '/api/v2/tables/$tableId/records',
      body: fields,
    );
    return _recordIdFrom(data);
  }

  Future<void> updateRecord({
    required String apiToken,
    required String tableId,
    required String recordId,
    required Map<String, Object?> fields,
  }) async {
    await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.patch,
      path: '/api/v2/tables/$tableId/records',
      body: {'Id': int.tryParse(recordId) ?? recordId, ...fields},
    );
  }

  Future<void> deleteRecord({
    required String apiToken,
    required String tableId,
    required String recordId,
  }) async {
    await _requestBody(
      apiToken: apiToken,
      method: NocoDBHttpMethod.delete,
      path: '/api/v2/tables/$tableId/records',
      body: {'Id': int.tryParse(recordId) ?? recordId},
    );
  }

  Future<void> validateTable({
    required String apiToken,
    required String tableId,
  }) async {
    await listRecords(apiToken: apiToken, tableId: tableId, limit: 1);
  }

  Future<Map<String, Object?>> _requestBody({
    required String apiToken,
    required NocoDBHttpMethod method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, Object?> body = const {},
  }) async {
    final response = await http.request(
      method: method,
      path: path,
      headers: {'xc-token': apiToken},
      queryParameters: queryParameters,
      body: body,
    );
    return _requireSuccess(response);
  }

  Map<String, Object?> _requireSuccess(NocoDBHttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = response.body['msg'] ?? response.body['message'];
      throw NocoDBApiException(
        msg is String && msg.isNotEmpty
            ? 'NocoDB request failed: $msg'
            : 'NocoDB request failed.',
        statusCode: response.statusCode,
      );
    }
    return response.body;
  }

  String _recordIdFrom(Map<String, Object?> data) {
    final recordId = data['Id'] ?? data['id'];
    if (recordId != null) {
      return '$recordId';
    }
    throw const NocoDBApiException('Missing NocoDB record id.');
  }

  NocoDBBase _baseFrom(Map<Object?, Object?> data) {
    final id = data['id'];
    final title = data['title'];
    final sources = data['sources'];
    String? sourceId = _stringOrNull(
      data['source_id'] ?? data['sourceId'] ?? data['fk_source_id'],
    );
    if (sources is List && sources.isNotEmpty) {
      final first = sources.first;
      if (first is Map && first['id'] != null) {
        sourceId = '${first['id']}';
      }
    }
    if (id == null || title == null) {
      throw const NocoDBApiException('Unexpected base response shape.');
    }
    return NocoDBBase(id: '$id', title: '$title', sourceId: sourceId);
  }

  NocoDBTable _tableFrom(Map<Object?, Object?> data) {
    final id = data['id'];
    final title = data['title'] ?? data['table_name'] ?? id;
    final sourceId = _stringOrNull(
      data['source_id'] ?? data['sourceId'] ?? data['fk_source_id'],
    );
    if (id == null) {
      throw const NocoDBApiException('Unexpected table response shape.');
    }
    return NocoDBTable(id: '$id', title: '$title', sourceId: sourceId);
  }

  String? _stringOrNull(Object? value) => value == null ? null : '$value';
}

import 'package:flow_tomato/integrations/nocodb/nocodb_http.dart';

class RecordingNocoDBHttpClient implements NocoDBHttpClient {
  RecordingNocoDBHttpClient({List<NocoDBHttpResponse>? responses})
    : _responses = List<NocoDBHttpResponse>.from(responses ?? []);

  final List<NocoDBHttpResponse> _responses;
  final List<RecordedNocoDBRequest> requests = [];

  @override
  Future<NocoDBHttpResponse> request({
    required NocoDBHttpMethod method,
    required String path,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Map<String, Object?> body = const {},
  }) async {
    requests.add(
      RecordedNocoDBRequest(
        method: method,
        path: path,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
      ),
    );
    if (_responses.isEmpty) {
      throw StateError('No fake response queued for $method $path.');
    }
    return _responses.removeAt(0);
  }
}

class RecordedNocoDBRequest {
  const RecordedNocoDBRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.queryParameters,
    required this.body,
  });

  final NocoDBHttpMethod method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final Map<String, Object?> body;
}

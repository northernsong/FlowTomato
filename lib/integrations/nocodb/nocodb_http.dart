import 'dart:convert';

import 'package:http/http.dart' as http;

enum NocoDBHttpMethod { get, post, put, patch, delete }

abstract class NocoDBHttpClient {
  Future<NocoDBHttpResponse> request({
    required NocoDBHttpMethod method,
    required String path,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Map<String, Object?> body = const {},
  });
}

class NocoDBHttpResponse {
  const NocoDBHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object?> body;
}

class HttpNocoDBHttpClient implements NocoDBHttpClient {
  HttpNocoDBHttpClient({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri =
          baseUri ??
          Uri.parse(
            const String.fromEnvironment(
              'NOCODB_BASE_URL',
              defaultValue: 'http://127.0.0.1:8080',
            ),
          );

  final http.Client _client;
  final Uri _baseUri;

  @override
  Future<NocoDBHttpResponse> request({
    required NocoDBHttpMethod method,
    required String path,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Map<String, Object?> body = const {},
  }) async {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final requestPath = path.startsWith('/') ? path : '/$path';
    final uri = _baseUri.replace(
      path: '$basePath$requestPath',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final requestHeaders = {
      'Content-Type': 'application/json; charset=utf-8',
      ...headers,
    };
    final encodedBody = body.isEmpty ? null : jsonEncode(body);
    final response = switch (method) {
      NocoDBHttpMethod.get => await _client.get(uri, headers: requestHeaders),
      NocoDBHttpMethod.post => await _client.post(
        uri,
        headers: requestHeaders,
        body: encodedBody,
      ),
      NocoDBHttpMethod.put => await _client.put(
        uri,
        headers: requestHeaders,
        body: encodedBody,
      ),
      NocoDBHttpMethod.patch => await _client.patch(
        uri,
        headers: requestHeaders,
        body: encodedBody,
      ),
      NocoDBHttpMethod.delete => await _client.delete(
        uri,
        headers: requestHeaders,
        body: encodedBody,
      ),
    };
    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;
    return NocoDBHttpResponse(statusCode: response.statusCode, body: decoded);
  }
}

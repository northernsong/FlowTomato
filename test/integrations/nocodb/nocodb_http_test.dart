import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flow_tomato/integrations/nocodb/nocodb_http.dart';

void main() {
  group('HttpNocoDBHttpClient', () {
    test(
      'does not create a double slash when base URL has trailing slash',
      () async {
        Uri? requestedUri;
        final client = HttpNocoDBHttpClient(
          baseUri: Uri.parse('https://noco.example.com/'),
          client: MockClient((request) async {
            requestedUri = request.url;
            return http.Response('{}', 200);
          }),
        );

        await client.request(
          method: NocoDBHttpMethod.get,
          path: '/api/v2/meta/bases/',
        );

        expect(requestedUri?.path, '/api/v2/meta/bases/');
      },
    );
  });
}

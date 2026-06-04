import 'dart:convert';
import 'dart:io';

import 'nocodb_models.dart';

class NocoDBWorkspaceCache {
  NocoDBWorkspaceCache({File? file}) : _file = file ?? _defaultFile();

  final File _file;

  Future<NocoDBWorkspaceConfig?> read() async {
    if (!await _file.exists()) {
      return null;
    }
    final text = await _file.readAsString();
    if (text.trim().isEmpty) {
      return null;
    }
    return NocoDBWorkspaceConfig.fromJson(
      jsonDecode(text) as Map<String, Object?>,
    );
  }

  Future<void> write(NocoDBWorkspaceConfig workspace) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(workspace.toJson()));
  }

  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  static File _defaultFile() {
    final home = Platform.environment['HOME'];
    final base = home == null || home.isEmpty
        ? Directory.systemTemp.path
        : '$home/Library/Application Support/FlowTomato';
    return File('$base/nocodb_workspace.json');
  }
}

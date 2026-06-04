class NocoDBWorkspaceConfig {
  const NocoDBWorkspaceConfig({
    required this.baseUrl,
    required this.apiToken,
    required this.baseId,
    required this.sourceId,
    required this.tasksTableId,
    required this.pomodoroTableId,
    required this.dailySummaryTableId,
  });

  final String baseUrl;
  final String apiToken;
  final String baseId;
  final String sourceId;
  final String tasksTableId;
  final String pomodoroTableId;
  final String dailySummaryTableId;

  Map<String, Object?> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiToken': apiToken,
      'baseId': baseId,
      'sourceId': sourceId,
      'tasksTableId': tasksTableId,
      'pomodoroTableId': pomodoroTableId,
      'dailySummaryTableId': dailySummaryTableId,
    };
  }

  static NocoDBWorkspaceConfig fromJson(Map<String, Object?> json) {
    return NocoDBWorkspaceConfig(
      baseUrl: json['baseUrl'] as String,
      apiToken: json['apiToken'] as String,
      baseId: json['baseId'] as String,
      sourceId: (json['sourceId'] as String?) ?? '',
      tasksTableId: json['tasksTableId'] as String,
      pomodoroTableId: json['pomodoroTableId'] as String,
      dailySummaryTableId: json['dailySummaryTableId'] as String,
    );
  }
}

class NocoDBBase {
  const NocoDBBase({required this.id, required this.title, this.sourceId});

  final String id;
  final String title;
  final String? sourceId;
}

class NocoDBTable {
  const NocoDBTable({required this.id, required this.title, this.sourceId});

  final String id;
  final String title;
  final String? sourceId;
}

class NocoDBColumnSchema {
  const NocoDBColumnSchema({
    required this.title,
    required this.type,
    this.primary = false,
    this.required = false,
  });

  final String title;
  final String type;
  final bool primary;
  final bool required;

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'uidt': type,
      if (primary) 'pv': true,
      if (required) 'rqd': true,
    };
  }
}

class NocoDBRecord {
  const NocoDBRecord({required this.recordId, required this.fields});

  final String recordId;
  final Map<String, Object?> fields;
}

class NocoDBApiException implements Exception {
  const NocoDBApiException(this.message, {this.code, this.statusCode});

  final String message;
  final int? code;
  final int? statusCode;

  @override
  String toString() {
    final details = [
      if (code != null) 'code=$code',
      if (statusCode != null) 'statusCode=$statusCode',
    ].join(', ');
    return details.isEmpty
        ? 'NocoDBApiException: $message'
        : 'NocoDBApiException: $message ($details)';
  }
}

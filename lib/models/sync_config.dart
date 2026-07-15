enum SyncType {
  webdav,
  sftp,
}

class SyncConfig {
  final SyncType type;
  final String serverUrl;
  final String username;
  final String password;
  final String path;
  final bool autoSync;
  final int syncIntervalMinutes;
  final DateTime? lastSyncTime;
  final bool enabled;

  SyncConfig({
    required this.type,
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.path = '/mi_xia/',
    this.autoSync = false,
    this.syncIntervalMinutes = 30,
    this.lastSyncTime,
    this.enabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'path': path,
      'autoSync': autoSync,
      'syncIntervalMinutes': syncIntervalMinutes,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'enabled': enabled,
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      type: SyncType.values[json['type']],
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      path: json['path'] ?? '/mi_xia/',
      autoSync: json['autoSync'] ?? false,
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 30,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
      enabled: json['enabled'] ?? false,
    );
  }

  SyncConfig copyWith({
    SyncType? type,
    String? serverUrl,
    String? username,
    String? password,
    String? path,
    bool? autoSync,
    int? syncIntervalMinutes,
    DateTime? lastSyncTime,
    bool? enabled,
  }) {
    return SyncConfig(
      type: type ?? this.type,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      path: path ?? this.path,
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      enabled: enabled ?? this.enabled,
    );
  }

  String get typeLabel {
    switch (type) {
      case SyncType.webdav:
        return 'WebDAV';
      case SyncType.sftp:
        return 'SFTP';
    }
  }
}

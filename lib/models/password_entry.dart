import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'entry_type_config.dart';

enum EntryType {
  login,
  card,
  note,
  identity,
  email,
  wifi,
  server,
  software,
  database,
  ssh,
}

class PasswordEntry {
  final String id;
  final EntryType type;
  String title;
  String username;
  String password;
  String url;
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;
  Map<String, String> fields;
  bool isFavorite;

  PasswordEntry({
    String? id,
    required this.type,
    required this.title,
    this.username = '',
    this.password = '',
    this.url = '',
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, String>? fields,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        fields = fields ?? {};

  String getField(String key) {
    switch (key) {
      case 'title':
        return title;
      case 'username':
        return username;
      case 'password':
        return password;
      case 'url':
        return url;
      case 'notes':
        return notes;
      default:
        return fields[key] ?? '';
    }
  }

  void setField(String key, String value) {
    switch (key) {
      case 'title':
        title = value;
        break;
      case 'username':
        username = value;
        break;
      case 'password':
        password = value;
        break;
      case 'url':
        url = value;
        break;
      case 'notes':
        notes = value;
        break;
      default:
        fields[key] = value;
    }
  }

  String get displaySubtitle {
    final config = EntryTypes.getConfig(type);
    for (final field in config.fields) {
      if (field.showInList) {
        final value = getField(field.key);
        if (value.isNotEmpty) {
          if (field.isSensitive) {
            return '••••••••';
          }
          return value;
        }
      }
    }
    final usernameValue = getField('username');
    if (usernameValue.isNotEmpty) return usernameValue;
    final emailValue = getField('email');
    if (emailValue.isNotEmpty) return emailValue;
    return '无附加信息';
  }

  IconData get icon => EntryTypes.getIcon(type);
  Color get typeColor => EntryTypes.getColor(type);
  String get typeLabel => EntryTypes.getLabel(type);
  List<EntryFieldConfig> get fieldConfigs => EntryTypes.getFields(type);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'username': username,
      'password': password,
      'url': url,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'fields': fields,
      'isFavorite': isFavorite,
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'],
      type: EntryType.values[json['type']],
      title: json['title'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      url: json['url'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      fields: Map<String, String>.from(json['fields'] ?? json['customFields'] ?? {}),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
    List<String>? tags,
    Map<String, String>? fields,
    bool? isFavorite,
  }) {
    return PasswordEntry(
      id: id,
      type: type,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
      fields: fields ?? Map<String, String>.from(this.fields),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

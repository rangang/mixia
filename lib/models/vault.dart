import 'password_entry.dart';

class Vault {
  final List<PasswordEntry> entries;
  final DateTime createdAt;
  DateTime lastModified;
  String version;

  Vault({
    List<PasswordEntry>? entries,
    DateTime? createdAt,
    DateTime? lastModified,
    this.version = '1.0.0',
  })  : entries = entries ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  factory Vault.fromJson(Map<String, dynamic> json) {
    return Vault(
      entries: (json['entries'] as List?)
              ?.map((e) => PasswordEntry.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      version: json['version'] ?? '1.0.0',
    );
  }

  void addEntry(PasswordEntry entry) {
    entries.add(entry);
    lastModified = DateTime.now();
  }

  void updateEntry(PasswordEntry entry) {
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entries[index] = entry;
      lastModified = DateTime.now();
    }
  }

  void deleteEntry(String id) {
    entries.removeWhere((e) => e.id == id);
    lastModified = DateTime.now();
  }

  PasswordEntry? getEntry(String id) {
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PasswordEntry> getEntriesByType(EntryType type) {
    return entries.where((e) => e.type == type).toList();
  }

  List<PasswordEntry> getFavoriteEntries() {
    return entries.where((e) => e.isFavorite).toList();
  }

  List<PasswordEntry> searchEntries(String query) {
    if (query.isEmpty) return entries;
    final lowerQuery = query.toLowerCase();
    return entries.where((e) {
      if (e.title.toLowerCase().contains(lowerQuery)) return true;
      for (final field in e.fieldConfigs) {
        final value = e.getField(field.key);
        if (value.toLowerCase().contains(lowerQuery)) return true;
      }
      return false;
    }).toList();
  }

  List<PasswordEntry> getRecentEntries({int limit = 5}) {
    final sorted = List<PasswordEntry>.from(entries)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  Map<String, int> getStatistics() {
    return {
      'total': entries.length,
      'login': getEntriesByType(EntryType.login).length,
      'card': getEntriesByType(EntryType.card).length,
      'note': getEntriesByType(EntryType.note).length,
      'identity': getEntriesByType(EntryType.identity).length,
      'favorite': getFavoriteEntries().length,
    };
  }
}

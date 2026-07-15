import 'dart:async';
import 'dart:convert';
import '../models/sync_config.dart';
import 'webdav_service_stub.dart'
    if (dart.library.html) 'webdav_service_web.dart'
    if (dart.library.io) 'webdav_service_io.dart';

abstract class WebDavService {
  factory WebDavService(SyncConfig config) => createService(config);
  
  Future<WebDavUploadResult> testConnection();
  Future<WebDavUploadResult> uploadFile(String fileName, String content);
  Future<WebDavUploadResult> deleteFile(String filePath);
  Future<String?> downloadFileContent(String filePath);
  Future<List<WebDavFileInfo>?> listFiles(String path);
}

class WebDavUploadResult {
  final bool success;
  final String? errorMessage;
  final int? statusCode;

  WebDavUploadResult({
    required this.success,
    this.errorMessage,
    this.statusCode,
  });
}

class WebDavFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final bool isDirectory;

  WebDavFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.isDirectory,
  });
}

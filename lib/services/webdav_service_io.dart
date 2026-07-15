import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'webdav_service.dart';
import '../models/sync_config.dart';

WebDavService createService(SyncConfig config) => WebDavServiceIo(config);

class WebDavServiceIo implements WebDavService {
  final SyncConfig config;
  late final String _baseUrl;
  late final String _authHeader;

  WebDavServiceIo(this.config) {
    String url = config.serverUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _baseUrl = url;
    _authHeader = 'Basic ${base64.encode(utf8.encode('${config.username}:${config.password}'))}';
  }

  String _buildUrl(String path) {
    String normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }
    return '$_baseUrl$normalizedPath';
  }

  Future<HttpClient> _createClient() async {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }

  String _normalizePath(String path, {bool isDirectory = false}) {
    String normalized = path;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (isDirectory && !normalized.endsWith('/')) {
      normalized = '$normalized/';
    }
    if (!isDirectory && normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  @override
  Future<WebDavUploadResult> testConnection() async {
    try {
      final dirPath = _normalizePath(config.path, isDirectory: true);
      final dirResult = await _ensureDirectory(dirPath);
      if (!dirResult.success) {
        return dirResult;
      }

      final url = _buildUrl(dirPath);
      final client = await _createClient();
      
      final request = await client.openUrl('PROPFIND', Uri.parse(url));
      request.headers.set('Authorization', _authHeader);
      request.headers.set('Depth', '1');
      request.headers.set('Content-Type', 'application/xml');
      request.write('''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>''');

      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return WebDavUploadResult(success: true, statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        return WebDavUploadResult(success: false, errorMessage: '认证失败，请检查用户名和密码');
      } else if (response.statusCode == 404) {
        return WebDavUploadResult(success: false, errorMessage: '服务器路径不存在，请检查配置');
      } else {
        return WebDavUploadResult(success: false, errorMessage: '连接失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return WebDavUploadResult(success: false, errorMessage: '连接错误: $e');
    }
  }

  Future<WebDavUploadResult> _ensureDirectory(String path) async {
    final normalizedPath = _normalizePath(path, isDirectory: true);
    final parts = normalizedPath.split('/').where((s) => s.isNotEmpty).toList();
    String currentPath = '';
    
    for (final part in parts) {
      currentPath = '$currentPath/$part/';
      final result = await _createDirectory(currentPath);
      if (!result.success) {
        return result;
      }
    }
    return WebDavUploadResult(success: true);
  }

  Future<WebDavUploadResult> _createDirectory(String path) async {
    try {
      final dirPath = _normalizePath(path, isDirectory: true);
      final url = _buildUrl(dirPath);
      final client = await _createClient();
      
      final request = await client.openUrl('MKCOL', Uri.parse(url));
      request.headers.set('Authorization', _authHeader);

      final response = await request.close();
      await response.drain();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return WebDavUploadResult(success: true);
      } else if (response.statusCode == 405 || response.statusCode == 409) {
        return WebDavUploadResult(success: true);
      } else if (response.statusCode == 401) {
        return WebDavUploadResult(success: false, errorMessage: '认证失败，无法创建目录');
      } else {
        return WebDavUploadResult(success: false, errorMessage: '创建目录失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return WebDavUploadResult(success: false, errorMessage: '创建目录错误: $e');
    }
  }

  @override
  Future<WebDavUploadResult> uploadFile(String fileName, String content) async {
    try {
      final dirPath = _normalizePath(config.path, isDirectory: true);
      final dirResult = await _ensureDirectory(dirPath);
      if (!dirResult.success) return dirResult;

      final cleanFileName = fileName.startsWith('/') ? fileName.substring(1) : fileName;
      final filePath = '$dirPath$cleanFileName';
      final url = _buildUrl(filePath);
      final client = await _createClient();
      
      final request = await client.putUrl(Uri.parse(url));
      request.headers.set('Authorization', _authHeader);
      request.headers.set('Content-Type', 'application/octet-stream');
      request.write(content);

      final response = await request.close();
      await response.drain();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return WebDavUploadResult(success: true, statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        return WebDavUploadResult(success: false, errorMessage: '认证失败，请检查用户名和密码');
      } else {
        return WebDavUploadResult(success: false, errorMessage: '上传失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return WebDavUploadResult(success: false, errorMessage: '上传错误: $e');
    }
  }

  @override
  Future<String?> downloadFileContent(String filePath) async {
    try {
      String fullPath = filePath;
      if (!fullPath.startsWith(config.path) && !fullPath.startsWith('/')) {
        fullPath = '${config.path}/$filePath';
      }
      
      final url = _buildUrl(fullPath);
      final client = await _createClient();
      
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Authorization', _authHeader);

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        return responseBody;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<WebDavUploadResult> deleteFile(String filePath) async {
    try {
      final url = _buildUrl(filePath);
      final client = await _createClient();
      
      final request = await client.deleteUrl(Uri.parse(url));
      request.headers.set('Authorization', _authHeader);

      final response = await request.close();
      await response.drain();
      
      if (response.statusCode >= 200 && response.statusCode < 300 || response.statusCode == 404) {
        return WebDavUploadResult(success: true, statusCode: response.statusCode);
      } else {
        return WebDavUploadResult(success: false, errorMessage: '删除失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return WebDavUploadResult(success: false, errorMessage: '删除错误: $e');
    }
  }

  @override
  Future<List<WebDavFileInfo>?> listFiles(String path) async {
    try {
      final dirPath = _normalizePath(path, isDirectory: true);
      final dirResult = await _ensureDirectory(dirPath);
      if (!dirResult.success) return null;

      final url = _buildUrl(dirPath);
      final client = await _createClient();
      
      final request = await client.openUrl('PROPFIND', Uri.parse(url));
      request.headers.set('Authorization', _authHeader);
      request.headers.set('Depth', '1');
      request.headers.set('Content-Type', 'application/xml');
      request.write('''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>''');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 207) {
        return _parseWebDavListResponse(responseBody, dirPath);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<WebDavFileInfo> _parseWebDavListResponse(String xml, String basePath) {
    final files = <WebDavFileInfo>[];
    
    final responseRegex = RegExp(r'<D:response[^>]*>([\s\S]*?)<\/D:response>', caseSensitive: false);
    final responses = responseRegex.allMatches(xml);

    String normalizedBase = basePath;
    if (!normalizedBase.endsWith('/')) {
      normalizedBase = '$normalizedBase/';
    }
    if (!normalizedBase.startsWith('/')) {
      normalizedBase = '/$normalizedBase';
    }

    for (final match in responses) {
      final responseXml = match.group(1)!;
      
      final hrefRegex = RegExp(r'<D:href[^>]*>([^<]+)<\/D:href>', caseSensitive: false);
      final hrefMatch = hrefRegex.firstMatch(responseXml);
      if (hrefMatch == null) continue;

      String href = Uri.decodeComponent(hrefMatch.group(1)!);
      String normalizedHref = href;
      if (!normalizedHref.startsWith('/')) {
        final uri = Uri.parse(_baseUrl);
        normalizedHref = uri.path;
        if (!normalizedHref.endsWith('/')) normalizedHref = '$normalizedHref/';
        normalizedHref = '$normalizedHref${href.split('/').where((s) => s.isNotEmpty).join('/')}';
      }
      
      if (normalizedHref == normalizedBase || normalizedHref == '${normalizedBase.substring(0, normalizedBase.length - 1)}') {
        continue;
      }

      final name = normalizedHref.split('/').where((s) => s.isNotEmpty).last;
      
      final contentLengthRegex = RegExp(r'<D:getcontentlength[^>]*>([^<]+)<\/D:getcontentlength>', caseSensitive: false);
      final contentLengthMatch = contentLengthRegex.firstMatch(responseXml);
      final size = contentLengthMatch != null ? int.tryParse(contentLengthMatch.group(1)!) ?? 0 : 0;

      final lastModifiedRegex = RegExp(r'<D:getlastmodified[^>]*>([^<]+)<\/D:getlastmodified>', caseSensitive: false);
      final lastModifiedMatch = lastModifiedRegex.firstMatch(responseXml);
      DateTime lastModified = DateTime.now();
      if (lastModifiedMatch != null) {
        try {
          lastModified = HttpDate.parse(lastModifiedMatch.group(1)!);
        } catch (_) {}
      }

      final collectionRegex = RegExp(r'<D:resourcetype[^>]*>[\s\S]*?<D:collection', caseSensitive: false);
      final isDirectory = collectionRegex.hasMatch(responseXml);

      if (!isDirectory) {
        files.add(WebDavFileInfo(
          name: name, 
          path: normalizedHref, 
          size: size, 
          lastModified: lastModified, 
          isDirectory: isDirectory
        ));
      }
    }
    return files;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'webdav_service.dart';
import '../models/sync_config.dart';
import 'dart:js_util' as js_util;

WebDavService createService(SyncConfig config) => WebDavServiceWeb(config);

class WebDavServiceImpl implements WebDavService {
  final SyncConfig config;
  final String _baseUrl;
  final String _authHeader;

  WebDavServiceImpl(this.config)
      : _baseUrl = _normalizeUrl(config.serverUrl),
        _authHeader = 'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}';

  static String _normalizeUrl(String url) {
    String normalizedUrl = url.trim();
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    return normalizedUrl;
  }

  String _buildUrl(String path) {
    if (path.isEmpty) {
      return _baseUrl;
    }
    String normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }
    if (normalizedPath.endsWith('/') && normalizedPath.length > 1) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }
    return '$_baseUrl$normalizedPath';
  }

  Future<WebDavUploadResult> _ensureDirectory(String path) async {
    return WebDavUploadResult(success: true);
  }

  @override
  Future<WebDavUploadResult> testConnection() async {
    try {
      final url = _buildUrl(config.path);
      final uri = Uri.parse(url);
      
      final xhr = html.HttpRequest();
      final completer = Completer<WebDavUploadResult>();
      
      void onComplete(bool success, int status, String? errorMsg) {
        if (completer.isCompleted) return;
        if (status >= 200 && status < 300) {
          completer.complete(WebDavUploadResult(success: true, statusCode: status));
        } else if (status == 401) {
          completer.complete(WebDavUploadResult(success: false, errorMessage: '认证失败，请检查用户名和密码'));
        } else if (status == 404) {
          completer.complete(WebDavUploadResult(success: true, statusCode: status));
        } else {
          completer.complete(WebDavUploadResult(
            success: false,
            errorMessage: errorMsg ?? 'HTTP $status',
          ));
        }
      }
      
      void handleError(String error) {
        if (!completer.isCompleted) {
          completer.complete(WebDavUploadResult(
            success: false,
            errorMessage: _getFriendlyErrorMessage(error),
          ));
        }
      }
      
      void handleTimeout() {
        if (!completer.isCompleted) {
          completer.complete(WebDavUploadResult(
            success: false,
            errorMessage: _getFriendlyErrorMessage('Connection timeout'),
          ));
        }
      }
      
      xhr
        ..open('PROPFIND', url, async: true)
        ..setRequestHeader('Authorization', _authHeader)
        ..setRequestHeader('Depth', '1')
        ..setRequestHeader('Content-Type', 'application/xml')
        ..onLoad.listen((e) {
          onComplete(
            xhr.status != null && xhr.status! >= 0,
            xhr.status ?? -1,
            xhr.status != null && (xhr.status! < 200 || xhr.status! >= 300) ? 'HTTP ${xhr.status}' : null,
          );
        })
        ..onError.listen((e) => handleError('Network error'))
        ..onTimeout.listen((e) => handleTimeout())
        ..send('''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>''');
      
      return await completer.future;
    } catch (e) {
      return WebDavUploadResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.toString()),
      );
    }
  }

  @override
  Future<WebDavUploadResult> uploadFile(String fileName, String content) async {
    try {
      final url = _buildUrl('${config.path}/$fileName');
      final xhr = html.HttpRequest();
      final completer = Completer<WebDavUploadResult>();
      
      xhr
        ..open('PUT', url, async: true)
        ..setRequestHeader('Authorization', _authHeader)
        ..setRequestHeader('Content-Type', 'application/octet-stream')
        ..onLoad.listen((e) {
          completer.complete(WebDavUploadResult(
            success: (xhr.status ?? 0) >= 200 && (xhr.status ?? 0) < 300,
            statusCode: xhr.status,
          ));
        })
        ..onError.listen((e) => completer.complete(WebDavUploadResult(
              success: false,
              errorMessage: _getFriendlyErrorMessage('Upload failed'),
            )))
        ..onTimeout.listen((e) => completer.complete(WebDavUploadResult(
              success: false,
              errorMessage: 'Upload timeout',
            )))
        ..send(content);
      
      return await completer.future;
    } catch (e) {
      return WebDavUploadResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.toString()),
      );
    }
  }

  @override
  Future<WebDavUploadResult> deleteFile(String filePath) async {
    try {
      final url = _buildUrl(filePath);
      final xhr = html.HttpRequest();
      final completer = Completer<WebDavUploadResult>();
      
      xhr
        ..open('DELETE', url, async: true)
        ..setRequestHeader('Authorization', _authHeader)
        ..onLoad.listen((e) {
          final status = xhr.status ?? 0;
          completer.complete(WebDavUploadResult(
            success: status >= 200 && status < 300 || status == 404,
            statusCode: status,
          ));
        })
        ..onError.listen((e) => completer.complete(WebDavUploadResult(
              success: false,
              errorMessage: _getFriendlyErrorMessage('Delete failed'),
            )))
        ..send();
      
      return await completer.future;
    } catch (e) {
      return WebDavUploadResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.toString()),
      );
    }
  }

  @override
  Future<String?> downloadFileContent(String filePath) async {
    try {
      final url = _buildUrl(filePath);
      final xhr = html.HttpRequest();
      final completer = Completer<String?>();
      
      xhr
        ..open('GET', url, async: true)
        ..setRequestHeader('Authorization', _authHeader)
        ..onLoad.listen((e) {
          if (xhr.status == 200) {
            completer.complete(xhr.responseText);
          } else {
            completer.complete(null);
          }
        })
        ..onError.listen((e) => completer.complete(null))
        ..onTimeout.listen((e) => completer.complete(null))
        ..send();
      
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<WebDavFileInfo>?> listFiles(String path) async {
    try {
      final url = _buildUrl(path);
      
      final xhr = html.HttpRequest();
      final completer = Completer<List<WebDavFileInfo>?>();
      
      xhr
        ..open('PROPFIND', url, async: true)
        ..setRequestHeader('Authorization', _authHeader)
        ..setRequestHeader('Depth', '1')
        ..setRequestHeader('Content-Type', 'application/xml')
        ..onLoad.listen((e) {
          if (xhr.status == 200 || xhr.status == 207) {
            completer.complete(_parseWebDavListResponse(xhr.responseText ?? '', path));
          } else {
            completer.complete(null);
          }
        })
        ..onError.listen((e) => completer.complete(null))
        ..onTimeout.listen((e) => completer.complete(null))
        ..send('''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>''');
      
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  List<WebDavFileInfo> _parseWebDavListResponse(String xml, String basePath) {
    final files = <WebDavFileInfo>[];
    final responseRegex = RegExp(r'<D:response[^>]*>([\s\S]*?)<\/D:response>');
    final responses = responseRegex.allMatches(xml);

    for (final match in responses) {
      final responseXml = match.group(1)!;
      final hrefRegex = RegExp(r'<D:href[^>]*>([^<]+)<\/D:href>');
      final hrefMatch = hrefRegex.firstMatch(responseXml);
      if (hrefMatch == null) continue;

      final href = Uri.decodeComponent(hrefMatch.group(1)!);
      if (href == basePath || href == '$basePath/') continue;

      final name = href.split('/').where((s) => s.isNotEmpty).last;
      final contentLengthRegex = RegExp(r'<D:getcontentlength[^>]*>([^<]+)<\/D:getcontentlength>');
      final contentLengthMatch = contentLengthRegex.firstMatch(responseXml);
      final size = contentLengthMatch != null ? int.tryParse(contentLengthMatch.group(1)!) ?? 0 : 0;

      final lastModifiedRegex = RegExp(r'<D:getlastmodified[^>]*>([^<]+)<\/D:getlastmodified>');
      final lastModifiedMatch = lastModifiedRegex.firstMatch(responseXml);
      DateTime lastModified = DateTime.now();
      if (lastModifiedMatch != null) {
        try {
          lastModified = HttpDate.parse(lastModifiedMatch.group(1)!);
        } catch (_) {}
      }

      final collectionRegex = RegExp(r'<D:resourcetype[^>]*>[\s\S]*?<D:collection');
      final isDirectory = collectionRegex.hasMatch(responseXml);

      files.add(WebDavFileInfo(name: name, path: href, size: size, lastModified: lastModified, isDirectory: isDirectory));
    }
    return files;
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Invalid URL') || error.contains('SyntaxError')) {
      return 'URL格式错误：请检查服务器地址格式是否正确';
    } else if (error.contains('CERT_AUTHORITY_INVALID') || error.contains('certificate') || error.contains('SSL') || error.contains('TLS')) {
      return '服务器证书不受信任：请先在浏览器中打开服务器地址并信任证书';
    } else if (error.contains('timeout') || error.contains('Timeout')) {
      return '连接超时：请检查服务器地址和网络连接';
    } else if (error.contains('Network error') || error.contains('Failed') || error.contains('fetch')) {
      return '网络错误：请检查服务器地址是否正确，或CORS策略是否阻止了请求';
    }
    return '连接错误: $error';
  }
}

class HttpDate {
  static DateTime parse(String date) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    final parts = date.split(' ');
    if (parts.length >= 5) {
      final day = int.tryParse(parts[1]) ?? 1;
      final month = months[parts[2]] ?? 1;
      final year = int.tryParse(parts[3]) ?? 2024;
      final timeParts = parts[4].split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final second = int.tryParse(timeParts[2]) ?? 0;
      return DateTime.utc(year, month, day, hour, minute, second);
    }
    return DateTime.now();
  }
}

/// Public alias for WebDavServiceImpl to match the expected class name
typedef WebDavServiceWeb = WebDavServiceImpl;

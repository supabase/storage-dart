import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart';
import 'package:storage_client/src/types.dart';
import 'package:universal_io/io.dart';

Fetch fetch = Fetch();

class Fetch {
  bool _isSuccessStatusCode(int code) {
    return code >= 200 && code <= 299;
  }

  MediaType? _parseMediaType(String path) {
    final mime = lookupMimeType(path);
    return MediaType.parse(mime ?? 'application/octet-stream');
  }

  StorageError _handleError(dynamic error) {
    if (error is http.Response) {
      try {
        final data = json.decode(error.body) as Map<String, dynamic>;
        return StorageError.fromJson(data);
      } on FormatException catch (_) {
        return StorageError(
          error.body,
          statusCode: error.statusCode.toString(),
        );
      }
    } else {
      return StorageError(
        error.toString(),
        statusCode: error.runtimeType.toString(),
      );
    }
  }

  Future<dynamic> _handleRequest(
    String method,
    String url,
    dynamic body,
    FetchOptions? options,
  ) async {
    try {
      final headers = options?.headers ?? {};
      if (method != 'GET') {
        headers['Content-Type'] = 'application/json';
      }
      final bodyStr = json.encode(body ?? {});
      final request = http.Request(method, Uri.parse(url))
        ..headers.addAll(headers)
        ..body = bodyStr;

      final streamedResponse = await request.send();
      return _handleResponse(streamedResponse, options);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future _handleMultipartRequest(
    String method,
    String url,
    File file,
    FileOptions fileOptions,
    FetchOptions? options,
  ) async {
    try {
      final headers = options?.headers ?? {};
      final contentType = fileOptions.mime != null
          ? MediaType.parse(fileOptions.mime!)
          : _parseMediaType(file.path);
      final multipartFile = http.MultipartFile.fromBytes(
        '',
        file.readAsBytesSync(),
        filename: file.path,
        contentType: contentType,
      );
      final request = http.MultipartRequest(method, Uri.parse(url))
        ..headers.addAll(headers)
        ..files.add(multipartFile)
        ..fields['cacheControl'] = fileOptions.cacheControl
        ..headers['x-upsert'] = fileOptions.upsert.toString();

      final streamedResponse = await request.send();
      return _handleResponse(streamedResponse, options);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future _handleBinaryFileRequest(
    String method,
    String url,
    Uint8List data,
    FileOptions fileOptions,
    FetchOptions? options,
  ) async {
    try {
      final headers = options?.headers ?? {};
      final contentType = fileOptions.mime != null
          ? MediaType.parse(fileOptions.mime!)
          : _parseMediaType(url);
      final multipartFile = http.MultipartFile.fromBytes(
        '',
        data,
        // request fails with null filename so set it empty instead.
        filename: '',
        contentType: contentType,
      );
      final request = http.MultipartRequest(method, Uri.parse(url))
        ..headers.addAll(headers)
        ..files.add(multipartFile)
        ..fields['cacheControl'] = fileOptions.cacheControl
        ..headers['x-upsert'] = fileOptions.upsert.toString();

      final streamedResponse = await request.send();
      return _handleResponse(streamedResponse, options);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _handleResponse(
    http.StreamedResponse streamedResponse,
    FetchOptions? options,
  ) async {
    try {
      final response = await http.Response.fromStream(streamedResponse);

      if (_isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return response.bodyBytes;
        } else {
          final jsonBody = json.decode(response.body);
          return jsonBody;
        }
      } else {
        throw response.body;
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> get(String url, {FetchOptions? options}) async {
    return _handleRequest('GET', url, {}, options);
  }

  Future<dynamic> post(
    String url,
    dynamic body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('POST', url, body, options);
  }

  Future<dynamic> put(
    String url,
    dynamic body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('PUT', url, body, options);
  }

  Future<dynamic> delete(
    String url,
    dynamic body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('DELETE', url, body, options);
  }

  Future<dynamic> postFile(
    String url,
    File file,
    FileOptions fileOptions, {
    FetchOptions? options,
  }) async {
    return _handleMultipartRequest('POST', url, file, fileOptions, options);
  }

  Future<dynamic> putFile(
    String url,
    File file,
    FileOptions fileOptions, {
    FetchOptions? options,
  }) async {
    return _handleMultipartRequest('PUT', url, file, fileOptions, options);
  }

  Future<dynamic> postBinaryFile(
    String url,
    Uint8List data,
    FileOptions fileOptions, {
    FetchOptions? options,
  }) async {
    return _handleBinaryFileRequest('POST', url, data, fileOptions, options);
  }

  Future<dynamic> putBinaryFile(
    String url,
    Uint8List data,
    FileOptions fileOptions, {
    FetchOptions? options,
  }) async {
    return _handleBinaryFileRequest('PUT', url, data, fileOptions, options);
  }
}

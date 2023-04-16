import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart';
import 'package:retry/retry.dart';
import 'package:storage_client/src/types.dart';
import 'package:universal_io/io.dart';

Fetch storageFetch = Fetch();

class Fetch {
  final Client? httpClient;

  Fetch([this.httpClient]);

  bool _isSuccessStatusCode(int code) {
    return code >= 200 && code <= 299;
  }

  MediaType? _parseMediaType(String path) {
    final mime = lookupMimeType(path);
    return MediaType.parse(mime ?? 'application/octet-stream');
  }

  StorageException _handleError(dynamic error, StackTrace stack) {
    if (error is http.Response) {
      try {
        final data = json.decode(error.body) as Map<String, dynamic>;
        return StorageException.fromJson(data, '${error.statusCode}');
      } on FormatException catch (_) {
        return StorageException(
          error.body,
          statusCode: '${error.statusCode}',
        );
      }
    } else {
      return StorageException(
        error.toString(),
        statusCode: error.runtimeType.toString(),
      );
    }
  }

  Future<dynamic> _handleRequest(
    String method,
    String url,
    Map<String, dynamic>? body,
    FetchOptions? options,
  ) async {
    final headers = options?.headers ?? {};
    if (method != 'GET') {
      headers['Content-Type'] = 'application/json';
    }

    final request = http.Request(method, Uri.parse(url))
      ..headers.addAll(headers);
    if (body != null) {
      request.body = json.encode(body);
    }

    final http.StreamedResponse streamedResponse;
    if (httpClient != null) {
      streamedResponse = await httpClient!.send(request);
    } else {
      streamedResponse = await request.send();
    }
    return _handleResponse(streamedResponse, options);
  }

  Future<dynamic> _handleMultipartRequest(
    String method,
    String url,
    File file,
    FileOptions fileOptions,
    FetchOptions? options,
    int retryAttempts,
    StorageRetryController? retryController,
  ) async {
    final headers = options?.headers ?? {};
    final contentType = fileOptions.contentType != null
        ? MediaType.parse(fileOptions.contentType!)
        : _parseMediaType(file.path);
    final multipartFile = http.MultipartFile.fromBytes(
      '',
      file.readAsBytesSync(),
      filename: file.path,
      contentType: contentType,
    );
    final request = _ChunkedMultipartRequest(
      method,
      Uri.parse(url),
      onProgress: options?.onRequestProgress,
    )
      ..headers.addAll(headers)
      ..files.add(multipartFile)
      ..fields['cacheControl'] = fileOptions.cacheControl
      ..headers['x-upsert'] = fileOptions.upsert.toString();

    final http.StreamedResponse streamedResponse;
    final r = RetryOptions(maxAttempts: (retryAttempts + 1));
    streamedResponse = await r.retry<http.StreamedResponse>(
      () async {
        if (httpClient != null) {
          return httpClient!.send(request);
        } else {
          return request.send();
        }
      },
      retryIf: (error) =>
          retryController?.cancelled != true &&
          (error is SocketException || error is TimeoutException),
    );

    return _handleResponse(streamedResponse, options);
  }

  Future<dynamic> _handleBinaryFileRequest(
    String method,
    String url,
    Uint8List data,
    FileOptions fileOptions,
    FetchOptions? options,
    int retryAttempts,
    StorageRetryController? retryController,
  ) async {
    final headers = options?.headers ?? {};
    final contentType = fileOptions.contentType != null
        ? MediaType.parse(fileOptions.contentType!)
        : _parseMediaType(url);
    final multipartFile = http.MultipartFile.fromBytes(
      '',
      data,
      // request fails with null filename so set it empty instead.
      filename: '',
      contentType: contentType,
    );
    final request = _ChunkedMultipartRequest(
      method,
      Uri.parse(url),
      onProgress: options?.onRequestProgress,
    )
      ..headers.addAll(headers)
      ..files.add(multipartFile)
      ..fields['cacheControl'] = fileOptions.cacheControl
      ..headers['x-upsert'] = fileOptions.upsert.toString();

    final http.StreamedResponse streamedResponse;
    final r = RetryOptions(maxAttempts: (retryAttempts + 1));
    streamedResponse = await r.retry<http.StreamedResponse>(
      () async {
        if (httpClient != null) {
          return httpClient!.send(request);
        } else {
          return request.send();
        }
      },
      retryIf: (error) =>
          retryController?.cancelled != true &&
          (error is SocketException || error is TimeoutException),
    );

    return _handleResponse(streamedResponse, options);
  }

  Future<dynamic> _handleResponse(
    http.StreamedResponse streamedResponse,
    FetchOptions? options,
  ) async {
    final onResponseProgress = options?.onResponseProgress;

    final Response response;
    if (onResponseProgress == null) {
      response = await http.Response.fromStream(streamedResponse);
    } else {
      response =
          await streamedResponse._getResponseWithProgress(onResponseProgress);
    }

    if (_isSuccessStatusCode(response.statusCode)) {
      if (options?.noResolveJson == true) {
        return response.bodyBytes;
      } else {
        final jsonBody = json.decode(response.body);
        return jsonBody;
      }
    } else {
      throw _handleError(response, StackTrace.current);
    }
  }

  Future<dynamic> get(String url, {FetchOptions? options}) async {
    return _handleRequest('GET', url, null, options);
  }

  Future<dynamic> post(
    String url,
    Map<String, dynamic>? body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('POST', url, body, options);
  }

  Future<dynamic> put(
    String url,
    Map<String, dynamic>? body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('PUT', url, body, options);
  }

  Future<dynamic> delete(
    String url,
    Map<String, dynamic>? body, {
    FetchOptions? options,
  }) async {
    return _handleRequest('DELETE', url, body, options);
  }

  Future<dynamic> postFile(
    String url,
    File file,
    FileOptions fileOptions, {
    FetchOptions? options,
    required int retryAttempts,
    required StorageRetryController? retryController,
  }) async {
    return _handleMultipartRequest('POST', url, file, fileOptions, options,
        retryAttempts, retryController);
  }

  Future<dynamic> putFile(
    String url,
    File file,
    FileOptions fileOptions, {
    FetchOptions? options,
    required int retryAttempts,
    required StorageRetryController? retryController,
  }) async {
    return _handleMultipartRequest(
      'PUT',
      url,
      file,
      fileOptions,
      options,
      retryAttempts,
      retryController,
    );
  }

  Future<dynamic> postBinaryFile(
    String url,
    Uint8List data,
    FileOptions fileOptions, {
    FetchOptions? options,
    required int retryAttempts,
    required StorageRetryController? retryController,
  }) async {
    return _handleBinaryFileRequest(
      'POST',
      url,
      data,
      fileOptions,
      options,
      retryAttempts,
      retryController,
    );
  }

  Future<dynamic> putBinaryFile(
    String url,
    Uint8List data,
    FileOptions fileOptions, {
    FetchOptions? options,
    required int retryAttempts,
    required StorageRetryController? retryController,
  }) async {
    return _handleBinaryFileRequest(
      'PUT',
      url,
      data,
      fileOptions,
      options,
      retryAttempts,
      retryController,
    );
  }
}

extension on http.StreamedResponse {
  // This utility function is modeled on Response.fromStream, but instead of
  // getting the body bytes directly, we insert the progressStream which calls
  // the progress update with each set of byte data emitted.
  Future<Response> _getResponseWithProgress(
    ProgressCallback onProgress,
  ) async {
    var count = 0;
    var total = contentLength ?? -1;

    final progressStream = stream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);
          count += data.length;
          onProgress(count, total);
        },
        handleDone: (sink) => sink.close(),
      ),
    );

    final body = await ByteStream(progressStream).toBytes();

    return Response.bytes(
      body,
      statusCode,
      request: request,
      headers: headers,
      isRedirect: isRedirect,
      persistentConnection: persistentConnection,
      reasonPhrase: reasonPhrase,
    );
  }
}

// In order to support upload progress callbacks, we use a custom
// MultipartRequest. The standard MultipartRequest doesn't work to report upload
// progress, because the added files are added to the byte stream in large (file
// size) chunks, which defeats the purpose of regular callbacks reporting upload
// progress. So this class adds two important transform features to the
// finalized byte stream: first, it breaks up the stream into data chunk sizes
// (as defined by chunkSize); second, for every chunk in the stream, the
// optional progress callback is invoked. If no progress callback is provided,
// then no byte stream transforms are added and this class functions effectively
// the same as the standard MultipartRequest.
class _ChunkedMultipartRequest extends http.MultipartRequest {
  static const chunkSize = 4096;

  final ProgressCallback? onProgress;

  _ChunkedMultipartRequest(
    String method,
    Uri url, {
    this.onProgress,
  }) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();

    if (onProgress == null) {
      return byteStream;
    }

    int count = 0;

    final chunkedProgressStream = byteStream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          var skip = 0;
          while (skip < data.length) {
            final chunk = data.skip(skip).take(chunkSize).toList();
            sink.add(chunk);

            skip += chunk.length;
            count += chunk.length;
            onProgress!(count, contentLength);

            if (chunk.length < chunkSize) return;
          }
        },
        handleDone: (sink) => sink.close(),
      ),
    );

    return ByteStream(chunkedProgressStream);
  }
}

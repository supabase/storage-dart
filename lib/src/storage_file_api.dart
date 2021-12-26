import 'dart:typed_data';

import 'package:storage_client/src/fetch.dart';
import 'package:storage_client/src/types.dart';
import 'package:universal_io/io.dart';

const defaultSearchOptions = SearchOptions(
  limit: 100,
  offset: 0,
  sortBy: SortBy(
    column: 'name',
    order: 'asc',
  ),
);

const defaultFileOptions = FileOptions();

class StorageFileApi {
  const StorageFileApi(this.url, this.headers, this.bucketId);

  final String url;
  final Map<String, String> headers;
  final String? bucketId;

  String _getFinalPath(String path) {
    return '$bucketId/$path';
  }

  /// Uploads a file to an existing bucket.
  ///
  /// [path] The relative file path. Should be of the format
  /// `folder/subfolder/filename.png`. The bucket must already exist before
  /// attempting to upload.
  ///
  /// [file] The File object to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  Future<String> upload(
    String path,
    File file, {
    FileOptions? fileOptions,
  }) async {
    final _path = _getFinalPath(path);
    final response = await fetch.postFile(
      '$url/object/$_path',
      file,
      fileOptions ?? defaultFileOptions,
      options: FetchOptions(headers: headers),
    );

    return (response as Map)['Key'] as String;
  }

  /// Uploads a binary file to an existing bucket. Can be used with Flutter web.
  ///
  /// [path] The relative file path. Should be of the format
  /// `folder/subfolder/filename.png`. The bucket must already exist before
  /// attempting to upload.
  ///
  /// [data] The bytes to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  Future<String> uploadBytes(
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  }) async {
    final _path = _getFinalPath(path);
    final response = await fetch.postBinaryFile(
      '$url/object/$_path',
      data,
      fileOptions ?? defaultFileOptions,
      options: FetchOptions(headers: headers),
    );

    return (response as Map)['Key'] as String;
  }

  /// Replaces an existing file at the specified path with a new one.
  ///
  /// [path] The relative file path. Should be of the format
  /// `folder/subfolder/filename.png`. The bucket must already exist before
  /// attempting to upload.
  ///
  /// [file] The file object to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  Future<String> update(
    String path,
    File file, {
    FileOptions? fileOptions,
  }) async {
    final _path = _getFinalPath(path);
    final response = await fetch.putFile(
      '$url/object/$_path',
      file,
      fileOptions ?? defaultFileOptions,
      options: FetchOptions(headers: headers),
    );

    return response['Key'] as String;
  }

  /// Replaces an existing file at the specified path with a new one.
  ///
  /// [path] The relative file path. Should be of the format
  /// `folder/subfolder/filename.png`. The bucket must already exist before
  /// attempting to upload.
  ///
  /// [data] The bytes to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  Future<String> updateBytes(
    String path,
    Uint8List data, {
    FileOptions? fileOptions,
  }) async {
    final _path = _getFinalPath(path);
    final response = await fetch.putBinaryFile(
      '$url/object/$_path',
      data,
      fileOptions ?? defaultFileOptions,
      options: FetchOptions(headers: headers),
    );

    return response['Key'] as String;
  }

  /// Moves an existing file, optionally renaming it at the same time.
  ///
  /// [fromPath] The original file path, including the current file name.
  /// For example `folder/image.png`.
  ///
  /// [toPath] The new file path, including the new file name. For example
  /// `folder/image-copy.png`.
  Future<String> move(String fromPath, String toPath) async {
    final options = FetchOptions(headers: headers);
    final response = await fetch.post(
      '$url/object/move',
      {
        'bucketId': bucketId,
        'sourceKey': fromPath,
        'destinationKey': toPath,
      },
      options: options,
    );
    return response['message'] as String;
  }

  /// Create signed url to download file without requiring permissions. This URL
  /// can be valid for a set number of seconds.
  ///
  /// [path] The file path to be downloaded, including the current file name.
  /// For example `folder/image.png`.
  ///
  /// [expiresIn] The number of seconds until the signed URL expires. For
  /// example, `60` for a URL which is valid for one minute.
  Future<String> createSignedUrl(
    String path,
    int expiresIn,
  ) async {
    final _path = _getFinalPath(path);
    final options = FetchOptions(headers: headers);
    final response = await fetch.post(
      '$url/object/sign/$_path',
      {'expiresIn': expiresIn},
      options: options,
    );
    final signedUrl = '$url${response['signedURL']}';
    return signedUrl;
  }

  /// Downloads a file.
  ///
  /// [path] The file path to be downloaded, including the path and file name.
  /// For example `folder/image.png`.
  Future<Uint8List> download(String path) async {
    final _path = _getFinalPath(path);
    final options = FetchOptions(headers: headers, noResolveJson: true);
    final response = await fetch.get('$url/object/$_path', options: options);
    return response as Uint8List;
  }

  /// Retrieve URLs for assets in public buckets
  ///
  /// [path] The file path to be downloaded, including the current file name.
  /// For example `folder/image.png`.
  String getPublicUrl(String path) {
    final _path = _getFinalPath(path);
    final publicUrl = '$url/object/public/$_path';
    return publicUrl;
  }

  /// Deletes files within the same bucket
  ///
  /// [paths] An array of files to be deletes, including the path and file name.
  /// For example [`folder/image.png`].
  Future<List<FileObject>> remove(List<String> paths) async {
    final options = FetchOptions(headers: headers);
    final response = await fetch.delete(
      '$url/object/$bucketId',
      {'prefixes': paths},
      options: options,
    );
    final fileObjects = List<FileObject>.from(
      (response as List).cast<Map<String, dynamic>>().map(
            (item) => FileObject.fromJson(item),
          ),
    );
    return fileObjects;
  }

  /// Lists all the files within a bucket.
  ///
  /// [path] The folder path.
  ///
  /// [searchOptions] includes `limit`, `offset`, and `sortBy`.
  Future<List<FileObject>> list({
    String? path,
    SearchOptions? searchOptions,
  }) async {
    final Map<String, dynamic> body = {
      'prefix': path ?? '',
      'limit': searchOptions?.limit ?? defaultSearchOptions.limit,
      'offset': searchOptions?.offset ?? defaultSearchOptions.offset,
      'sort_by': {
        'column': searchOptions?.sortBy?.column ??
            defaultSearchOptions.sortBy!.column,
        'order':
            searchOptions?.sortBy?.order ?? defaultSearchOptions.sortBy!.order,
      },
    };
    final options = FetchOptions(headers: headers);
    final response = await fetch.post(
      '$url/object/list/$bucketId',
      body,
      options: options,
    );
    final fileObjects = List<FileObject>.from(
      (response as List).cast<Map<String, dynamic>>().map(
            (item) => FileObject.fromJson(item),
          ),
    );
    return fileObjects;
  }
}

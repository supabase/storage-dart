import 'dart:typed_data';

import 'package:storage_client/src/fetch.dart';
import 'package:storage_client/src/types.dart';
import 'package:universal_io/io.dart';

class StorageFileApi {
  final String url;
  final Map<String, String> headers;
  final String? bucketId;
  final int _maxAttempts;

  const StorageFileApi(
    this.url,
    this.headers,
    this.bucketId,
    this._maxAttempts,
  );

  String _getFinalPath(String path) {
    return '$bucketId/$path';
  }

  /// Uploads a file to an existing bucket.
  ///
  /// [path] is the relative file path including the bucket ID. Should be of the
  /// format `bucket/folder/subfolder/filename.png`. The bucket must already
  /// exist before attempting to upload.
  ///
  /// [file] is the File object to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  ///
  /// [maxAttempts] overrides the maxAttempts parameter set across the storage client.
  Future<String> upload(
    String path,
    File file, {
    FileOptions fileOptions = const FileOptions(),
    int? maxAttempts,
    StorageAbortController? abortController,
  }) async {
    assert(maxAttempts == null || maxAttempts >= 1,
        'maxAttempts has to be greater or equal to 1');
    final finalPath = _getFinalPath(path);
    final response = await storageFetch.postFile(
      '$url/object/$finalPath',
      file,
      fileOptions,
      options: FetchOptions(headers: headers),
      maxAttempts: maxAttempts ?? _maxAttempts,
      abortController: abortController,
    );

    return (response as Map)['Key'] as String;
  }

  /// Uploads a binary file to an existing bucket. Can be used on the web.
  ///
  /// [path] is the relative file path including the bucket ID. Should be of the
  /// format `bucket/folder/subfolder/filename.png`. The bucket must already
  /// exist before attempting to upload.
  ///
  /// [data] is the binary file data to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  ///
  /// [maxAttempts] overrides the maxAttempts parameter set across the storage client.
  Future<String> uploadBinary(
    String path,
    Uint8List data, {
    FileOptions fileOptions = const FileOptions(),
    int? maxAttempts,
    StorageAbortController? abortController,
  }) async {
    assert(maxAttempts == null || maxAttempts >= 1,
        'maxAttempts has to be greater or equal to 1');
    final finalPath = _getFinalPath(path);
    final response = await storageFetch.postBinaryFile(
      '$url/object/$finalPath',
      data,
      fileOptions,
      options: FetchOptions(headers: headers),
      maxAttempts: maxAttempts ?? _maxAttempts,
      abortController: abortController,
    );

    return (response as Map)['Key'] as String;
  }

  /// Replaces an existing file at the specified path with a new one.
  ///
  /// [path] is the relative file path including the bucket ID. Should be of the
  /// format `bucket/folder/subfolder`. The bucket already exist before
  /// attempting to upload.
  /// [file] is the file object to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  ///
  /// [maxAttempts] overrides the maxAttempts parameter set across the storage client.
  Future<String> update(
    String path,
    File file, {
    FileOptions fileOptions = const FileOptions(),
    int? maxAttempts,
    StorageAbortController? abortController,
  }) async {
    assert(maxAttempts == null || maxAttempts >= 1,
        'maxAttempts has to be greater or equal to 1');
    final finalPath = _getFinalPath(path);
    final response = await storageFetch.putFile(
      '$url/object/$finalPath',
      file,
      fileOptions,
      options: FetchOptions(headers: headers),
      maxAttempts: maxAttempts ?? _maxAttempts,
      abortController: abortController,
    );

    return (response as Map<String, dynamic>)['Key'] as String;
  }

  /// Replaces an existing file at the specified path with a new one. Can be
  /// used on the web.
  ///
  /// [path] is the relative file path including the bucket ID. Should be of the
  /// format `bucket/folder/subfolder`. The bucket already exist before
  /// attempting to upload.
  ///
  /// [data] is the binary file data to be stored in the bucket.
  ///
  /// [fileOptions] HTTP headers. For example `cacheControl`
  ///
  /// [maxAttempts] overrides the maxAttempts parameter set across the storage client.
  Future<String> updateBinary(
    String path,
    Uint8List data, {
    FileOptions fileOptions = const FileOptions(),
    int? maxAttempts,
    StorageAbortController? abortController,
  }) async {
    assert(maxAttempts == null || maxAttempts >= 1,
        'maxAttempts has to be greater or equal to 1');
    final finalPath = _getFinalPath(path);
    final response = await storageFetch.putBinaryFile(
      '$url/object/$finalPath',
      data,
      fileOptions,
      options: FetchOptions(headers: headers),
      maxAttempts: maxAttempts ?? _maxAttempts,
      abortController: abortController,
    );

    return (response as Map)['Key'] as String;
  }

  /// Moves an existing file.
  ///
  /// [fromPath] is the original file path, including the current file name. For
  /// example `folder/image.png`.
  /// [toPath] is the new file path, including the new file name. For example
  /// `folder/image-new.png`.
  Future<String> move(String fromPath, String toPath) async {
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.post(
      '$url/object/move',
      {
        'bucketId': bucketId,
        'sourceKey': fromPath,
        'destinationKey': toPath,
      },
      options: options,
    );
    return (response as Map<String, dynamic>)['message'] as String;
  }

  /// Copies an existing file.
  ///
  /// [fromPath] is the original file path, including the current file name. For
  /// example `folder/image.png`.
  ///
  /// [toPath] is the new file path, including the new file name. For example
  /// `folder/image-copy.png`.
  Future<String> copy(String fromPath, String toPath) async {
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.post(
      '$url/object/copy',
      {
        'bucketId': bucketId,
        'sourceKey': fromPath,
        'destinationKey': toPath,
      },
      options: options,
    );
    return (response as Map<String, dynamic>)['message'] as String;
  }

  /// Create signed URL to download file without requiring permissions. This URL
  /// can be valid for a set number of seconds.
  ///
  /// [path] is the file path to be downloaded, including the current file
  /// names. For example: `createdSignedUrl('folder/image.png')`.
  ///
  /// [expiresIn] is the number of seconds until the signed URL expire. For
  /// example, `60` for a URL which are valid for one minute.
  ///
  /// The signed url is returned.
  Future<String> createSignedUrl(
    String path,
    int expiresIn,
  ) async {
    final finalPath = _getFinalPath(path);
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.post(
      '$url/object/sign/$finalPath',
      {'expiresIn': expiresIn},
      options: options,
    );
    final signedUrlPath = (response as Map<String, dynamic>)['signedURL'];
    final signedUrl = '$url$signedUrlPath';
    return signedUrl;
  }

  /// Create signed URLs to download files without requiring permissions. These
  /// URLs can be valid for a set number of seconds.
  ///
  /// [paths] is the file paths to be downloaded, including the current file
  /// names. For example: `createdSignedUrl(['folder/image.png', 'folder2/image2.png'])`.
  ///
  /// [expiresIn] is the number of seconds until the signed URLs expire. For
  /// example, `60` for URLs which are valid for one minute.
  ///
  /// A list of [SignedUrl]s is returned.
  Future<List<SignedUrl>> createSignedUrls(
    List<String> paths,
    int expiresIn,
  ) async {
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.post(
      '$url/object/sign/$bucketId',
      {
        'expiresIn': expiresIn,
        'paths': paths,
      },
      options: options,
    );
    final List<SignedUrl> urls = (response as List).map((e) {
      return SignedUrl(
        path: e['path'],
        signedUrl: e['signedURL'],
      );
    }).toList();
    return urls;
  }

  /// Downloads a file.
  ///
  /// [path] is the file path to be downloaded, including the path and file
  /// name. For example `download('folder/image.png')`.
  Future<Uint8List> download(String path) async {
    final finalPath = _getFinalPath(path);
    final options = FetchOptions(headers: headers, noResolveJson: true);
    final response =
        await storageFetch.get('$url/object/$finalPath', options: options);
    return response as Uint8List;
  }

  /// Retrieve URLs for assets in public buckets
  ///
  /// [path] is the file path to be downloaded, including the current file name.
  /// For example `getPublicUrl('folder/image.png')`.
  String getPublicUrl(String path) {
    final finalPath = _getFinalPath(path);
    final publicUrl = '$url/object/public/$finalPath';
    return publicUrl;
  }

  /// Deletes files within the same bucket
  ///
  /// [paths] is an array of files to be deleted, including the path and file
  /// name. For example: `remove(['folder/image.png'])`.
  Future<List<FileObject>> remove(List<String> paths) async {
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.delete(
      '$url/object/$bucketId',
      {'prefixes': paths},
      options: options,
    );
    final fileObjects = List<FileObject>.from(
      (response as List).map(
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
    SearchOptions searchOptions = const SearchOptions(),
  }) async {
    final Map<String, dynamic> body = {
      'prefix': path ?? '',
      ...searchOptions.toMap(),
    };
    final options = FetchOptions(headers: headers);
    final response = await storageFetch.post(
      '$url/object/list/$bucketId',
      body,
      options: options,
    );
    final fileObjects = List<FileObject>.from(
      (response as List).map(
        (item) => FileObject.fromJson(item),
      ),
    );
    return fileObjects;
  }
}

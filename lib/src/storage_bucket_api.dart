import 'package:http/http.dart';
import 'package:storage_client/src/fetch.dart';
import 'package:storage_client/src/types.dart';

class StorageBucketApi {
  StorageBucketApi(this.url, this.headers, {Client? httpClient}) {
    fetch = Fetch(httpClient);
  }

  final String url;
  final Map<String, String> headers;

  /// Retrieves the details of all Storage buckets within an existing product.
  Future<StorageResponse<List<Bucket>>> listBuckets() async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response = await fetch.get('$url/bucket', options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final buckets = List<Bucket>.from(
          (response.data as List).map(
            (value) => Bucket.fromJson(value),
          ),
        );
        return StorageResponse<List<Bucket>>(data: buckets);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Retrieves the details of an existing Storage bucket.
  ///
  /// [id] The unique identifier of the bucket you would like to retrieve.
  Future<StorageResponse<Bucket>> getBucket(String id) async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response = await fetch.get('$url/bucket/$id', options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<Bucket>(data: Bucket.fromJson(response.data));
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Creates a new Storage bucket
  ///
  /// [id] A unique identifier for the bucket you are creating.
  /// [bucketOptions] A parameter to optionally make the bucket public.
  Future<StorageResponse<String>> createBucket(
    String id, [
    BucketOptions bucketOptions = const BucketOptions(public: false),
  ]) async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response = await fetch.post(
        '$url/bucket',
        {'id': id, 'name': id, 'public': bucketOptions.public},
        options: options,
      );
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final bucketId =
            (response.data as Map<String, dynamic>)['name'] as String;
        return StorageResponse<String>(data: bucketId);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Updates a new Storage bucket
  ///
  /// [id] A unique identifier for the bucket you are creating.
  /// [bucketOptions] A parameter to set the publicity of the bucket.
  Future<StorageResponse<String>> updateBucket(
    String id,
    BucketOptions bucketOptions,
  ) async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response = await fetch.put(
        '$url/bucket/$id',
        {'id': id, 'public': bucketOptions.public},
        options: options,
      );
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final message =
            (response.data as Map<String, dynamic>)['message'] as String;
        return StorageResponse<String>(data: message);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Removes all objects inside a single bucket.
  ///
  /// [id] The unique identifier of the bucket you would like to empty.
  Future<StorageResponse<String>> emptyBucket(String id) async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response =
          await fetch.post('$url/bucket/$id/empty', {}, options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<String>(
          data: (response.data as Map<String, dynamic>)['message'] as String,
        );
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Deletes an existing bucket. A bucket can't be deleted with existing objects inside it.
  /// You must first `emptyBucket()` the bucket.
  ///
  /// [id] The unique identifier of the bucket you would like to delete.
  Future<StorageResponse<String>> deleteBucket(String id) async {
    try {
      final FetchOptions options = FetchOptions(headers: headers);
      final response =
          await fetch.delete('$url/bucket/$id', {}, options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<String>(
          data: (response.data as Map<String, dynamic>)['message'] as String,
        );
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }
}

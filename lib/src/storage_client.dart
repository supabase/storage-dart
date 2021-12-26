import 'constants.dart';
import 'storage_bucket_api.dart';
import 'storage_file_api.dart';

class SupabaseStorageClient extends StorageBucketApi {
  SupabaseStorageClient(String url, Map<String, String> headers)
      : super(url, {...Constants.defaultHeaders, ...headers});

  /// Perform file operation in a bucket.
  ///
  /// [id] The bucket id to operate on.
  StorageFileApi from(String id) {
    return StorageFileApi(url, headers, id);
  }
}

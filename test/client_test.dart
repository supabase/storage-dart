import 'package:mocktail/mocktail.dart';
import 'package:storage_client/storage_client.dart';
import 'package:test/test.dart';

const storageUrl = 'http://localhost:8000/storage/v1';
const storageKey =
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTYwMzk2ODgzNCwiZXhwIjoyNTUwNjUzNjM0LCJhdWQiOiIiLCJzdWIiOiIzMTdlYWRjZS02MzFhLTQ0MjktYTBiYi1mMTlhN2E1MTdiNGEiLCJSb2xlIjoicG9zdGdyZXMifQ.pZobPtp6gDcX0UbzMmG3FHSlg4m4Q-22tKtGWalOrNo';

final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
final newBucketName = 'my-new-bucket-$timestamp';

void main() {
  late SupabaseStorageClient client;

  setUp(() {
    // init SupabaseClient with test url & test key
    client = SupabaseStorageClient(storageUrl, {
      'Authorization': 'Bearer $storageKey',
    });

    // Register default mock values (used by mocktail)
    registerFallbackValue<FileOptions>(const FileOptions());
    registerFallbackValue<FetchOptions>(const FetchOptions());
  });

  test('List buckets', () async {
    try {
      final response = await client.listBuckets();
      expect(response.length, 4);
    } catch (e) {
      fail(e.toString());
    }
  });

  test('Get bucket by id', () async {
    try {
      final response = await client.getBucket('bucket2');
      expect(response.name, 'bucket2');
    } catch (e) {
      fail(e.toString());
    }
  });

  test('Get bucket with wrong id', () async {
    try {
      await client.getBucket('not-exist-id');
      fail('Bucket with wrong id found');
    } catch (e) {
      expect(e, isNotNull);
    }
  });

  test('Create new bucket', () async {
    try {
      final response = await client.createBucket(newBucketName);
      expect(response, newBucketName);
    } catch (e) {
      fail(e.toString());
    }
  });

  test('Create new public bucket', () async {
    try {
      const newPublicBucketName = 'my-new-public-bucket';
      await client.createBucket(
        newPublicBucketName,
        const BucketOptions(public: true),
      );
      final response = await client.getBucket(newPublicBucketName);
      expect(response.public, true);
    } catch (e) {
      fail(e.toString());
    }
  });

  test('update bucket', () async {
    try {
      final updateRes = await client.updateBucket(
        newBucketName,
        const BucketOptions(public: true),
      );
      expect(updateRes, isA<String>());
      final getRes = await client.getBucket(newBucketName);
      expect(getRes.public, true);
    } catch (e) {
      fail(e.toString());
    }
  });

  test('Empty bucket', () async {
    try {
      final response = await client.emptyBucket(newBucketName);
      expect(response, 'Successfully emptied');
    } catch (e) {
      fail(e.toString());
    }
  });

  test('Delete bucket', () async {
    try {
      final response = await client.deleteBucket(newBucketName);
      expect(response, 'Successfully deleted');
    } catch (e) {
      fail(e.toString());
    }
  });
}

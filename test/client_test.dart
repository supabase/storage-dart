import 'package:mocktail/mocktail.dart';
import 'package:storage_client/src/types.dart';
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
    registerFallbackValue(const FileOptions());
    registerFallbackValue(const FetchOptions());
  });

  test('List buckets', () async {
    final response = await client.listBuckets();
    expect(response.length, 4);
  });

  test('Get bucket by id', () async {
    final response = await client.getBucket('bucket2');
    expect(response.name, 'bucket2');
  });

  test('Get bucket with wrong id', () async {
    try {
      await client.getBucket('not-exist-id');
      fail('Bucket that does not exist was found');
    } catch (error) {
      expect(error, isNotNull);
    }
  });

  test('Create new bucket', () async {
    final response = await client.createBucket(newBucketName);
    expect(response, newBucketName);
  });

  test('Create new public bucket', () async {
    const newPublicBucketName = 'my-new-public-bucket';
    await client.createBucket(
      newPublicBucketName,
      const BucketOptions(public: true),
    );
    final response = await client.getBucket(newPublicBucketName);
    expect(response.public, true);
    expect(response.name, newPublicBucketName);
  });

  test('update bucket', () async {
    final updateRes = await client.updateBucket(
      newBucketName,
      const BucketOptions(public: true),
    );
    expect(updateRes, 'Successfully updated');

    final getRes = await client.getBucket(newBucketName);
    expect(getRes.public, true);
  });

  test('Empty bucket', () async {
    final response = await client.emptyBucket(newBucketName);
    expect(response, 'Successfully emptied');
  });

  test('Delete bucket', () async {
    final response = await client.deleteBucket(newBucketName);
    expect(response, 'Successfully deleted');
  });
}

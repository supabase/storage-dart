import 'dart:io';

import 'package:mime/mime.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_client/src/types.dart';
import 'package:storage_client/storage_client.dart';
import 'package:test/test.dart';
import "package:path/path.dart" show join;

const storageUrl = 'http://localhost:8000/storage/v1';
const storageKey =
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTYwMzk2ODgzNCwiZXhwIjoyNTUwNjUzNjM0LCJhdWQiOiIiLCJzdWIiOiIzMTdlYWRjZS02MzFhLTQ0MjktYTBiYi1mMTlhN2E1MTdiNGEiLCJSb2xlIjoicG9zdGdyZXMifQ.pZobPtp6gDcX0UbzMmG3FHSlg4m4Q-22tKtGWalOrNo';

final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
final newBucketName = 'my-new-bucket-$timestamp';

final uploadPath = 'testpath/file-${DateTime.now().toIso8601String()}.jpg';

void main() {
  late SupabaseStorageClient storage;

  late File file;

  Future<String> findOrCreateBucket(String name, [bool isPublic = true]) async {
    try {
      await storage.getBucket(name);
    } catch (error) {
      await storage.createBucket(name, BucketOptions(public: isPublic));
    }
    return name;
  }

  setUp(() async {
    // init SupabaseClient with test url & test key
    storage = SupabaseStorageClient(storageUrl, {
      'Authorization': 'Bearer $storageKey',
    });

    // Register default mock values (used by mocktail)
    registerFallbackValue(const FileOptions());
    registerFallbackValue(const FetchOptions());
    file = File(join(
        Directory.current.path, 'test', 'fixtures', 'upload', 'sadcat.jpg'));
  });

  test('List files', () async {
    final response = await storage.from('bucket2').list(path: 'public');
    expect(response.length, 2);
  });

  test('List buckets', () async {
    final response = await storage.listBuckets();
    expect(response.length, 4);
  });

  test('Get bucket by id', () async {
    final response = await storage.getBucket('bucket2');
    expect(response.name, 'bucket2');
  });

  test('Get bucket with wrong id', () async {
    try {
      await storage.getBucket('not-exist-id');
      fail('Bucket that does not exist was found');
    } catch (error) {
      expect(error, isNotNull);
    }
  });

  test('Create new bucket', () async {
    final response = await storage.createBucket(newBucketName);
    expect(response, newBucketName);
  });

  test('Create new public bucket', () async {
    const newPublicBucketName = 'my-new-public-bucket';
    await storage.createBucket(
      newPublicBucketName,
      const BucketOptions(public: true),
    );
    final response = await storage.getBucket(newPublicBucketName);
    expect(response.public, true);
    expect(response.name, newPublicBucketName);
  });

  test('update bucket', () async {
    final updateRes = await storage.updateBucket(
      newBucketName,
      const BucketOptions(public: true),
    );
    expect(updateRes, 'Successfully updated');

    final getRes = await storage.getBucket(newBucketName);
    expect(getRes.public, true);
  });

  test('Empty bucket', () async {
    final response = await storage.emptyBucket(newBucketName);
    expect(response, 'Successfully emptied');
  });

  test('Delete bucket', () async {
    final response = await storage.deleteBucket(newBucketName);
    expect(response, 'Successfully deleted');
  });

  group('Transformations', () {
    test('sign url with transform options', () async {
      await storage.from(newBucketName).upload(uploadPath, file);
      final url =
          await storage.from(newBucketName).createSignedUrl(uploadPath, 2000,
              transform: TransformOptions(
                width: 100,
                height: 100,
              ));

      expect(
          url.contains(
              '$storageUrl/render/image/sign/$newBucketName/$uploadPath'),
          isTrue);
    });

    test('gets public url with transformation options', () async {
      final url = storage.from(newBucketName).getPublicUrl(uploadPath,
          transform: TransformOptions(width: 200, height: 300));

      expect(url,
          '$storageUrl/render/image/public/$newBucketName/$uploadPath?width=200&height=300');
    });

    test('will download a public transformed file', () async {
      // await storage.from(bucketName).upload(uploadPath, file);
      final bytesArray =
          await storage.from(newBucketName).publicDownload(uploadPath,
              transform: TransformOptions(
                width: 200,
                height: 200,
              ));

      final downloadedFile = File.fromRawPath(bytesArray);
      final size = downloadedFile.length();
      final type = lookupMimeType(downloadedFile.path);
      expect(size, isPositive);
      expect(type, 'image/jpeg');
    });

    test('will download an authenticated transformed file', () async {
      const privateBucketName = 'my-private-bucket';
      await findOrCreateBucket(privateBucketName);

      await storage.from(privateBucketName).upload(uploadPath, file);

      final bytesArray = await storage
          .from(privateBucketName)
          .authenticatedDownload(uploadPath,
              transform: TransformOptions(width: 200, height: 200));

      final downloadedFile = File.fromRawPath(bytesArray);
      final size = downloadedFile.length();
      final type = lookupMimeType(downloadedFile.path);

      expect(size, isPositive);
      expect(type, 'image/jpeg');
    });
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:storage_client/storage_client.dart';

Future<void> main() async {
  const supabaseUrl = '';
  const supabaseKey = '';
  final client = SupabaseStorageClient(
    '$supabaseUrl/storage/v1',
    {
      'Authorization': 'Bearer $supabaseKey',
    },
  );

  // Upload a list of bytes
  final List<int> listBytes = 'Hello world'.codeUnits;
  final Uint8List fileData = Uint8List.fromList(listBytes);
  try {
    final uploadBinaryResponse = await client.from('public').uploadBytes(
          'binaryExample.txt',
          fileData,
          fileOptions: const FileOptions(upsert: true),
        );
    print('upload binary response: $uploadBinaryResponse');
  } catch (e) {
    print('failed to upload a list of bytes: $e');
  }

  // Upload file to bucket "public"
  final file = File('example.txt');
  await file.writeAsString('File content');

  try {
    final key = await client.from('public').upload('example.txt', file);
    print('file uploaded: $key');
  } catch (e) {
    print('failed to upload file');
  }

  // Get download url
  try {
    final url = await client.from('public').createSignedUrl('example.txt', 60);
    print('download url: $url');
  } catch (e) {
    print('Error getting signed url: $e');
  }

  // Download text file
  try {
    final fileResponse = await client.from('public').download('example.txt');
    print('downloaded file : ${String.fromCharCodes(fileResponse)}');
  } catch (e) {
    print('Error while downloading file: $e');
  }

  // Delete file
  try {
    final deleteResponse = await client.from('public').remove(['example.txt']);
    print('deleted file id: ${deleteResponse.first.id}');
  } catch (e) {
    print('Error while deleting file: $e');
  }

  // Local file cleanup
  if (file.existsSync()) await file.delete();
}

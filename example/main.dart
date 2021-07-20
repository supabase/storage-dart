import 'dart:io';
import 'dart:typed_data';

import 'package:storage_client/storage_client.dart';

Future<void> main() async {
  const supabaseUrl = '';
  const supabaseKey = '';
  final client = SupabaseStorageClient(
      '$supabaseUrl/storage/v1', {'Authorization': 'Bearer $supabaseKey'});

  // Upload binary file
  final List<int> listBytes = 'Hello world'.codeUnits;
  final Uint8List fileData = Uint8List.fromList(listBytes);
  final uploadBinaryResponse = await client.from('public-images').uploadBinary(
      'binaryExample.txt', fileData,
      fileOptions: const FileOptions(upsert: true));
  print('upload binary response : ${uploadBinaryResponse.data}');

  // Upload file to bucket "public"
  final file = File('example.txt');
  file.writeAsStringSync('File content');
  final storageResponse =
      await client.from('public').upload('example.txt', file);
  print('upload response : ${storageResponse.data}');

  // Get download url
  final urlResponse =
      await client.from('public').createSignedUrl('example.txt', 60);
  print('download url : ${urlResponse.data}');

  // Download text file
  final fileResponse = await client.from('public').download('example.txt');
  if (fileResponse.hasError) {
    print('Error while downloading file : ${fileResponse.error}');
  } else {
    print('downloaded file : ${String.fromCharCodes(fileResponse.data!)}');
  }

  // Delete file
  final deleteResponse = await client.from('public').remove(['example.txt']);
  print('deleted file id : ${deleteResponse.data?.first.id}');

  // Local file cleanup
  if (file.existsSync()) file.deleteSync();
}
